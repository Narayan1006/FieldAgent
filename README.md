# FieldAgent 🏥

> **AI-powered offline-first mobile app for ASHA healthcare workers in rural India.**  
> Built with Flutter · Firebase Firestore · Gemma 4 E4B (on-device AI) · SQLite

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Download APK](https://img.shields.io/badge/Download-APK%20v1.0.0-brightgreen?logo=android)](https://github.com/Narayan1006/FieldAgent/releases/latest/download/app-release.apk)

---

## ⬇️ Download

| Platform | Link | Size |
|---|---|---|
| **Android (arm64)** | [📦 app-release.apk](https://github.com/Narayan1006/FieldAgent/releases/latest/download/app-release.apk) | 234.6 MB |

> **First-launch note:** On first run the app downloads the **Gemma 4 E4B model (3.65 GB)** over WiFi.  
> After that it works **fully offline** — no internet needed for AI inference.

### Install via ADB
```bash
adb install app-release.apk
```

---

---

## 📱 What is FieldAgent?

FieldAgent is a mobile clinical assistant designed for **ASHA (Accredited Social Health Activist) workers** operating in remote, low-connectivity villages across rural India. It enables:

- **Offline-first patient data capture** — works without internet
- **7 patient category workflows** — each with dedicated visit forms and danger flags
- **On-device AI referral notes** — powered by Gemma 4 E4B (no cloud API needed)
- **Automatic background sync** — data pushes to Firebase when connectivity returns
- **Village-based patient segmentation** — ASHA workers manage their assigned cohort

---

## 🩺 Patient Categories

| # | Category | Emoji | Key Workflow | Danger Flags |
|---|---|---|---|---|
| 1 | **Maternal Health** | 🤰 | ANC visits, BP, weight, LMP/EDD tracking | High BP (pre-eclampsia), hypotension |
| 2 | **Child Immunization** | 👶 | BCG, OPV, DPT, Measles schedule tracking | Adverse reactions, missed vaccines |
| 3 | **TB Follow-up** | 💊 | DOTS daily dose compliance, symptom check | Missed dose, hemoptysis, wt loss |
| 4 | **Malaria/Dengue** | 🦟 | RDT result, fever, treatment compliance | High fever ≥39.5°C, unconsciousness |
| 5 | **Family Planning** | 🌸 | Contraceptive method, follow-up schedule | Severe side effects, non-compliance |
| 6 | **Newborn Care** | 🍼 | Weight, breastfeeding, jaundice check | Jaundice, breathing issues, not feeding |
| 7 | **General Sick Visit** | 🩺 | Symptoms, temperature, referral decision | High fever, chest pain, altered consciousness |

---

## ✨ Key Features

### 🔌 Offline-First Architecture
- **SQLite** is the source of truth — all data written locally first
- Approved visits are queued in `sync_status = 'pending'`
- `SyncService` monitors connectivity via `connectivity_plus`
- On reconnection → auto-flushes queue to **Firebase Firestore**

### 🤖 On-Device AI (Gemma 4 E4B)
- Runs entirely on the device — no internet required for AI
- Generates contextual **referral notes** per patient type
- ASHA worker can edit the note before approving

### 🏥 Village-Based Workflow
- First-launch **village selection** screen
- Resilient: hardcoded village list shown instantly, Firestore refreshes in background
- Pull-to-refresh syncs new patients from cloud to local SQLite

### 📊 Danger Flag System
- Real-time threshold checks per category (no AI needed)
- Maternal: BP thresholds (WHO/MOHFW guidelines)
- TB: DOTS compliance tracking
- Malaria: Severity indicators (unconscious, convulsions)
- Newborn: IMNCI-based danger sign checklist

### 🔄 Sync Status Indicators
- Every patient card shows `✅ Synced` or `🔄 Pending`
- Category filter chips: filter by type across all patients
- Live online/offline indicator in the app bar

---

## 🗂️ Project Structure

```
lib/
├── models/
│   ├── patient.dart          # Patient model with patientType + extraData JSON
│   ├── patient_type.dart     # Enum: 7 types with emoji/color/label
│   └── visit.dart            # Visit model with visitType + visitData JSON
│
├── screens/
│   ├── home_screen.dart      # Patient list with category filter chips
│   ├── add_patient_screen.dart   # Type selector + dynamic registration form
│   ├── typed_visit_screen.dart   # Universal visit form (6 non-maternal types)
│   ├── capture_screen.dart   # OCR capture (maternal health)
│   ├── summary_screen.dart   # Visit review + Gemma referral note + approve
│   ├── village_selection_screen.dart
│   └── settings_screen.dart  # Change village, app config
│
├── services/
│   ├── database_service.dart # SQLite v3 — patient + visit CRUD + migrations
│   ├── sync_service.dart     # Firestore ↔ SQLite sync engine
│   └── gemma_service.dart    # On-device Gemma 4 E4B integration
│
├── tools/
│   ├── flag_danger_signs.dart    # Deterministic danger flag computation
│   ├── draft_referral_note.dart  # Gemma prompt builder per patient type
│   └── log_visit_entry.dart      # Visit field update utility
│
└── widgets/
    ├── patient_card.dart     # Card with type emoji, color badge, sync status
    ├── danger_banner.dart    # Red/yellow alert banner
    └── bp_number_input.dart  # Numeric BP input widget
```

---

## 🗄️ Database Schema (SQLite v3)

### `patients`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PK | UUID |
| `name` | TEXT | Patient name |
| `age` | INTEGER | Age in years |
| `village` | TEXT | Assigned village |
| `patient_type` | TEXT | `maternal` / `child` / `tb` / `malaria` / `family_planning` / `newborn` / `general` |
| `anc_number` | TEXT | ANC number (maternal only) |
| `lmp_date` | TEXT | Last menstrual period (maternal only) |
| `edd` | TEXT | Expected delivery date (maternal only) |
| `extra_data` | TEXT | JSON blob for type-specific fields |
| `sync_status` | TEXT | `pending` / `synced` |

### `visits`
| Column | Type | Description |
|---|---|---|
| `id` | TEXT PK | UUID |
| `patient_id` | TEXT FK | References patients |
| `visit_type` | TEXT | Matches patient_type |
| `bp_systolic` | INTEGER | (maternal/general) |
| `bp_diastolic` | INTEGER | (maternal/general) |
| `weight` | REAL | kg |
| `temperature` | REAL | °C (malaria/general) |
| `symptoms` | TEXT | Comma-separated |
| `danger_flags` | TEXT | Pipe-separated flags |
| `referral_note` | TEXT | Gemma-generated + ASHA-edited |
| `approved` | INTEGER | 0/1 |
| `visit_data` | TEXT | JSON blob for type-specific readings |
| `sync_status` | TEXT | `pending` / `synced` |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Android device / emulator (API 23+)
- Firebase project with Firestore in **Test Mode**
- Gemma 4 E4B model downloaded to device

### Setup

```bash
# Clone
git clone https://github.com/Narayan1006/FieldAgent.git
cd FieldAgent

# Install dependencies
flutter pub get

# Place your google-services.json in android/app/

# Run
flutter run
```

### Firestore Rules (Development)
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

> ⚠️ Update to `request.auth != null` before production deployment.

### Seed Firestore (optional)
```bash
node firestore_seed.js
# or
.\firestore_seed.ps1
```

---

## 🔄 Sync Architecture

```
ASHA Worker Action
       │
       ▼
  SQLite (local) ──── Source of Truth
       │
       ├─── Online?  ──YES──► Firestore (cloud)  ──► sync_status = 'synced'
       │
       └─── Offline? ──────► Queue (sync_status = 'pending')
                                     │
                              On reconnect
                                     │
                                     ▼
                              Auto-flush to Firestore ✅
```

---

## 📱 App Flow

```
App Start
    │
    ├─ First launch ──► Village Selection
    │                        │
    │                        ▼
    └─ Returning ────► Home Screen
                           │
              ┌────────────┼────────────┐
              │            │            │
         Filter Tab    Add Patient   Sync Button
         (7 types)    (type picker)  (pull Firestore)
              │
              ▼
         Patient Card → Start Visit
                              │
                    ┌─────────┴──────────┐
                    │                    │
               Maternal           All Other Types
                    │                    │
            CaptureScreen       TypedVisitScreen
           (OCR + voice)       (type-specific form)
                    └─────────┬──────────┘
                              │
                         SummaryScreen
                         (Gemma AI note)
                              │
                           APPROVE
                              │
                    SQLite ◄──┴──► Firestore
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **UI** | Flutter 3.x (Dart) |
| **Local DB** | SQLite via `sqflite` |
| **Cloud DB** | Firebase Firestore |
| **Connectivity** | `connectivity_plus` |
| **On-Device AI** | Gemma 4 E4B (`flutter_gemma`) |
| **State** | `StatefulWidget` + `StreamController` |
| **Sync** | Custom `SyncService` with event stream |
| **Preferences** | `shared_preferences` |

---

## 🔐 Security Notes

- `google-services.json` is included for development convenience
- **Before production:** enable Firebase Auth and update Firestore rules
- Patient data is stored locally in SQLite — encrypted storage recommended for production
- On-device AI ensures clinical data never leaves the device for inference

---

## 👥 Built For

**ASHA Workers** across rural India who:
- Work in areas with intermittent or no internet connectivity
- Manage maternal health, child immunization, TB, and communicable disease cohorts
- Need AI assistance for referral decisions without cloud dependency
- Require a simple, language-agnostic interface for field conditions

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

*Built for the Google AI Hackathon 2026 — leveraging Gemma on-device AI for last-mile healthcare delivery.*
