# nmap2web
Full text search engine for nmap  results. Written in C# ASP.NET

It consists of three parts:

# nmap command to scan particular network range, collecting metadata through nse scripts and saving results into the nmap XML format
# XLS transformation to convert nmap output into a T-SQL script for direct import into a MS SQL database
# ASP.NET application providing full text search through nmap results

!! Usage

The search field accepts following commands or any combination of them:
* *word1 word2* - matches "word1" and "word2"
* *word1 !word2* - matches "word1" and not "word2"
* *ip:a.b.c.d* - shows all records for ip address a.b.c.d
* *script:xyz* - shows all entries detected by nmap nse script "xyz"
* *net:a.b.c* - shows all entries for the subnet a.b.c.*
* *port:aaa,bbb* - shows all entries for a network port aaa or bbb, e.g. 80,443 for http/https

!! Screenshots

Some of the examples with blended IP addresses and host names.

_Full text search example_
[image:screen_fulltext.png]

_List all available information about single host_
[image:screen_ip.png]

_Detect available nfs servers_
[image:screen_detectnfs.png]

_Detect host with heartbleed bug_
[image:screen_detectheartbleed.png]
