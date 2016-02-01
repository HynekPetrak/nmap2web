#!/bin/sh

nmap -p T:110,137,139,445,143,17185,1900,21,22,23,25,389,80,8080,5353,5900,443,10000,3306,1433,993,995,873,8118,3128,111,79,3260,8222,8333 --script ssl-heartbleed,ms-sql-info,iscsi-info,http-vuln-cve2010-0738,http-vmware-path-vuln,snmp-interfaces,snmp-netstat,snmp-sysdescr,mysql-info,banner,ftp-anon,ldap-rootdse,http-headers,http-title,vnc-info,realvnc-auth-bypass,imap-capabilities,pop3-capabilities,finger,http-methods,rpcinfo,http-open-proxy,rsync-list-modules,nbstat,nfs-ls,nfs-showmount,nfs-statfs,p2p-conficker,smb-os-discovery,smb-check-vulns --script-args=checkconficker=1,safe=1 -oX nmapoutput.xml -oG nmapoutput.txt -sS -Pn -sV --max-retries 2 --open your_ip_address_list_goes_here