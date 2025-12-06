# AxeGuide

> A modern Flutter app for newcomers, students, and travelers in Nova Scotia, providing personalized onboarding and essential resources for campus and city life.

---

## Features
- **Personalized Onboarding:** Step-by-step walkthrough tailored to your location and needs.
- **Location-Based Home Screen:** Dynamic sections for campus, city, and travel essentials, powered by Supabase backend.
- **User Preferences:** Save progress, location, and onboarding status with Hive local storage.
- **Modern UI:** Deep blue and lime green theme, bold typography, rounded corners, and logo integration.
- **Settings:** Change location, restart onboarding, and reset personalization.
- **Offline Caching:** Fast access to locations, even without internet.
- **Multi-Platform:** Runs on Android, iOS, Web, Windows, macOS, and Linux.
- **Test Coverage:** Core business logic and data layer tested for reliability.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Hive](https://docs.hivedb.dev/) (local storage)
- Dart 3.x

### Supabase Access
- **You do NOT need your own Supabase account to use the app.**
- The app connects to a pre-configured Supabase backend using a public "anon" key for read-only access.
- You need a valid `.env` file with the following keys:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
- The `.env` file is not included in the repository (see `.gitignore`).
- Ask the project maintainer for the `.env` file, or use the provided `.env.example` as a template.

#### Example `.env.example`:
```
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_anon_key_here
```

#### For Developers
- If you want to deploy your own backend or modify data, create a Supabase project and set Row Level Security (RLS) policies to allow read-only access for the anon role:
  - Example RLS policy for each table:
    - `SELECT: role() = 'anon'`
- Never share your service role key publicly.

---

### Setup
1. **Clone the repo:**
   ```sh
   git clone https://github.com/melita-pereira/axeguide.git
   cd axeguide
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Configure environment:**
   - Add your `.env` file to the project root (see above).

---

## Usage
- **Onboarding:** Start with a personalized walkthrough to set your location and preferences.
- **Home Screen:** Explore dynamic sections for campus, city, and travel resources.
- **User Preferences:** Save progress, location, and onboarding status with Hive local storage.
- **Settings:** Change location, restart onboarding, or reset your data anytime.

---

## Project Structure
- `lib/screens/` — Main UI screens (home, walkthrough, settings, welcome)
- `lib/walkthrough/` — Onboarding logic, action handlers, and step management
- `lib/utils/` — User preferences, Hive helpers
- `assets/` — Layouts, images, walkthrough configs
- `test/` — Unit and integration tests

---

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you’d like to change.

- Fork the repo
- Create your feature branch (`git checkout -b feature/fooBar`)
- Commit your changes (`git commit -am 'Add some fooBar'`)
- Push to the branch (`git push origin feature/fooBar`)
- Open a pull request

---

## License
MIT © Melita Pereira
