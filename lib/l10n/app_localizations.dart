import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ro')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Krono'**
  String get appTitle;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @madeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ using Flutter.'**
  String get madeWith;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Krono Team. All rights reserved.'**
  String get copyright;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get processing;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @weekShort.
  ///
  /// In en, this message translates to:
  /// **'wk.'**
  String get weekShort;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @yourMemories.
  ///
  /// In en, this message translates to:
  /// **'Your Memories'**
  String get yourMemories;

  /// No description provided for @quoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote of the Day'**
  String get quoteTitle;

  /// No description provided for @streakSuffix.
  ///
  /// In en, this message translates to:
  /// **'Day Streak!'**
  String get streakSuffix;

  /// No description provided for @streakLongMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re phenomenal! You\'ve saved memories for {count} days.'**
  String streakLongMessage(Object count);

  /// No description provided for @startFirstDay.
  ///
  /// In en, this message translates to:
  /// **'Start your first day!'**
  String get startFirstDay;

  /// No description provided for @emptyJournalTitle.
  ///
  /// In en, this message translates to:
  /// **'Your journal is empty'**
  String get emptyJournalTitle;

  /// No description provided for @emptyJournalMessage.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first memory! ✨'**
  String get emptyJournalMessage;

  /// No description provided for @createMemory.
  ///
  /// In en, this message translates to:
  /// **'Create a memory'**
  String get createMemory;

  /// No description provided for @startFirstMemory.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first memory! ✨'**
  String get startFirstMemory;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @visualJournal.
  ///
  /// In en, this message translates to:
  /// **'Your Visual Journal'**
  String get visualJournal;

  /// No description provided for @addMemory.
  ///
  /// In en, this message translates to:
  /// **'Add Today\'s Memory'**
  String get addMemory;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit memory'**
  String get editEntry;

  /// No description provided for @saveDay.
  ///
  /// In en, this message translates to:
  /// **'Save Day'**
  String get saveDay;

  /// No description provided for @writeMemory.
  ///
  /// In en, this message translates to:
  /// **'Write a memory...'**
  String get writeMemory;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'What interesting happened?'**
  String get noteHint;

  /// No description provided for @noNote.
  ///
  /// In en, this message translates to:
  /// **'No note for this day.'**
  String get noNote;

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get noPhotos;

  /// No description provided for @futureDateError.
  ///
  /// In en, this message translates to:
  /// **'You can\'t add memories for the future! 😊'**
  String get futureDateError;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @pickGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery'**
  String get pickGallery;

  /// No description provided for @moodTitle.
  ///
  /// In en, this message translates to:
  /// **'How was today?'**
  String get moodTitle;

  /// No description provided for @myMood.
  ///
  /// In en, this message translates to:
  /// **'Your mood'**
  String get myMood;

  /// No description provided for @yourMood.
  ///
  /// In en, this message translates to:
  /// **'Your mood'**
  String get yourMood;

  /// No description provided for @moodLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily Mood'**
  String get moodLabel;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get addLocation;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @addWeather.
  ///
  /// In en, this message translates to:
  /// **'Add weather'**
  String get addWeather;

  /// Title for the multiple memories modal
  ///
  /// In en, this message translates to:
  /// **'Memories from {date}'**
  String memoriesFrom(String date);

  /// Label for the long-press preview popup
  ///
  /// In en, this message translates to:
  /// **'{emoji} Memory'**
  String memoryPopup(String emoji);

  /// No description provided for @memoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 memory} other{{count} memories}}'**
  String memoriesCount(num count);

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this memory?'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryDesc.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and will also delete the photo.'**
  String get deleteEntryDesc;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @personalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalization;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @aboutKrono.
  ///
  /// In en, this message translates to:
  /// **'About Krono'**
  String get aboutKrono;

  /// No description provided for @aboutKronoDetail.
  ///
  /// In en, this message translates to:
  /// **'Krono is your personal space for thoughts and memories. Designed with privacy and simplicity in mind, it helps you capture life\'s moments one day at a time. Thank you for choosing us to be part of your journey!'**
  String get aboutKronoDetail;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Krono is your daily visual journal. Designed to be simple, private, and fast.'**
  String get aboutDescription;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @chooseAccent.
  ///
  /// In en, this message translates to:
  /// **'Choose accent color'**
  String get chooseAccent;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @themeKrono.
  ///
  /// In en, this message translates to:
  /// **'Krono'**
  String get themeKrono;

  /// No description provided for @themeEmerald.
  ///
  /// In en, this message translates to:
  /// **'Emerald'**
  String get themeEmerald;

  /// No description provided for @themeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themeOcean;

  /// No description provided for @themeSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get themeSunset;

  /// No description provided for @themeBerry.
  ///
  /// In en, this message translates to:
  /// **'Berry'**
  String get themeBerry;

  /// No description provided for @themeMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get themeMidnight;

  /// No description provided for @themeGarnet.
  ///
  /// In en, this message translates to:
  /// **'Garnet'**
  String get themeGarnet;

  /// No description provided for @themeAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get themeAurora;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @reminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a notification so you don\'t forget to save your memory.'**
  String get reminderSubtitle;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for Krono 📸'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'How was your day? Don\'t forget to add a photo and some thoughts!'**
  String get reminderNotificationBody;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pause. Capture. Krono. ✨'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'One photo today, a thousand memories tomorrow.'**
  String get notificationBody;

  /// No description provided for @notificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied'**
  String get notificationsDenied;

  /// No description provided for @notificationsDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsDeniedTitle;

  /// No description provided for @notificationsDeniedContent.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Please enable them from the phone settings to receive daily reminders.'**
  String get notificationsDeniedContent;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLock;

  /// No description provided for @biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometrics (FaceID / Fingerprint)'**
  String get biometrics;

  /// No description provided for @authReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm identity to open the journal'**
  String get authReason;

  /// No description provided for @authReasonToggleOn.
  ///
  /// In en, this message translates to:
  /// **'Confirm identity to enable app lock'**
  String get authReasonToggleOn;

  /// No description provided for @authReasonToggleOff.
  ///
  /// In en, this message translates to:
  /// **'Confirm identity to disable app lock'**
  String get authReasonToggleOff;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authFailed;

  /// No description provided for @accessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Access Restricted'**
  String get accessRestricted;

  /// No description provided for @confirmIdentity.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your identity to continue.'**
  String get confirmIdentity;

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data & Backup'**
  String get dataBackup;

  /// No description provided for @myKronoBackup.
  ///
  /// In en, this message translates to:
  /// **'My Krono Backup'**
  String get myKronoBackup;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Full Backup'**
  String get exportBackup;

  /// No description provided for @exportZipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a ZIP file with photos and data'**
  String get exportZipSubtitle;

  /// No description provided for @exportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing Backup...'**
  String get exportingTitle;

  /// No description provided for @exportingMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we compress your memories. This may take a minute.'**
  String get exportingMessage;

  /// No description provided for @backupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Krono Backup'**
  String get backupShareSubject;

  /// No description provided for @backupShareText.
  ///
  /// In en, this message translates to:
  /// **'Here is my Krono journal backup file.'**
  String get backupShareText;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @importZipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore everything from a ZIP file'**
  String get importZipSubtitle;

  /// No description provided for @importingTitle.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get importingTitle;

  /// No description provided for @importingMessage.
  ///
  /// In en, this message translates to:
  /// **'We are bringing your memories back.'**
  String get importingMessage;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportPdf;

  /// No description provided for @exportPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a book of your memories'**
  String get exportPdfSubtitle;

  /// No description provided for @generatingPdf.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF...'**
  String get generatingPdf;

  /// No description provided for @noEntriesToExport.
  ///
  /// In en, this message translates to:
  /// **'No entries found to export.'**
  String get noEntriesToExport;

  /// No description provided for @securityNotSetup.
  ///
  /// In en, this message translates to:
  /// **'Security not set up. Please enable a PIN or biometrics in your device settings.'**
  String get securityNotSetup;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAll;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @irreversible.
  ///
  /// In en, this message translates to:
  /// **'Irreversible action'**
  String get irreversible;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all data? This action is permanent.'**
  String get confirmDeleteContent;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete all memories from the journal. You cannot undo this operation.'**
  String get deleteConfirmDesc;

  /// No description provided for @saveGallerySuccess.
  ///
  /// In en, this message translates to:
  /// **'Image saved to gallery! ✨'**
  String get saveGallerySuccess;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Memory deleted'**
  String get entryDeleted;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup generated successfully!'**
  String get backupSuccess;

  /// No description provided for @backupExportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully!'**
  String get backupExportedSuccess;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully!'**
  String get backupRestored;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data imported successfully!'**
  String get importSuccess;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data has been deleted.'**
  String get deleteSuccess;

  /// No description provided for @deleteAllSuccess.
  ///
  /// In en, this message translates to:
  /// **'All data has been successfully deleted'**
  String get deleteAllSuccess;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading data.'**
  String get loadingError;

  /// No description provided for @imageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading image'**
  String get imageLoadError;

  /// No description provided for @backupExportError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup. Please try again.'**
  String get backupExportError;

  /// No description provided for @backupErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: Generated file is empty.'**
  String get backupErrorEmpty;

  /// No description provided for @errorExport.
  ///
  /// In en, this message translates to:
  /// **'Export error: {e}'**
  String errorExport(String e);

  /// No description provided for @errorImport.
  ///
  /// In en, this message translates to:
  /// **'Import error: {e}'**
  String errorImport(String e);

  /// Error message shown when the user attempts to fetch metadata without an active internet connection.
  ///
  /// In en, this message translates to:
  /// **'Internet connection required for weather and location.'**
  String get noInternetError;

  /// Error message shown when the system GPS/Location toggle is turned off.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled on this device.'**
  String get locationDisabled;

  /// Error message shown when the user refuses to grant location access to the app.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionDenied;

  /// Generic error message for metadata retrieval failures.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch weather and location data.'**
  String get errorFetchingMetadata;

  /// No description provided for @enableLocationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable location access in settings to fetch weather and city name.'**
  String get enableLocationMessage;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @feedbackSubject.
  ///
  /// In en, this message translates to:
  /// **'Krono Feedback'**
  String get feedbackSubject;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device Info'**
  String get deviceInfo;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingStart;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Your Life in Photos'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Capture one photo every day. Build a timeline of memories that you can cherish forever.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'100% Private & Offline'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Your memories stay on your device. No tracking, no cloud uploads, no data collection.'**
  String get onboardingDesc2;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'ro': return AppLocalizationsRo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
