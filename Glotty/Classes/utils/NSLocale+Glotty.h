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

@interface NSLocale (Glotty)

- (NSLocaleLanguageDirection) lineDirection;
- (NSLocaleLanguageDirection) characterDirection;
- (NSString*) languageCode;
- (NSString*) languageID;
- (NSString*) countryCode;
- (NSString*) scriptCode;
- (NSString*) variantCode;
- (NSCharacterSet*) exemplarCharacterSet;
- (NSCalendar*) calendar;
- (NSString*) collationIdentifier;
- (BOOL) usesMetricSystem;
- (NSString*) measurementSystem;
- (NSString*) decimalSeparator;
- (NSString*) groupingSeparator;
- (NSString*) currencySymbol;
- (NSString*) currencyCode;
- (NSString*) collatorIdentifier;
- (NSString*) quotationBeginDelimiter;
- (NSString*) quotationEndDelimiter;
- (NSString*) alternateQuotationBeginDelimiter;
- (NSString*) alternateQuotationEndDelimiter;
- (NSLocale*) baseLanguageLocale;

- (BOOL)isEqualToLocale:(NSLocale*)locale;

+ (BOOL)isLocaleIdentifierAvailableOnSystem:(NSString*)identifier;

@end
