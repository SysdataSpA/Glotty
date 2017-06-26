//
//  NSLocale+Utils.m
//  SysdataCore
//
//  Created by Paolo Ardia on 17/11/15.
//
//

#import "NSLocale+RosettaUtils.h"

@implementation NSLocale (RosettaUtils)

- (NSLocaleLanguageDirection)lineDirection
{
    return [NSLocale lineDirectionForLanguage:self.languageCode];
}

- (NSLocaleLanguageDirection)characterDirection
{
    return [NSLocale characterDirectionForLanguage:self.languageCode];
}

- (NSString *)languageCode
{
    return [self objectForKey:NSLocaleLanguageCode];
}

- (NSString *)languageID
{
    return [self.localeIdentifier stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
}

- (NSString *)countryCode
{
    return [self objectForKey:NSLocaleCountryCode];
}

- (NSString *)scriptCode
{
    return [self objectForKey:NSLocaleScriptCode];
}
- (NSString *)variantCode
{
    return [self objectForKey:NSLocaleVariantCode];
}

- (NSCharacterSet *)exemplarCharacterSet
{
    return [self objectForKey:NSLocaleExemplarCharacterSet];
}

- (NSCalendar *)calendar
{
    return [self objectForKey:NSLocaleCalendar];
}

- (NSString *)collationIdentifier
{
    return [self objectForKey:NSLocaleCollationIdentifier];
}

- (BOOL)usesMetricSystem
{
    return [[self objectForKey:NSLocaleUsesMetricSystem] boolValue];
}

- (NSString *)measurementSystem
{
    return [self objectForKey:NSLocaleMeasurementSystem];
}

- (NSString *)decimalSeparator
{
    return [self objectForKey:NSLocaleDecimalSeparator];
}

- (NSString *)groupingSeparator
{
    return [self objectForKey:NSLocaleGroupingSeparator];
}

- (NSString *)currencySymbol
{
    return [self objectForKey:NSLocaleCurrencySymbol];
}

- (NSString *)currencyCode
{
    return [self objectForKey:NSLocaleCurrencyCode];
}

- (NSString *)collatorIdentifier
{
    return [self objectForKey:NSLocaleCollatorIdentifier];
}

- (NSString *)quotationBeginDelimiter
{
    return [self objectForKey:NSLocaleQuotationBeginDelimiterKey];
}

- (NSString *)quotationEndDelimiter
{
    return [self objectForKey:NSLocaleQuotationEndDelimiterKey];
}

- (NSString *)alternateQuotationBeginDelimiter
{
    return [self objectForKey:NSLocaleAlternateQuotationBeginDelimiterKey];
}

- (NSString *)alternateQuotationEndDelimiter
{
    return [self objectForKey:NSLocaleAlternateQuotationEndDelimiterKey];
}

- (NSLocale *)baseLanguageLocale
{
    if (self.countryCode.length == 0) {
        return self;
    }
    
    return [NSLocale localeWithLocaleIdentifier:self.languageCode];
}

- (BOOL)isEqualToLocale:(NSLocale *)locale
{
    return ([self.languageCode isEqualToString:locale.languageCode] && [self.countryCode isEqualToString:locale.countryCode]);
}

+ (BOOL)isLocaleIdentifierAvailableOnSystem:(NSString *)identifier
{
    NSArray *availableLocales = [NSLocale availableLocaleIdentifiers];
    return [availableLocales containsObject:identifier];
}

@end
