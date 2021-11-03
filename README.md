# ELO File Export
Der Kopiervorgang wird mittels einer CSV - Datei ermöglicht.
Diese kann durch 2 Wege erstelt werden.
1. Das 'ELOFileExport.ps1' mit Hilfer der Keasy Datenbankverbindung.xml oder
2. per SQL Management-Studio oder SQLCMD und der *ELO Struktur Export as File.sql*

## Ablauf:
1. Alle Dateien herunterladen
2. 'ELOFileExport.ps1' öffnen (Doppelklick oder mit PowerShell ISE)
3. *$Zielpfad* und *$OrdnerId* angeben
 z.B.: 
    ```ps
    #--Exportordner Pfad angeben!
    $Zielpfad = "C:\\vfm\EXPORT";
    #------------^^

    #-- ID des gewünschten ELO Ordners angeben!
    $OrdnerId = 70681;
    #-----------^^
    ```
4. **Wenn** keine Datenbankverbindung.xml vorhanden ist:

   per PowerShell folgende Anweisung ausführen
    ```
    sqlcmd -S <keasyserver> -d <keasydb> -i "ELO_Struktur_Export_as_File.sql" -o "ELOFileExportData.csv" -h-1 -s";    
    ```
    oder das Script *ELO_Struktur_Export_as_File.sql* im SQL Management-Studio ausführen

5. Export starten im ISE mit   
    
    ## ```|> "Skript ausführen" oder F5 betätigen ```    

