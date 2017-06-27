# Glotty

[![CI Status](http://img.shields.io/travis/francescoceravolo/Glotty.svg?style=flat)](https://travis-ci.org/francescoceravolo/Glotty)
[![Version](https://img.shields.io/cocoapods/v/Glotty.svg?style=flat)](http://cocoapods.org/pods/Glotty)
[![License](https://img.shields.io/cocoapods/l/Glotty.svg?style=flat)](http://cocoapods.org/pods/Glotty)
[![Platform](https://img.shields.io/cocoapods/p/Glotty.svg?style=flat)](http://cocoapods.org/pods/Glotty)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Glotty is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Glotty"
```


## License

Glotty is available under the Apache license. See the LICENSE file for more info.

## Introduction

The **SDLocalizationManager** (hereinafter referred to as **LM**) is born mainly with the intention of simplifying and standardizing development of applications that require the change of language inside of the application itself, thus disengaging from the selected language by the operating system.

Another purpose for the LM is to make available DateFormatter and NumberFormers more common and to render them "Customizable" for individual languages ​​supported by a project.

So the LM can be divided into two main blocks: 
* the first is for locales management
* the second is for formatters

## Locales Management

### Initial Settings

#### Default Locale

If you want to drive the language in app, you need to set a default locale among those supported by the method:

`- (void) setDefaultLocaleWithIdentifier: (NSString *) identifier;`

#### Supported Locales

The LM is also useful when you do not want to drive the language in the app, but you intend to use its formatters.

To pilot the language in app you must set the supported locales by the method

`- (void) setSupportedLocales: (NSArray *) locales`

Or uploading locales from an external file through

`- (void) loadSupportedLocalesFromFileWithName: (NSString *) fileName`

In this case the file is typically a plist added to the resources of the project containing an array of local identifiers.

At this time the LM controls the local default. If this is not set or if it is not supported, then LM chooses the first local supported list and set it as default.

Then the LM automatically selects one of the supported locales with the following priorities:

1. Initially check if a locale was previously saved in *UserDefaults*. This is selected if it is still in the supported locale.

2. As a second step, the LM cycles between *preferredLanguages​​* indicated by the operating system and for each of these checks:

	3. If the language is supported, it is selected and saved in *UserDefaults* for future executions.
	4. Otherwise, if the language is country-specific (eg "en \ _GB"), check whether its generic version ("en") is supported. In that case, select the generic version and save it to *UserDefaults*.

3. As the last resource sets the default locale as "local selected".

#### Allow local unrecognized by the operating system

By default, LM allows you to set only locales as "supported" recognized by the operating system. If a no-standard locale is passed, this will be discarded and will write in console the error.

In rare cases where it is necessary to use no-standard locale, you can avoid it setting the property

`allowsOnlyLocalesAvailableOnSystem = NO;`

By doing this, the LM will not perform any compliance checks.

If a no-standard locale is set as **selected locale**, the LM asks its *delegate* which standard locale should use for future locations and formatting. If no valid standard locale is indicated, the LM will fallback on default.

#### Example of LM initialization

Typically in *AppDelegate*:

```
[[SDLocalizationManager sharedManager] setAllowsOnlyLocalesAvailableOnSystem: NO];

[[SDLocalizationManager sharedManager] setSupportedLocales: @ [@ "en",
@ "en-US", @ "it", @ "invented-locale"];

[[SDLocalizationManager sharedManager] setDefaultLocaleWithIdentifier: @ "it"];
```

### Using locales

#### Change the selected language

To change the selected language, just call the method:

`- (void) setSelectedLocaleWithIdentifier: (NSString *) identifier;`

Passing one of the supported identifiers.

The LM will verify that the indicated location is supported, going in fallback on its no-country-specific locale supported, or finally on the default locale.

If the selected locale has changed, the LM launches the notification

**SDLocalizationManagerLanguageDidChangeNotification**

To know if a particular language is selected you can call the method of control

`- (BOOL) isLocaleWithIdentifierSelected: (NSString *) identifier;`

#### Reset the settings

If you want to reset the saved settings so that the LM recalculates the language to use, call the following method before setting the supportedLocales and / or the defaultLocal:

``- (BOOL) resetSavedSettings;`

The method returns YES if it resets the saved settings, otherwise it returns NO.

#### Methods for supported locales

To get the list of supported locales, call the method:

`- (NSArray *) supportedLocales;`

To find out if a certain locale is supported, call instead:

`- (BOOL) supportsLocaleWithIdentifier: (NSString *) identifier;`

To get the * NSLocale * object that the LM would use with a certain one
Identifier, call:

`- (NSLocale *) supportedLocaleWithIdentifier: (NSString *) identifier;`

If the given identifier is not supported, the method checks if it is supported its no-country-specific locale and returns the corresponding *NSLocale*. Even if this is not supported, the method returns *nil*.

### Localization

#### Get a localized value

LM allows you to get the localized value associated with a determined key. At this stage the LM will look for the key in the first file associated with the selected locale (ex en-US.strings). As a second attempt he will try in the no-country-specific locale file (ex en.strings). Search ends in the default locale file.

If the value was not found, the methods will return a value of default (if passed in argument) or the key itself.

If the method inputs the file name, the LM looks for only in files with that name.

**N.B** if no "Supported Locales" are set, then methods below will return the value returned by similar System Methods *NSLocalizedString*.

The four methods are:

```
- (NSString *) localizedKey: (NSString *) key;
- (NSString *) localizedKey: (NSString *) key fromTable: (NSString *) tableName;
- (NSString *) localizedKey: (NSString *) key withDefaultValue (NSString *) defaultValue;
- (NSString *) localizedKey: (NSString *) key fromTable: (NSString *) tableName withDefaultValue: (NSString *) defaultValue;
- (NSString *) localizedKey: (NSString *) key fromTable: (NSString *) tableName placeholderDictionary: (NSDictionary <NSString *, NSString *> *) placeholderDictionary withDefaultValue: (NSString *) defaultValue;
```

The 4 methods correspond to 4 comfortable C methods:

```
NSString * SDLocalizedString (NSString * key);
NSString * SDLocalizedStringFromTable (NSString * key, NSString * table);
NSString * SDLocalizedStringWithDefault (NSString * key, NSString * val);
NSString * SDLocalizedStringFromTableWithDefault (NSString * key, NSString * table, NSString * val);
NSString * SDLocalizedStringWithPlaceholders (NSString * key, NSDictionary <NSString *, NSString *> * placeholders);
```

#### Add strings located by code

Strings can be added programmatically passing the corresponding dictionary for a specific table and localizations. 

```
- (void) addStrings:(NSDictionary<NSString*, NSString*>*)strings toTableWithName:(NSString*)tableName forLocalization:(NSString*)localization;
```

This strings will be maintained along the app life. To remove them use methods like:

```
- (void) resetAddedStringsToTableWithName:(NSString*)tableName forLocalization:(NSString*)localization;
```

#### Supported language names

The LM provides two methods for obtaining language display names supported by the operating system.

The first returns all the names that are currently localized in the language
selected:

`- (NSArray *) supportedLocalesNamesInSelectedLocale;`

The second returns any localized name in its own language:

`- (NSArray *) supportedLocalesNamesInCorrespondingLocale;`

In either case, if a name does not exist, it returns a string
empty.

It also provides two methods to retrieve the names of the languages ​​from the files
of localization.

First look in *Localizable.strings*:

`- (NSArray *) supportedLocalesNamesInLocalizableStrings;`

The second searches the file in the topic:

`- (NSArray *) supportedLocalesNamesInTableWithName: (NSString *) tableName;`

Keys in *.strings* must necessarily follow the following convention:


`LM_locale_name_ <locale_id \>" `

eg:

`LM_locale_name_it_IT '' = 'Italian';` 

## Formatters and Calendars

The LM offers a variety of formatters and calendars for most frequent cases.

Formatters use the selected locale to format consistently Dates and numbers. In the absence of a selected locale use the *[NSLocale currentLocale]*. However, you can request a formatter to the LM and change their settings, but these settings are not guaranteed to remain set between two different calls to the formatter, as all formatters and calendars are reinstated as a result of some events, especially whenever the selected locale changes.

*UserDefaultFormatters* and *UserDefaultCalendars* allow you to save formatting and calendar preferences in
*UserDefaults* and come back very useful in those applications where the user can choose the date format, currency, time zone, and so on.
For these components, some comfortable properties allow you to set and then save the preferred settings in *UserDefaults*.

### LM subclasses

If you subclass the LM to add formatters or calendars, it is important to overwrite the method

`- (void) resetFormattersAndCalendars;`

In which the *super* must be called and must be placed at *nil* all formatters and calendars added from the subclass. This is necessary as the components do not set the room any time are used, but are only being created.

### DateFormatters

A brief description of the formatters dates made available by LM:

- **simpleDateFormatter**: formatter that follows the template *"dd / MM / yyyy"*. The final format depends on the selected locale.

- **twelveHoursTimeFormatter**: formatter that follows the template *"hh: mm a"* for the 12-hour format followed by the period (AM / PM). The final format depends on the selected locale.

- **twentyFourHoursTimeFormatter**: follows the template *"HH: mm"* for 24 hours. The final format depends on the selected locale.

- **simpleDateTimeFormatter**: follows the template *"dd / mm / yyyy HH: mm"*. The final format depends on the selected locale.

- **serverDateTimeFormatter**: Has a fixed format *"yyyy-MM-dd hh: mm: ss.SSS"* and the GMT timezone to handle dates from servers that follow this pattern.

- **userDefaultDateFormatter**: Use the format set in the **userDefaultDateFormat** property and the selected locale. The format is saved in *UserDefaults*. By default it is *"dd / MM / yyyy"*.

- **userDefaultTimeFormatter**: Use the format set in the **userDefaultTimeFormat** property and the selected locale. The format is saved in UserDefaults. Default is *"HH: mm"*.

- **userDefaultDateTimeFormatter**: Uses the formats set in properties **userDefaultDateFormat** and **userDefaultTimeFormat** and the selected locale.

### NumberFormatters

By default, number formatters use the selected locale to establish the symbols for the decimal separator and the separator of the thousands. These symbols can be overwritten by adding to **Localizable.strings** define their respective keys:

```
#define kDecimalSeparatorLocalizedKey @ "LM_decimal_separator"
#define kGroupingSeparatorLocalizedKey @ "LM_grouping_separator"
```

A brief description of the number formatters made available by LM:

- **userDefaultDistanceFormatter**: format the distances by adding the unit of measurement, which can be set and saved by the property **userDefaultDistanceUnit**. By default, use *"m"* for metric systems and *"ft"* for U.S. systems. By default, always use a number after the comma.

- **userDefaultSpeedFormatter**: format the speeds by adding the unit of measurement, which can be set and saved by the property **userDefaultSpeedUnit**. By default, use *"km / h"* for metric systems and *"mph"* for US systems. By default, always use a number after the comma.

- **userDefaultCurrencyFormatter**: format the numbers by adding the currency symbol after the value, which can be set and saved by the property **userDefaultCurrencySymbol**. By default, use the symbol indicated by the selected locale. By default, always use two numbers after the comma.

- **percentageFormatter**: format the numbers in percent format by avoiding the division by 100 that is normally performed by *NSNumberFormatter* by default.

### Calendars

A brief description of the calendars made available by LM:

- **userDefaultCalendar**: Calendar with the timeZone indicated in the property **userDefaultTimeZone** and the calendarIdentifier indicated in the property **userDefaultCalendarIdentifier *. Use the selected locale. By default, the timeZone and calendarIdentifier are those specified by the operating system.

- **utcCalendar**: Calendar set with timeZone *UTC*.

- **gmtCalendar**: Calendar set with timeZone *GMT*.


