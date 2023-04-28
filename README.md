# ELO File Export
Der Kopiervorgang wird mittels einer CSV - Datei ermöglicht.
Diese kann durch 2 Wege erstelt werden.
1. Das [`ELOFileExport.ps1`](ELOFileExport.ps1) erzeugt die Datei selbst und mit Hilfe der Keasy Datenbankverbindung.xml oder
2. per SQL Managementstudio oder SQLCMD und der [`ELO Struktur Export as File.sql`](ELO_Struktur_Export_as_File.sql)

## Ablauf:
### 1. Alle Dateien herunterladen, Zip extrahieren
Siehe [Releases](https://github.com/vfm/ELOFileExport/releases/)
und [ELOFileExport.zip](https://github.com/vfm/ELOFileExport/archive/refs/heads/master.zip)

#### 1.1 PowerShell Policies und Permission prüfen
Siehe: https://docs.microsoft.com/de-de/powershell/module/microsoft.powershell.core/about/about_execution_policies
PowerShell mit Administratorrechten ausführen

`Get-ExecutionPolicy -List`
  
Erlauben:
`Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine`

Zurücksetzen
`Set-ExecutionPolicy -ExecutionPolicy Default -Scope LocalMachine`
  
### 2. Datenbankverbindung.xml in den gleichen Ordner kopieren
2.1. **Wenn** keine Datenbankverbindung.xml vorhanden ist (Ansonsten siehe 3.):

per PowerShell folgende Anweisung ausführen
```cmd
sqlcmd -S <keasyserver> -d <keasydb> -i "ELO_Struktur_Export_as_File.sql" -o "ELOFileExportData.csv" -h-1 -s";
```
oder das Script [`ELO Struktur Export as File.sql`](ELO_Struktur_Export_as_File.sql) im SQL Management-Studio ausführen und die Ergebnismenge mit Spalten-Info als `ELOFileExportData.csv` speichern

### 3. PowerShell Script klassisch oder mit ISE ausführen

  **Option 1:** PowerShell öffnen, zum Ordner- Pfad der ELOFileExport.ps1 navigieren
  `ELOFileExport.ps1`, mit den Paramentern _Exportordner_ und _ELO Ordner ObjectId_, ausführen 
  z.B.: 
  
  ```ps
  .\ELOFileExport.ps1 "C:\\vfm\EXPORT" 70681
  ```
  
  und Ausführung abwarten

**ODER**

  **Option 2:** [`ELOFileExport.ps1`](ELOFileExport.ps1) öffnen (Doppelklick oder mit PowerShell ISE)
    `$Zielpfad` und `$OrdnerId` angeben
    z.B.: 

```ps
#--Exportordner Pfad angeben!
$Zielpfad = "C:\\vfm\EXPORT";
#------------^^

#-- ID des gewünschten ELO Ordners angeben!
$OrdnerId = 70681;
#-----------^^
```
    
   Export starten im ISE mit   
    
### ```|> "Skript ausführen" oder F5 betätigen ``` 

und Ausführung abwarten   
