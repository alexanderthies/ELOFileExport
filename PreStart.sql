	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'exported' AND Object_ID = Object_ID(N'Migration_ELODokumente'))
	 ALTER TABLE Migration_ELODokumente ADD exported bit;

	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'filename' AND Object_ID = Object_ID(N'Migration_ELODokumente'))
	  ALTER TABLE Migration_ELODokumente ADD filename nvarchar(max); 


	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'extension' AND Object_ID = Object_ID(N'Migration_ELODokumente'))
	  ALTER TABLE Migration_ELODokumente ADD extension nvarchar(max); 


	IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'exporterror' AND Object_ID = Object_ID(N'Migration_ELODokumente'))
	 ALTER TABLE Migration_ELODokumente ADD exporterror bit;