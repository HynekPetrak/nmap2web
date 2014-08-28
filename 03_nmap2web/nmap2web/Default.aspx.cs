using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

/* 
 * Copyright (c) Hynek Petrak 2014 
 * Distributed under the GPLv3 license
 */

namespace nmap2web {

    public static class StringExtensions {
        public static string[] SplitWithQualifier(this string text,
                                                      char delimiter,
                                                      char qualifier,
                                                      bool stripQualifierFromResult) {
            string pattern = string.Format(
                @"{0}(?=(?:[^{1}]*{1}[^{1}]*{1})*(?![^{1}]*{1}))",
                Regex.Escape(delimiter.ToString()),
                Regex.Escape(qualifier.ToString())
            );

            string[] split = Regex.Split(text, pattern);

            if (stripQualifierFromResult)
                return split.Select(s => s.Trim().Trim(qualifier)).ToArray();
            else
                return split;
        }

        public static string Truncate(this string value, int maxLength) {
            if (string.IsNullOrEmpty(value)) return value;
            return value.Length <= maxLength ? value : value.Substring(0, maxLength);
        }

    }

    public partial class Default : System.Web.UI.Page {
        protected void Page_Load(object sender, EventArgs e) {
            string w = Request.QueryString["what"];
            if (!string.IsNullOrWhiteSpace(w)) {
                What.Text = w;
                ReBind();
            }
        }

        List<string> to_highlight = new List<string>();
        int row_count = 0;

        protected void ReBind() {
            string cmd_str = "SELECT * " +
                "FROM all_scripts ";

            to_highlight = new List<string>();
            string[] in_str = What.Text.SplitWithQualifier(' ', '\"', true);
            List<string> whs = new List<string>();
            Dictionary<string, string> pms = new Dictionary<string, string>();
            int counter = 0;
            foreach (string tok2 in in_str) {
                if (string.IsNullOrWhiteSpace(tok2)) {
                    continue;
                }
                bool reverse;
                string tok;
                if (tok2.StartsWith("!")) {
                    tok = tok2.Substring(1);
                    reverse = true;
                } else {
                    tok = tok2;
                    reverse = false;
                }
                string pname = "p" + counter++;
                if (tok.Contains(":")) {
                    string[] cmd = tok.Split(":".ToCharArray());
                    List<string> st = new List<string>();
                    string[] values = cmd[1].Split(",".ToCharArray());
                    switch (cmd[0]) {
                        case "net":
                            foreach (string net in values) {
                                st.Add(string.Format("(address like {0})", "@" + pname));
                                pms[pname] = net + "%";
                                pname = "p" + counter++;
                            }
                            break;
                        case "ip":
                            foreach (string net in values) {
                                st.Add(string.Format("(address = {0})", "@" + pname));
                                pms[pname] = net;
                                pname = "p" + counter++;
                            }
                            break;
                        case "port":
                            foreach (string port in values) {
                                st.Add(string.Format("(portid = {0})", "@" + pname));
                                pms[pname] = port;
                                pname = "p" + counter++;
                            }
                            break;
                        case "script":
                            foreach (string sc in values) {
                                st.Add(string.Format("(id like {0})", "@" + pname));
                                pms[pname] = "%" + sc + "%";
                                pname = "p" + counter++;
                            }
                            break;
                        default:
                            break;
                    }
                    string c = string.Join(" or ", st);
                    if (c != "") {
                        c = "(" + c + ")";
                        if (reverse) {
                            c = "NOT " + c;
                        }
                        whs.Add(c);
                    }
                    continue;
                } else {
                    to_highlight.Add(tok);
                    pms[pname] = "%" + tok + "%";
                    string s = string.Format("(([output] LIKE {0}) or " +
                "([service_product] LIKE {0}) or " +
                "([service_extrainfo] LIKE {0}))", "@" + pname);
                    if (reverse) {
                        s = "NOT " + s;
                    }
                    whs.Add(s);
                }
            }
            string cmd_where = string.Join(" and ", whs.ToArray());
            if (!string.IsNullOrWhiteSpace(cmd_where)) {
                cmd_str += " WHERE " + cmd_where;
            }
            cmd_str += " order by address, portid, id";
            ResultsDataSource.SelectParameters.Clear();
            foreach (string p in pms.Keys) {
                ResultsDataSource.SelectParameters.Add(p, pms[p]);
            }
            ResultsDataSource.SelectCommand = cmd_str;

            Results.DataBind();
        }

        protected void Search_Click(object sender, EventArgs e) {
            ReBind();
            Results.PageIndex = 0;
        }

        protected string Sanitize(string inputText) {
            string s;
            s = HttpUtility.HtmlEncode(inputText.Trim().Truncate(1024));
            s = s.Replace("\n", "<br/>").Replace("\r", "");
            return s;
        }

        [System.Web.Services.WebMethod]
        public static string SaveBookmark(string name, string value) {
            try {
                string _connStr = ConfigurationManager.ConnectionStrings["nmap2webdb"].ConnectionString;

                using (SqlConnection conn = new SqlConnection(_connStr)) {
                    conn.Open();
                    string sql = "delete from [dbo].[bookmarks] WHERE [name] = @name; "+ 
                        "INSERT INTO [dbo].[bookmarks] ([name],[search],[searchenc],[username]) " +
                "VALUES (@name, @search, @searchenc, @username)";
                    using (SqlCommand cmd = new SqlCommand(sql, conn)) {
                        cmd.Parameters.AddWithValue("@name", name);
                        cmd.Parameters.AddWithValue("@search", value);
                        cmd.Parameters.AddWithValue("@searchenc", HttpUtility.UrlEncode(value));
                        cmd.Parameters.AddWithValue("@username",
                            System.Web.HttpContext.Current.User.Identity.Name);
                        cmd.ExecuteNonQuery();
                    }
                }
            } catch (Exception ex) {
                return "Error occured: " + ex.Message;
            }
                    
            return "Saved '" +value+ "' as '"+ name +"'";
        }

        protected string HighlightText(string inputText) {
            inputText = Sanitize(inputText);
            if (to_highlight.Count == 0)
                return inputText;
            string searchWord = string.Join("|", to_highlight);
            Regex expression = new Regex(searchWord.Replace(" ", "|"), RegexOptions.IgnoreCase);
            return expression.Replace(inputText, new MatchEvaluator(ReplaceKeywords));

        }

        protected string GetPortLink(string address, string portid, string service_name, string protocol) {  
            if (portid.Length <= 0)
                return "";
            string service_name2;
            switch (portid) {
                case "443":
                    service_name2 = "https";
                    break;
                case "80":
                    service_name2 = "http";
                    break;
                default:
                    service_name2 = service_name;
                    break;
            }
            string r = "<a href=" + service_name2 + "://" + address + ":" + portid +">";
            r += portid + "/" + protocol + " (" + service_name + ") </a>";
            return r;
        }

        public string ReplaceKeywords(Match m) {
            return "<span class='highlight'>" + m.Value + "</span>";
        }

        protected void Results_PageIndexChanging(object sender, GridViewPageEventArgs e) {
            ReBind();
        }

        protected void Results_Sorting(object sender, GridViewSortEventArgs e) {
            ReBind();
        }

        protected void ResultsDataSource_Selected(object sender, SqlDataSourceStatusEventArgs e) {
            if (e.Exception == null) {
                row_count = e.AffectedRows;
            } else {
                row_count = 0;
            }
            if (row_count == 0) {
                EmptyResultLabel.Text = "<br />No records found";
            } else {
                EmptyResultLabel.Text = "";
            }
        }

        protected void Results_RowDataBound(object sender, GridViewRowEventArgs e) {
            if (e.Row.RowType == DataControlRowType.DataRow) {
                Label lbl = (Label)e.Row.FindControl("hostlbl");
                Label addr = (Label)e.Row.FindControl("Address");

                if (lbl != null && addr != null) {
                    DataTable table = new DataTable();
                    string _connStr = ConfigurationManager.ConnectionStrings["nmap2webdb"].ConnectionString;

                    using (SqlConnection conn = new SqlConnection(_connStr)) {
                        string sql = "SELECT name FROM hostnames WHERE address = @address";
                        using (SqlCommand cmd = new SqlCommand(sql, conn)) {
                            SqlParameter prm = new SqlParameter("@address", addr.Text);
                            cmd.Parameters.Add(prm);
                            using (SqlDataAdapter ad = new SqlDataAdapter(cmd)) {
                                ad.Fill(table);
                            }
                        }
                    }
                    foreach (DataRow row in table.Rows) {
                        lbl.Text += row["name"] + "<br />";
                    }
                }
            }
        }

        protected void AdjustPager(GridViewRow pagerRow) {
            DropDownList sizeList = (DropDownList)pagerRow.Cells[0].FindControl("SizeDropDownList");
            if (sizeList != null) {
                sizeList.SelectedValue = Results.PageSize.ToString();
            }

            DropDownList pageList = (DropDownList)pagerRow.Cells[0].FindControl("PageDropDownList");
            if (pageList != null) {
                for (int i = 0; i < Results.PageCount; i++) {
                    int pageNumber = i + 1;
                    ListItem item = new ListItem(pageNumber.ToString());
                    if (i == Results.PageIndex) {
                        item.Selected = true;
                    }
                    pageList.Items.Add(item);
                }
            }

            Label pageLabel = (Label)pagerRow.Cells[0].FindControl("CurrentPageLabel");
            if (pageLabel != null) {
                int currentPage = Results.PageIndex + 1;
                pageLabel.Text = "Page " + currentPage.ToString() +
                  " of " + Results.PageCount.ToString();
            }

            Label totallbl = (Label)pagerRow.Cells[0].FindControl("totallbl");
            totallbl.Text = String.Format("{0} entries found", row_count);
        }

        protected void Results_DataBound(object sender, EventArgs e) {
            GridViewRow pagerRow = Results.BottomPagerRow;
            if (pagerRow != null) {
                pagerRow.Visible = true;
                AdjustPager(pagerRow);
            }

            pagerRow = Results.TopPagerRow;
            if (pagerRow != null) {
                pagerRow.Visible = true;
                AdjustPager(pagerRow);
            }
        }

        protected void PageDropDownList_SelectedIndexChanged(object sender, EventArgs e) {
            //GridViewRow pagerRow = Results.TopPagerRow;
            //DropDownList pageList = (DropDownList)pagerRow.Cells[0].FindControl("PageDropDownList");
            DropDownList pageList = (DropDownList)sender;
            Results.PageIndex = pageList.SelectedIndex;
            ReBind();
        }
        protected void SizeDropDownList_SelectedIndexChanged(object sender, EventArgs e) {
            //GridViewRow pagerRow = Results.TopPagerRow;
            //DropDownList sizeList = (DropDownList)pagerRow.Cells[0].FindControl("SizeDropDownList");
            DropDownList sizeList = (DropDownList)sender;
            Results.PageSize = Convert.ToInt32(sizeList.SelectedValue);
            ReBind();
        }
    }
}