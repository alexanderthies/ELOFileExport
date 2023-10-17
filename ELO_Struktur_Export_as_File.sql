-- ###############################################################################################################################################################################################################
--  Author   : AT
--  Geändert von       : AT
--  Datum der Änderung : 16.10.2021
--  Mitwirkende        : AT
--  Kompatibilität     : 21.2.5
-- ###############################################################################################################################################################################################################

 
-- Ziel Ordner angeben!
DECLARE @exportfolder nvarchar(max)  = 'C:\vfm\EXPORT'
----------------------------------------^^

-- ID des gewünschten Ordners angeben!
DECLARE @folderid int = 99999
------------------------^^

-- #######################################################################
-- ggf. vor zurücksetzen
/* 
   UPDATE Migration_ELODokumente SET exporterror = 0 WHERE exporterror = 1
   UPDATE Migration_ELODokumente SET exported = 0 WHERE exported = 1
*/


SET NOCOUNT ON
IF (@folderid <= 0) 
  RAISERROR ('ELO Ordner Id wurde nicht angegeben!', 18, 1);  

IF (@exportfolder = '' OR @exportfolder = null) 
  RAISERROR ('Ziel Ordner wurde nicht angegeben!', 18, 1); 
   
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'exported' AND Object_ID = Object_ID(N'Migration_ELODokumente'))
 ALTER TABLE Migration_ELODokumente ADD exported bit;

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'filename' AND Object_ID = Object_ID(N'Migration_ELODokumente'))
  ALTER TABLE Migration_ELODokumente ADD filename nvarchar(max); 


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'extension' AND Object_ID = Object_ID(N'Migration_ELODokumente'))
  ALTER TABLE Migration_ELODokumente ADD extension nvarchar(max); 


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'exporterror' AND Object_ID = Object_ID(N'Migration_ELODokumente'))
 ALTER TABLE Migration_ELODokumente ADD exporterror bit;

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ELOFileExport'))
BEGIN
  CREATE TABLE ELOFileExport
  (
     Source nvarchar(256),
     Directory nvarchar(256),
	 Filename nvarchar(256),
	 ObjId int,
  )
END
ELSE
    DELETE FROM ELOFileExport


-- Es wird heiß, Variablen deklarieren
DECLARE
        @folderpath nvarchar(max),
        @copydestination nvarchar(1000),
        @copydestinationfile nvarchar(1000),
		@filename nvarchar(max),
		@filesource nvarchar(1000),
		@fileextension nvarchar(max),
		@exported bit,
        @count int = 0,
		@total int = 0,
		@docobjectguid uniqueidentifier,
		@vFileExists int,
		@objid int; 

-- Temp - Tabelle mit allen nötigen Daten erzeugen
-- Nicht Exportierte Dokumente (und ohne Exportfehler) aus Migration_ELODokumente 
-- die unterhalb eines bestimmten Ordners (Migration_ELODokEbenen, siehe @folderid) liegen
SELECT * INTO #ExportDoks FROM (
SELECT md.docobjguid, md.objid FROM Migration_ELODokumente MD 
JOIN Migration_ELODokEbenen MDE on MDE.docobjguid = MD.docobjguid
WHERE (exported = 0 OR exported is null) AND (exporterror = 0 OR exporterror is null)
AND ebenenid = @folderid) as x 


SELECT @total = COUNT(*) FROM #ExportDoks

IF (@total <= 0)
  RAISERROR ('Keine Exportierbaren Dokumente! Es gibt nichts zu tun! Stimmt die ELO - Ordner ID?', 18, 1); 
ELSE
BEGIN
  
	--filename generieren bzw. alle Sonderzeichen entfernen
 
	--PRINT 'Dateiname generieren und von Sonderzeichen befreien'

	UPDATE Migration_ELODokumente SET [filename] = REPLACE(objshort,'\','')
	UPDATE Migration_ELODokumente SET [filename] = REPLACE([filename],'/','')
	UPDATE Migration_ELODokumente SET [filename] = REPLACE([filename],':','')
	UPDATE Migration_ELODokumente SET [filename] = REPLACE([filename],'*','')
	UPDATE Migration_ELODokumente SET [filename] = REPLACE([filename],'?','')
	UPDATE Migration_ELODokumente SET [filename] = REPLACE([filename],'"','')
	UPDATE Migration_ELODokumente SET [filename] = REPLACE([filename],'<','')
	UPDATE Migration_ELODokumente SET [filename] = REPLACE([filename],'>','')
	UPDATE Migration_ELODokumente SET [filename] = REPLACE([filename],'|','')
	UPDATE Migration_ELODokumente SET extension = LOWER(RIGHT([path], LEN([path]) - CHARINDEX('.', [path])))  

	--PRINT CONCAT(@count, ' Datensätze - Zeit zum Kaffee holen?')
	--PRINT CONCAT('Begin ', GETDATE())

	--Export start
	WHILE (SELECT COUNT(*) FROM #ExportDoks) > 0
	BEGIN
		SELECT TOP 1 @docobjectguid = docobjguid, @objid = [objid] FROM #ExportDoks

		--Pfad erzeugen
 		SET @folderpath = (SELECT DISTINCT 
		SUBSTRING((SELECT 
				'\'+Replace(MDE2.ebenenname,'/','_')  AS [text()]
				FROM Migration_ELODokEbenen MDE2
				WHERE MDE2.docobjguid = MDE.docobjguid and ebenenguid <> @docobjectguid
				ORDER BY MDE2.ebenenposition desc
				FOR XML PATH ('')
			), 2, 1000) [PATH]
			FROM Migration_ELODokEbenen MDE  
			WHERE docobjguid = @docobjectguid)  

		-- Filename mit Extension erzeugen und Quell-Pfad holen
		SELECT 
		  @filename = CONCAT(iif (len([filename])> 90,SUBSTRING([filename],0,85),[filename]),'_',@objid, '.', [extension]), 
		  @filesource = [path] 
		FROM Migration_ELODokumente where docobjguid = @docobjectguid 
		-- Ziel Ordner-und Datei Pfad zusammenstellen
		SELECT @copydestination = CONCAT(@exportfolder,'\',@folderpath,'\',@filename) 
		SELECT @copydestinationfile = CONCAT(@exportfolder,'\',@folderpath) 

		SET @count = @count +1;
		-- Ausgabe x/total, Dok Guid und Pfad, ggf. Troubleshooting
        
		--PRINT CONCAT(@count,'/',@total, ' |',@docobjectguid,'| ',' Copydestination ', @copydestination)

		
		     IF (SELECT Count(*) FROM ELOFileExport WHERE (Objid = @objid)) = 0 AND (ISNULL(@filesource,'') <> '')
			 BEGIN
			  INSERT INTO ELOFileExport (Source, Directory, Filename, objid) Values (rtrim(ltrim(@filesource)), rtrim(ltrim(@copydestinationfile)), ltrim(rtrim(@filename)), @objid)
			  --UPDATE Migration_ELODokumente SET exported = 1 WHERE docobjguid = @docobjectguid;
			 END

		DELETE FROM #ExportDoks WHERE objid = @objid;
	END
	
    SELECT * FROM ELOFileExport
--  PRINT CONCAT('End ', GETDATE())  
END

DROP TABLE #ExportDoks  
 