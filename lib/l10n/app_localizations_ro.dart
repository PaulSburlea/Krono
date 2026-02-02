// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Krono';

  @override
  String get version => 'Versiune';

  @override
  String get madeWith => 'Creat cu ❤️ folosind Flutter.';

  @override
  String get copyright => '© 2026 Echipa Krono. Toate drepturile rezervate.';

  @override
  String get save => 'Salvează';

  @override
  String get cancel => 'Anulează';

  @override
  String get delete => 'Șterge';

  @override
  String get retry => 'Încearcă din nou';

  @override
  String get retake => 'Refă';

  @override
  String get processing => 'Se procesează…';

  @override
  String get unlock => 'Deblochează';

  @override
  String get year => 'an';

  @override
  String get years => 'ani';

  @override
  String get weekShort => 'săpt.';

  @override
  String get day => 'zi';

  @override
  String get days => 'zile';

  @override
  String get yourMemories => 'Amintirile tale';

  @override
  String get quoteTitle => 'Citatul zilei';

  @override
  String get streakSuffix => 'Zile de Amintiri!';

  @override
  String streakLongMessage(Object count) {
    return 'Ești fenomenal! Ai salvat amintiri timp de $count zile.';
  }

  @override
  String get startFirstDay => 'Începe prima ta zi!';

  @override
  String get emptyJournalTitle => 'Jurnalul tău e gol';

  @override
  String get emptyJournalMessage => 'Începe prin a adăuga prima amintire! ✨';

  @override
  String get createMemory => 'Creează o amintire';

  @override
  String get startFirstMemory => 'Începe prin a adăuga prima amintire! ✨';

  @override
  String get journal => 'Jurnal';

  @override
  String get visualJournal => 'Jurnalul tău vizual';

  @override
  String get addMemory => 'Adaugă amintirea de azi';

  @override
  String get editEntry => 'Editează amintirea';

  @override
  String get saveDay => 'Salvează ziua';

  @override
  String get writeMemory => 'Scrie o amintire...';

  @override
  String get noteHint => 'Ce s-a întâmplat interesant?';

  @override
  String get noNote => 'Nicio notiță pentru această zi.';

  @override
  String get noPhotos => 'Încă nu ai nicio poză.';

  @override
  String get futureDateError => 'Nu poți adăuga amintiri pentru viitor! 😊';

  @override
  String get camera => 'Cameră';

  @override
  String get gallery => 'Galerie';

  @override
  String get takePhoto => 'Fă o poză';

  @override
  String get pickGallery => 'Alege din galerie';

  @override
  String get moodTitle => 'Cum a fost azi?';

  @override
  String get myMood => 'Mood-ul tău';

  @override
  String get yourMood => 'Mood-ul tău';

  @override
  String get moodLabel => 'Mood-ul zilei';

  @override
  String get location => 'Locație';

  @override
  String get addLocation => 'Adaugă locația';

  @override
  String get weather => 'Vreme';

  @override
  String get addWeather => 'Adaugă vremea';

  @override
  String memoriesFrom(String date) {
    return 'Amintirile din $date';
  }

  @override
  String memoryPopup(String emoji) {
    return '$emoji Amintire';
  }

  @override
  String memoriesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amintiri',
      one: 'o amintire',
    );
    return '$_temp0';
  }

  @override
  String get deleteEntryTitle => 'Ștergi această amintire?';

  @override
  String get deleteEntryDesc => 'Această acțiune este permanentă și va șterge și fotografia.';

  @override
  String get settings => 'Setări';

  @override
  String get personalization => 'Personalizare';

  @override
  String get info => 'Informații';

  @override
  String get aboutKrono => 'Despre Krono';

  @override
  String get aboutKronoDetail => 'Krono este spațiul tău personal pentru gânduri și amintiri. Creat cu accent pe intimitate și simplitate, te ajută să surprinzi momentele vieții zi de zi. Îți mulțumim că ne-ai ales să facem parte din călătoria ta!';

  @override
  String get aboutDescription => 'Krono este jurnalul tău vizual zilnic. Conceput să fie simplu, privat și rapid.';

  @override
  String get appTheme => 'Temă Aplicație';

  @override
  String get chooseTheme => 'Alege Tema';

  @override
  String get chooseAccent => 'Alege culoarea de accent';

  @override
  String get darkMode => 'Mod Întunecat';

  @override
  String get themeKrono => 'Krono';

  @override
  String get themeEmerald => 'Smarald';

  @override
  String get themeOcean => 'Ocean';

  @override
  String get themeSunset => 'Apus';

  @override
  String get themeBerry => 'Fructe de pădure';

  @override
  String get themeMidnight => 'Miezul nopții';

  @override
  String get themeGarnet => 'Garnet';

  @override
  String get themeAurora => 'Aurora';

  @override
  String get language => 'Limbă';

  @override
  String get chooseLanguage => 'Alege limba';

  @override
  String get notifications => 'Notificări';

  @override
  String get dailyReminder => 'Reminder Zilnic';

  @override
  String get reminderSubtitle => 'Primește o notificare pentru a nu uita să salvezi amintirea.';

  @override
  String get reminderNotificationTitle => 'Timpul pentru Krono 📸';

  @override
  String get reminderNotificationBody => 'Cum a fost ziua ta? Nu uita să adaugi o poză și câteva gânduri!';

  @override
  String get notificationTitle => 'Zâmbește! 📸';

  @override
  String get notificationBody => 'E timpul pentru momentul tău zilnic. Cum arată ziua ta de astăzi?';

  @override
  String get notificationsDenied => 'Permisiunea pentru notificări a fost respinsă';

  @override
  String get notificationsDeniedTitle => 'Notificări dezactivate';

  @override
  String get notificationsDeniedContent => 'Notificările sunt dezactivate. Te rugăm să le activezi din setările telefonului pentru a primi remindere zilnice.';

  @override
  String get openSettings => 'Setări';

  @override
  String get appLock => 'Blocare Aplicație';

  @override
  String get biometrics => 'Biometrie (FaceID / Fingerprint)';

  @override
  String get authReason => 'Confirmă identitatea pentru a deschide jurnalul';

  @override
  String get authReasonToggleOn => 'Confirmă identitatea pentru a activa blocarea';

  @override
  String get authReasonToggleOff => 'Confirmă identitatea pentru a dezactiva blocarea';

  @override
  String get authFailed => 'Autentificare eșuată';

  @override
  String get accessRestricted => 'Acces restricționat';

  @override
  String get confirmIdentity => 'Confirmă identitatea pentru a continua.';

  @override
  String get dataBackup => 'Date și Backup';

  @override
  String get myKronoBackup => 'Backup-ul meu Krono';

  @override
  String get exportBackup => 'Exportă Backup Complet';

  @override
  String get exportZipSubtitle => 'Creează un fișier ZIP cu poze și date';

  @override
  String get exportingTitle => 'Se pregătește backup-ul...';

  @override
  String get exportingMessage => 'Te rugăm să aștepți în timp ce îți arhivăm amintirile. Acest proces poate dura un minut.';

  @override
  String get backupShareSubject => 'Backup Krono';

  @override
  String get backupShareText => 'Iată fișierul de backup al jurnalului Krono.';

  @override
  String get importBackup => 'Importă Backup';

  @override
  String get importZipSubtitle => 'Restabilește totul dintr-un fișier ZIP';

  @override
  String get importingTitle => 'Se restaurează...';

  @override
  String get importingMessage => 'Îți readucem amintirile.';

  @override
  String get exportPdf => 'Exportă ca PDF';

  @override
  String get exportPdfSubtitle => 'Creează o carte cu amintirile tale';

  @override
  String get generatingPdf => 'Se generează PDF-ul...';

  @override
  String get noEntriesToExport => 'Nu există însemnări pentru export.';

  @override
  String get securityNotSetup => 'Securitatea nu este configurată. Te rugăm să activezi un cod PIN sau biometria în setările dispozitivului.';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteAll => 'Șterge toate datele';

  @override
  String get deleteAllData => 'Șterge toate datele';

  @override
  String get irreversible => 'Acțiune ireversibilă';

  @override
  String get confirmDeleteTitle => 'Ștergi toate datele?';

  @override
  String get confirmDeleteContent => 'Sigur vrei să ștergi toate datele? Această acțiune este permanentă.';

  @override
  String get deleteConfirmTitle => 'Ștergi toate datele?';

  @override
  String get deleteConfirmDesc => 'Această acțiune va șterge permanent toate amintirile din jurnal. Nu poți anula această operațiune.';

  @override
  String get saveGallerySuccess => 'Imagine salvată în galerie! ✨';

  @override
  String get entryDeleted => 'Amintire ștearsă';

  @override
  String get backupSuccess => 'Backup generat cu succes!';

  @override
  String get backupExportedSuccess => 'Backup exportat cu succes!';

  @override
  String get backupRestored => 'Backup restaurat cu succes!';

  @override
  String get importSuccess => 'Datele au fost importate cu succes!';

  @override
  String get deleteSuccess => 'Toate datele au fost șterse.';

  @override
  String get deleteAllSuccess => 'Toate datele au fost șterse cu succes';

  @override
  String get loadingError => 'Eroare la încărcare.';

  @override
  String get imageLoadError => 'Eroare la încărcarea imaginii';

  @override
  String get backupExportError => 'Eroare la crearea backup-ului. Te rugăm să încerci din nou.';

  @override
  String get backupErrorEmpty => 'Backup eșuat: Fișierul generat este gol.';

  @override
  String errorExport(String e) {
    return 'Eroare la export: $e';
  }

  @override
  String errorImport(String e) {
    return 'Eroare la import: $e';
  }

  @override
  String get noInternetError => 'Conexiunea la internet este necesară pentru vreme și locație.';

  @override
  String get locationDisabled => 'Serviciile de locație sunt dezactivate pe acest dispozitiv.';

  @override
  String get locationPermissionDenied => 'Permisiunea de locație a fost refuzată.';

  @override
  String get errorFetchingMetadata => 'Nu am putut prelua datele meteo și de locație.';

  @override
  String get enableLocationMessage => 'Te rugăm să activezi accesul la locație în setări pentru a prelua vremea și orașul.';

  @override
  String get privacyPolicy => 'Politică de Confidențialitate';

  @override
  String get sendFeedback => 'Trimite Feedback';

  @override
  String get feedbackSubject => 'Feedback Krono';

  @override
  String get deviceInfo => 'Informații Dispozitiv';
}
