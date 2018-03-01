//
//  SDLocalizationManagerModels.h
//  Glotty
//
//  Created by Paolo Ardia on 28/02/18.
//

#import <Foundation/Foundation.h>

@interface SDLocalizationTable: NSObject
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSMutableDictionary* content;
@end

@interface SDTablesBundle: NSObject
@property (nonatomic, strong) NSString* identifier;
@property (nonatomic, strong) NSMutableDictionary<NSString*, SDLocalizationTable*>* tablesByName;
@end

@interface SDLocaleModel: NSObject
@property (nonatomic, strong) NSString* languageID;
@property (nonatomic, strong) SDTablesBundle* dynamic;
@property (nonatomic, strong) SDTablesBundle* main;
@property (nonatomic, strong) NSMutableDictionary<NSString*, SDTablesBundle*>* bundlesById;
@end

@interface SDLocalizationDataSource: NSObject
@property (nonatomic, strong) SDLocaleModel* selectedLocale;
@property (nonatomic, strong) SDLocaleModel* baseLocale;
@property (nonatomic, strong) SDLocaleModel* defaultLocale;
@end
