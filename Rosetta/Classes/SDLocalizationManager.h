//
//  SDLocalizationManager.h
//  SysdataCore
//
//  Created by Paolo Ardia on 16/11/15.
//
//

#import <Foundation/Foundation.h>
#import "NSLocale+RosettaUtils.h"
#import "SDLocalizationLogger.h"

typedef NS_ENUM (NSUInteger, LMLogLevel)
{
    LMLogLevelVerbose = 1,
    LMLogLevelWarning,
    LMLogLevelError
};

// ridefinizione delle macro per la localizzazione delle stringhe
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

@protocol SDLocalizationManagerDelegate <NSObject>
@optional
/**
 *  L'implementazione di questo metodo è utile solo quando si usano locale non standard, le cui localizzazioni e formattazioni devono rispecchiare quello di un altro locale (standard).
 *
 *  @param locale Il locale non standard da convertire.
 *
 *  @return L'identificativo di un locale standard accettato dal sistema operativo.
 */
- (NSString*)ISOLocaleIdentifierForNonStandardLocale:(NSString*)locale;
@end

#define SDLocalizationManagerLanguageDidChangeNotification @"SDLocalizationManagerLanguageDidChangeNotification"

@class SDLocalizationManager;

/**
 *  Questa classe permette di gestire le localizzazioni in maniera indipendente dal sistema operativo.
 *  Per renderla indipendente è necessario settare i locale supportati tramite un array o un file plist.
 *  Il manager può accettare anche locale non standard, ma in tal caso ha bisogno di un delegate per a quale lingua corrispondono, altrimenti non è in grado di tradurre correttamente.
 *  Il manager prevede sempre un locale di default, che se non diversamente specificato, è "en".
 *
 *  Il manager mette a disposizione anche i formatter più comuni per date e numeri, utilizzando le informazioni del locale selezionato per formattare in maniera conforme al locale stesso.
 */
#if BLABBER
@interface SDLocalizationManager : NSObject <SDLoggerModuleProtocol>
#else
@interface SDLocalizationManager : NSObject
#endif

+ (instancetype) sharedManager;

#pragma mark - Locales
/**
 *  Il locale attualmente selezionato.
 *
 *  Prima di settare i locale supportati è nil, mentre subito dopo è uguale a quello del sistema operativo (se supportato) o a quello di default. Il locale selezionato viene salvato negli user defaults.
 */
@property (nonatomic, readonly) NSLocale *selectedLocale;

/**
 *  Il locale di default.
 *
 *  Viene selezionato in fase di inizializzazione se il locale del sistema operativo non è tra quelli supportati. Viene utilizzato anche come ultima risorsa nel caso in cui una stringa non è localizzata nel locale selezionato.
 */
@property (nonatomic, readonly) NSLocale *defaultLocale;

/**
 *  Indica se il manager può accettare solo i locale riconosciuti dal sistema operativo.
 *
 *  Questa impostazione va cambiata prima di settare i supportedLocales. Il default è YES.
 */
@property (nonatomic, assign) BOOL allowsOnlyLocalesAvailableOnSystem;

@property (nonatomic, weak) id<SDLocalizationManagerDelegate> delegate;

#pragma mark - Selected Locale & Default Locale
/**
 *  Imposta il selectedLocale in base all'identificativo passato, verificando che il locale sia supportato.
 *
 *  Se il selectedLocale è cambiato, allora lancia una notifica SDLocalizationManagerLanguageDidChangeNotification
 *
 *  @param identifier Identificativo del locale da impostare come selezionato.
 */
- (void) setSelectedLocaleWithIdentifier:(NSString*)identifier;

/**
 *  Controlla se il selectedLocale ha un identificativo uguale a quello passato.
 *
 *  @param identifier Identificativo da controllare.
 *
 *  @return YES se il selectedLocale ha un identificativo uguale a quello passato, altrimenti NO.
 */
- (BOOL) isLocaleWithIdentifierSelected:(NSString*)identifier;

/**
 *  Imposta il defaultLocale in base all'identificativo passato.
 *
 *  @param identifier Identificativo del locale da impostare come default.
 */
- (void) setDefaultLocaleWithIdentifier:(NSString*)identifier;

/**
 *  Cancella le impostazioni salvate negli user defaults in modo che il selected locale venga ricalcolato.
 *  Questo metodo deve essere chiamato prima di effettuare qualsiasi impostazione del SDLocalizationManager.
 *
 *  @return YES se riesce a resettare i settings.
 */
- (BOOL) resetSavedSettings;

#pragma mark - Supported Locales
/**
 *  Imposta i locales passati come "supportati" dall'applicazione.
 *
 *  Non settare i supportedLocales se si vuole lasciare la gestione della lingua al sistema operativo.
 *
 *  @param supportedLocales un NSArray di oggetti NSString che rappresentano identificativi validi per NSLocale.
 */
- (void) setSupportedLocales:(NSArray*)supportedLocales;

/**
 *  Carica e imposta i locales "supportati" dal file nelle resources.
 *
 *  Se il nome del file non ha estensione, viene scelto "plist" come default.
 *
 *  @param fileName Il nome del file nelle resources contenente l'array di locales supportati.
 */
- (void) loadSupportedLocalesFromFileWithName:(NSString*)fileName;

/**
 *  Restistuisce la lista degli identificativi dei locale supportati.
 *
 *  @return I locales supportati.
 */
- (NSArray*) supportedLocales;

/**
 *  Controlla se il locale con l'identificativo passato è tra quelli supportati.
 *
 *  @param identifier Identificativo da controllare.
 *
 *  @return YES se il locale è supportato, altrimenti NO.
 */
- (BOOL) supportsLocaleWithIdentifier:(NSString*)identifier;

/**
 *  Restituisce il locale supportato più specifico corrispondente all'identificativo passato in argomento.
 *  Se la stringa passata identifica un locale specifico per country (ad es.: "es_ES") e questo non è supportato, allora questo metodo verifica se l'app supporta il relativo locale generico (ad es.: "es"). In tal caso lo restituisce, altrimenti restituisce nil.
 *
 *  @param identifier Identificativo del locale da restituire.
 *
 *  @return l'oggetto NSLocale supportato corrispondente all'identificativo dato.
 */
- (NSLocale*) supportedLocaleWithIdentifier:(NSString*)identifier;

#pragma mark - Display Names
/**
 *  Restituisce i nomi dei locales supportati localizzati nella lingua attualmente selezionata.
 *
 *  @return un array di NSString rappresentanti i nomi dei locales supportati.
 */
- (NSArray*) supportedLocalesNamesInSelectedLocale;

/**
 *  Restituisce i nomi dei locales supportati localizzati nella rispettiva lingua.
 *
 *  @return un array di NSString rappresentanti i nomi dei locales supportati.
 */
- (NSArray*) supportedLocalesNamesInCorrespondingLocale;

/**
 *  Restituisce i nomi dei locales supportati come riportati nel file Localizable.strings associato al selectedLocale.
 *
 *  @return un array di NSString rappresentanti i nomi dei locales supportati.
 */
- (NSArray*) supportedLocalesNamesInLocalizableStrings;

/**
 *  Restituisce i nomi dei locales supportati come riportati nel file .strings indicato e associato al selectedLocale.
 *
 *  @return un array di NSString rappresentanti i nomi dei locales supportati.
 */
- (NSArray *) supportedLocalesNamesInTableWithName:(NSString*)tableName;

#pragma mark - Localized Strings
/**
 *  Restituisce il valore della chiave localizzata nel Localizable.strings associato al selectedLocale.
 *
 *  La ricerca viene effettuata prima usando il selectedLocale, poi usando l'eventuale locale non specifico per country, infine usando il defaultLocale.
 *
 *  @param key La chiave localizzata.
 *
 *  @return Il valore associato alla chiave localizzata.
 */
- (NSString*) localizedKey:(NSString*)key;

/**
 *  Restituisce il valore della chiave localizzata nel .strings passato associato al selectedLocale.
 *
 *  La ricerca viene effettuata prima usando il selectedLocale, poi usando l'eventuale locale non specifico per country, infine usando il defaultLocale.
 *
 *  @param key       La chiave localizzata.
 *  @param tableName Il nome del .strings contenente la chiave.
 *
 *  @return Il valore associato alla chiave localizzata.
 */
- (NSString*) localizedKey:(NSString*)key fromTable:(NSString*)tableName;

/**
 *  Restituisce il valore della chiave localizzata nel Localizable.strings associato al selectedLocale.
 *
 *  La ricerca viene effettuata prima usando il selectedLocale, poi usando l'eventuale locale non specifico per country, infine usando il defaultLocale.
 *
 *  @param key          La chiave localizzata.
 *  @param defaultValue Valore di default da restituire nel caso in cui la chiave non esista.
 *
 *  @return Il valore associato alla chiave localizzata o il valore di default passato.
 */
- (NSString*) localizedKey:(NSString*)key withDefaultValue:(NSString*)defaultValue;

/**
 *  Restituisce il valore della chiave localizzata nel .strings passato associato al selectedLocale.
 *
 *  La ricerca viene effettuata prima usando il selectedLocale, poi usando l'eventuale locale non specifico per country, infine usando il defaultLocale.
 *
 *  @param key          La chiave localizzata.
 *  @param tableName    Il nome del .strings contenente la chiave.
 *  @param defaultValue Valore di default da restituire nel caso in cui la chiave non esista.
 *
 *  @return Il valore associato alla chiave localizzata o il valore di default passato.
 */
- (NSString *)localizedKey:(NSString *)key fromTable:(NSString *)tableName withDefaultValue:(NSString *)defaultValue;

/**
 *  Restituisce il valore della chiave localizzata nel .strings passato associato al selectedLocale.
 *
 *  La ricerca viene effettuata prima usando il selectedLocale, poi usando l'eventuale locale non specifico per country, infine usando il defaultLocale.
 *
 *  @param key          La chiave localizzata.
 *  @param tableName    Il nome del .strings contenente la chiave.
 *  @param placeholderDictionary    Dizionario che ha come chiavi le stringhe da cercare nella localizedString e da sostituire con i relativi valori.
 *  @param defaultValue Valore di default da restituire nel caso in cui la chiave non esista.
 *
 *  @return Il valore associato alla chiave localizzata o il valore di default passato.
 */
- (NSString*) localizedKey:(NSString*)key fromTable:(NSString*)tableName placeholderDictionary:(NSDictionary<NSString*, NSString*>*)placeholderDictionary withDefaultValue:(NSString*)defaultValue;

/**
 *  Recupera e restituisce tutte le stringhe localizzate associate alle chiavi che hanno il formato "<prefix>.%d"
 *
 *  @param prefix Il prefisso della lista di chiavi localizzate da recuperare.
 *
 *  @return La lista di tutte le stringhe associate alle chiavi con il prefisso passato.
 */
- (NSArray*) arrayOfLocalizedStringsWithPrefix:(NSString*)prefix;

#pragma mark - Adding strings

/**
 *  Aggiunge il dizionario di stringhe passato alla tabella data. Se la tabella non esiste viene creata. Se la tabella esiste le stringhe vengono unite a quelle preesistenti, sovrascrivendo le chiavi che combaciano.
 *
 *  @param strings   Dizionario di stringhe localizzate.
 *  @param tableName Nome della tabella alla quale vanno aggiunte le stringhe.
 */
- (void) addStrings:(NSDictionary<NSString*, NSString*>*)strings toTableWithName:(NSString*)tableName;

#pragma mark - Formatters & Calendars Management

/**
 *  Questo metodo resetta tutti i formatter e i calendari.
 *
 *  Le sottoclassi che aggiungono formatter o calendari devono sovrascrivere questo metodo e chiamarne il super.
 */
- (void)resetFormattersAndCalendars;

#pragma mark - Date Formatters

/**
 *  Restituisce il locale da usare per i formatters.
 *
 *  @return Il locale da usare per i formatters.
 */
- (NSLocale*)formatterLocale;

/**
 *  Questo formatter formatta le date nel classico formato "dd/MM/yyyy" localizzate secondo il selectedLocale
 *  oppure, se questo non è valorizzato, secondo il [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSDateFormatter* simpleDateFormatter;

/**
 *  Questo formatter formatta il tempo nel formato a 12 ore seguito dal periodo "12:24 PM" localizzate secondo il selectedLocale
 *  oppure, se questo non è valorizzato, secondo il [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSDateFormatter* twelveHoursTimeFormatter;

/**
 *  Questo formatter formatta il tempo nel formato a 24 ore "22:24" localizzate secondo il selectedLocale
 *  oppure, se questo non è valorizzato, secondo il [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSDateFormatter* twentyFourHoursTimeFormatter;

/**
 *  Questo formatter formatta le date nel classico formato "dd/MM/yyyy" e il tempo nel formato a 24 ore "22:24" localizzate secondo il selectedLocale
 *  oppure, se questo non è valorizzato, secondo il [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSDateFormatter* simpleDateTimeFormatter;

/**
 *  Questo formatter formatta le date nel formato "yyyy-MM-dd hh:mm:ss.SSS" usando la timezone GMT.
 */
@property (nonatomic, strong) NSDateFormatter* serverDateTimeFormatter;

#pragma mark - User Default Date Formatters
/**
 *  Formato per le date utilizzato dagli userDefault formatters.
 *  Quando settato viene salvato negli userDefaults e i relativi formatter non tengono conto del locale.
 *
 *  Il valore di default è "dd/MM/yyyy".
 */
@property (nonatomic, strong) NSString *userDefaultDateFormat;
/**
 *  Formato per il tempo utilizzato dagli userDefault formatters.
 *  Quando settato viene salvato negli userDefaults e i relativi formatter non tengono conto del locale.
 *
 *  Il valore di default è "HH:mm".
 */
@property (nonatomic, strong) NSString *userDefaultTimeFormat;

/**
 *  Questo formatter formatta le date secondo il formato definito in userDefaultDateFormat.
 */
@property (nonatomic, strong) NSDateFormatter* userDefaultDateFormatter;

/**
 *  Questo formatter formatta il tempo secondo il formato definito in userDefaultTimeFormat.
 */
@property (nonatomic, strong) NSDateFormatter* userDefaultTimeFormatter;

/**
 *  Questo formatter formatta le date secondo il formato definito in userDefaultDateFormat, e il tempo secondo il formato definito in userDefaultTimeFormat. Lascia uno spazio tra la data e l'ora. 
 */
@property (nonatomic, strong) NSDateFormatter* userDefaultDateTimeFormatter;

#pragma mark - Number Formatters

#define kDecimalSeparatorLocalizedKey       @"LM_decimal_separator"
#define kGroupingSeparatorLocalizedKey      @"LM_grouping_separator"

/**
 *  Unità di misura per le distanze utilizzata dagli userDefault formatters.
 *  Quando settata viene salvata negli userDefaults.
 *
 *  Il valore di default è " m" locale con sistema metrico e " ft" per quelli con sistema statunitense.
 *  Il locale utilizzato è il selectedLocale o, in mancanza, il [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSString *userDefaultDistanceUnit;

/**
 *  Unità di misura per le velocità utilizzata dagli userDefault formatters.
 *  Quando settata viene salvata negli userDefaults.
 *
 *  Il valore di default è " km/h" locale con sistema metrico e " mph" per quelli con sistema statunitense.
 *  Il locale utilizzato è il selectedLocale o, in mancanza, il [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSString *userDefaultSpeedUnit;

/**
 *  Simbolo di valuta utilizzato dagli userDefault formatters.
 *  Quando settato viene salvato negli userDefaults.
 *
 *  Il valore di default è quello fornito dal locale associato al formatter.
 */
@property (nonatomic, strong) NSString *userDefaultCurrencySymbol;

/**
 *  Questo formatter formatta le distanze aggiungendo come suffisso il valore di userDefaultDistanceUnit.
 *
 *  Di default usa sempre un numero dopo la virgola.
 *
 *  I simboli per il separatore dei decimali e dei gruppi sono quelli definiti dal selectedLocale, o in mancanza, dal [NSLocale currentLocale]. Possono essere sovrascritti usando le chiavi localizzate "LM_decimal_separator" e "LM_grouping_separator".
 */
@property (nonatomic, strong) NSNumberFormatter* userDefaultDistanceFormatter;

/**
 *  Questo formatter formatta le velocità aggiungendo come suffisso il valore di userDefaultSpeedUnit.
 *
 *  Di default usa sempre un numero dopo la virgola.
 *
 *  I simboli per il separatore dei decimali e dei gruppi sono quelli definiti dal selectedLocale, o in mancanza, dal [NSLocale currentLocale]. Possono essere sovrascritti usando le chiavi localizzate "LM_decimal_separator" e "LM_grouping_separator".
 */
@property (nonatomic, strong) NSNumberFormatter* userDefaultSpeedFormatter;

/**
 *  Questo formatter formatta i numeri aggiungendo come suffisso il valore di userDefaultCurrencySymbol.
 *
 *  Di default usa sempre due numeri dopo la virgola.
 *
 *  I simboli per il separatore dei decimali e dei gruppi sono quelli definiti dal selectedLocale, o in mancanza, dal [NSLocale currentLocale]. Possono essere sovrascritti usando le chiavi localizzate "LM_decimal_separator" e "LM_grouping_separator".
 */
@property (nonatomic, strong) NSNumberFormatter* userDefaultCurrencyFormatter;

/**
 *  Formatta i numeri in formato percentuale evitando la divisione per 100 che normalmente viene effettuata da
    NSNumberFormatter di default.
 */
@property (nonatomic, strong) NSNumberFormatter* percentageFormatter;

#pragma mark - Calendars

/**
 *  Time zone utilizzata dagli userDefault caledars.
 *  Quando settata viene salvata negli userDefaults.
 *
 *  Il valore di default è quello fornito dal [NSCalendar currentCalendar].
 */
@property (nonatomic, strong) NSTimeZone *userDefaultTimeZone;

/**
 *  Identificativo di calendario utilizzato dagli userDefault caledars.
 *  Quando settato viene salvato negli userDefaults.
 *
 *  Il valore di default è quello fornito dal [NSCalendar currentCalendar].
 */
@property (nonatomic, strong) NSString *userDefaultCalendarIdentifier;

/**
 *  Calendario con le impostazioni degli userDefaults.
 *
 *  La time zone è presa da userDefaultTimeZone.
 *  Il calendar identifier è preso da userDefaultCalendarIdentifier.
 *  Il locale del calendario è selectedLocale, o in mancanza, [NSLocale currentLocale].
 */
@property (nonatomic, strong) NSCalendar *userDefaultCalendar;

/**
 *  Calendario gregoriano con time zone impostata a UTC.
 */
@property (nonatomic, strong) NSCalendar* utcCalendar;

/**
 *  Calendario gregoriano con time zone impostata a GMT.
 */
@property (nonatomic, strong) NSCalendar* gmtCalendar;

@end
