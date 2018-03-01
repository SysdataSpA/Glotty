//
//  SDLocalizationManagerModels.m
//  Glotty
//
//  Created by Paolo Ardia on 28/02/18.
//

#import "SDLocalizationManagerModels.h"
#define DYNAMIC_BUNDLE_IDENTIFIER @"DYNAMIC"

@implementation SDLocalizationTable
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.content = [NSMutableDictionary new];
    }
    return self;
}
@end

@implementation SDTablesBundle
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.tablesByName = [NSMutableDictionary new];
    }
    return self;
}

+ (SDTablesBundle*)dynamicTablesBundle
{
    SDTablesBundle* bundle = [SDTablesBundle new];
    bundle.identifier = DYNAMIC_BUNDLE_IDENTIFIER;
    return bundle;
}

+ (SDTablesBundle*)mainTablesBundle
{
    SDTablesBundle* bundle = [SDTablesBundle new];
    bundle.identifier = [[NSBundle mainBundle] bundleIdentifier];
    return bundle;
}
@end

@implementation SDLocaleModel
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.dynamic = [SDTablesBundle dynamicTablesBundle];
        self.main = [SDTablesBundle mainTablesBundle];
        self.bundlesById = [NSMutableDictionary new];
    }
    return self;
}
@end

@implementation SDLocalizationDataSource
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.selectedLocale = [SDLocaleModel new];
        self.baseLocale = [SDLocaleModel new];
        self.defaultLocale = [SDLocaleModel new];
    }
    return self;
}
@end
