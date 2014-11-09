using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.SessionState;

namespace nmap2web {
    public class Global : System.Web.HttpApplication {

        protected void Application_Start(object sender, EventArgs e) {
            string _connStr = ConfigurationManager.ConnectionStrings["nmap2webdb"].ConnectionString;
            string sql1 = @"
IF OBJECT_ID('dbo.port_scripts') IS NOT NULL
BEGIN
    DROP VIEW [dbo].[port_scripts]
END
GO
CREATE VIEW [dbo].[port_scripts]
    AS
    SELECT        dbo.scripts.id, dbo.ports.service_name, dbo.ports.portid, dbo.ports.protocol, dbo.ports.service_product, dbo.ports.service_extrainfo, dbo.scripts.output, 
                         dbo.ports.address
    FROM            dbo.scripts RIGHT OUTER JOIN
                         dbo.ports ON dbo.scripts.address = dbo.ports.address AND dbo.scripts.port = dbo.ports.portid

GO
IF OBJECT_ID('dbo.host_scripts') IS NOT NULL
BEGIN
DROP VIEW [dbo].[host_scripts]
END
GO
CREATE VIEW [dbo].[host_scripts]
AS
SELECT        dbo.scripts.id, '' AS service_name, '' AS portid, '' AS protocol, '' AS service_product, '' AS service_extrainfo, dbo.scripts.output, dbo.hosts.address
FROM            dbo.hosts RIGHT OUTER JOIN
                         dbo.scripts ON dbo.hosts.address = dbo.scripts.address
WHERE        (dbo.scripts.port IS NULL) OR
                         (dbo.scripts.port = '')
GO
IF OBJECT_ID('dbo.all_scripts') IS NOT NULL
BEGIN
DROP VIEW [dbo].[all_scripts]
END
GO
CREATE VIEW [dbo].[all_scripts]
AS
SELECT        *
FROM            dbo.host_scripts 
union all select *
from                         dbo.port_scripts
";
            using (SqlConnection conn = new SqlConnection(_connStr)) {
                conn.Open();
                string []split = new string[] {"GO"};
                foreach(string s in sql1.Split(split, StringSplitOptions.RemoveEmptyEntries))
                using (SqlCommand cmd = new SqlCommand(s, conn)) {
                    cmd.ExecuteNonQuery();
                }
            }
        }

        protected void Session_Start(object sender, EventArgs e) {

        }

        protected void Application_BeginRequest(object sender, EventArgs e) {

        }

        protected void Application_AuthenticateRequest(object sender, EventArgs e) {

        }

        protected void Application_Error(object sender, EventArgs e) {

        }

        protected void Session_End(object sender, EventArgs e) {

        }

        protected void Application_End(object sender, EventArgs e) {

        }
    }
}