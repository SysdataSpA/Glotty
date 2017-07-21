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

#import "NSLocale+Glotty.h"

@implementation NSLocale (Glotty)

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
    return ([availableLocales containsObject:[identifier stringByReplacingOccurrencesOfString:@"-" withString:@"_"]]);
}

@end
