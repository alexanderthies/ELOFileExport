##sqlcmd -S sqlinstance -d database -i "SQL-Script ELO Struktur Export as File (mit Hilfe Keasy ELO Migration).sql" -o "ELOFileExportData.csv" -h-1 -s";"

echo 'Datenbankinfo laden'
If ((Test-Path "DatenbankVerbindung.xml") -eq $true)
{
    $conn = Select-Xml -Path DatenbankVerbindung.xml -XPath 'xml/DatabaseConnection' | ForEach-Object { $_.Node.InnerXML }
    $connectionsstring = '';
    try { $connectionsstring = [Convert]::FromBase64String("$conn ")}
    catch { $connectionsstring = $conn; }

    echo  'ELO Struktur Export - Script ausführen und als CSV speichern'

    $sqlscript = "SQL-Script ELO Struktur Export as File (mit Hilfe Keasy ELO Migration).sql";
    If ((Test-Path $sqlscript) -eq $false)
    {
      write-host ($sqlscript +" wurde nicht gefunden." ) -ForegroundColor Red
    }

    Invoke-Sqlcmd -connectionstring $connectionsstring -InputFile "SQL-Script ELO Struktur Export as File (mit Hilfe Keasy ELO Migration).sql" |
    Export-Csv -NoTypeInformation `
               -Path "ELOFileExportData.csv" `
               -Encoding UTF8

    echo 'ELOFileExportData.csv gespeichert'
}
ELSE  
  {
     write-host ("Datenbankverbindungs.xml Konnte nicht gefunden werden, bitte SQL Script manuell ausführen oder ") -ForegroundColor DarkYellow
     write-host ("PowerShell Command: " + 'sqlcmd -S sqlserverinstance -d database -i "SQL-Script ELO Struktur Export as File (mit Hilfe easy ELO Migration).sql" -o "ELOFileExportData.csv" -h-1 -s";"' ) -ForegroundColor DarkCyan

  }

$ELOFileExportData = "ELOFileExportData.csv"
If ((Test-Path $ELOFileExportData) -eq $false)
{
  write-host ($ELOFileExportData +" wurde nicht gefunden, wurde das Export-Script ausgeführt?" ) -ForegroundColor Red
}
ELSE
{


    ##$files=Import-CSV -Path  $ELOFileExportData -Header "Source","Directory","Filename", "ObjId" -Delimiter ";" -encoding UTF7
    $files=Import-CSV -Path $ELOFileExportData -Delimiter "," -encoding UTF7
 
    echo (""+$files.Count +" Dateien werden exportiert.")

    foreach($file in $files){

    $DestinationFile = ($file.Directory.Trim()+ '\' +$file.Filename.Trim())
    If ($DestinationFile.Length -gt 256)
    {
        echo "Kürzen";
       $length = $file.Directory.Trim().Length - 256;
       if ($length -gt (20 + $file.ObjId.Trim().length))
       {  
          $ext = [System.IO.Path]::GetFileNameWithoutExtension($file.Filename.Trim());
          if ($ext)  
          {
            $filename2 = $file.Filename.Trim();
            $filename2 = $filename2.Substring(0, $length - $ext.length) + $file.ObjId.Trim() +$ext ;
            $DestinationFile = ($file.Directory.Trim()+ '\' +$filename2)
          }
          else
          {
             echo ($file.Filename +' wird übersprungen');
             continue;
          }
       }
       else 
       {
         echo ($file.Filename +' wird übersprungen');
         continue;
       }
    } 

    If ((Test-Path $file.Directory) -eq $false) {
        New-Item -ItemType Directory -Path $file.Directory.Trim() -Force
    } 

      Copy-Item -Path $file.Source -Destination $DestinationFile.Trim();

      If ((Test-Path $file.Directory) -eq $true)
      {
         echo ("Exportiert: "+$file.filename)
      }


    }
}