# Melodle

Multiuser-Musik-Ratespiel für Freundesgruppen (Modul 223). Dokumentation: [docs/](docs/README.md).

## Stand

- Registrierung, Login/Logout, Dashboard (geschützt)
- Noch offen: Gruppen, Songlisten, Runden, Tipps, Bestenliste

## Technologie-Stack

Ruby 4.0.6, Rails 8.1.3, SQLite 3, bcrypt (`has_secure_password`), Minitest

## Installation & Start

```bash
bundle install
bin/rails db:setup
bin/rails server   # http://localhost:3000
```

## Tests

```bash
bin/rails test
```

## Demo-Konten

Noch keine (folgen mit den Seed-Daten).
