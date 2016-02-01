# nmap2web
Full text search engine for nmap  results. Written in C# ASP.NET

## Components

### Nmap command

nmap command to scan particular network range, collecting metadata through nse scripts and saving results into the nmap XML format

### XSLT transformation into SQL

XLS transformation to convert nmap output into a T-SQL script for direct import into a MS SQL database

### ASP.NET app for full text search

ASP.NET application providing full text search through nmap results

## Usage

The search field accepts following commands or any combination of them:

- **word1 word2** - matches "word1" and "word2"
- **word1 !word2** - matches "word1" and not "word2"
- **ip:a.b.c.d** - shows all records for ip address a.b.c.d
- **script:xyz** - shows all entries detected by nmap nse script "xyz"
- **net:a.b.c** - shows all entries for the subnet a.b.c.\*
- **port:aaa,bbb** - shows all entries for a network port aaa or bbb, e.g. 80,443 for http/https

## Screenshots / Examples

_(The IP addresses and hostnames are masked)_

__Full text search example__
![fulltext.png](images/screen_fulltext.png)

__List all available information about single host__
![ip.png](images/screen_ip.png)

__Detect available nfs servers__
![detectnfs.png](images/screen_detectnfs.png)

__Detect host with heartbleed bug__
![detectheartbleed.png](images/screen_detectheatbleed.png)
