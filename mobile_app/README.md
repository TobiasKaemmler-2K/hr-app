# Mobile App

Dies ist die Flutter-Clientanwendung des Projekts `hr-app`. Die App dient als mobiles Frontend für die digitale Verwaltung von Abwesenheiten.

## Funktionsumfang

- Login mit Personalnummer und Passwort
- NFC-Verifikation als zweiter Faktor
- NFC-Scan mit Eintragung in das Token-Feld und expliziter Prüfung per Button
- Dashboard mit Urlaubsständen und Kalenderansicht
- Kennzahlen-Kacheln im 2x2-Raster (Dashboard und Profil)
- Eigene Abwesenheiten anzeigen, erstellen und stornieren
- Genehmigungsansicht für Vorgesetzte
- Unterstellte Soldaten mit Kalender- und Kontaktdaten einsehen
- Admin-Funktionen: Nutzerverwaltung und NFC-Token-Verwaltung
- Profilansicht mit E-Mail, Telefonnummer und Passwortänderung
- Sitzungsablauf bei App-Verlassen und nach 10 Minuten Inaktivität

## Technischer Aufbau

Die App verwendet:

- Flutter
- Provider für State Management
- Dio für API-Kommunikation
- Flutter Secure Storage
- table_calendar für Kalenderdarstellungen

Wichtige Bereiche im Projekt:

- `lib/core/` für Konfiguration und Routing
- `lib/models/` für DTOs und App-Modelle
- `lib/providers/` für Zustandsverwaltung
- `lib/services/` für API- und Plattformzugriffe
- `lib/screens/` für UI-Seiten
- `lib/widgets/` für wiederverwendbare Komponenten

## Lokale Ausführung

```bash
flutter pub get
flutter run
```

## Backend-Anbindung

Die App unterstützt Emulator und echtes Handy. Aktuell ist Android auf LAN-Backend ausgelegt.

Ohne zusätzliche Parameter:

- `dotnet run` im Backend
- `flutter run` in `mobile_app`
- Die App nutzt die in `lib/core/api_constants.dart` hinterlegte Basis-URL

Beispiele:

```bash
# Standardstart
flutter run

# Optionaler Override (falls erforderlich)
flutter run --dart-define=API_BASE_URL=http://192.168.178.44:5203
```

Wichtig für echtes Handy:

- Backend darf nicht nur auf `localhost` lauschen
- Handy und PC müssen im gleichen Netzwerk sein
- Firewall muss den Backend-Port (z. B. `5203`) erlauben
- Wenn sich die LAN-IP ändert, muss die App-Basis-URL angepasst oder per `--dart-define` überschrieben werden

## Testzugänge

- Soldat: `100002` / `test123` / `NFC-100002`
- Vorgesetzter: `100001` / `test123` / `NFC-100001`
- Admin: `100000` / `admin123` / `NFC-100000`

Im Debug-Modus kann das NFC-Token in der Verifikationsansicht weiterhin manuell eingegeben werden.
