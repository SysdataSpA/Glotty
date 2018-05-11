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

#import <Foundation/Foundation.h>
#import "NSLocale+Glotty.h"
#import "SDLocalizationLogger.h"


#ifdef SDLocalizedString
#undef SDLocalizedString
#endif

#ifdef SDLocalizedStringFromTable
#undef SDLocalizedStringFromTable
#endif

#ifdef SDLocalizedStringWithDefault
#undef SDLocalizedStringWithDefault
#endif

#ifdef SDLocalizedStringFromTableWithDefault
#undef SDLocalizedStringFromTableWithDefault
#endif

NSString* SDLocalizedString(NSString * key);

NSString* SDLocalizedStringFromTable(NSString * key, NSString *table);

NSString* SDLocalizedStringWithDefault(NSString * key, NSString *val);

NSString* SDLocalizedStringFromTableWithDefault(NSString * key,NSString *table, NSString *val);

NSString* SDLocalizedStringWithPlaceholders(NSString* key, NSDictionary<NSString*, NSString*>* placeholders);

NSString* SDLocalizedStringInBundleForClass(NSString * key, Class bundleClass);

NSString* SDLocalizedStringFromTableInBundleForClass(NSString * key, NSString *table, Class bundleClass);

NSString* SDLocalizedStringFromTableInBundleForClassWithDefault(NSString * key, NSString *table, Class bundleClass, NSString *val);

UIImage* SDLocalizedImage(NSString * key);
UIImage* SDLocalizedImageWithNameAndExtension(NSString * key, NSString *type);


@protocol SDLocalizationManagerDelegate <NSObject>
@optional
/**
 * Implementing this method is only useful when using nonstandard locale, whose localization and formatting should reflect that of another locale (standard).
 *
 * @param locale The non-standard locale to convert.
 *
 * @return The identifier of a standard locale accepted by the operating system.
 */
- (NSString*)ISOLocaleIdentifierForNonStandardLocale:(NSString*)locale;
@end

#define SDLocalizationManagerLanguageDidChangeNotification @"SDLocalizationManagerLanguageDidChangeNotification"

@class SDLocalizationManager;

/**
 * This class allows you to manage your locations independently from the operating system.
 * To make it stand-alone, you need to set up locales supported by an array or plist file.
 * The manager may also accept non-standard locale, but in this case he needs a delegate to which language he or she is otherwise unable to translate correctly.
 * The manager always provides a default locale, which unless otherwise specified, is "en".
 *
 * The manager also provides the most common formatters for dates and numbers, using the information of the selected locale to format in a conforming manner to the locale itself.
 */
#if BLABBER
@interface SDLocalizationManager : NSObject <SDLoggerModuleProtocol>
#else
@interface SDLocalizationManager : NSObject
#endif

+ (instancetype) sharedManager;

#pragma mark - Locales
/**
 * The currently selected locale.
 *
 * Before setting up the supported locales is nil, but immediately after it is the same as the operating system (if supported) or the default one. The selected locale is saved in user defaults.
 */
@property (nonatomic, readonly) NSLocale *selectedLocale;

/**
 * The default locale.
 *
 * Is selected during initialization if the operating system locale is not one of the supported ones. It is also used as the last resource if a string is not localized in the selected locale.
 */
@property (nonatomic, readonly) NSLocale *defaultLocale;

/**
 * Indicates whether the manager can accept only the recognized premises by the operating system.
 *
 * This setting must be changed before setting the supportedLocales. The default is YES.
 */
@property (nonatomic, assign) BOOL allowsOnlyLocalesAvailableOnSystem;

@property (nonatomic, weak) id<SDLocalizationManagerDelegate> delegate;

#pragma mark - Selected Locale & Default Locale
/**
 * Set the selectedLocale based on the past id, verifying that the locale is supported.
 *
 * If the selectedLocale has changed, then launches an SDLocalizationManagerLanguageDidChangeNotification notification
 *
 * @param identifier The locale identifier to be set as selected.
 */
- (void) setSelectedLocaleWithIdentifier:(NSString*)identifier;

/**
 * Check if the selectedLocale has an identifier equal to the previous one.
 *
 * @param identifier Identifier to be checked.
 *
 * @return YES if the selectedLocale has an identifier equal to the previous one, otherwise NO.
 */
- (BOOL) isLocaleWithIdentifierSelected:(NSString*)identifier;

/**
 * Set the defaultLocale based on the past ID.
 *
 * @param identifier The locale identifier to be set as default.
 */
- (void) setDefaultLocaleWithIdentifier:(NSString*)identifier;

/**
 * Erases saved settings in user defaults so that the local selection is recalculated.
 * This method must be called before making any setting in the SDLocalizationManager.
 *
 * @return YES if you can reset the settings.
 */
- (BOOL) resetSavedSettings;

#pragma mark - Supported Locales
/**
 * Set passed locales as "supported" by the application.
 *
 * Do not set supportedLocales if you want to leave language management to the operating system.
 *
 * @param supportedLocales an NSArring NSArray that represents valid identifiers for NSLocale.
 */
- (void) setSupportedLocales:(NSArray*)supportedLocales;

/**
 * Load and set the "supported" locales from the file in the resources.
 *
 * If the file name does not have extension, "plist" is selected as the default.
 *
 * @param fileName The file name in the resources that contain the supported locales array.
 */
- (void) loadSupportedLocalesFromFileWithName:(NSString*)fileName;

/**
 * Restores the list of supported locale identifiers.
 *
 * @return Supported locales.
 */
- (NSArray*) supportedLocales;

/**
 * Check whether the locale with the past ID is among the supported ones.
 *
 * @param identifier Identifier to be checked.
 *
 * @return YES if the locale is supported, otherwise NO.
 */
- (BOOL) supportsLocaleWithIdentifier:(NSString*)identifier;

/**
 * Returns the most specific supported locale corresponding to the past argument in the topic.
 * If the past string identifies a country-specific locale (eg "es_ES") and this is not supported, then this method verifies whether the app supports its generic locale (eg "es"). In that case returns it, otherwise it returns nil.
 *
 * @param identifier The locale identifier to be returned.
 *
 * Reset the supported NSLocal object corresponding to the given ID.
 */
- (NSLocale*) supportedLocaleWithIdentifier:(NSString*)identifier;

#pragma mark - Display Names
/**
 * Returns the names of localized supported locales in the currently selected language.
 *
 * @return an array of NSString representing the names of supported locales.
 */
- (NSArray*) supportedLocalesNamesInSelectedLocale;

/**
 * Returns the names of supported locales located in their respective language.
 *
 * @return an array of NSString representing the names of supported locales.
 */
- (NSArray*) supportedLocalesNamesInCorrespondingLocale;

/**
 * Returns the names of the supported locales as reported in the Localizable.strings file associated with the selectedLocale.
 *
 * @return an array of NSString representing the names of supported locales.
 */
- (NSArray*) supportedLocalesNamesInLocalizableStrings;

/**
 * Returns the names of supported locales as reported in the .strings file indicated and associated with the selectedLocale.
 *
 * @return an array of NSString representing the names of supported locales.
 */
- (NSArray *) supportedLocalesNamesInTableWithName:(NSString*)tableName;

/**
 * Returns the name of given locale in the corresponding language.
 *
 * @return The name of given locale in the corresponding language.
 */
- (NSString *) localeNameForLocaleIdentifier:(NSString *)identifier;

/**
 * Returns the name of given locale in selected language.
 *
 * @return The name of given locale in selected language.
 */
- (NSString *) localeNameForLocaleIdentifierInSelectedLocale:(NSString *)identifier;

#pragma mark - Localized Strings
/**
 * Returns the localized key value in Localizable.strings associated with the selectedLocale.
 *
 * Search is done first using the selectedLocale, then using any locale that is not specific to country, and finally using the defaultLocale.
 *
 * @param key The localized key.
 *
 * @return The value associated with the localized key.
 */
- (NSString*) localizedKey:(NSString*)key;

/**
 * Returns the localized key value in the past strings associated with the selectedLocale.
 *
 * Search is done first using the selectedLocale, then using any locale that is not specific to country, and finally using the defaultLocale.
 *
 * @param key The localized key.
 * @param tableName The .strings name that contains the key.
 *
 * @return The value associated with the localized key.
 */
- (NSString*) localizedKey:(NSString*)key fromTable:(NSString*)tableName;

/**
 * Returns the localized key value in Localizable.strings associated with the selectedLocale.
 *
 * Search is done first using the selectedLocale, then using any locale that is not specific to country, and finally using the defaultLocale.
 *
 * @param key The localized key.
 * @param defaultValue The default value to be returned if the key does not exist.
 *
 * @return The value associated with the localized key or the default value passed.
 */
- (NSString*) localizedKey:(NSString*)key withDefaultValue:(NSString*)defaultValue;

/**
 * Returns the localized key value in the past strings associated with the selectedLocale.
 *
 * Search is done first using the selectedLocale, then using any locale that is not specific to country, and finally using the defaultLocale.
 *
 * @param key The localized key.
 * @param tableName The .strings name that contains the key.
 * @param defaultValue The default value to be returned if the key does not exist.
 *
 * @return The value associated with the localized key or the default value passed.
 */
- (NSString *)localizedKey:(NSString *)key fromTable:(NSString *)tableName withDefaultValue:(NSString *)defaultValue;

/**
 * Returns the localized key value in the past strings associated with the selectedLocale.
 *
 * Search is done first using the selectedLocale, then using any locale that is not specific to country, and finally using the defaultLocale.
 *
 * @param key The localized key.
 * @param tableName The .strings name that contains the key.
 * @param placeholderDictionary A dictionary that has the keys as strings to look for in localizedString and to be replaced with its values.
 * @param defaultValue The default value to be returned if the key does not exist.
 *
 * @return The value associated with the localized key or the default value passed.
 */
- (NSString*) localizedKey:(NSString*)key fromTable:(NSString*)tableName placeholderDictionary:(NSDictionary<NSString*, NSString*>*)placeholderDictionary withDefaultValue:(NSString*)defaultValue;

/**
 * Returns the localized key value in the past strings associated with the selectedLocale.
 *
 * Search is done first using the selectedLocale, then using any locale that is not specific to country, and finally using the defaultLocale.
 *
 * @param key The localized key.
 * @param tableName The .strings name that contains the key.
 * @param bundleClass A class contained in the same bundle of the table. Typically this is the caller class. This is useful to load tables from frameworks. The manager will search into the main bundle and then into the given bundle.
 * @param defaultValue The default value to be returned if the key does not exist.
 *
 * @return The value associated with the localized key or the default value passed.
 */
- (NSString *)localizedKey:(NSString *)key fromTable:(NSString *)tableName inBundleForClass:(Class)bundleClass withDefaultValue:(NSString *)defaultValue;

/**
 * Retrieves and returns all localized strings associated with keys that have the format "<prefix>.% D"
 *
 * @param prefix The prefix of the localized key list to retrieve.
 *
 * @return The list of all keys associated with the past prefix.
 */
- (NSArray*) arrayOfLocalizedStringsWithPrefix:(NSString*)prefix;

#pragma mark - Adding/Removing strings

/**
 * Adds the given strings to the specific table and localization. Added strings will be maintained permanently. To remove them use resetAddedStringXXX methods.
 *
 * @param strings dictionary with keys and values for the translations
 * @param tableName Name of the table to which the strings are to be added
 * @param localization id of localization of strings.
 */
- (void) addStrings:(NSDictionary<NSString*, NSString*>*)strings toTableWithName:(NSString*)tableName forLocalization:(NSString*)localization;
/**
 * Like previous method. Localization is the current selected.
 */
- (void) addStrings:(NSDictionary<NSString*, NSString*>*)strings toTableWithName:(NSString*)tableName;
/**
 * Like previous method. Table is the Localizable one (default table).
 */
- (void) addStrings:(NSDictionary<NSString*, NSString*>*)strings;

/**
 * Removes added strings to the specific table and localization.
 *
 * @param tableName Name of the table to which the strings are to be added
 * @param localization id of localization of strings.
 */
- (void) resetAddedStringsToTableWithName:(NSString*)tableName forLocalization:(NSString*)localization;
- (void) resetAllAddedStringsForLocalization:(NSString*)localization;
- (void) resetAllAddedStrings;


#pragma mark - Formatters & Calendars Management

/**
 * This method resets all formatters and calendars.
 *
 * Subclasses that add formatters or calendars must overwrite this method and call it super.
 */
- (void)resetFormattersAndCalendars;

#pragma mark - Date Formatters

/**
 * Returns the locale to use for formatters.
 *
 * @return The locale to use for formatters.
 */
- (NSLocale*)formatterLocale;

/**
 * This formatter formats the dates in the classic "dd / dd / yyyy" format, localized according to the selectedLocale
 * Or, if this is not validated, according to [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSDateFormatter* simpleDateFormatter;

/**
 * This formatter formats the time in the 12-hour format followed by the "12:24 PM" period, which is localized according to the selectedLocale
 * Or, if this is not validated, according to [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSDateFormatter* twelveHoursTimeFormatter;

/**
 * This formatter formats the time in the 24-hour format "22:24" localized according to the selectedLocale
 * Or, if this is not validated, according to [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSDateFormatter* twentyFourHoursTimeFormatter;

/**
 * This formatter formats the dates in the classic "dd / mm / yyyy" format and the 24 hour "22:24" time format localized according to the selectedLocale
 * Or, if this is not validated, according to [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSDateFormatter* simpleDateTimeFormatter;

/**
 * This formatter formats dates in "yyyy-MM-dd hh: mm: ss.SSS" format using the GMT timezone.
 */
@property (nonatomic, strong) NSDateFormatter* serverDateTimeFormatter;

#pragma mark - User Default Date Formatters
/**
 * Format for dates used by userDefault formatters.
 * When set is saved in userDefaults and their formatters do not account for the locale.
 *
 * The default value is "dd / MM / yyyy".
 */
@property (nonatomic, strong) NSString *userDefaultDateFormat;
/**
 * Format for time used by userDefault formatters.
 * When set is saved in userDefaults and their formatters do not account for the locale.
 *
 * The default value is "HH: mm".
 */
@property (nonatomic, strong) NSString *userDefaultTimeFormat;

/**
 * This formatter formats dates according to the format defined in userDefaultDateFormat.
 */
@property (nonatomic, strong) NSDateFormatter* userDefaultDateFormatter;

/**
 * This formatter formats time according to the format defined in userDefaultTimeFormat.
 */
@property (nonatomic, strong) NSDateFormatter* userDefaultTimeFormatter;

/**
 * This formatter formats dates according to the format defined in userDefaultDateFormat, and the time according to the format defined in userDefaultTimeFormat. Leave a space between the date and time.
 */
@property (nonatomic, strong) NSDateFormatter* userDefaultDateTimeFormatter;

#pragma mark - Number Formatters

#define kDecimalSeparatorLocalizedKey       @"LM_decimal_separator"
#define kGroupingSeparatorLocalizedKey      @"LM_grouping_separator"

/**
 * Unit for distances used by userDefault formatters.
 * When set, it is saved in userDefaults.
 *
 * The default value is local "m" with metric and "ft" system for those with the US system.
 * The locale used is the selectedLocale or, failing [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSString *userDefaultDistanceUnit;

/**
 * Unit for speeds used by userDefault formatters.
 * When set, it is saved in userDefaults.
 *
 * The default value is the local "km / h" with metric and "mph" system for those with the US system.
 * The locale used is the selectedLocale or, failing [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSString *userDefaultSpeedUnit;

/**
 * Currency symbol used by userDefault formatters.
 * When set, it is saved in userDefaults.
 *
 * The default value is that provided by the locale associated with the formatter.
 */
@property (nonatomic, strong) NSString *userDefaultCurrencySymbol;

/**
 * This formatter formats distances by adding the value of userDefaultDistanceUnit as suffix.
 *
 * By default, always use a comma-number.
 *
 * The symbols for the decimals and groups are those defined by the selectedLocale, or failing, from the [CurrentLocale NSLocale]. They can be overwritten using the localized keys "LM_decimal_separator" and "LM_grouping_separator".
 */
@property (nonatomic, strong) NSNumberFormatter* userDefaultDistanceFormatter;

/**
 * This formatter formats the speeds by adding the userDefaultSpeedUnit value as suffix.
 *
 * By default, always use a comma-number.
 *
 * The symbols for the decimals and groups are those defined by the selectedLocale, or failing, from the [CurrentLocale NSLocale]. They can be overwritten using the localized keys "LM_decimal_separator" and "LM_grouping_separator".
 */
@property (nonatomic, strong) NSNumberFormatter* userDefaultSpeedFormatter;

/**
 * This formatter formats the numbers by adding the value of userDefaultCurrencySymbol as suffix.
 *
 * By default, always use two numbers after the comma.
 *
 * The symbols for the decimals and groups are those defined by the selectedLocale, or failing, from the [CurrentLocale NSLocale]. They can be overwritten using the localized keys "LM_decimal_separator" and "LM_grouping_separator".
 */
@property (nonatomic, strong) NSNumberFormatter* userDefaultCurrencyFormatter;

/**
 * Format the numbers in percent format by avoiding the division by 100 that is normally done by
 NSNumberFormatter by default.
 */
@property (nonatomic, strong) NSNumberFormatter* percentageFormatter;

#pragma mark - Calendars

/**
 * Time zones used by userDefault caledars.
 * When set, it is saved in userDefaults.
 *
 * The default value is that provided by [NSCalendar currentCalendar].
 */
@property (nonatomic, strong) NSTimeZone *userDefaultTimeZone;

/**
 * Calendar identifier used by userDefault caledars.
 * When set, it is saved in userDefaults.
 *
 * The default value is that provided by [NSCalendar currentCalendar].
 */
@property (nonatomic, strong) NSString *userDefaultCalendarIdentifier;

/**
 * Calendar with userDefaults settings.
 *
 * The time zone is taken by userDefaultTimeZone.
 * The calendar identifier is taken from userDefaultCalendarIdentifier.
 * The calendar locale is selectedLocale, or fails, [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSCalendar *userDefaultCalendar;

/**
 * Gregorian calendar with time zones set to UTC.
 */
@property (nonatomic, strong) NSCalendar* utcCalendar;

/**
 * Gregorian calendar with time zones set to GMT.
 */
@property (nonatomic, strong) NSCalendar* gmtCalendar;

@end

