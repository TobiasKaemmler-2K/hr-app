# HR Mobile App

Dieses Projekt implementiert eine mobile HR-Anwendung zur Verwaltung von Abwesenheiten im militärischen Umfeld. Soldatinnen und Soldaten können Abwesenheiten digital beantragen, ihren Status einsehen und ihre Urlaubsstände verfolgen. Vorgesetzte können Anträge genehmigen oder ablehnen und ihre unterstellten Soldaten inklusive Kalenderübersicht einsehen. Administratoren verwalten technische und organisatorische Grunddaten.

## Architektur

Das System besteht aus drei zentralen Komponenten:

Frontend
- Flutter
- Dart

Backend
- ASP.NET Core Web API
- C#
- Entity Framework Core

Datenbank
- PostgreSQL

## Projektstruktur

backend/
- ASP.NET Core Web API

mobile_app/
- Flutter-Anwendung für Android, iOS, Windows, Linux, macOS und Web

docker/
- Docker-Compose-Konfiguration für lokale Infrastruktur

docs/
- Projekt- und Entwicklungsdokumentation

## Aktuell umgesetzte Funktionen

- Login mit Personalnummer und Passwort
- NFC-basierter zweiter Faktor mit Login-Challenge
- NFC-Scan liest Token in ein Eingabefeld; Verifikation erfolgt erst nach explizitem Prüfen
- Rollenmodell für `SOLDAT`, `VORGESETZTER` und `ADMIN`
- Hierarchiemodell: Vorgesetzte besitzen zusätzlich Soldatenfunktionen
- Erstellung, Anzeige und Stornierung eigener Abwesenheitsanträge
- Genehmigungsworkflow für offene und bereits entschiedene Anträge
- Anzeige unterstellter Soldaten inklusive Kontaktdaten und Kalenderansicht
- Vollständiger Admin-Bereich (Nutzer erstellen, bearbeiten, sperren/entsperren, löschen, Passwort zurücksetzen)
- NFC-Token-Verwaltung im Admin-Bereich (ausgeben, neu zuweisen, sperren, löschen)
- Dashboard mit Urlaubskennzahlen für aktuelles und vorheriges Jahr
- Urlaubskennzahlen in 2x2-Kachelraster im Dashboard und im Profil
- Werktagsbasierte Urlaubsberechnung nur von Montag bis Freitag
- Validierung des Jahreskontingents von maximal 30 Urlaubstagen
- Session-Schutz: erneute Anmeldung nach App-Verlassen und nach 10 Minuten
- Hintergrundwechsel-Toleranz für NFC-Systemwechsel (kein sofortiger Logout)
- Profilansicht mit Einheit, Dienstgrad, E-Mail und Telefonnummer
- Passwortänderung direkt in der App
- Bundeswehr-orientiertes UI: zentrales Theme, Low-Poly-Tarnmuster, Splash-Screen
- Seed-Daten für Benutzer, Rollen, NFC-Tokens, Abwesenheiten und Audit-Logs

## Technologien

Frontend
- Flutter
- Dart
- Provider
- Dio
- table_calendar

Backend
- ASP.NET Core
- Entity Framework Core
- BCrypt

Datenbank
- PostgreSQL

Infrastruktur
- Docker Compose

## Lokale Entwicklung

### PostgreSQL starten

```bash
cd docker
docker compose up -d
```

### Backend starten

```bash
cd backend/HrApp.Api
dotnet run
```

Für Handy-Tests muss das Backend aus dem gleichen WLAN erreichbar sein.

### Flutter App starten

```bash
cd mobile_app
flutter pub get
flutter run
```

Hinweise zur lokalen Ausführung:

- Standard-Workflow: `dotnet run` im Backend und `flutter run` in der App.
- Die aktuelle Android-Konfiguration ist auf LAN-Entwicklung mit dem lokalen Backend ausgelegt.
- Wenn sich die LAN-IP des Rechners ändert, muss die Basis-URL in `mobile_app/lib/core/api_constants.dart` angepasst werden.

## Testzugänge

Beispiele für bereits hinterlegte Seed-Benutzer:

- Soldat: Personalnummer `100002`, Passwort `test123`, NFC-Token `NFC-100002`
- Vorgesetzter: Personalnummer `100001`, Passwort `test123`, NFC-Token `NFC-100001`
- Admin: Personalnummer `100000`, Passwort `admin123`, NFC-Token `NFC-100000`

## Dokumentation

Weitere technische und fachliche Details befinden sich in den Dateien unter `docs/`, insbesondere in der Entwicklungsdokumentation, der Architekturübersicht und der Benutzerdokumentation für Endanwender.

## Autor

Projekt im Rahmen der Ausbildung zum
Fachinformatiker für Anwendungsentwicklung
