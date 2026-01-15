// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Krono';

  @override
  String get streakSuffix => 'Jours de série !';

  @override
  String get addMemory => 'Ajouter un souvenir';

  @override
  String get quoteTitle => 'Citation du jour';

  @override
  String get visualJournal => 'Votre journal visuel';

  @override
  String get noPhotos => 'Pas encore de photos.';

  @override
  String get editEntry => 'Modifier le souvenir';

  @override
  String get moodTitle => 'Comment s\'est passée la journée ?';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get pickGallery => 'Choisir dans la galerie';

  @override
  String get myMood => 'Votre humeur';

  @override
  String get noteHint => 'Qu\'est-ce qui s\'est passé d\'intéressant ?';

  @override
  String get saveDay => 'Enregistrer la journée';

  @override
  String get moodLabel => 'Humeur quotidienne';

  @override
  String get journal => 'Journal';

  @override
  String get noNote => 'Pas de note pour ce jour.';

  @override
  String streakLongMessage(Object count) {
    return 'Vous êtes phénoménal ! Vous avez enregistré des souvenirs pendant $count jours.';
  }

  @override
  String get startFirstDay => 'Commencez votre première journée !';

  @override
  String get year => 'an';

  @override
  String get years => 'ans';

  @override
  String get weekShort => 'sem.';

  @override
  String get day => 'jour';

  @override
  String get days => 'jours';

  @override
  String get settings => 'Paramètres';

  @override
  String get personalization => 'Personnalisation';

  @override
  String get appTheme => 'Thème de l\'app';

  @override
  String get chooseAccent => 'Choisir la couleur d\'accentuation';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get dataBackup => 'Données et Sauvegarde';

  @override
  String get exportBackup => 'Exporter une sauvegarde complète';

  @override
  String get exportZipSubtitle => 'Créer un fichier ZIP avec photos et données';

  @override
  String get importBackup => 'Importer une sauvegarde';

  @override
  String get importZipSubtitle => 'Tout restaurer à partir d\'un fichier ZIP';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get exportPdfSubtitle => 'Créer un livre de vos souvenirs';

  @override
  String get info => 'Informations';

  @override
  String get appLock => 'Verrouillage';

  @override
  String get biometrics => 'Biométrie (FaceID / Empreinte)';

  @override
  String get aboutKrono => 'À propos de Krono';

  @override
  String get dangerZone => 'Zone de danger';

  @override
  String get deleteAll => 'Supprimer toutes les données';

  @override
  String get irreversible => 'Action irréversible';

  @override
  String get version => 'Version';

  @override
  String get aboutDescription => 'Krono est votre journal visuel quotidien. Conçu pour être simple, privé et rapide.';

  @override
  String get madeWith => 'Fait avec ❤️ avec Flutter.';

  @override
  String get chooseTheme => 'Choisir le thème';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteConfirmTitle => 'Supprimer toutes les données ?';

  @override
  String get deleteConfirmDesc => 'Cette action supprimera définitivement tous les souvenirs du journal. Vous ne pouvez pas annuler cette opération.';

  @override
  String get backupSuccess => 'Sauvegarde générée avec succès !';

  @override
  String get importSuccess => 'Données importées avec succès !';

  @override
  String get deleteSuccess => 'Toutes les données ont été supprimées.';

  @override
  String errorExport(String e) {
    return 'Erreur d\'exportation : $e';
  }

  @override
  String errorImport(Object e) {
    return 'Erreur d\'importation : $e';
  }

  @override
  String memoriesFrom(String date) {
    return 'Souvenirs du $date';
  }

  @override
  String memoryPopup(String emoji) {
    return '$emoji Souvenir';
  }

  @override
  String get camera => 'Appareil photo';

  @override
  String get gallery => 'Galerie';

  @override
  String get writeMemory => 'Écrire un souvenir...';

  @override
  String get saveGallerySuccess => 'Image enregistrée dans la galerie ! ✨';

  @override
  String get deleteEntryTitle => 'Supprimer ce souvenir ?';

  @override
  String get deleteEntryDesc => 'Cette action est définitive et supprimera également la photo.';

  @override
  String get entryDeleted => 'Souvenir supprimé';

  @override
  String get yourMood => 'Votre humeur';

  @override
  String get language => 'Langue';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get authReason => 'Confirmez votre identité pour ouvrir le journal';

  @override
  String get accessRestricted => 'Accès restreint';

  @override
  String get confirmIdentity => 'Veuillez confirmer votre identité pour continuer.';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get noEntriesToExport => 'Aucune entrée à exporter.';

  @override
  String get generatingPdf => 'Génération du PDF...';

  @override
  String memoriesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count souvenirs',
      one: '1 souvenir',
    );
    return '$_temp0';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get dailyReminder => 'Rappel Quotidien';

  @override
  String get reminderSubtitle => 'Recevez une notification pour ne pas oublier de sauvegarder votre souvenir.';

  @override
  String get reminderNotificationTitle => 'L\'heure de Krono 📸';

  @override
  String get reminderNotificationBody => 'Comment s\'est passée votre journée ? N\'oubliez pas d\'ajouter une photo et quelques pensées !';

  @override
  String get notificationsDenied => 'Permission de notification refusée';

  @override
  String get authReasonToggleOn => 'Confirmez l\'identité pour activer le verrouillage';

  @override
  String get authReasonToggleOff => 'Confirmez l\'identité pour désactiver le verrouillage';

  @override
  String get authFailed => 'Authentification échouée';

  @override
  String get themeKrono => 'Krono';

  @override
  String get themeEmerald => 'Émeraude';

  @override
  String get themeOcean => 'Océan';

  @override
  String get themeSunset => 'Coucher de soleil';

  @override
  String get themeBerry => 'Baie';

  @override
  String get themeMidnight => 'Minuit';

  @override
  String get themeGarnet => 'Garnet';

  @override
  String get themeAurora => 'Aurora';

  @override
  String get notificationTitle => 'Clic ! C\'est l\'heure 📸';

  @override
  String get notificationBody => 'Ne laissez pas ce moment s\'envoler. Ajoutez votre photo du jour !';

  @override
  String get save => 'Enregistrer';

  @override
  String get aboutKronoDetail => 'Krono est votre espace personnel pour vos pensées et souvenirs. Conçu dans un esprit de confidentialité et de simplicité, il vous aide à capturer les moments de la vie jour après jour. Merci de nous avoir choisis pour faire partie de votre voyage !';

  @override
  String get copyright => '© 2026 Équipe Krono. Tous droits réservés.';

  @override
  String get backupRestored => 'Sauvegarde restaurée avec succès !';

  @override
  String get confirmDeleteTitle => 'Supprimer toutes les données ?';

  @override
  String get confirmDeleteContent => 'Êtes-vous sûr de vouloir supprimer toutes les données ? Cette action est permanente.';

  @override
  String get startFirstMemory => 'Commencez par ajouter votre premier souvenir ! ✨';

  @override
  String get loadingError => 'Erreur lors du chargement.';

  @override
  String get myKronoBackup => 'Ma sauvegarde Krono';

  @override
  String get addLocation => 'Ajouter le lieu';

  @override
  String get addWeather => 'Ajouter la météo';

  @override
  String get location => 'Lieu';

  @override
  String get weather => 'Météo';

  @override
  String get notificationsDeniedTitle => 'Notifications désactivées';

  @override
  String get notificationsDeniedContent => 'Les notifications sont désactivées. Veuillez les activer dans les paramètres du téléphone pour recevoir des rappels quotidiens.';

  @override
  String get openSettings => 'Paramètres';

  @override
  String get deleteAllData => 'Supprimer toate les données';

  @override
  String get deleteAllSuccess => 'Toutes les données ont été supprimées avec succès';

  @override
  String get yourMemories => 'Vos Souvenirs';

  @override
  String get emptyJournalMessage => 'Commencez par ajouter votre premier souvenir ! ✨';

  @override
  String get futureDateError => 'Vous ne pouvez pas ajouter de souvenirs pour le futur ! 😊';

  @override
  String get emptyJournalTitle => 'Votre journal est vide';

  @override
  String get createMemory => 'Créer un souvenir';
}
