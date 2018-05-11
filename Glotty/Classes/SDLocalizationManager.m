// Copyright 2017 Sysdata S.p.A.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "SDLocalizationManager.h"
#import "SDLocalizationManagerModels.h"
#import "GTYFileManager.h"

#define USER_DEF_LOCALE_KEY             @"APP_LANGUAGE_SETTING"
#define USER_DEF_DATE_FORMAT            @"LM_USER_DEF_DATE_FORMAT"
#define USER_DEF_TIME_FORMAT            @"LM_USER_DEF_TIME_FORMAT"
#define USER_DEF_DISTANCE_UNIT          @"LM_USER_DEF_DISTANCE_UNIT"
#define USER_DEF_SPEED_UNIT             @"LM_USER_DEF_SPEED_UNIT"
#define USER_DEF_CURRENCY_SYMBOL        @"LM_USER_DEF_CURRENCY_SYMBOL"
#define USER_DEF_TIME_ZONE              @"LM_USER_DEF_TIME_ZONE"
#define USER_DEF_CALENDAR_ID            @"LM_USER_DEF_CALENDAR_ID"

#define kDisplayNameLocalizedKeyPrefix  @"LM_locale_name"

#define kSelectedLocaleTablesKey        @"selectedLocalesTables"
#define kBaseLocaleTablesKey            @"baseLocalesTables"
#define kDefaultLocaleTablesKey         @"defaultLocaleTables"

NSString* SDLocalizedString(NSString *key)
{
    return [[SDLocalizationManager sharedManager] localizedKey:key];
}
NSString* SDLocalizedStringFromTable(NSString *key, NSString *table)
{
    return [[SDLocalizationManager sharedManager] localizedKey:key fromTable:table];
}
NSString* SDLocalizedStringWithDefault(NSString *key, NSString *val)
{
    return [[SDLocalizationManager sharedManager] localizedKey:key withDefaultValue:val];
}
NSString* SDLocalizedStringFromTableWithDefault(NSString * key,NSString *table, NSString *val)
{
    return [[SDLocalizationManager sharedManager] localizedKey:key fromTable:table withDefaultValue:val];
}

NSString* SDLocalizedStringWithPlaceholders(NSString* key, NSDictionary<NSString*, NSString*>* placeholders)
{
    return [[SDLocalizationManager sharedManager] localizedKey:key fromTable:@"Localizable" placeholderDictionary:placeholders withDefaultValue:nil];
}

NSString* SDLocalizedStringInBundleForClass(NSString * key, Class bundleClass)
{
    return [[SDLocalizationManager sharedManager] localizedKey:key fromTable:@"Localizable" inBundleForClass:bundleClass withDefaultValue:nil];
}

NSString* SDLocalizedStringFromTableInBundleForClass(NSString * key, NSString *table, Class bundleClass)
{
    return [[SDLocalizationManager sharedManager] localizedKey:key fromTable:table inBundleForClass:bundleClass withDefaultValue:nil];
}

NSString* SDLocalizedStringFromTableInBundleForClassWithDefault(NSString * key, NSString *table, Class bundleClass, NSString *val)
{
    return [[SDLocalizationManager sharedManager] localizedKey:key fromTable:table inBundleForClass:bundleClass withDefaultValue:val];
}

UIImage* SDLocalizedImage(NSString * key)
{
    UIImage *image = SDLocalizedImageWithNameAndExtension(key, @"png");
    
    if (!image)
    {
        image =  SDLocalizedImageWithNameAndExtension(key, @"jpg");
    }
    if (!image)
    {
        image =  SDLocalizedImageWithNameAndExtension(key, @"jpeg");
    }
    if (!image)
    {
        image =  SDLocalizedImageWithNameAndExtension(key, nil);
    }
    return image;
}



UIImage* SDLocalizedImageWithNameAndExtension(NSString * key, NSString *type)
{
    UIImage *image;
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:key ofType:type inDirectory:nil forLocalization:[SDLocalizationManager sharedManager].selectedLocale.localeIdentifier];
    if (!imagePath)
    {
        SDLogError(@"Path image nil for key: %@ and type: %@", key, type);
        
    }else
    {
        image = [UIImage imageWithContentsOfFile:imagePath];
    }
    return image;
}



@interface SDLocalizationManager ()

@property (nonatomic, strong) NSMutableOrderedSet *locales; // NSString
@property (nonatomic, strong) SDLocalizationDataSource* dataSource;

/**
 * This locale is only used if the selectedLocale is not an ISO standard and is the standard alternative for localization and formatting.
 */
@property (nonatomic, strong) NSLocale* correspondingStandardLocale;

@property (nonatomic, strong) NSString* pathForDynamicStrings;

@end

@implementation SDLocalizationManager

#pragma mark - Singleton Pattern
+ (instancetype) sharedManager
{
    static dispatch_once_t pred;
    static id sharedManagerInstance_ = nil;
    
    dispatch_once(&pred, ^{
        sharedManagerInstance_ = [[self alloc] init];
    });
    
    return sharedManagerInstance_;
}

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self)
    {
#if BLABBER
        SDLogLevel logLevel = SDLogLevelWarning;
#if DEBUG
        logLevel = SDLogLevelInfo;
#endif
        
        [[SDLogger sharedLogger] setLogLevel:logLevel forModuleWithName:self.loggerModuleName];
#endif
        
        _defaultLocale = nil;
        _selectedLocale = nil;
        _allowsOnlyLocalesAvailableOnSystem = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTimeZone) name:NSSystemTimeZoneDidChangeNotification object:nil];
        
        NSString* path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Localizations"];
        if ([GTYFileManager createDirectoryAtPath:path withIntermediateDirectories:YES])
        {
            self.pathForDynamicStrings = path;
        }
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - SDLoggerModuleProtocol

#if BLABBER

- (NSString *) loggerModuleName
{
    return kLocalizationManagerLogModuleName;
}

- (SDLogLevel)loggerModuleLogLevel
{
    return [[SDLogger sharedLogger] logLevelForModuleWithName:self.loggerModuleName];
}

- (void)setLoggerModuleLogLevel:(SDLogLevel)level
{
    [[SDLogger sharedLogger] setLogLevel:level forModuleWithName:self.loggerModuleName];
}
#endif

#pragma mark - Notifications

- (void)resetTimeZone
{
    [NSTimeZone resetSystemTimeZone];
}

#pragma mark - Selected Locale & Default Locale

- (void) setSelectedLocaleWithIdentifier:(NSString *)identifier persistingSelection:(BOOL)persisting
{
    if ([self.selectedLocale.localeIdentifier isEqualToString:identifier])
    {
        SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"The selected locale did not change: %@", identifier);
        if (persisting)
        {
            [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:USER_DEF_LOCALE_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        return;
    }
    
    // Verify if the past locale is supported
    NSLocale *locale = [self supportedLocaleWithIdentifier:identifier];
    if (locale)
    {
        // save selected locale only if requested
        _selectedLocale = locale;
        if (persisting)
        {
            [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:USER_DEF_LOCALE_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"New locale selected: %@", locale.localeIdentifier);
        
        // If the manager adopts no-standard locales and is a no-standard locale, ask the delegate the standard fee
        self.correspondingStandardLocale = nil;
        if (!self.allowsOnlyLocalesAvailableOnSystem && ![NSLocale isLocaleIdentifierAvailableOnSystem:identifier])
        {
            [self setupCorrespondingStandardLocaleFromIdentifier:identifier];
        }
        
        // reinit label structure
        [self resetLocalizedTables];
        
        // reset formatters
        [self resetFormattersAndCalendars];
    }
    else
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"The given selected locale (%@) is not supported. The selected locale is %@", identifier, self.selectedLocale.localeIdentifier);
    }
}

- (void) resetLocalizedTables
{
    self.dataSource = [SDLocalizationDataSource new];
    self.dataSource.selectedLocale.languageID = [self ISOSelectedLocale].languageID;
    self.dataSource.baseLocale.languageID = [self ISOSelectedLocale].baseLanguageLocale.languageID;
    self.dataSource.defaultLocale.languageID = self.defaultLocale.languageID;
    
    // fire the notification
    [[NSNotificationCenter defaultCenter] postNotificationName:SDLocalizationManagerLanguageDidChangeNotification object:self.selectedLocale];
}

- (void)setSelectedLocaleWithIdentifier:(NSString *)identifier
{
    [self setSelectedLocaleWithIdentifier:identifier persistingSelection:YES];
}

- (BOOL)isLocaleWithIdentifierSelected:(NSString *)identifier
{
    return [self.selectedLocale.localeIdentifier isEqualToString:identifier];
}

- (void)setDefaultLocaleWithIdentifier:(NSString *)identifier
{
    if ([self.defaultLocale.localeIdentifier isEqualToString:identifier])
    {
        // current locale didn't change
        return;
    }
    
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:identifier];
    _defaultLocale = locale;
    SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Default Locale setted to %@", identifier);
}

- (void) setupCorrespondingStandardLocaleFromIdentifier:(NSString*)identifier
{
    if ([self.delegate respondsToSelector:@selector(ISOLocaleIdentifierForNonStandardLocale:)])
    {
        NSString *standardLocale = [self.delegate ISOLocaleIdentifierForNonStandardLocale:identifier];
        self.correspondingStandardLocale = [NSLocale localeWithLocaleIdentifier:standardLocale];
        
        // Verify that the indicated locale is valid and standard
        if (![NSLocale isLocaleIdentifierAvailableOnSystem:standardLocale] || !self.correspondingStandardLocale)
        {
            SDLogModuleError(kLocalizationManagerLogModuleName, @"The indicated standard locale (%@) is not valid. Fallback to default", standardLocale);
            self.correspondingStandardLocale = self.defaultLocale;
        }
        else
        {
            SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"New standard locale %@ indicated for the non standard locale %@", standardLocale, identifier);
        }
    }
    else
    {
        self.correspondingStandardLocale = self.defaultLocale;
    }
}

- (NSLocale*)ISOSelectedLocale
{
    return self.correspondingStandardLocale ? self.correspondingStandardLocale : self.selectedLocale;
}

- (BOOL)resetSavedSettings
{
    NSUserDefaults *userDef = [NSUserDefaults standardUserDefaults];
    [userDef removeObjectForKey:USER_DEF_LOCALE_KEY];
    return [userDef synchronize];
}

#pragma mark - Supported Locales

- (void)setSupportedLocales:(NSArray *)supportedLocales
{
    self.locales = [NSMutableOrderedSet orderedSet];
    
    for (NSString *supportedLocale in supportedLocales)
    {
        [self addSupportedLocale:supportedLocale];
    }
    
    if (self.locales.count > 0)
    {
        // if the defaultLocale has not yet been set from the outside
        if (self.defaultLocale == nil)
        {
            // set the local default to the first array value
            [self setDefaultLocaleWithIdentifier:self.locales[0]];
        }
        // otherwise verify that the defaultLocal setting is supported, otherwise it will change
        else if (![self supportsLocaleWithIdentifier:self.defaultLocale.localeIdentifier])
        {
            SDLogModuleError(kLocalizationManagerLogModuleName, @"The current default locale %@ is not supported", self.defaultLocale.localeIdentifier);
            [self setDefaultLocaleWithIdentifier:self.locales[0]];
        }
        [self setupLocalization];
    }
}

- (void)loadSupportedLocalesFromFileWithName:(NSString *)fileName
{
    BOOL addExtension = fileName.pathExtension.length == 0;
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:(addExtension ? @"plist" : nil)];
    if (path.length == 0)
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"File of supported locales not found: %@", fileName);
    }
    else
    {
        NSArray *supportedLocales = [NSArray arrayWithContentsOfFile:path];
        if (supportedLocales.count == 0)
        {
            SDLogModuleError(kLocalizationManagerLogModuleName, @"File of supported locales is empty: %@", fileName);
        }
        else
        {
            [self setSupportedLocales:supportedLocales];
        }
    }
}

- (NSArray *)supportedLocales
{
    return [self.locales copy];
}

/**
 * Adds local past to those supported by making the necessary checks.
 *
 * @param supportedLocale locale identifier to be added.
 */
- (void) addSupportedLocale:(NSString*)supportedLocale
{
    // If the manager accepts only local recognized by the SO
    if (self.allowsOnlyLocalesAvailableOnSystem && ![NSLocale isLocaleIdentifierAvailableOnSystem:supportedLocale])
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"The locale you're trying to support is not available on the operative system: %@", supportedLocale);
        return;
    }
    
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:supportedLocale];
    
    // check first if the past locale is a valid language
    // so all supportedLocals are not valid
    if (locale.languageCode.length > 0)
    {
        // if it is already added a locale for this language
        if ([self.locales containsObject:supportedLocale])
        {
            SDLogModuleWarning(kLocalizationManagerLogModuleName, @"Locale already added to supported locales: %@", supportedLocale);
        }
        // otherwise adds the locale
        else
        {
            [self.locales addObject:supportedLocale];
        }
    }
    else
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"The locale you're trying to support is invalid: %@", supportedLocale);
    }
}

/**
 * Selects the selected locale in initialization based on the saved choice and languages
 * Of the operating system.
 */
- (void) setupLocalization
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* preferredLangCode = [userDefaults stringForKey:USER_DEF_LOCALE_KEY];
    
    // Verify if a user default setting was saved
    if (preferredLangCode.length > 0)
    {
        // I do a check to make sure that the chosen language is still supported
        if (![self supportsLocaleWithIdentifier:preferredLangCode])
        {
            // if it does not delete the setting from the user defaults and refit the setupLocalization
            SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Saved preferred language is not supported anymore: %@", preferredLangCode);
            [userDefaults removeObjectForKey:USER_DEF_LOCALE_KEY];
            [userDefaults synchronize];
            [self setupLocalization];
        }
        else
        {
            // otherwise save as selectedLocale
            [self setSelectedLocaleWithIdentifier:preferredLangCode];
        }
    }
    // if there are no saved settings
    else
    {
        NSArray* soLanguages = [NSLocale preferredLanguages];
        
        // language loop for the operating system
        for (NSString *soLanguage in soLanguages)
        {
            // if the language is supported then set as selectedLocale
            if ([self supportsLocaleWithIdentifier:soLanguage])
            {
                SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"User language supported: %@", soLanguage);
                [self setSelectedLocaleWithIdentifier:soLanguage persistingSelection:NO];
                return;
            }
            // else verifies if the app supports the basic language version
            else
            {
                NSLocale *locale = [NSLocale localeWithLocaleIdentifier:soLanguage];
                
                // if the base language is supported the set as selectedLocale
                if ([self supportsLocaleWithIdentifier:locale.languageCode])
                {
                    SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"User language not supported, but is supported his generic version: %@", locale.languageCode);
                    [self setSelectedLocaleWithIdentifier:locale.languageCode persistingSelection:NO];
                    return;
                }
            }
        }
        
        // if I still do not have a selectedLocale then I choose the defaultLocale
        SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"No user's language supported. Default locale selected.");
        [self setSelectedLocaleWithIdentifier:self.defaultLocale.localeIdentifier persistingSelection:NO];
    }
}

- (BOOL)supportsLocaleWithIdentifier:(NSString *)identifier
{
    NSLocale *locale = [self supportedLocaleWithIdentifier:identifier];
    
    return locale != nil;
}

- (NSLocale *)supportedLocaleWithIdentifier:(NSString *)identifier
{
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:identifier];
    
    if (locale.languageCode.length == 0)
    {
        return nil;
    }
    
    if ([self.locales containsObject:locale.localeIdentifier])
    {
        return locale;
    }
    else
    {
        NSLocale *baseLocale = locale.baseLanguageLocale;
        if ([self.locales containsObject:baseLocale.localeIdentifier])
        {
            return baseLocale;
        }
        return nil;
    }
}

#pragma mark - Display Names

- (NSArray *) supportedLocalesNamesInSelectedLocale
{
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.locales.count];
    for (NSString *localeId in self.locales)
    {
        NSString *name = [self localeNameForLocaleIdentifierInSelectedLocale:localeId];
        [names addObject:name];
    }
    return [names copy];
}

- (NSArray *) supportedLocalesNamesInCorrespondingLocale
{
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.locales.count];
    for (NSString *localeId in self.locales)
    {
        NSString *name = [self localeNameForLocaleIdentifier:localeId];
        [names addObject:name];
    }
    return [names copy];
}


- (NSArray *) supportedLocalesNamesInLocalizableStrings
{
    return [self supportedLocalesNamesInTableWithName:@"Localizable"];
}

- (NSArray *) supportedLocalesNamesInTableWithName:(NSString*)tableName
{
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.locales.count];
    for (NSString *localeId in self.locales)
    {
        NSString *localizedKey = [NSString stringWithFormat:@"%@_%@", kDisplayNameLocalizedKeyPrefix, localeId];
        NSString *localizedName = SDLocalizedStringFromTable(localizedKey, tableName);
        if (localizedName.length > 0)
        {
            [names addObject:localizedName];
        }
        else
        {
            // if I do not find localization I return the key
            [names addObject:localizedKey];
        }
    }
    return [names copy];
}

- (NSString *) localeNameForLocaleIdentifier:(NSString *)identifier
{
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:identifier];
    NSString *name = [locale displayNameForKey:NSLocaleIdentifier value:locale.localeIdentifier];
    if (name.length == 0)
    {
        SDLogModuleWarning(kLocalizationManagerLogModuleName, @"Name for locale %@ not found", identifier);
        name = @"";
    }
    return name;
}

- (NSString *) localeNameForLocaleIdentifierInSelectedLocale:(NSString *)identifier
{
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:identifier];
    NSString *name = [[self ISOSelectedLocale] displayNameForKey:NSLocaleIdentifier value:locale.localeIdentifier];
    if (name.length == 0)
    {
        SDLogModuleWarning(kLocalizationManagerLogModuleName, @"Name for locale %@ not found", identifier);
        name = @"";
    }
    return name;
}

#pragma mark - Localized Strings

- (NSString *)localizedKey:(NSString *)key
{
    return [self localizedKey:key fromTable:@"Localizable" placeholderDictionary:nil withDefaultValue:nil];
}

- (NSString *)localizedKey:(NSString *)key fromTable:(NSString *)tableName
{
    return [self localizedKey:key fromTable:tableName placeholderDictionary:nil withDefaultValue:nil];
}

- (NSString *)localizedKey:(NSString *)key withDefaultValue:(NSString *)defaultValue
{
    return [self localizedKey:key fromTable:@"Localizable" placeholderDictionary:nil withDefaultValue:defaultValue];
}

- (NSString *)localizedKey:(NSString *)key fromTable:(NSString *)tableName placeholderDictionary:(NSDictionary<NSString*, NSString*> *)placeholderDictionary withDefaultValue:(NSString *)defaultValue
{
    NSString* localizedString = [self localizedKey:key fromTable:tableName withDefaultValue:defaultValue];
    
    if (placeholderDictionary && localizedString)
    {
        for (NSString* key in placeholderDictionary.allKeys)
        {
            NSString* replacer = [placeholderDictionary objectForKey:key];
            if (replacer)
            {
                localizedString = [localizedString stringByReplacingOccurrencesOfString:key withString:replacer];
            }
        }
    }
    return localizedString;
}


- (NSString *)localizedKey:(NSString *)key fromTable:(NSString *)tableName withDefaultValue:(NSString *)defaultValue
{
    return [self localizedKey:key fromTable:tableName inBundleForClass:nil withDefaultValue:defaultValue];
}

- (NSString *)localizedKey:(NSString *)key fromTable:(NSString *)tableName inBundleForClass:(Class)bundleClass withDefaultValue:(NSString *)defaultValue
{
    // find the bundle
    NSBundle* bundle = [self bundleForClass:bundleClass];
    NSString* defaultInMainBundle = [bundle isEqual:[NSBundle mainBundle]] ? defaultValue : nil;
    
    // fallback on standard call
    if (!self.selectedLocale)
    {
        NSString* value = [[NSBundle mainBundle] localizedStringForKey:key value:defaultInMainBundle table:tableName];
        if ([value isEqualToString:key])
        {
            value = [bundle localizedStringForKey:key value:defaultValue table:tableName];
        }
        return value;
    }
    
    NSString* localizedString;
    NSString* table = [tableName stringByReplacingOccurrencesOfString:@".strings" withString:@""];
    
    // procedendo prima nella struttura in memoria e poi nel file system
    // cerco prima nella lingua selezionata
    NSString* selectedLang = self.dataSource.selectedLocale.languageID;
    if(selectedLang)
    {
        localizedString = [self retrieveLocalizedStringForKey:key locale:self.dataSource.selectedLocale inBundle:bundle andTableName:table];
        if(localizedString)
        {
            return localizedString;
        }
    }
    
    
    // if I did not find anything I would look for in any basic locale
    NSString* baseLang = self.dataSource.baseLocale.languageID;
    if (![baseLang isEqualToString:selectedLang])
    {
        localizedString = [self retrieveLocalizedStringForKey:key locale:self.dataSource.baseLocale inBundle:bundle andTableName:table];
        if(localizedString)
        {
            return localizedString;
        }
    }
    
    // last try with the default locale
    NSString* defaultLang = self.dataSource.defaultLocale.languageID;
    if (defaultLang.length > 0 && ![defaultLang isEqualToString:selectedLang] &&
        ![defaultLang isEqualToString:baseLang])
    {
        localizedString = [self retrieveLocalizedStringForKey:key locale:self.dataSource.defaultLocale inBundle:bundle andTableName:table];
        if(localizedString)
        {
            return localizedString;
        }
    }
    
    // no matches were found.
    if (defaultValue)
    {
        SDLogModuleWarning(kLocalizationManagerLogModuleName, @"No localized value found for given key (%@) in table %@. The default value will be returned: %@", key, table, defaultValue);
        return defaultValue;
    }
    else
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"No localized value found for given key (%@) in table %@. The key will be returned.", key, table);
        return key;
    }
}

- (NSBundle*)bundleForClass:(Class)clazz
{
    if (!clazz)
    {
        return [NSBundle mainBundle];
    }
    NSBundle* bundle = [NSBundle bundleForClass:clazz];
    bundle = bundle ?: [NSBundle mainBundle];
    return bundle;
}

- (NSArray*) arrayOfLocalizedStringsWithPrefix:(NSString *)prefix
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:0];
    int counter = 0;
    NSString* name = [NSString stringWithFormat:@"%@.%d", prefix, counter];
    NSString* value = SDLocalizedString(name);
    
    while (![value isEqualToString:name])
    {
        [array addObject:value];
        counter++;
        name = [NSString stringWithFormat:@"%@.%d", prefix, counter];
        value = SDLocalizedString(name);
    }
    
    return [NSArray arrayWithArray:array];
}

- (NSString*) retrieveLocalizedStringForKey:(NSString*)key locale:(SDLocaleModel*)locale inBundle:(NSBundle*)bundle andTableName:(NSString*)tableName
{
    NSString* localizedValue = nil;
    // search in dynamic content
    localizedValue = locale.dynamic.tablesByName[tableName].content[key];
    if (!localizedValue)
    {
        // try to load dynamic contents from file system
        NSString* fileSystemPath = [self fileSystemPathForTable:tableName localization:locale.languageID];
        NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:fileSystemPath];
        if (dictionary)
        {
            SDLocalizationTable* table = [SDLocalizationTable new];
            table.name = tableName;
            [table.content addEntriesFromDictionary:dictionary];
            locale.dynamic.tablesByName[tableName] = table;
            localizedValue = table.content[key];
        }
    }
    if (localizedValue)
    {
        return localizedValue;
    }
    
    // search in main bundle
    localizedValue = locale.main.tablesByName[tableName].content[key];
    if (!localizedValue)
    {
        // try to load the table from main bundle
        NSString* bundlePath = [self bundle:[NSBundle mainBundle] pathForTable:tableName localization:locale.languageID];
        if (bundlePath)
        {
            NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:bundlePath];
            if (dictionary)
            {
                SDLocalizationTable* table = [SDLocalizationTable new];
                table.name = tableName;
                [table.content addEntriesFromDictionary:dictionary];
                locale.main.tablesByName[tableName] = table;
                localizedValue = table.content[key];
            }
        }
    }
    if (localizedValue)
    {
        return localizedValue;
    }
    
    // finally search in given bundle, if it is different from main bundle
    if (![bundle isEqual:[NSBundle mainBundle]])
    {
        localizedValue = locale.bundlesById[bundle.bundleIdentifier].tablesByName[tableName].content[key];
        if (!localizedValue)
        {
            // try to load the table from the given bundle
            NSString* bundlePath = [self bundle:bundle pathForTable:tableName localization:locale.languageID];
            if (bundlePath)
            {
                NSDictionary* dictionary = [NSDictionary dictionaryWithContentsOfFile:bundlePath];
                if (dictionary)
                {
                    // create the bundle in data source if needed
                    SDTablesBundle* tablesBundle = locale.bundlesById[bundle.bundleIdentifier];
                    if (!tablesBundle)
                    {
                        tablesBundle = [SDTablesBundle new];
                        tablesBundle.identifier = bundle.bundleIdentifier;
                        locale.bundlesById[bundle.bundleIdentifier] = tablesBundle;
                    }
                    
                    SDLocalizationTable* table = [SDLocalizationTable new];
                    table.name = tableName;
                    [table.content addEntriesFromDictionary:dictionary];
                    tablesBundle.tablesByName[tableName] = table;
                    localizedValue = table.content[key];
                }
            }
        }
    }
    
    if (!localizedValue)
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"Key not found in table %@: %@", tableName, key);
    }
    return localizedValue;
}

- (NSString*) bundle:(NSBundle*)bundle pathForTable:(NSString*)tableName localization:(NSString*)localization
{
    NSString* path = [bundle pathForResource:tableName ofType:@"strings" inDirectory:nil forLocalization:localization];
    return path;
}

- (NSString*) fileSystemPathForTable:(NSString*)tableName localization:(NSString*)localization
{
    NSString* path = [self.pathForDynamicStrings stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.strings", tableName, localization]];
    return path;
}

#pragma mark - Adding strings

- (void) addStrings:(NSDictionary<NSString*, NSString*>*)strings
{
    [self addStrings:strings toTableWithName:@"Localizable"];
}

- (void) addStrings:(NSDictionary<NSString*, NSString*>*)strings toTableWithName:(NSString*)tableName
{
    [self addStrings:strings toTableWithName:tableName forLocalization:self.ISOSelectedLocale.languageID];
}

- (void) addStrings:(NSDictionary<NSString*, NSString*>*)strings toTableWithName:(NSString*)tableName forLocalization:(NSString*)localization
{
    // Parameters validation
    if (!strings)
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"Passed a nil dictionary of strings to add to table with name %@", tableName);
        return;
    }
    
    if (tableName.length == 0)
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"Invalid table name");
        return;
    }
    
    if (localization.length == 0)
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"Invalid localization");
        return;
    }
    
    NSString* fileSystemPath = [self fileSystemPathForTable:tableName localization:localization];
    NSMutableDictionary* dynamicDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:fileSystemPath];
    if(!dynamicDictionary)
    {
        dynamicDictionary = [NSMutableDictionary new];
    }
    
    [dynamicDictionary addEntriesFromDictionary:strings];
    
    [dynamicDictionary writeToFile:fileSystemPath atomically:YES];
    
    [self resetLocalizedTables];
}

- (void) resetAddedStringsToTableWithName:(NSString*)tableName forLocalization:(NSString*)localization
{
    NSString* fileSystemPath = [self fileSystemPathForTable:tableName localization:localization];
    [GTYFileManager deleteFilesAtPath:fileSystemPath];
    
    [self resetLocalizedTables];
}

- (void) resetAllAddedStringsForLocalization:(NSString*)localization
{
    NSArray<NSString*>* filePaths = [GTYFileManager getFilesContentInDirectoryNamed:self.pathForDynamicStrings];
    for (NSString* fileName in filePaths)
    {
        if([fileName containsString:[NSString stringWithFormat:@"_%@.strings", localization]])
        {
            NSString* filePath = [self.pathForDynamicStrings stringByAppendingPathComponent:fileName];
            [GTYFileManager deleteFilesAtPath:filePath];
        }
    }
    [self resetLocalizedTables];
}

- (void) resetAllAddedStrings
{
    NSArray<NSString*>* filePaths = [GTYFileManager getFilesContentInDirectoryNamed:self.pathForDynamicStrings];
    for (NSString* fileName in filePaths)
    {
        NSString* filePath = [self.pathForDynamicStrings stringByAppendingPathComponent:fileName];
        [GTYFileManager deleteFilesAtPath:filePath];
    }
    [self resetLocalizedTables];
}

#pragma mark - Formatters & Calendars Management

- (void)resetFormattersAndCalendars
{
    self.simpleDateFormatter = nil;
    self.twelveHoursTimeFormatter = nil;
    self.twentyFourHoursTimeFormatter = nil;
    self.simpleDateTimeFormatter = nil;
    self.serverDateTimeFormatter = nil;
    self.userDefaultDateFormatter = nil;
    self.userDefaultTimeFormatter = nil;
    self.userDefaultDateTimeFormatter = nil;
    
    self.userDefaultDistanceFormatter = nil;
    self.userDefaultSpeedFormatter = nil;
    self.userDefaultCurrencyFormatter = nil;
    self.percentageFormatter = nil;
    
    self.userDefaultCalendar = nil;
}

#pragma mark - Date Formatters

- (NSLocale*)formatterLocale
{
    NSLocale *isoLocale = [self ISOSelectedLocale];
    return isoLocale ? isoLocale : [NSLocale currentLocale];
}

- (NSDateFormatter *)simpleDateFormatter
{
    if (!_simpleDateFormatter)
    {
        NSString *template = [NSString stringWithFormat:@"dd/MM/yyyy"];
        NSString* format = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:self.formatterLocale];
        _simpleDateFormatter = [[NSDateFormatter alloc] init];
        _simpleDateFormatter.locale = self.formatterLocale;
        _simpleDateFormatter.dateFormat = format;
    }
    return _simpleDateFormatter;
}

- (NSDateFormatter *)twelveHoursTimeFormatter
{
    if (!_twelveHoursTimeFormatter)
    {
        NSString *template = [NSString stringWithFormat:@"hh:mm a"];
        NSString* format = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:self.formatterLocale];
        _twelveHoursTimeFormatter = [[NSDateFormatter alloc] init];
        _twelveHoursTimeFormatter.locale = self.formatterLocale;
        _twelveHoursTimeFormatter.dateFormat = format;
    }
    return _twelveHoursTimeFormatter;
}

- (NSDateFormatter *)twentyFourHoursTimeFormatter
{
    if (!_twentyFourHoursTimeFormatter)
    {
        NSString *template = [NSString stringWithFormat:@"HH:mm"];
        NSString* format = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:self.formatterLocale];
        _twentyFourHoursTimeFormatter = [[NSDateFormatter alloc] init];
        _twentyFourHoursTimeFormatter.locale = self.formatterLocale;
        _twentyFourHoursTimeFormatter.dateFormat = format;
    }
    return _twentyFourHoursTimeFormatter;
}

- (NSDateFormatter *)simpleDateTimeFormatter
{
    if (!_simpleDateTimeFormatter)
    {
        NSString *template = [NSString stringWithFormat:@"dd/MM/yyyy HH:mm"];
        NSString* format = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:self.formatterLocale];
        _simpleDateTimeFormatter = [[NSDateFormatter alloc] init];
        _simpleDateTimeFormatter.locale = self.formatterLocale;
        _simpleDateTimeFormatter.dateFormat = format;
    }
    return _simpleDateTimeFormatter;
}

- (NSDateFormatter*) serverDateTimeFormatter
{
    if (!_serverDateTimeFormatter)
    {
        _serverDateTimeFormatter = [[NSDateFormatter alloc] init];
        _serverDateTimeFormatter.dateFormat = @"yyyy-MM-dd hh:mm:ss.SSS";
        _serverDateTimeFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    return _serverDateTimeFormatter;
}

#pragma mark - User Default Date Formatters

- (NSString *)userDefaultDateFormat
{
    NSString* dateFormat = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEF_DATE_FORMAT];
    
    if (dateFormat.length == 0)
    {
        dateFormat = @"dd/MM/yyyy";
    }
    return dateFormat;
}

- (void)setUserDefaultDateFormat:(NSString *)userDefaultDateFormat
{
    [[NSUserDefaults standardUserDefaults] setObject:userDefaultDateFormat forKey:USER_DEF_DATE_FORMAT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)userDefaultTimeFormat
{
    NSString* dateFormat = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEF_TIME_FORMAT];
    
    if (dateFormat.length == 0)
    {
        dateFormat = @"HH:mm";
    }
    return dateFormat;
}

- (void)setUserDefaultTimeFormat:(NSString *)userDefaultTimeFormat
{
    [[NSUserDefaults standardUserDefaults] setObject:userDefaultTimeFormat forKey:USER_DEF_TIME_FORMAT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDateFormatter*) userDefaultDateFormatter
{
    if (!_userDefaultDateFormatter)
    {
        _userDefaultDateFormatter = [[NSDateFormatter alloc] init];
        _userDefaultDateFormatter.locale = self.formatterLocale;
    }
    _userDefaultDateFormatter.dateFormat = self.userDefaultDateFormat;
    return _userDefaultDateFormatter;
}

- (NSDateFormatter*) userDefaultTimeFormatter
{
    if (!_userDefaultTimeFormatter)
    {
        _userDefaultTimeFormatter = [[NSDateFormatter alloc] init];
        _userDefaultTimeFormatter.locale = self.formatterLocale;
    }
    _userDefaultTimeFormatter.dateFormat = self.userDefaultTimeFormat;
    return _userDefaultTimeFormatter;
}

- (NSDateFormatter*) userDefaultDateTimeFormatter
{
    if (!_userDefaultDateTimeFormatter)
    {
        _userDefaultDateTimeFormatter = [[NSDateFormatter alloc] init];
        _userDefaultDateTimeFormatter.locale = self.formatterLocale;
    }
    _userDefaultDateTimeFormatter.dateFormat = [NSString stringWithFormat:@"%@ %@", self.userDefaultDateFormat, self.userDefaultTimeFormat];
    
    return _userDefaultDateTimeFormatter;
}

#pragma mark - Number Formatters

- (NSString *)userDefaultDistanceUnit
{
    NSString* unit = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEF_DISTANCE_UNIT];
    
    if (unit.length == 0)
    {
        unit = [self formatterLocale].usesMetricSystem ? @" m" : @" ft";
    }
    return unit;
}

- (void)setUserDefaultDistanceUnit:(NSString *)userDefaultDistanceUnit
{
    [[NSUserDefaults standardUserDefaults] setObject:userDefaultDistanceUnit forKey:USER_DEF_DISTANCE_UNIT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)userDefaultSpeedUnit
{
    NSString* unit = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEF_SPEED_UNIT];
    
    if (unit.length == 0)
    {
        unit = [self formatterLocale].usesMetricSystem ? @" km/h" : @" mph";
    }
    return unit;
}

- (void)setUserDefaultSpeedUnit:(NSString *)userDefaultSpeedUnit
{
    [[NSUserDefaults standardUserDefaults] setObject:userDefaultSpeedUnit forKey:USER_DEF_SPEED_UNIT];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)userDefaultCurrencySymbol
{
    NSString* symbol = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEF_CURRENCY_SYMBOL];
    
    if (symbol.length == 0)
    {
        symbol = [self formatterLocale].currencySymbol;
    }
    return symbol;
}

- (void)setUserDefaultCurrencySymbol:(NSString *)userDefaultCurrencySymbol
{
    [[NSUserDefaults standardUserDefaults] setObject:userDefaultCurrencySymbol forKey:USER_DEF_CURRENCY_SYMBOL];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumberFormatter*) userDefaultDistanceFormatter
{
    if (!_userDefaultDistanceFormatter)
    {
        _userDefaultDistanceFormatter = [[NSNumberFormatter alloc] init];
        _userDefaultDistanceFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _userDefaultDistanceFormatter.minimumFractionDigits = _userDefaultDistanceFormatter.maximumFractionDigits = 1;
        _userDefaultDistanceFormatter.locale = [self formatterLocale];
        _userDefaultDistanceFormatter.usesGroupingSeparator = YES;
        
        NSString *decimalSeparator = SDLocalizedStringWithDefault(kDecimalSeparatorLocalizedKey, _userDefaultDistanceFormatter.locale.decimalSeparator);
        _userDefaultDistanceFormatter.decimalSeparator = decimalSeparator;
        NSString *groupingSeparator = SDLocalizedStringWithDefault(kGroupingSeparatorLocalizedKey, _userDefaultDistanceFormatter.locale.groupingSeparator);
        _userDefaultDistanceFormatter.groupingSeparator = groupingSeparator;
    }
    _userDefaultDistanceFormatter.positiveSuffix = self.userDefaultDistanceUnit;
    return _userDefaultDistanceFormatter;
}

- (NSNumberFormatter *)userDefaultSpeedFormatter
{
    if (!_userDefaultSpeedFormatter)
    {
        _userDefaultSpeedFormatter = [[NSNumberFormatter alloc] init];
        _userDefaultSpeedFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _userDefaultSpeedFormatter.minimumFractionDigits = _userDefaultSpeedFormatter.maximumFractionDigits = 1;
        _userDefaultSpeedFormatter.locale = [self formatterLocale];
        _userDefaultSpeedFormatter.usesGroupingSeparator = YES;
        
        NSString *decimalSeparator = SDLocalizedStringWithDefault(kDecimalSeparatorLocalizedKey, _userDefaultSpeedFormatter.locale.decimalSeparator);
        _userDefaultSpeedFormatter.decimalSeparator = decimalSeparator;
        NSString *groupingSeparator = SDLocalizedStringWithDefault(kGroupingSeparatorLocalizedKey, _userDefaultSpeedFormatter.locale.groupingSeparator);
        _userDefaultSpeedFormatter.groupingSeparator = groupingSeparator;
    }
    _userDefaultSpeedFormatter.positiveSuffix = self.userDefaultSpeedUnit;
    return _userDefaultSpeedFormatter;
}

- (NSNumberFormatter *)userDefaultCurrencyFormatter
{
    if (!_userDefaultCurrencyFormatter)
    {
        _userDefaultCurrencyFormatter = [[NSNumberFormatter alloc] init];
        _userDefaultCurrencyFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _userDefaultCurrencyFormatter.minimumFractionDigits = _userDefaultSpeedFormatter.maximumFractionDigits = 2;
        _userDefaultCurrencyFormatter.locale = [self formatterLocale];
        _userDefaultCurrencyFormatter.usesGroupingSeparator = YES;
        
        NSString *decimalSeparator = SDLocalizedStringWithDefault(kDecimalSeparatorLocalizedKey, _userDefaultCurrencyFormatter.locale.decimalSeparator);
        _userDefaultCurrencyFormatter.decimalSeparator = decimalSeparator;
        NSString *groupingSeparator = SDLocalizedStringWithDefault(kGroupingSeparatorLocalizedKey, _userDefaultCurrencyFormatter.locale.groupingSeparator);
        _userDefaultCurrencyFormatter.groupingSeparator = groupingSeparator;
    }
    _userDefaultCurrencyFormatter.positiveSuffix = self.userDefaultCurrencySymbol;
    return _userDefaultCurrencyFormatter;
}

- (NSNumberFormatter *)percentageFormatter
{
    if (!_percentageFormatter)
    {
        _percentageFormatter = [[NSNumberFormatter alloc] init];
        _percentageFormatter.locale = self.formatterLocale;
        [_percentageFormatter setNumberStyle:NSNumberFormatterPercentStyle];
        [_percentageFormatter setMaximumFractionDigits:2];
        [_percentageFormatter setMultiplier:@1];
    }
    return _percentageFormatter;
}

#pragma mark - Calendars

- (NSTimeZone *)userDefaultTimeZone
{
    NSString* timeZoneName = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEF_TIME_ZONE];
    
    if (timeZoneName.length == 0)
    {
        return [NSTimeZone systemTimeZone];
    }
    return [NSTimeZone timeZoneWithName:timeZoneName];
}

- (void)setUserDefaultTimeZone:(NSTimeZone *)userDefaultTimeZone
{
    [[NSUserDefaults standardUserDefaults] setObject:userDefaultTimeZone.name forKey:USER_DEF_TIME_ZONE];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)userDefaultCalendarIdentifier
{
    NSString* calendarID = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEF_CALENDAR_ID];
    if (calendarID.length == 0)
    {
        calendarID = [NSCalendar currentCalendar].calendarIdentifier;
    }
    return calendarID;
}

- (void)setUserDefaultCalendarIdentifier:(NSString *)userDefaultCalendarIdentifier
{
    [[NSUserDefaults standardUserDefaults] setObject:userDefaultCalendarIdentifier forKey:USER_DEF_CALENDAR_ID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setUserDefaultCalendar:nil];
}

- (NSCalendar *)userDefaultCalendar
{
    if (!_userDefaultCalendar)
    {
        _userDefaultCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:self.userDefaultCalendarIdentifier];
        _userDefaultCalendar.locale = self.formatterLocale;
    }
    _userDefaultCalendar.timeZone = self.userDefaultTimeZone;
    return _userDefaultCalendar;
}

- (NSCalendar *)utcCalendar
{
    if (!_utcCalendar)
    {
        _utcCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        _utcCalendar.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    }
    return _utcCalendar;
}

- (NSCalendar *)gmtCalendar
{
    if (!_gmtCalendar)
    {
        _gmtCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        _gmtCalendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    return _gmtCalendar;
}

@end

