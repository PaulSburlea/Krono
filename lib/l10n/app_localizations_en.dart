// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Krono';

  @override
  String get version => 'Version';

  @override
  String get madeWith => 'Made with ❤️ using Flutter.';

  @override
  String get copyright => '© 2026 Krono Team. All rights reserved.';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get retake => 'Retake';

  @override
  String get processing => 'Processing…';

  @override
  String get unlock => 'Unlock';

  @override
  String get year => 'year';

  @override
  String get years => 'years';

  @override
  String get weekShort => 'wk.';

  @override
  String get day => 'day';

  @override
  String get days => 'days';

  @override
  String get yourMemories => 'Your Memories';

  @override
  String get quoteTitle => 'Quote of the Day';

  @override
  String get streakSuffix => 'Day Streak!';

  @override
  String streakLongMessage(Object count) {
    return 'You\'re phenomenal! You\'ve saved memories for $count days.';
  }

  @override
  String get startFirstDay => 'Start your first day!';

  @override
  String get emptyJournalTitle => 'Your journal is empty';

  @override
  String get emptyJournalMessage => 'Start by adding your first memory! ✨';

  @override
  String get createMemory => 'Create a memory';

  @override
  String get startFirstMemory => 'Start by adding your first memory! ✨';

  @override
  String get journal => 'Journal';

  @override
  String get visualJournal => 'Your Visual Journal';

  @override
  String get addMemory => 'Add Today\'s Memory';

  @override
  String get editEntry => 'Edit memory';

  @override
  String get saveDay => 'Save Day';

  @override
  String get writeMemory => 'Write a memory...';

  @override
  String get noteHint => 'What interesting happened?';

  @override
  String get noNote => 'No note for this day.';

  @override
  String get noPhotos => 'No photos yet.';

  @override
  String get futureDateError => 'You can\'t add memories for the future! 😊';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get pickGallery => 'Pick from gallery';

  @override
  String get moodTitle => 'How was today?';

  @override
  String get myMood => 'Your mood';

  @override
  String get yourMood => 'Your mood';

  @override
  String get moodLabel => 'Daily Mood';

  @override
  String get location => 'Location';

  @override
  String get addLocation => 'Add location';

  @override
  String get weather => 'Weather';

  @override
  String get addWeather => 'Add weather';

  @override
  String memoriesFrom(String date) {
    return 'Memories from $date';
  }

  @override
  String memoryPopup(String emoji) {
    return '$emoji Memory';
  }

  @override
  String memoriesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count memories',
      one: '1 memory',
    );
    return '$_temp0';
  }

  @override
  String get deleteEntryTitle => 'Delete this memory?';

  @override
  String get deleteEntryDesc => 'This action is permanent and will also delete the photo.';

  @override
  String get settings => 'Settings';

  @override
  String get personalization => 'Personalization';

  @override
  String get info => 'Information';

  @override
  String get aboutKrono => 'About Krono';

  @override
  String get aboutKronoDetail => 'Krono is your personal space for thoughts and memories. Designed with privacy and simplicity in mind, it helps you capture life\'s moments one day at a time. Thank you for choosing us to be part of your journey!';

  @override
  String get aboutDescription => 'Krono is your daily visual journal. Designed to be simple, private, and fast.';

  @override
  String get appTheme => 'App Theme';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get chooseAccent => 'Choose accent color';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get themeKrono => 'Krono';

  @override
  String get themeEmerald => 'Emerald';

  @override
  String get themeOcean => 'Ocean';

  @override
  String get themeSunset => 'Sunset';

  @override
  String get themeBerry => 'Berry';

  @override
  String get themeMidnight => 'Midnight';

  @override
  String get themeGarnet => 'Garnet';

  @override
  String get themeAurora => 'Aurora';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get reminderSubtitle => 'Get a notification so you don\'t forget to save your memory.';

  @override
  String get reminderNotificationTitle => 'Time for Krono 📸';

  @override
  String get reminderNotificationBody => 'How was your day? Don\'t forget to add a photo and some thoughts!';

  @override
  String get notificationTitle => 'Pause. Capture. Krono. ✨';

  @override
  String get notificationBody => 'One photo today, a thousand memories tomorrow.';

  @override
  String get notificationsDenied => 'Notification permission denied';

  @override
  String get notificationsDeniedTitle => 'Notifications Disabled';

  @override
  String get notificationsDeniedContent => 'Notifications are disabled. Please enable them from the phone settings to receive daily reminders.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get appLock => 'App Lock';

  @override
  String get biometrics => 'Biometrics (FaceID / Fingerprint)';

  @override
  String get authReason => 'Confirm identity to open the journal';

  @override
  String get authReasonToggleOn => 'Confirm identity to enable app lock';

  @override
  String get authReasonToggleOff => 'Confirm identity to disable app lock';

  @override
  String get authFailed => 'Authentication failed';

  @override
  String get accessRestricted => 'Access Restricted';

  @override
  String get confirmIdentity => 'Please confirm your identity to continue.';

  @override
  String get dataBackup => 'Data & Backup';

  @override
  String get myKronoBackup => 'My Krono Backup';

  @override
  String get exportBackup => 'Export Full Backup';

  @override
  String get exportZipSubtitle => 'Create a ZIP file with photos and data';

  @override
  String get exportingTitle => 'Preparing Backup...';

  @override
  String get exportingMessage => 'Please wait while we compress your memories. This may take a minute.';

  @override
  String get backupShareSubject => 'Krono Backup';

  @override
  String get backupShareText => 'Here is my Krono journal backup file.';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get importZipSubtitle => 'Restore everything from a ZIP file';

  @override
  String get importingTitle => 'Restoring...';

  @override
  String get importingMessage => 'We are bringing your memories back.';

  @override
  String get exportPdf => 'Export as PDF';

  @override
  String get exportPdfSubtitle => 'Create a book of your memories';

  @override
  String get generatingPdf => 'Generating PDF...';

  @override
  String get noEntriesToExport => 'No entries found to export.';

  @override
  String get securityNotSetup => 'Security not set up. Please enable a PIN or biometrics in your device settings.';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteAll => 'Delete All Data';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get irreversible => 'Irreversible action';

  @override
  String get confirmDeleteTitle => 'Delete all data?';

  @override
  String get confirmDeleteContent => 'Are you sure you want to delete all data? This action is permanent.';

  @override
  String get deleteConfirmTitle => 'Delete all data?';

  @override
  String get deleteConfirmDesc => 'This action will permanently delete all memories from the journal. You cannot undo this operation.';

  @override
  String get saveGallerySuccess => 'Image saved to gallery! ✨';

  @override
  String get entryDeleted => 'Memory deleted';

  @override
  String get backupSuccess => 'Backup generated successfully!';

  @override
  String get backupExportedSuccess => 'Backup exported successfully!';

  @override
  String get backupRestored => 'Backup restored successfully!';

  @override
  String get importSuccess => 'Data imported successfully!';

  @override
  String get deleteSuccess => 'All data has been deleted.';

  @override
  String get deleteAllSuccess => 'All data has been successfully deleted';

  @override
  String get loadingError => 'Error loading data.';

  @override
  String get imageLoadError => 'Error loading image';

  @override
  String get backupExportError => 'Failed to create backup. Please try again.';

  @override
  String get backupErrorEmpty => 'Backup failed: Generated file is empty.';

  @override
  String errorExport(String e) {
    return 'Export error: $e';
  }

  @override
  String errorImport(String e) {
    return 'Import error: $e';
  }

  @override
  String get noInternetError => 'Internet connection required for weather and location.';

  @override
  String get locationDisabled => 'Location services are disabled on this device.';

  @override
  String get locationPermissionDenied => 'Location permission was denied.';

  @override
  String get errorFetchingMetadata => 'Could not fetch weather and location data.';

  @override
  String get enableLocationMessage => 'Please enable location access in settings to fetch weather and city name.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get feedbackSubject => 'Krono Feedback';

  @override
  String get deviceInfo => 'Device Info';
}
