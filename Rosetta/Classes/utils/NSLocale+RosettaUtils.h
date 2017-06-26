//
//  NSLocale+Utils.h
//  SysdataCore
//
//  Created by Paolo Ardia on 17/11/15.
//
//

#import <Foundation/Foundation.h>

@interface NSLocale (Utils)

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
