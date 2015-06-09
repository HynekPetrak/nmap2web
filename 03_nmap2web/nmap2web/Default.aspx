
<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="nmap2web.Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <script src="s/jquery-1.11.1.js"></script>
    <title>nmap2web</title>
    <link href="Site.css" rel="stylesheet" />
    <script type="text/javascript">
        function CClick() {
            $('#Bookmark').val("Bookmark");
            $('#Bookname').hide();
            $('#CancelBtn').hide();
        }
        function BClick() {
            var a = $('#Bookmark').val();
            if ($('#Bookmark').val() == "Save") {
                if ($('#Bookname').val().length == 0) {
                    alert("Specify bookmark name");
                } else {
                    $.ajax({
                        type: "POST",
                        url: "Default.aspx/SaveBookmark",
                        data: '{name: "' + $("#<%=Bookname.ClientID%>").val() + '",' +
                              'value: "' + $("#<%=What.ClientID%>").val() + '"}',
                        contentType: "application/json; charset=utf-8",
                        dataType: "json",
                        success: OnSuccess,
                        failure: function (response) {
                            alert(response.d);
                        }
                    });
                    $('#Bookmark').val("Bookmark");
                    $('#Bookname').hide();
                    $('#CancelBtn').hide();
                }
            } else {
                $('#Bookmark').val("Save");
                var a = $('#Bookname');
                $('#Bookname').val($('#What').val());
                $('#Bookname').show();
                $('#CancelBtn').show();
            }
        }
        function OnSuccess(response) {
            alert(response.d);
        }
    </script>
</head>
<body>
    <asp:SqlDataSource EnableCaching="false" runat="server" ID="BookSource" ConnectionString='<%$ ConnectionStrings:nmap2webdb %>' SelectCommand="SELECT [name], [search], [searchenc] FROM [bookmarks]"></asp:SqlDataSource>
    <form id="form1" runat="server" action="Default.aspx">
        <header>
            <div class="content-wrapper">
                <h3>nmap2web metadata search engine</h3>
                <asp:TextBox ID="What" runat="server" Width="387px" ToolTip="Hint: net:10.134.5 script:ftp-anon port:80,443 contain !donot"></asp:TextBox><asp:Button ID="Search" runat="server" Text="Search" OnClick="Search_Click" />
                <span>
                    <asp:TextBox ID="Bookname" runat="server" Width="200px" Style="display: none;"></asp:TextBox>
                    <asp:Button ID="Bookmark" runat="server" Text="Bookmark" OnClientClick="BClick(); return false;" /><asp:Button ID="CancelBtn" runat="server" Text="Cancel" OnClientClick="CClick(); return false;" Style="display: none;" />
                </span>
                <asp:DropDownList runat="server" ID="BookmarksList" DataSourceID="BookSource" AutoPostBack="true"
                         DataTextField="name" DataValueField="search" OnSelectedIndexChanged="BookmarksList_SelectedIndexChanged"></asp:DropDownList>
                <asp:Label ID="EmptyResultLabel" runat="server" ForeColor="Red"></asp:Label>
            </div>
        </header>

        <div class="main-content">

            <asp:GridView ID="Results" runat="server" AllowPaging="True" OnPageIndexChanging="Results_PageIndexChanging"
                OnSorting="Results_Sorting" DataSourceID="ResultsDataSource"
                PagerSettings-Position="TopAndBottom" AlternatingRowStyle-BackColor="#F4F4F4"
                HeaderStyle-BackColor="#3399ff" HeaderStyle-ForeColor="White" AllowSorting="True" 
                ShowFooter="true" FooterStyle-BackColor="#3399ff" FooterStyle-ForeColor="White"
                AutoGenerateColumns="False" CssClass="results" PageSize="20"
                SortedAscendingHeaderStyle-CssClass="asc" SortedDescendingHeaderStyle-CssClass="desc"
                OnRowDataBound="Results_RowDataBound" ShowHeaderWhenEmpty="false" OnDataBound="Results_DataBound">


                <PagerTemplate>

                    <table class="pager" style="width: 100%">
                        <tr>
                            <td style="width: 70%;">
                                <asp:Label ID="totallbl" runat="server" CssClass="pager-text"></asp:Label>
                                <asp:ImageButton ID="buttonFirst" AlternateText="First Page"
                                     CommandName="Page" CommandArgument="first"
                                    ImageUrl="~/img/first.png" runat="server" />
                                <asp:ImageButton ID="buttonPrevious" AlternateText="" 
                                    CommandName="Page" CommandArgument="prev"
                                    ImageUrl="~/img/prev.png" runat="server" />
                                <asp:Label ID="MessageLabel"
                                    Text="Select a page:"
                                    runat="server" CssClass="pager-text" />
                                <asp:DropDownList ID="PageDropDownList"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="PageDropDownList_SelectedIndexChanged"
                                    runat="server" CssClass="pager-text" />
                               <asp:ImageButton ID="buttonNext" AlternateText=""
                                   CommandName="Page"  CommandArgument="next" 
                                   ImageUrl="~/img/next.png"
                                    runat="server" />
                                <asp:ImageButton ID="buttonLast" AlternateText="Last Page"
                                    CommandName="Page"  CommandArgument="last"
                                    ImageUrl="~/img/last.png" runat="server" />
                                 <asp:Label ID="Label1"
                                    Text="Results per page:"
                                    runat="server" CssClass="pager-text" />
                                <asp:DropDownList ID="SizeDropDownList"
                                    AutoPostBack="true"
                                    OnSelectedIndexChanged="SizeDropDownList_SelectedIndexChanged"
                                    runat="server" CssClass="pager-text" > 
                                    <asp:ListItem Value="10" />
                                    <asp:ListItem Value="20" />
                                    <asp:ListItem Value="30" />
                                </asp:DropDownList>
                          

                                <asp:Label ID="CurrentPageLabel"
                                    runat="server" CssClass="pager-text"  />

                            </td>

                        </tr>
                    </table>

                </PagerTemplate>

                <Columns>
                    <asp:TemplateField HeaderText="Host" SortExpression="address" FooterText="Host">
                        <ItemTemplate>
                            <!-- <a href="host.aspx?host=<%# Eval("address") %>"><%# Eval("address") %></a> -->

                            <a href="?what=ip:<%# Eval("address") %>">
                                <asp:Label ID="Address" runat="server" Text='<%# Eval("address") %>' /></a><br />
                            <asp:Label ID="hostlbl" runat="server" CssClass="hostnames" />
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Port" SortExpression="portid" FooterText="Port">
                        <ItemTemplate>
                            <%# GetPortLink(Eval("address").ToString(),
                                   Eval("portid").ToString(),
                                   Eval("service_name").ToString(),
                                   Eval("protocol").ToString())  %>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Product" SortExpression="service_product" FooterText="Protuct">
                        <ItemTemplate>
                            <%# HighlightText(Eval("service_product").ToString())  %>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Extra Info" SortExpression="service_extrainfo" FooterText="Extra Info">
                        <ItemTemplate>
                            <%# HighlightText(Eval("service_extrainfo").ToString())  %>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField HeaderText="Check" SortExpression="id" FooterText="Check">
                        <ItemTemplate>
                    <a href="?what=script:<%# Eval("id") %>">
                                <asp:Label ID="Script" runat="server" Text='<%# Eval("id") %>' /></a>
                            </ItemTemplate>
                        </asp:TemplateField>

                    <asp:TemplateField HeaderText="Output" SortExpression="output" FooterText="Output">
                        <ItemTemplate>
                            <%# HighlightText(Eval("output").ToString())  %>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
            <asp:SqlDataSource ID="ResultsDataSource" runat="server"
                ConnectionString="<%$ ConnectionStrings:nmap2webdb %>" OnSelected="ResultsDataSource_Selected"></asp:SqlDataSource>
        </div>
    </form>
</body>
</html>
