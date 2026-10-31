# MAXKO F&B Mobile

MAXKO F&B customer app for discovering brands, ordering, tracking orders, and managing membership.

## API data source

The app uses the MAXKO API at `https://api.legiapos.vn` by default in debug and release builds, matching the production endpoint in the supplied MAXKO project archive. To point a local build at the backend in this repository, pass `API_BASE_URL` when starting Flutter:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

Use `http://localhost:5000` for web, iOS simulator, or desktop runs, and your computer's LAN IP with port `5000` for a physical phone. The backend reads its MongoDB connection from `backend/.env`; the ZIP does not provide a production MongoDB/Atlas connection string.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
