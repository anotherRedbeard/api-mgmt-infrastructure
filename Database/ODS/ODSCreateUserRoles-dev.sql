CREATE USER [ar-scus-salesapi-fa-dev] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [ar-scus-salesapi-fa-dev];
ALTER ROLE db_datawriter ADD MEMBER [ar-scus-salesapi-fa-dev];
GO

CREATE USER [ar-scus-productionapi-fa-dev] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [ar-scus-productionapi-fa-dev];
ALTER ROLE db_datawriter ADD MEMBER [ar-scus-productionapi-fa-dev];
GO