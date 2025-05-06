# Dwaya - Application de Recherche de Pharmacies

<p align="center">
  <img src="assets/images/logo.png" alt="Logo Dwaya" width="200"/>
</p>

Dwaya est une application mobile basée sur Flutter qui aide les utilisateurs à trouver des pharmacies à proximité, consulter les détails des pharmacies, enregistrer leurs favoris et obtenir des itinéraires vers la pharmacie de leur choix.

## Fonctionnalités

- **Recherche de Pharmacies**: Trouvez des pharmacies près de votre emplacement ou dans des zones spécifiques
- **Informations Détaillées**: Consultez les coordonnées, les heures d'ouverture et les services disponibles des pharmacies
- **Favoris**: Enregistrez vos pharmacies préférées pour un accès rapide
- **Itinéraires**: Obtenez des directions vers les pharmacies grâce à l'intégration de cartes
- **Profils Utilisateurs**: Créez et gérez votre profil utilisateur

## Technologies Utilisées

- **Flutter**: Kit d'outils UI multiplateforme
- **Firebase**: Authentification, Cloud Firestore et Analytics
- **API Google Maps**: Services de localisation et intégration de cartes

## Démarrage

### Prérequis

- Flutter (dernière version stable)
- SDK Dart
- Android Studio / VS Code
- Compte Firebase pour les services backend
- Clé API Google Maps

### Installation

1. Clonez le dépôt:
   ```
   git clone https://github.com/yourusername/dwaya_app.git
   ```

2. Naviguez vers le répertoire du projet:
   ```
   cd dwaya_app
   ```

3. Installez les dépendances:
   ```
   flutter pub get
   ```

4. Configurez Firebase:
   - Créez un projet Firebase
   - Ajoutez vos applications Android et iOS au projet Firebase
   - Téléchargez et ajoutez les fichiers google-services.json et GoogleService-Info.plist dans les répertoires respectifs
   - Activez l'authentification et Firestore dans la console Firebase

5. Configurez l'API Google Maps:
   - Obtenez une clé API Google Maps
   - Ajoutez la clé API aux fichiers appropriés:
     - Android: android/app/src/main/AndroidManifest.xml
     - iOS: ios/Runner/AppDelegate.swift

6. Exécutez l'application:
   ```
   flutter run
   ```

## Structure du Projet

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── firebase_options.dart     # Configuration Firebase
├── initializers/             # Initialisation spécifique à la plateforme
├── models/                   # Modèles de données
├── providers/                # Gestion d'état
├── screens/                  # Écrans UI
├── services/                 # Services API et backend
├── utils/                    # Classes utilitaires
└── widgets/                  # Composants UI réutilisables
```

## Optimisations de Performance

- **Système de Cache**: Utilise SharedPreferences pour le stockage persistant des réponses API
- **Gestion des Erreurs**: Système complet de rapport d'erreurs
- **Optimisation d'Images**: CachedNetworkImage pour le chargement efficace des images

## Notre Equipe

- MESKIOUI Anwar
- MAMOUNI Outhmane
- BOUDI Othmane
- BENALI Nada
