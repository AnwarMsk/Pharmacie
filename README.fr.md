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
- **Support Hors Ligne**: Accédez aux fonctionnalités de base même sans connexion internet
- **Support Multilingue**: Disponible en plusieurs langues (Anglais, Arabe)

## Technologies Utilisées

- **Flutter**: Kit d'outils UI multiplateforme
- **Firebase**: Authentification, Cloud Firestore et Analytics
- **Provider**: Gestion d'état
- **API Google Maps**: Services de localisation et intégration de cartes
- **Connectivity Plus**: Surveillance de la connectivité réseau
- **Cached Network Image**: Chargement et mise en cache efficaces des images
- **Flutter Secure Storage**: Stockage sécurisé des données

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
- **Support Hors Ligne**: ConnectivityHelper pour la surveillance de l'état du réseau
- **Optimisation d'Images**: CachedNetworkImage pour le chargement efficace des images
- **Sécurité**: Flutter Secure Storage pour les données sensibles
- **Validation des Entrées**: Utilitaires de validation robustes

## Sécurité

L'application implémente plusieurs mesures de sécurité:
- Stockage sécurisé pour les données sensibles des utilisateurs
- Validation des entrées pour prévenir les attaques par injection
- Règles Proguard pour Android pour obfusquer le code
- Firebase Authentication pour une gestion sécurisée des utilisateurs

## Contribution

1. Forkez le dépôt
2. Créez votre branche de fonctionnalité (`git checkout -b fonctionnalite/super-feature`)
3. Validez vos modifications (`git commit -m 'Ajout d'une super fonctionnalité'`)
4. Poussez vers la branche (`git push origin fonctionnalite/super-feature`)
5. Ouvrez une Pull Request

## Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.

## Remerciements

- L'équipe Flutter pour le framework incroyable
- Firebase pour les services backend
- Tous les packages open-source utilisés dans ce projet 