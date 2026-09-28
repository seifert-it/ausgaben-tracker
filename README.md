# seifert-it Ausgaben

Eine schlanke macOS-Anwendung für den privaten Ausgabenüberblick. Die App arbeitet vollständig lokal und benötigt weder Benutzerkonto noch Internetverbindung.

## Voraussetzungen

- macOS 14 oder neuer
- Apple-Silicon-Mac

## Installation

1. Die DMG-Datei öffnen.
2. **seifert-it Ausgaben** in den Ordner **Programme** ziehen.
3. Die App aus dem Programme-Ordner starten.

## Bedienung

Über **Ausgabe erfassen** lassen sich Betrag, Datum, Kategorie und eine optionale Notiz speichern. Die Übersicht stellt Tages- und Monatslimit gegenüber und wechselt bei einer Überschreitung von Blau auf Rot.

Die Limits und der monatliche Stichtag werden über die Schaltfläche **Budgets** angepasst. Beträge können beispielsweise als `1200`, `40,50` oder `1.200,50` eingegeben werden. Am Stichtag beginnt ein neuer Zeitraum; der abgeschlossene Zeitraum bleibt im lokalen Archiv verfügbar.

## Lokale Daten

Alle Einträge liegen ausschließlich in:

`~/Library/Application Support/de.seifert-it.ausgaben/data.json`

Beim Austausch oder Aktualisieren der App bleibt diese Datei erhalten. Für eine Sicherung genügt es, die Datei bei geschlossener App zu kopieren.

## Entwicklung

Das Projekt verwendet Swift 6, SwiftUI und Swift Charts. Zusätzliche Bibliotheken oder Paketabhängigkeiten werden nicht benötigt.

```bash
swift run
```

App-Paket und DMG erzeugen:

```bash
Scripts/build-app.sh
Scripts/build-dmg.sh
```

Die fertigen Dateien werden im Verzeichnis `dist` abgelegt.

## Datenschutz

Die Anwendung überträgt keine Daten und bindet keine externen Dienste ein. Weitere Hinweise stehen in [PRIVACY.md](PRIVACY.md).

## Lizenz

Veröffentlicht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE).
