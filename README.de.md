# SQLPROJECTS Repository [![de](https://img.shields.io/badge/lang-de-green.svg)]

Dieses Repository enthält eine Sammlung von PL/SQL-Projekten (SQL-Skripten) im Oracle-Dialekt, die jeweils spezifischen JIRA-Stories bzw. Story-Identifikatoren des Kunden zugeordnet sind. Jeder Unterordner repräsentiert ein Projekt und enthält alle zugehörigen PL/SQL-Skripte sowie ergänzende Dokumentationen oder Hilfsdateien.

## Repository-Struktur

- **Unterordner:**  
  Jeder Unterordner entspricht einer spezifischen JIRA-Story. So können Sie die Inhalte direkt der entsprechenden Story zuordnen.

- **Dateien:**  
  Neben den PL/SQL-Skripten können in den Unterordnern auch Dokumentationen, Beispiele oder andere relevante Dateien abgelegt werden.

## Namenskonvention der PL/SQL-Dateien

Alle PL/SQL-Dateien in diesem Repository folgen der folgenden Namenskonvention:

<Storynummer>-JW_<Kurze_Beschreibung_mit_Unterstrichen>.sql


**Beispiel:**  
`DEV-1234-JW_Update_User_Table.sql`

- **<Storynummer>**: Der eindeutige JIRA-Story-Identifikator  
- **JW**: Ein fester Bestandteil im Dateinamen  
- **<Kurze_Beschreibung_mit_Unterstrichen>**: Eine kurze, prägnante Beschreibung des Inhalts oder der Funktion des PL/SQL-Skripts (Leerzeichen werden durch Unterstriche ersetzt)

## Voraussetzungen

- **Oracle-Datenbank:**  
  Die Skripte in diesem Repository sind für den Oracle-Dialekt (PL/SQL) ausgelegt. Eine Oracle-Datenbank ist daher Voraussetzung, um die Skripte auszuführen.

## Nutzung und Ausführung

- **PL/SQL-Skripte ausführen:**  
  Führen Sie die Skripte mit einem Oracle-kompatiblen Datenbank-Client wie Oracle SQL Developer oder einem anderen geeigneten Tool aus.

- **Weitere Informationen:**  
  In den jeweiligen Unterordnern finden Sie zusätzliche Dokumentationen oder Hilfsdateien, die den Zweck und die Funktionsweise der PL/SQL-Skripte erläutern.

## Beiträge und Versionskontrolle

- **Branching und Pull Requests:**  
  Änderungen und Erweiterungen sollten in separaten Branches erfolgen und mittels Pull Requests in den Hauptzweig integriert werden. Bitte verwenden Sie aussagekräftige Commit-Nachrichten.

- **Interne Nutzung:**  
  Dieses Repository dient der internen Verwaltung und Nachverfolgung der PL/SQL-Projekte, die direkt den entsprechenden JIRA-Stories zugeordnet sind.

## Abhängigkeiten & Lizenz

- **Abhängigkeiten:**  
  Dieses Repository enthält ausschließlich PL/SQL-Skripte und erfordert keine weiteren externen Bibliotheken.

- **Lizenz:**  
  Copyright (c) 2025 [ICP Solution GmbH]

  Hiermit wird jeder Person, die eine Kopie dieser Software und der zugehörigen Dokumentationsdateien (die "Software") erhält, kostenlos die Erlaubnis erteilt, uneingeschränkt mit der Software zu handeln, einschließlich und ohne Ausnahme der Rechte, die Software zu nutzen, zu kopieren, zu ändern, zusammenzuführen, zu veröffentlichen, zu verbreiten, unterzulizenzieren und/oder zu verkaufen, und Personen, denen die Software bereitgestellt wird, dies ebenfalls zu erlauben, unter den folgenden Bedingungen:

  Der obige Urheberrechtshinweis und dieser Erlaubnishinweis sind in allen Kopien oder wesentlichen Teilen der Software enthalten.

  DIE SOFTWARE WIRD „WIE BESEHEN“ BEREITGESTELLT, OHNE JEGLICHE GARANTIE, AUSDRÜCKLICH ODER IMPLIZIT, EINSCHLIESSLICH ABER NICHT BESCHRÄNKT AUF DIE GEWÄHRLEISTUNG DER MARKTGÄNGIGKEIT, DER EIGNUNG FÜR EINEN BESTIMMTEN ZWECK UND DER NICHTVERLETZUNG. IN KEINEM FALL SIND DIE AUTOREN ODER URHEBERRECHTSINHABER FÜR ANSPRÜCHE, SCHÄDEN ODER SONSTIGE HAFTUNGEN VERANTWORTLICH, SEI ES AUFGRUND EINES VERTRAGS, EINER UNERLAUBTEN HANDLUNG ODER ANDERWEITIG, DIE AUS ODER IN VERBINDUNG MIT DER SOFTWARE ODER DER NUTZUNG ODER ANDEREN GESCHÄFTEN MIT DER SOFTWARE ENTSTEHEN.

  Weitere Informationen finden Sie auf der offiziellen Website:  
  **[ICP Solution GmbH](https://www.icpsolution.com)**

## Kontakt & Support

Bei Fragen, Anregungen oder Problemen wenden Sie sich bitte per E-Mail an:  
📩 **[raptile.bytez@gmail.com](mailto:raptile.bytez@gmail.com)**
