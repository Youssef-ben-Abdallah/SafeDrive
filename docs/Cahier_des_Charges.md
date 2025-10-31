# Cahier des Charges – Application Mobile « SafeDrive »

## 1. Informations générales
- **Titre du projet** : SafeDrive – Détection de somnolence et de distraction du conducteur
- **Enseignant encadrant** : S. Hadhri
- **Module** : Programmation Mobile
- **Technologie utilisée** : Flutter + Firebase ML Kit
- **Équipe de développement** : — (à compléter)
- **Durée estimée du projet** : 4 à 6 semaines

## 2. Contexte et motivation
La somnolence et la distraction au volant sont deux causes majeures d’accidents de la route. L’application SafeDrive vise à contribuer à la sécurité routière en utilisant des techniques d’intelligence artificielle embarquée (on-device) pour analyser le visage et l’environnement du conducteur en temps réel, et détecter les signes de fatigue ou d’inattention.

Le projet exploite deux services ML Kit de Firebase — la détection de visage et la détection d’objets — afin d’analyser les flux vidéo de la caméra et déclencher des alertes préventives.

## 3. Objectifs du projet
### Objectif principal
Concevoir une application mobile Flutter capable de :

- Surveiller le conducteur via la caméra avant du smartphone.
- Détecter la somnolence (yeux fermés, bâillement) grâce à la détection de visages.
- Identifier une distraction (utilisation du téléphone, regard détourné) grâce à la détection d’objets.
- Alerter le conducteur en temps réel par son et vibration.

### Objectifs secondaires
- Offrir une interface intuitive et moderne (mode clair/sombre).
- Générer un rapport de conduite récapitulant les alertes détectées.
- Permettre la personnalisation des paramètres (sons, notifications, langues, etc.).
- Être multilingue (Français, Anglais, Arabe).
- Fonctionner en local (offline) pour plus de rapidité et de confidentialité.

## 4. Technologies et outils
| Catégorie            | Outil / Librairie                     |
|----------------------|----------------------------------------|
| Framework mobile     | Flutter                                |
| Langage              | Dart                                   |
| Base d’IA            | Firebase ML Kit                        |
| Services ML Kit      | Face Detection, Object Detection & Tracking |
| Base de données locale | Hive ou SharedPreferences           |
| Gestion d’état       | Provider ou Riverpod                   |
| Notifications        | flutter_local_notifications            |
| Caméra               | Plugin `camera`                        |
| Design               | Material Design 3 + Mode clair/sombre  |
| Plateforme cible     | Android (option iOS)                   |

## 5. Architecture générale
### 5.1 Structure fonctionnelle
| Module   | Description |
|----------|-------------|
| Accueil  | Présentation de l’application, accès aux principales fonctionnalités. |
| Détection | Activation de la caméra frontale et analyse en temps réel. |
| Rapports | Historique des sessions et statistiques des alertes détectées. |
| Paramètres | Gestion des préférences utilisateur (sons, vibrations, langues, thèmes). |
| À propos | Informations sur l’application et les technologies utilisées. |

### 5.2 Schéma fonctionnel simplifié
```
[Caméra frontale]
     ↓
[ML Kit - Détection de visage] → [Analyse yeux/mouvements]
     ↓
[ML Kit - Détection d'objets] → [Analyse distraction (téléphone, mouvement)]
     ↓
[Système d’alerte (son + vibration)]
     ↓
[Enregistrement de l’événement]
     ↓
[Rapport de conduite]
```

## 6. Fonctionnalités détaillées
### 6.1 Fonctionnalités principales
| Fonctionnalité              | Description                                               | Service ML Kit utilisé |
|----------------------------|-----------------------------------------------------------|------------------------|
| Détection de somnolence    | Analyse des yeux fermés et du bâillement                  | Face Detection         |
| Détection de distraction   | Détection d’un téléphone ou autre objet dans le champ de vision | Object Detection  |
| Alerte sonore et vibration | Déclenchement d’une alarme en cas de somnolence/distraction | —                   |
| Rapport de conduite        | Sauvegarde et affichage du nombre d’alertes, durée du trajet, date | —              |

### 6.2 Fonctionnalités supplémentaires
| Fonctionnalité         | Description |
|------------------------|-------------|
| Mode clair/sombre      | Thème ajustable selon la préférence de l’utilisateur. |
| Notifications push     | Rappel quotidien pour utiliser l’application avant de conduire. |
| Multilingue (Fr-En-Ar) | Interface traduite via fichiers JSON localisés. |
| Paramétrage            | Activation/désactivation des sons, notifications, ou du mode sombre. |

## 7. Structure logicielle (arborescence du projet)
```
SafeDrive/
│
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── home_screen.dart
│   │   ├── detection_screen.dart
│   │   ├── report_screen.dart
│   │   ├── settings_screen.dart
│   │   └── about_screen.dart
│   ├── services/
│   │   ├── face_detection_service.dart
│   │   ├── object_detection_service.dart
│   │   └── notification_service.dart
│   ├── models/
│   │   ├── detection_event.dart
│   │   └── trip_report.dart
│   ├── providers/
│   │   └── settings_provider.dart
│   └── widgets/
│       ├── custom_button.dart
│       ├── camera_overlay.dart
│       └── report_card.dart
│
├── assets/
│   ├── images/
│   │   └── logo.png
│   ├── sounds/
│   │   ├── alarm.mp3
│   │   └── notification.mp3
│   └── lang/
│       ├── en.json
│       ├── fr.json
│       └── ar.json
│
├── pubspec.yaml
└── README.md
```

## 8. Maquettage (wireframes prévus)
| Écran    | Description |
|----------|-------------|
| Accueil  | Logo + boutons « Démarrer », « Rapports », « Paramètres », « À propos ». |
| Détection | Vue caméra + cadres de détection, message d’alerte si fatigue. |
| Rapports | Liste des trajets précédents avec statistiques. |
| Paramètres | Switchs pour sons, notifications, thème, langue. |
| À propos | Informations sur l’application et les API utilisées. |

## 9. Contraintes techniques et fonctionnelles
| Type         | Détail |
|--------------|--------|
| Technique    | Fonctionne uniquement sur Android 8+ avec caméra frontale. |
| Performance  | Traitement en temps réel avec latence < 300 ms. |
| Confidentialité | Aucune donnée envoyée à un serveur, tout est traité localement. |
| Compatibilité | Adapté aux écrans de différentes tailles (responsive). |
| Langue du code | Anglais pour les identifiants, commentaires en français/anglais. |

## 10. Livrables attendus
- Code source Flutter complet et fonctionnel.
- Rapport détaillé incluant :
  - Les services ML Kit utilisés.
  - Les choix techniques et plugins.
  - La structure de l’application.
  - Des captures d’écran illustrant le fonctionnement.
  - Lien vers une vidéo de démonstration (optionnelle).
- Documentation technique (README + Cahier des Charges).

## 11. Conclusion
Le projet SafeDrive illustre une application mobile utile et innovante qui intègre des fonctionnalités d’intelligence artificielle embarquée pour renforcer la sécurité au volant. Grâce à l’exploitation de Firebase ML Kit et à l’environnement Flutter, l’application met en œuvre des technologies modernes de vision par ordinateur et de traitement en temps réel, tout en respectant les exigences académiques du module de Programmation Mobile.
