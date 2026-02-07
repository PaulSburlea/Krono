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
  String get version => 'Version';

  @override
  String get madeWith => 'Fait avec ❤️ avec Flutter.';

  @override
  String get copyright => '© 2026 Équipe Krono. Tous droits réservés.';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get retry => 'Réessayer';

  @override
  String get retake => 'Reprendre';

  @override
  String get processing => 'Traitement en cours…';

  @override
  String get unlock => 'Déverrouiller';

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
  String get streakDaySingular => 'Jour de Série';

  @override
  String get streakDaysPlural => 'Jours de Série';

  @override
  String get thisWeek => 'Cette Semaine';

  @override
  String get nextMilestone => 'Prochain jalon';

  @override
  String daysRemaining(Object count) {
    return '$count jours restants';
  }

  @override
  String get streakFirstDay => 'Excellent début ! Revenez demain ! 🌟';

  @override
  String get streakWeekProgress => 'Vous créez une habitude ! Continuez ! 💪';

  @override
  String get streakFirstWeek => 'Une semaine ! Vous êtes en feu ! 🔥';

  @override
  String get streakMonthProgress => 'Cohérence incroyable ! Ne cassez pas la chaîne ! ⛓️';

  @override
  String get streakFirstMonth => '30 jours ! Vous êtes un champion de la mémoire ! 🏆';

  @override
  String get streakHundredProgress => 'Vous êtes imbattable ! Continuez ! 🚀';

  @override
  String get streakHundred => '100 jours ! Statut légendaire atteint ! ⭐';

  @override
  String get streakYearProgress => 'Vous êtes un maître du journal ! Presque là ! 👑';

  @override
  String get streakFirstYear => '365 jours ! Une année complète de souvenirs ! 🎉';

  @override
  String get streakLegendary => 'Vous êtes une légende ! Votre dévouement inspire ! 💎';

  @override
  String get yourMemories => 'Vos Souvenirs';

  @override
  String get quoteTitle => 'Citation du jour';

  @override
  String get streakSuffix => 'Jours de série !';

  @override
  String streakLongMessage(Object count) {
    return 'Vous êtes phénoménal ! Vous avez enregistré des souvenirs pendant $count jours.';
  }

  @override
  String get startFirstDay => 'Commencez votre première journée !';

  @override
  String get emptyJournalTitle => 'Votre journal est vide';

  @override
  String get emptyJournalMessage => 'Commencez par ajouter votre premier souvenir ! ✨';

  @override
  String get createMemory => 'Créer un souvenir';

  @override
  String get startFirstMemory => 'Commencez par ajouter votre premier souvenir ! ✨';

  @override
  String get journal => 'Journal';

  @override
  String get visualJournal => 'Votre journal visuel';

  @override
  String get addMemory => 'Ajouter un souvenir';

  @override
  String get editEntry => 'Modifier le souvenir';

  @override
  String get saveDay => 'Enregistrer la journée';

  @override
  String get writeMemory => 'Écrire un souvenir...';

  @override
  String get noteHint => 'Qu\'est-ce qui s\'est passé d\'intéressant ?';

  @override
  String get noNote => 'Pas de note pour ce jour.';

  @override
  String get noPhotos => 'Pas encore de photos.';

  @override
  String get futureDateError => 'Vous ne pouvez pas ajouter de souvenirs pour le futur ! 😊';

  @override
  String get camera => 'Appareil photo';

  @override
  String get gallery => 'Galerie';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get pickGallery => 'Choisir dans la galerie';

  @override
  String get moodTitle => 'Comment s\'est passée la journée ?';

  @override
  String get myMood => 'Votre humeur';

  @override
  String get yourMood => 'Votre humeur';

  @override
  String get moodLabel => 'Humeur quotidienne';

  @override
  String get location => 'Lieu';

  @override
  String get addLocation => 'Ajouter le lieu';

  @override
  String get weather => 'Météo';

  @override
  String get addWeather => 'Ajouter la météo';

  @override
  String memoriesFrom(String date) {
    return 'Souvenirs du $date';
  }

  @override
  String memoryPopup(String emoji) {
    return '$emoji Souvenir';
  }

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
  String get deleteEntryTitle => 'Supprimer ce souvenir ?';

  @override
  String get deleteEntryDesc => 'Cette action est définitive et supprimera également la photo.';

  @override
  String get settings => 'Paramètres';

  @override
  String get personalization => 'Personnalisation';

  @override
  String get info => 'Informations';

  @override
  String get aboutKrono => 'À propos de Krono';

  @override
  String get aboutKronoDetail => 'Krono est votre espace personnel pour vos pensées et souvenirs. Conçu dans un esprit de confidentialité et de simplicité, il vous aide à capturer les moments de la vie jour après jour. Merci de nous avoir choisis pour faire partie de votre voyage !';

  @override
  String get aboutDescription => 'Krono est votre journal visuel quotidien. Conçu pour être simple, privé et rapide.';

  @override
  String get appTheme => 'Thème de l\'app';

  @override
  String get chooseTheme => 'Choisir le thème';

  @override
  String get chooseAccent => 'Choisir la couleur d\'accentuation';

  @override
  String get darkMode => 'Mode sombre';

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
  String get language => 'Langue';

  @override
  String get chooseLanguage => 'Choisir la langue';

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
  String get notificationTitle => 'Clic ! C\'est l\'heure 📸';

  @override
  String get notificationBody => 'Ne laissez pas ce moment s\'envoler. Ajoutez votre photo du jour !';

  @override
  String get notificationsDenied => 'Permission de notification refusée';

  @override
  String get notificationsDeniedTitle => 'Notifications désactivées';

  @override
  String get notificationsDeniedContent => 'Les notifications sont désactivées. Veuillez les activer dans les paramètres du téléphone pour recevoir des rappels quotidiens.';

  @override
  String get openSettings => 'Paramètres';

  @override
  String get appLock => 'Verrouillage';

  @override
  String get biometrics => 'Biométrie (FaceID / Empreinte)';

  @override
  String get authReason => 'Confirmez votre identité pour ouvrir le journal';

  @override
  String get authReasonToggleOn => 'Confirmez l\'identité pour activer le verrouillage';

  @override
  String get authReasonToggleOff => 'Confirmez l\'identité pour désactiver le verrouillage';

  @override
  String get authFailed => 'Authentification échouée';

  @override
  String get accessRestricted => 'Accès restreint';

  @override
  String get confirmIdentity => 'Veuillez confirmer votre identité pour continuer.';

  @override
  String get dataBackup => 'Données et Sauvegarde';

  @override
  String get myKronoBackup => 'Ma sauvegarde Krono';

  @override
  String get exportBackup => 'Exporter une sauvegarde complète';

  @override
  String get exportZipSubtitle => 'Créer un fichier ZIP avec photos et données';

  @override
  String get exportingTitle => 'Préparation de la sauvegarde...';

  @override
  String get exportingMessage => 'Veuillez patienter pendant que nous compressons vos souvenirs. Cela peut prendre une minute.';

  @override
  String get backupShareSubject => 'Sauvegarde Krono';

  @override
  String get backupShareText => 'Voici le fichier de sauvegarde de mon journal Krono.';

  @override
  String get importBackup => 'Importer une sauvegarde';

  @override
  String get importZipSubtitle => 'Tout restaurer à partir d\'un fichier ZIP';

  @override
  String get importingTitle => 'Restauration...';

  @override
  String get importingMessage => 'Nous récupérons vos souvenirs.';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get exportPdfSubtitle => 'Créer un livre de vos souvenirs';

  @override
  String get generatingPdf => 'Génération du PDF...';

  @override
  String get noEntriesToExport => 'Aucune entrée à exporter.';

  @override
  String get securityNotSetup => 'Sécurité non configurée. Veuillez activer un code PIN ou la biométrie dans les paramètres de votre appareil.';

  @override
  String get dangerZone => 'Zone de danger';

  @override
  String get deleteAll => 'Supprimer toutes les données';

  @override
  String get deleteAllData => 'Supprimer toutes les données';

  @override
  String get irreversible => 'Action irréversible';

  @override
  String get confirmDeleteTitle => 'Supprimer toutes les données ?';

  @override
  String get confirmDeleteContent => 'Êtes-vous sûr de vouloir supprimer toutes les données ? Cette action est permanente.';

  @override
  String get deleteConfirmTitle => 'Supprimer toutes les données ?';

  @override
  String get deleteConfirmDesc => 'Cette action supprimera définitivement tous les souvenirs du journal. Vous ne pouvez pas annuler cette opération.';

  @override
  String get saveGallerySuccess => 'Image enregistrée dans la galerie ! ✨';

  @override
  String get entryDeleted => 'Souvenir supprimé';

  @override
  String get backupSuccess => 'Sauvegarde générée avec succès !';

  @override
  String get backupExportedSuccess => 'Sauvegarde exportée avec succès !';

  @override
  String get backupRestored => 'Sauvegarde restaurée avec succès !';

  @override
  String get importSuccess => 'Données importées avec succès !';

  @override
  String get deleteSuccess => 'Toutes les données ont été supprimées.';

  @override
  String get deleteAllSuccess => 'Toutes les données ont été supprimées avec succès';

  @override
  String get loadingError => 'Erreur lors du chargement.';

  @override
  String get imageLoadError => 'Erreur de chargement de l\'image';

  @override
  String get backupExportError => 'Échec de la création de la sauvegarde. Veuillez réessayer.';

  @override
  String get backupErrorEmpty => 'Échec de la sauvegarde : le fichier généré est vide.';

  @override
  String errorExport(String e) {
    return 'Erreur d\'exportation : $e';
  }

  @override
  String errorImport(String e) {
    return 'Erreur d\'importation : $e';
  }

  @override
  String get noInternetError => 'Connexion Internet requise pour la météo et la localisation.';

  @override
  String get locationDisabled => 'Les services de localisation sont désactivés sur cet appareil.';

  @override
  String get locationPermissionDenied => 'L\'autorisation de localisation a été refusée.';

  @override
  String get errorFetchingMetadata => 'Impossible de récupérer les données météo et de localisation.';

  @override
  String get enableLocationMessage => 'Veuillez activer l\'accès à la localisation dans les paramètres pour récupérer la météo et la ville.';

  @override
  String get privacyPolicy => 'Politique de Confidentialité';

  @override
  String get sendFeedback => 'Envoyer un avis';

  @override
  String get feedbackSubject => 'Avis Krono';

  @override
  String get deviceInfo => 'Infos Appareil';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingTitle1 => 'Votre vie en photos';

  @override
  String get onboardingDesc1 => 'Capturez une photo chaque jour. Construisez une chronologie de souvenirs à chérir pour toujours.';

  @override
  String get onboardingTitle2 => '100% Privé et Hors ligne';

  @override
  String get onboardingDesc2 => 'Vos souvenirs restent sur votre appareil. Pas de suivi, pas de cloud, pas de collecte de données.';

  @override
  String get themeCrimson => 'Cramoisi';

  @override
  String get themeAmethyst => 'Améthyste';

  @override
  String get themeGold => 'Or';

  @override
  String get themeTurquoise => 'Turquoise';

  @override
  String get themeRose => 'Rose';

  @override
  String get themeSapphire => 'Saphir';

  @override
  String get update => 'Mettre à jour';

  @override
  String get remove => 'Supprimer';

  @override
  String get discardChangesTitle => 'Abandonner ce souvenir ?';

  @override
  String get discardChangesMessage => 'Vous n\'avez pas sauvegardé. Si vous quittez, cette entrée sera définitivement effacée.';

  @override
  String get discard => 'Abandonner';

  @override
  String get notificationPromptTitle => 'Gardez la série en vie !';

  @override
  String get notificationPromptBody => 'Bravo pour votre premier souvenir ! Définissez un rappel quotidien pour ne jamais oublier de capturer l\'instant.';

  @override
  String get maybeLater => 'Plus tard';

  @override
  String get setReminder => 'Définir un rappel';
}
