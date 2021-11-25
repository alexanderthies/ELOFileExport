param($p1, $p2)

##--Option 1 - Über ISE
 

#--Exportordner Pfad angeben!
$Zielpfad = "C:\vfm\EXPORT";
#------------^^

#-- ID des gewünschten ELO Ordners angeben!
$OrdnerId = 0;
#----------^^


# Jetzt |> "Skript ausführen" oder F5 betätigen  

##--Option 2

# ODER ps1 über PowerShell mit Parameter aufrufen
# .\ELOFileExport.ps1 "C:\\vfm\EXPORT" 70681

if ($p1 -eq $null -And $p2 -eq $null)
{
  echo x;
}
else
{
  $Zielpfad = $p1;
  $OrdnerId=  $p2;
}

write-host ("Exportordner: "+ $Zielpfad ) -ForegroundColor Green

if ($OrdnerId -eq 0)
{
  write-host ("OrdnerId wurde nicht angegeben!") -ForegroundColor Red
  return;
}

$ELOFileExportData = "ELOFileExportData.csv"    
$sqlscript = "sp_CreateExport_List.sql";

echo 'Datenbankinfo laden'
If ((Test-Path "DatenbankVerbindung.xml") -eq $true)
{
    If ((Test-Path $sqlscript) -eq $false)
    {
      write-host ($sqlscript +" wurde nicht gefunden." ) -ForegroundColor Red
      return;
    }
     
    $conn = Select-Xml -Path DatenbankVerbindung.xml -XPath 'xml/DatabaseConnection' | ForEach-Object { $_.Node.InnerXML }
    $connectionsstring = '';
    try { $connectionsstring = [Convert]::FromBase64String("$conn ")}
    catch { $connectionsstring = $conn; }

    if ($connectionsstring -eq "")
    {    
        write-host "Connectionstring ist leer!" -ForegroundColor Red
        Return;
    }


    $Connection = New-Object System.Data.SQLClient.SQLConnection
    $Connection.ConnectionString = $connectionsstring
    $Connection.Open()
    $command = $Connection.CreateCommand()

    #proc anlegen
    $createSP_query = Get-Content sp_CreateExport_List.sql -Raw;
    $command.CommandText = $createSP_query;
    $command.ExecuteNonQuery()  | out-null;
    
    #proc ausführen
    echo 'ELO Struktur Export - Script ausführen'
    $command.CommandType = [System.Data.CommandType]::StoredProcedure
    $command.CommandText = "dbo.#sp_CreateExport_List";

    $Parameter1 = new-object System.Data.SqlClient.SqlParameter; 
    $Parameter2 = new-object System.Data.SqlClient.SqlParameter;

    $Parameter1.ParameterName = "@exportfolder";
    $Parameter1.Value =$Zielpfad; 

    $Parameter2.ParameterName = "@folderid";
    $Parameter2.Value =$OrdnerId;

    $command.Parameters.Add($Parameter1)  | out-null;
    $command.Parameters.Add($Parameter2)  | out-null;        
    
    $command.ExecuteNonQuery();

    #Ergebnis abfragen
    $command.CommandType = [System.Data.CommandType]::Text
    $command.CommandText = "SELECT * FROM ELOFileExport";
    $result = $command.ExecuteReader();
    
    $Datatable = New-Object System.Data.Datatable  
    $Datatable.Load($result);

    if($Datatable.Rows.Count -lt 0)
    {
       write-host "Keine Dateien gefunden!";
        Return;
    }

    #Ergebnis speichern
    echo  'ELOFileExportData.csv erstellen'

    $Datatable | Export-Csv $ELOFileExportData -notypeinformation -Encoding UTF8
    $connection.Close();     
}
ELSE  
  {
     write-host ("Datenbankverbindungs.xml Konnte nicht gefunden werden, bitte SQL Script manuell ausführen oder ") -ForegroundColor DarkYellow
     # Alternative
     # sqlcmd -S sqlinstance -d database -i "ELO_Struktur_Export_as_File.sql" -o "ELOFileExportData.csv" -h-1 -s";"
     write-host ("PowerShell Command: " + 'sqlcmd -S sqlserverinstance -d database -i "ELO_Struktur_Export_as_File.sql" -o "ELOFileExportData.csv" -h-1 -s";"' ) -ForegroundColor DarkCyan

  }

If ((Test-Path $ELOFileExportData) -eq $false)
{
  write-host ($ELOFileExportData +" wurde nicht gefunden, wurde das Export-Script ausgeführt?" ) -ForegroundColor Red
}
ELSE
{

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
