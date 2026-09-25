# Melodle – Testnachweis

Ausführen: `bin/rails test` (Minitest, 97 Tests, 315 Assertions, alle grün, keine übersprungenen Tests). Stil prüfen: `bin/rubocop`.

## Testarten

| Art | Dateien | Inhalt |
|---|---|---|
| Modelltests | `test/models/user_test.rb`, `schema_constraints_test.rb`, `round_test.rb` | Validierungen, DB-Constraints (Unique-Indizes, partieller Index), Stufen- und Punkteregeln mit fester Zeit |
| Policy-Tests | `test/policies/policies_test.rb` | Host / Spieler / Nicht-Mitglied für jede Aktion, Rolle pro Gruppe, Scope |
| Integrationstests | `test/integration/*_test.rb` | Login, Profil, Gruppen, Songs, Runden, Bestenliste, Aktivitäten über echte HTTP-Requests |
| Nebenläufigkeitstests | `test/models/concurrency_test.rb` | Mehrere Threads mit eigener DB-Verbindung, gleichzeitig gestartet |

Testdaten werden meist direkt im Test angelegt (`Group.create_with_host!`, `User.create!`), weil Gruppen, Mitgliedschaften und Punktestände voneinander abhängen und so im Test lesbar bleiben. Fixtures gibt es für den Standardbenutzer `alice`.

## Anforderung → Test → Ergebnis

| Anforderung / Qualitätsattribut | Test | Ergebnis |
|---|---|---|
| 1 Registrieren und Einloggen, Passwort ≥ 12 | `authentication_test`, `user_test` | grün |
| 2 Gruppe erstellen, Beitritt per Einladungscode | `groups_test` (Erstellen, Beitritt, unbekannter Code, doppelt, voll) | grün |
| 3 Host stellt Songliste zusammen | `songs_test`, `policies_test` | grün |
| 4 Host startet Runde, nur eine aktive Runde | `rounds_test`, `round_test`, `concurrency_test` (Doppelstart) | grün |
| 5 Stufen 0.1 s … 16 s, Server bestimmt die Stufe pro Spieler | `round_test` (eigene Stufe je Spieler, nur nach eigenem falschen Tipp) | grün |
| 6 Punkte nach Stufe, 0 Punkte wenn nicht erraten; Mitspielen zu einem späteren Zeitpunkt | `round_test`, `rounds_test` (Spieler tritt nach dem Host bei, Banner bleibt bis er gespielt hat, Host kann Runde beenden) | grün |
| 7 Gemeinsame Bestenliste | `leaderboard_test` (Sortierung, Gleichstand, Runden gespielt) | grün |
| 8 Mitglieder entfernen (nur Host, nicht sich selbst) | `groups_test`, `policies_test` | grün |
| 9 Anzeigename ändern | `profile_test` (auch Passwort, E-Mail-Bestätigung) | grün |
| Rollen und Berechtigungen | `policies_test`, Controller-Tests mit 404 bzw. Redirect | grün |
| Aktivitätsprotokoll, Akteur aus Session, Rollback | `activities_test` | grün |
| QA 2 Ergebnisse gleichzeitig ohne Verlust | `concurrency_test` (fünf Spieler lösen gleichzeitig; derselbe Spieler zweimal) | grün |
| QA 3 Punktesumme ohne Lost Update | `concurrency_test` (10 gleichzeitige Erhöhungen = 100) | grün |
| QA 5 Bestenliste aktualisiert sich | `leaderboard_test` (Broadcast wird ausgelöst); Zeitmessung manuell | Broadcast grün, Zeit offen |
| QA 1 Start < 2 s, QA 4 20 Mitglieder | nicht automatisiert | manuell zu prüfen |

## Locking-Fälle

| Fall | Test |
|---|---|
| Nur eine aktive Runde pro Gruppe | `schema_constraints_test` (Index), `concurrency_test` (3 Threads starten, 1 Erfolg) |
| Eine Teilnahme pro Benutzer und Runde | `schema_constraints_test`, `concurrency_test` (doppelter Tipp) |
| Punkteverbuchung atomar | `concurrency_test` (`Score#add_points!`) |
| Letzter freier Platz | `concurrency_test` (2 und 8 Threads, ein Platz frei; derselbe Benutzer zweimal) |
| Änderung und Aktivität in einer Transaktion | `activities_test` (Rollback bei fehlgeschlagenem Eintrag) |

## Aussagekraft der Tests

Schutzmassnahmen wurden kurz entfernt, um zu sehen, dass der passende Test rot wird. Danach wurde alles wiederhergestellt und die Suite lief grün.

| Änderung | Erwartung | Beobachtung |
|---|---|---|
| `Score#add_points!` liest, addiert und schreibt statt `update_counters` | Concurrency-Test rot | rot (100 erwartet, 20 erhalten) |
| Policy `SongPolicy` erlaubt jedem alles | Policy-Test rot | rot |
| `Group.join!` ohne Transaktion | Concurrency-Test rot | zuerst **nicht rot**: die Lücke zwischen «Platz frei?» und «Platz nehmen» war zu klein. Der Test verlangsamt deshalb künstlich `Group#full?` (`with_slow_full_check`), danach rot (beide Nutzer aufgenommen) |

## Bekannte Lücken

- Die Ausschnittslänge im Browser (Stimulus, `setTimeout`) ist nicht automatisiert getestet.
- Kein Systemtest mit echtem Browser und mehreren Sitzungen; das Echtzeitverhalten wurde nur über die ausgelösten Broadcasts geprüft.
- SQLite serialisiert Schreibzugriffe. Die Nebenläufigkeitstests belegen das Verhalten unter SQLite, nicht unter einer anderen Datenbank.
