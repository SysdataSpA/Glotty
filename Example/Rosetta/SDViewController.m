//
//  SDViewController.m
//  Rosetta
//
//  Created by francescoceravolo on 06/26/2017.
//  Copyright (c) 2017 francescoceravolo. All rights reserved.
//

#import "SDViewController.h"
#import <Rosetta/SDLocalizationManager.h>

@interface SDViewController ()

@end

@implementation SDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    
    [[SDLocalizationManager sharedManager] setSupportedLocales:@[@"it_US"]];
    [[SDLocalizationManager sharedManager] setDefaultLocaleWithIdentifier:@"it_US"];
    
//    [[SDLocalizationManager sharedManager] addStrings:@{@"common_ok" : @"ciaone"} toTableWithName:@"Localizable"];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupLabels];
}

- (void) setupLabels
{
    NSString* localizedString = SDLocalizedString(@"common_ok");
    NSLog(@"%@", localizedString);
}
@end
