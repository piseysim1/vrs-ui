# DriveBlue - Vehicle Rental & Management System

**DriveBlue** is a cross-platform vehicle rental and management system built with **Flutter**. It offers a seamless customer-facing web/mobile portal to explore and book available rental cars, alongside a comprehensive administrative dashboard for managing fleet inventory, bookings, brands, locations, and customer records.

---

## 🚀 Features

### 🚘 Customer Portal
- **Vehicle Catalog:** Browse trending and available vehicles with real-time status indicators.
- **Detailed Fleet Search:** Search and filter vehicles by brand (e.g., Toyota, BMW, Honda, Ford), model, and rental pricing.
- **Easy Booking:** Flexible rental duration options (hourly/daily rates) and location hub pick-up selection (e.g., Phnom Penh City Center, Phnom Penh International Airport).
- **Booking History:** Access past and active rental reservations.

### ⚙️ Admin Dashboard
- **Fleet Management Overview:** Live analytics tracking Total Fleet size, Available vehicles, Rented units, and Out-of-service/Unavailable status.
- **Vehicle Inventory CRUD:** Add, edit, remove, and update vehicle status, hourly/daily pricing, plate numbers, and location hubs.
- **Booking & Customer Management:** Centralized view for managing customer accounts and booking schedules.
- **Brand & Location Hub Settings:** Configure vehicle brands and regional pickup/drop-off locations.

---

## 🛠 Tech Stack & Architecture

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Architecture/Pattern:** Modular clean architecture (separating core utilities, data layer, routes, and UI presentation components)
- **UI & Routing:** Custom responsive UI supporting web and desktop interfaces with structured route management (`app_routes.dart` & `app_pages.dart`).

---

## 📂 Project Structure

```text
lib/
├── app/
│   ├── core/           # Utility classes, constants, and theme helpers
│   ├── data/           # Models, providers, and repositories
│   ├── routes/         # Application routing configuration
│   └── ui/             # User Interface presentation layer
│       ├── admin/      # Admin portal views (Dashboard, Bookings, Vehicles, Brands, Locations)
│       ├── pages/      # Public-facing views & Auth
│       └── components/ # Reusable UI widgets and dialogs
└── main.dart           # App entry point
```

---

## 💻 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
* [Dart SDK](https://dart.dev/get-dart)
* IDE: [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/driveblue-vrs.git
   cd driveblue-vrs
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   - **Web:**
     ```bash
     flutter run -d chrome
     ```
   - **Desktop/Mobile:**
     ```bash
     flutter run
     ```

---

## 🔧 Build & Deployment

To build a production release for the web:
```bash
flutter build web --release
```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).