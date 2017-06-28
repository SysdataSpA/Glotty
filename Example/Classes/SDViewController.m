//
//  SDViewController.m
//  Rosetta
//
//  Created by francescoceravolo on 06/26/2017.
//  Copyright (c) 2017 francescoceravolo. All rights reserved.
//

#import "SDViewController.h"
#import <Glotty/SDLocalizationManager.h>


#define SUPPORTED_LOCALES @[@"en", @"it", @"zh-Hant"]

@interface SDViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UILabel *dynamicLabel;

@end

@implementation SDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
//    [SDLocalizationManager sharedManager].allowsOnlyLocalesAvailableOnSystem = NO;
    [[SDLocalizationManager sharedManager] setSupportedLocales:SUPPORTED_LOCALES];
    [[SDLocalizationManager sharedManager] setDefaultLocaleWithIdentifier:SUPPORTED_LOCALES.firstObject];
    
//
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLabels) name:SDLocalizationManagerLanguageDidChangeNotification object:nil];
    
//    [[SDLocalizationManager sharedManager] resetAllAddedStrings];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshCurrentSelctionOnSegmentedControl];
    
    [self refreshLabels];
}

- (void) refreshCurrentSelctionOnSegmentedControl
{
    NSString* currentLocale = [SDLocalizationManager sharedManager].selectedLocale.localeIdentifier;
    for(int i=0; i<SUPPORTED_LOCALES.count; i++)
    {
        NSString* localeIdentifier = SUPPORTED_LOCALES[i];
        if([currentLocale isEqualToString:localeIdentifier])
        {
            [self.segmentedControl setSelectedSegmentIndex:i];
        }
    }
}

- (void) refreshLabels
{
    NSString* localizedString = SDLocalizedString(@"welkome_key");
    self.welcomeLabel.text = localizedString;
    
    NSString* dynamicString = SDLocalizedString(@"dynamic_key");
    self.dynamicLabel.text = dynamicString;
}

#pragma mark IBActions
- (IBAction)segmentedControlValueChanaged:(UISegmentedControl *)sender
{
    NSString* localeIdentifier = SUPPORTED_LOCALES[sender.selectedSegmentIndex];
    [[SDLocalizationManager sharedManager] setSelectedLocaleWithIdentifier:localeIdentifier];
}

- (IBAction)addToEnglishTapped:(UIButton *)sender
{
    [[SDLocalizationManager sharedManager] addStrings:@{@"dynamic_key" : @"This is a dynamic label added programmaticaly for the English localization"} toTableWithName:@"Localizable" forLocalization:SUPPORTED_LOCALES[0]];
}

- (IBAction)addToItalianTapped:(id)sender
{
    [[SDLocalizationManager sharedManager] addStrings:@{@"dynamic_key" : @"Questa è una stringa dinamica aggiunta programmaticamente per la lingua Italiana"} toTableWithName:@"Localizable" forLocalization:SUPPORTED_LOCALES[1]];
}

- (IBAction)resetTapped:(id)sender
{
    [[SDLocalizationManager sharedManager] resetAllAddedStrings];
}

@end
