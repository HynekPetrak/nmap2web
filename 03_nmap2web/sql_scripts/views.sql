USE [nmap2web]
GO

/****** Object:  View [dbo].[all_scripts]    Script Date: 28.8.2014 14:23:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[port_scripts]
AS
SELECT        dbo.scripts.id, dbo.ports.service_name, dbo.ports.portid, dbo.ports.protocol, dbo.ports.service_product, dbo.ports.service_extrainfo, dbo.scripts.output, 
                         dbo.ports.address
FROM            dbo.scripts RIGHT OUTER JOIN
                         dbo.ports ON dbo.scripts.address = dbo.ports.address AND dbo.scripts.port = dbo.ports.portid

GO

CREATE VIEW [dbo].[host_scripts]
AS
SELECT        dbo.scripts.id, '' AS service_name, '' AS portid, '' AS protocol, '' AS service_product, '' AS service_extrainfo, dbo.scripts.output, dbo.hosts.address
FROM            dbo.hosts RIGHT OUTER JOIN
                         dbo.scripts ON dbo.hosts.address = dbo.scripts.address
WHERE        (dbo.scripts.port IS NULL) OR
                         (dbo.scripts.port = '')
GO

CREATE VIEW [dbo].[all_scripts]
AS
SELECT        *
FROM            dbo.host_scripts 
union all select *
from                         dbo.port_scripts

GO


