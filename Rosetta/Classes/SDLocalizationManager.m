//
//  SDLocalizationManager.m
//  SysdataCore
//
//  Created by Paolo Ardia on 16/11/15.
//
//

#import "SDLocalizationManager.h"

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

@interface SDLocalizationManager ()

@property (nonatomic, strong) NSMutableOrderedSet *locales; // NSString
@property (nonatomic, strong) NSMutableDictionary *localizedTables;
/**
 *  Questo locale viene usato solo nel caso in cui il selectedLocale non sia uno standard previsto dal SO e rappresenta l'alternativa standard per localizzazioni e formattazioni.
 */
@property (nonatomic, strong) NSLocale* correspondingStandardLocale;

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
    
    // verifico se il locale passato è supportato
    NSLocale *locale = [self supportedLocaleWithIdentifier:identifier];
    if (locale)
    {
        // salvo il locale selezionato solo se richiesto
        _selectedLocale = locale;
        if (persisting)
        {
            [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:USER_DEF_LOCALE_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"New locale selected: %@", locale.localeIdentifier);
        
        // se il manager ammette locales non standard e si tratta di un locale non standard chiedo al delegate il corrispettivo standard
        self.correspondingStandardLocale = nil;
        if (!self.allowsOnlyLocalesAvailableOnSystem && ![NSLocale isLocaleIdentifierAvailableOnSystem:identifier])
        {
            [self setupCorrespondingStandardLocaleFromIdentifier:identifier];
        }
        
        // reinizializzo la struttura delle label localizzate
        self.localizedTables = [NSMutableDictionary dictionary];
        self.localizedTables[kSelectedLocaleTablesKey] = [NSMutableDictionary dictionary];
        self.localizedTables[kBaseLocaleTablesKey] = [NSMutableDictionary dictionary];
        self.localizedTables[kDefaultLocaleTablesKey] = [NSMutableDictionary dictionary];
        
        // resetto i formatters
        [self resetFormattersAndCalendars];

        // lancio la notifica
        [[NSNotificationCenter defaultCenter] postNotificationName:SDLocalizationManagerLanguageDidChangeNotification object:locale];
    }
    else
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"The given selected locale (%@) is not supported. The selected locale is %@", identifier, self.selectedLocale.localeIdentifier);
    }
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
        // il locale non è cambiato
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
        // verifico che il locale indicato sia valido e standard
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
        // se il defaultLocale non è ancora stato impostato dall'esterno
        if (self.defaultLocale == nil)
        {
            // imposto il default locale con il primo valore dell'array
            [self setDefaultLocaleWithIdentifier:self.locales[0]];
        }
        // altrimenti verifica che il defaultLocale impostato sia supportato, altrimenti lo cambia
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
 *  Aggiunge il locale passato a quelli supportati facendo le opportune verifiche.
 *
 *  @param supportedLocale identificativo del locale da aggiungere.
 */
- (void) addSupportedLocale:(NSString*)supportedLocale
{
    // se il manager accetta solo locale riconosciuti dal SO
    if (self.allowsOnlyLocalesAvailableOnSystem && ![NSLocale isLocaleIdentifierAvailableOnSystem:supportedLocale])
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"The locale you're trying to support is not available on the operative system: %@", supportedLocale);
        return;
    }
    
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:supportedLocale];
    
    // verifico prima se il locale passato è una lingua valida
    // in questo modo tutti i supportedLocale non nil sono validi
    if (locale.languageCode.length > 0)
    {
        // se ho già aggiunto un locale per questa lingua
        if ([self.locales containsObject:supportedLocale])
        {
            SDLogModuleWarning(kLocalizationManagerLogModuleName, @"Locale already added to supported locales: %@", supportedLocale);
        }
        // altrimenti aggiungo il locale
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
 *  Sceglie il locale selezionato in fase di inizializzazione in base alla scelta salvata e alle lingue
 *  del sistema operativo.
 */
- (void) setupLocalization
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* preferredLangCode = [userDefaults stringForKey:USER_DEF_LOCALE_KEY];
    
    // Verifica se è stata salvata un'impostazione negli user defaults
    if (preferredLangCode.length > 0)
    {
        // faccio un check per essere sicuro che la lingua scelta sia ancora supportata
        if (![self supportsLocaleWithIdentifier:preferredLangCode])
        {
            // se non lo è cancello l'impostazione dagli user defaults e rifaccio il setupLocalization
            SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Saved preferred language is not supported anymore: %@", preferredLangCode);
            [userDefaults removeObjectForKey:USER_DEF_LOCALE_KEY];
            [userDefaults synchronize];
            [self setupLocalization];
        }
        else
        {
            // altrimenti la salvo come selectedLocale
            [self setSelectedLocaleWithIdentifier:preferredLangCode];
        }
    }
    // se non ci sono impostazioni salvate
    else
    {
        NSArray* soLanguages = [NSLocale preferredLanguages];
        
        // ciclo sulle lingue scelte per il sistema operativo
        for (NSString *soLanguage in soLanguages)
        {
            // se la lingua è supportata la setto come selectedLocale
            if ([self supportsLocaleWithIdentifier:soLanguage])
            {
                SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"User language supported: %@", soLanguage);
                [self setSelectedLocaleWithIdentifier:soLanguage persistingSelection:NO];
                return;
            }
            // altrimenti verifico se l'app supporta la versione base della lingua
            else
            {
                NSLocale *locale = [NSLocale localeWithLocaleIdentifier:soLanguage];
                // se la lingua base è supportata la setto come selectedLocale
                if ([self supportsLocaleWithIdentifier:locale.languageCode])
                {
                    SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"User language not supported, but is supported his generic version: %@", locale.languageCode);
                    [self setSelectedLocaleWithIdentifier:locale.languageCode persistingSelection:NO];
                    return;
                }
            }
        }
        
        // se non ho ancora un selectedLocale allora scelgo il defaultLocale
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
        NSString *name = [self.ISOSelectedLocale displayNameForKey:NSLocaleIdentifier value:localeId];
        if (name.length == 0)
        {
            SDLogModuleWarning(kLocalizationManagerLogModuleName, @"Name for locale %@ not found", localeId);
            name = @"";
        }
        [names addObject:name];
    }
    return [names copy];
}

- (NSArray *) supportedLocalesNamesInCorrespondingLocale
{
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:self.locales.count];
    for (NSString *localeId in self.locales)
    {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:localeId];
        NSString *name = [locale displayNameForKey:NSLocaleIdentifier value:locale.localeIdentifier];
        if (name.length == 0)
        {
            SDLogModuleWarning(kLocalizationManagerLogModuleName, @"Name for locale %@ not found", localeId);
            name = @"";
        }
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
            // se non trovo la localizzazione restituisco la key
            [names addObject:localizedKey];
        }
    }
    return [names copy];
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
    // fallback sulla chiamata standard
    if (!self.selectedLocale)
    {
        return [[NSBundle mainBundle] localizedStringForKey:key value:defaultValue table:tableName];
    }
    
    NSString* table = [tableName stringByReplacingOccurrencesOfString:@".strings" withString:@""];
    
    // procedendo prima nella struttura in memoria e poi nel file system
    // cerco prima nella lingua selezionata
    NSString* selectedLang = self.ISOSelectedLocale.languageID;
    NSDictionary *tableContent = self.localizedTables[kSelectedLocaleTablesKey][table];
    if (!tableContent)
    {
        tableContent = [self loadLocalizedTableWithName:table forLocalization:selectedLang];
        if (tableContent)
        {
            SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Table with name %@ loaded for selected locale", table);
            [self.localizedTables[kSelectedLocaleTablesKey] setObject:tableContent forKey:table];
        }
    }
    
    if (tableContent[key])
    {
        return tableContent[key];
    }
    else
    {
        SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Key not found in table %@ for selected locale: %@", table, key);
    }
    
    // se non ho trovato nulla cerco nell'eventuale locale di base
    NSString* baseLang = self.ISOSelectedLocale.baseLanguageLocale.languageID;
    if (![baseLang isEqualToString:selectedLang])
    {
        NSDictionary *tableContent = self.localizedTables[kBaseLocaleTablesKey][table];
        if (!tableContent)
        {
            tableContent = [self loadLocalizedTableWithName:table forLocalization:baseLang];
            if (tableContent)
            {
                SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Table with name %@ loaded for generic version of selected locale (%@)", table, baseLang);
                [self.localizedTables[kBaseLocaleTablesKey] setObject:tableContent forKey:table];
            }
        }
        
        if (tableContent[key])
        {
            return tableContent[key];
        }
        else
        {
            SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Key not found in table %@ for generic version of selected locale: %@", table, key);
        }
    }
    
    // per ultimo provo con il locale di default
    NSString* defaultLang = self.defaultLocale.languageID;
    if (defaultLang.length > 0 && ![defaultLang isEqualToString:selectedLang] &&
        ![defaultLang isEqualToString:baseLang])
    {
        NSDictionary *tableContent = self.localizedTables[kDefaultLocaleTablesKey][table];
        if (!tableContent)
        {
            tableContent = [self loadLocalizedTableWithName:table forLocalization:defaultLang];
            if (tableContent)
            {
                SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Table with name %@ loaded for default locale", table);
                [self.localizedTables[kDefaultLocaleTablesKey] setObject:tableContent forKey:table];
            }
        }
        
        if (tableContent[key])
        {
            return tableContent[key];
        }
        else
        {
            SDLogModuleWarning(kLocalizationManagerLogModuleName, @"Key not found in table %@ for default locale: %@", table, key);
        }
    }
    
    // non è stata trovata alcuna corrispondenza.
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

/**
 *  Carica da file system la table localizzata con il nome e la localizzazione passati.
 *
 *  @param tableName    la table da caricare.
 *  @param localization la localizzazione nella quale cercare la table.
 *
 *  @return Un NSDictionary con il contenuto della table caricata, oppure nil se la table non è stata trovata.
 */
- (NSDictionary*) loadLocalizedTableWithName:(NSString*)tableName forLocalization:(NSString*)localization
{
    // carico il contenuto della table da file system
    NSString* path = [[NSBundle mainBundle] pathForResource:tableName ofType:@"strings" inDirectory:nil forLocalization:localization];
    if (path)
    {
        return [NSDictionary dictionaryWithContentsOfFile:path];
    }
    else
    {
        SDLogModuleError(kLocalizationManagerLogModuleName, @"Table with name %@ not found in resources for localization %@", tableName, localization);
    }
    return nil;
}

#pragma mark - Adding strings

- (void) addStrings:(NSDictionary<NSString*, NSString*>*)strings toTableWithName:(NSString*)tableName
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
    
    // Look for the table in memory and eventually create it
    NSMutableDictionary* selectedLocaleTables = self.localizedTables[kSelectedLocaleTablesKey];
    if (!selectedLocaleTables)
    {
        selectedLocaleTables = [NSMutableDictionary new];
        self.localizedTables[kSelectedLocaleTablesKey] = selectedLocaleTables;
    }
    
    NSMutableDictionary* table = [selectedLocaleTables[tableName] mutableCopy];
    if (!table)
    {
        table = [NSMutableDictionary new];
        SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Table %@ not found in memory for localization %@. I create it!", tableName, self.selectedLocale.localeIdentifier);
    }
    
    // add the entries to the table
    [table addEntriesFromDictionary:strings];
    
    // save the table
    selectedLocaleTables[tableName] = [table copy];
    
    SDLogModuleVerbose(kLocalizationManagerLogModuleName, @"Added %lu strings to table with name %@ for localization %@", (unsigned long)strings.count, tableName, self.selectedLocale.localeIdentifier);
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
