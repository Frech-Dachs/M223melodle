# Melodle

Multiuser-Musik-Ratespiel für Freundesgruppen (ICT-Modul 223). Ein Host startet eine Runde mit einem Song aus der Songliste der Gruppe. Alle Mitglieder hören einen Ausschnitt, der nach jedem falschen Tipp länger wird (0.1 s bis 16 s). Wer früher richtig rät, erhält mehr Punkte. Die Bestenliste der Gruppe aktualisiert sich in Echtzeit.

Die Projektdokumentation (Was und Warum) steht unter [docs/](docs/README.md), vor allem in [docs/dokumentation_melodle.md](docs/dokumentation_melodle.md).

## Technologie-Stack

| Komponente | Version |
|---|---|
| Ruby | 4.0.6 (`.ruby-version`) |
| Ruby on Rails | 8.1.3.1 |
| SQLite | 3 (Gem `sqlite3` 2.9.6) |
| Pundit | 2.5.2 |
| bcrypt | 3.1.22 |
| Turbo / Stimulus / Importmap | turbo-rails 2.0.23, stimulus-rails 1.3.4 |
| Action Cable | Development `async`, Production Solid Cable |
| Minitest | 6.0.6 |

## Voraussetzungen

- Ruby 4.0.6 (z. B. über `mise use ruby@4.0.6`) und Bundler
- SQLite 3
- Git

Weitere Dienste (Redis, Node.js, Mailserver) sind nicht nötig.

## Installation und Konfiguration

```bash
git clone <repository-url> melodle
cd melodle
bundle install
bin/rails db:prepare   # erstellt die SQLite-Datenbank aus db/schema.rb und lädt die Demo-Daten
```

Es ist keine weitere Konfiguration nötig. Die Datenbanken liegen unter `storage/` (`development.sqlite3`, `test.sqlite3`).

Demo-Daten neu laden bzw. Datenbank zurücksetzen:

```bash
bin/rails db:seed    # Demo-Daten ergänzen (idempotent)
bin/rails db:reset   # Datenbank löschen, neu aufbauen, Demo-Daten laden
```

Die Demo-Daten (`db/seeds.rb`) enthalten drei Konten, die Gruppe «Demo Group» und sechs Songs mit selbst erzeugten Melodien (`public/audio/*.wav`).

## Starten

```bash
bin/rails server
```

Danach http://localhost:3000 öffnen. Für den Mehrbenutzer-Test zwei Browserfenster verwenden (z. B. ein normales und ein privates Fenster) und mit zwei Demo-Konten anmelden.

Bestätigungslinks für E-Mail-Änderungen werden in der Entwicklung nicht verschickt, sondern stehen in `log/development.log`.

## Tests und Prüfungen

```bash
bin/rails test       # alle Tests (Modell-, Policy-, Integrations- und Nebenläufigkeitstests)
bin/rubocop          # Code-Stil
bin/brakeman         # Sicherheitsanalyse
bin/bundler-audit    # bekannte Schwachstellen in Gems
```

Testnachweis: [docs/tests.md](docs/tests.md).

## Demo-Konten

Passwort für alle Konten: `demo-password-123`

| E-Mail | Anzeigename | Rolle in «Demo Group» |
|---|---|---|
| `host@example.test` | Host | Host (Songliste verwalten, Runden starten und beenden, Mitglieder entfernen) |
| `anna@example.test` | Anna | Spieler |
| `ben@example.test` | Ben | Spieler |

Mit einem neu registrierten Konto kann man selbst eine Gruppe erstellen (und ist dort Host) oder der «Demo Group» mit ihrem Einladungscode beitreten. Den Code sehen alle Mitglieder auf der Gruppenseite.

## Dokumentation

- [docs/dokumentation_melodle.md](docs/dokumentation_melodle.md): Projektdokumentation
- [docs/projektantrag_melodle.md](docs/projektantrag_melodle.md): Projektantrag
- [docs/tests.md](docs/tests.md): Testnachweis
