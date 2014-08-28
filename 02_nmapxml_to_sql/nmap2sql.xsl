<?xml version="1.0"?>
<!-- 
  nmap2sql.xsl stylesheet version 0.1
  Author: Hynek Petrak   
 
  Copyright (c) Hynek Petrak 2014 
  Distributed under the GPLv3 license
     -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:date="http://exslt.org/dates-and-times"
xmlns:fo="http://www.w3.org/1999/XSL/Format">
  <xsl:output method="text" encoding="UTF-8" />

  <xsl:variable name="nmap2sql_version">0.1</xsl:variable>
  <xsl:variable name="start">
    <xsl:value-of select="/nmaprun/@startstr" />
  </xsl:variable>
  <xsl:variable name="end">
    <xsl:value-of select="/nmaprun/runstats/finished/@timestr" />
  </xsl:variable>
  <xsl:variable name="totaltime">
    <xsl:value-of select="/nmaprun/runstats/finished/@time -/nmaprun/@start" />
  </xsl:variable>
  <xsl:key name="portstatus" match="@state" use="."/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="/nmaprun">
    use nmap2sql;
    -----------------------------------------------------------------------
    -- generated with nmap2sql.xsl - version <xsl:value-of select="$nmap2sql_version" /> by Hynek Petrak
    -----------------------------------------------------------------------
    -- Nmap Scan Report - Scanned at <xsl:value-of select="$start" />
    --                    Finished at <xsl:value-of select="$end" />
    --                    Total time <xsl:value-of select="$totaltime" />
    --
    -- Cmd: Nmap <xsl:value-of select="@version" /> arguments: <xsl:value-of select="@args" />
    --
    -- create tables if not exist
    IF object_id('hosts', 'U') is null
    create table hosts (
    address nvarchar(MAX) NOT NULL,
    state nvarchar(10) NULL,
    seen nvarchar(30) NULL,
    starttime nvarchar(30) NULL,
    endtime nvarchar(30) NULL,
    )  ON [PRIMARY];
    IF object_id('hostnames', 'U') is null
    CREATE TABLE hostnames
    (
    name nvarchar(MAX) NULL,
    address nvarchar(MAX) NOT NULL
    )  ON [PRIMARY];
    IF object_id('ports', 'U') is null
    CREATE TABLE ports
    (
    address nvarchar(MAX) NOT NULL,
    state nvarchar(20) NULL,
    portid nvarchar(10) NOT NULL,
    protocol nvarchar(MAX) NULL,
    service_name nvarchar(MAX) NULL,
    state_reason nvarchar(50) NULL,
    state_reason_ip nvarchar(50) NULL,
    service_product nvarchar(MAX) NULL,
    service_version nvarchar(MAX) NULL,
    service_extrainfo nvarchar(MAX) NULL
    )  ON [PRIMARY];
    IF object_id('scripts', 'U') is null
    create table  scripts (
    address nvarchar(MAX) NOT NULL,
    port nvarchar(50) NOT NULL,
    id nvarchar(50) NOT NULL,
    output text null) ON [PRIMARY];
    IF object_id('bookmarks', 'U') is null
    BEGIN
    CREATE TABLE [dbo].[bookmarks] (
    [name] [nvarchar](max) NOT NULL,
    [search] [nvarchar](max) NOT NULL,
    [searchenc] [nvarchar](max) NOT NULL,
    [username] [nvarchar](50) NULL,
    [private] [bit] NOT NULL
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
    ALTER TABLE [dbo].[bookmarks] ADD  CONSTRAINT [DF_bookmarks_private]  DEFAULT ((0)) FOR [private]
    END

    <xsl:apply-templates select="host">
      <xsl:sort select="substring ( address/@addr, 1, string-length ( substring-before ( address/@addr, '.' ) ) )* (256*256*256) + substring ( substring-after ( address/@addr, '.' ), 1, string-length ( substring-before ( substring-after ( address/@addr, '.' ), '.' ) ) )* (256*256) + substring ( substring-after ( substring-after ( address/@addr, '.' ), '.' ), 1, string-length ( substring-before ( substring-after ( substring-after ( address/@addr, '.' ), '.' ), '.' ) ) ) * 256 + substring ( substring-after ( substring-after ( substring-after ( address/@addr, '.' ), '.' ), '.' ), 1 )" order="ascending" data-type="number"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="host">
    <xsl:variable name="var_addr" select="address/@addr" />
    <!-- translate(address/@addr, '.', '_') -->
    -- perform cleanup for <xsl:value-of select="$var_addr"/>
    delete from hosts where address =
    '<xsl:value-of select="$var_addr"/>';
    delete from hostnames where address =
    'do_not_delete<xsl:value-of select="$var_addr"/>';
    delete from ports where address =
    '<xsl:value-of select="$var_addr"/>';
    delete from scripts where address =
    '<xsl:value-of select="$var_addr"/>';


    -- insert updated values for <xsl:value-of select="$var_addr"/>
    insert into hosts (address, state, seen, starttime, endtime)
    values (
    '<xsl:value-of select="$var_addr"/>',
    '<xsl:value-of select="status/@state"/>',
    '<xsl:value-of select="$start"/>',
    '<xsl:value-of select="date:add('1970-01-01T00:00:00Z', date:duration(@starttime))"/>',
    '<xsl:value-of select="date:add('1970-01-01T00:00:00Z', date:duration(@endtime))"/>'
    );
    <xsl:for-each select="hostnames/hostname">
      insert into hostnames (name, address)
      values (
      '<xsl:value-of select="@name"/>',
      '<xsl:value-of select="$var_addr"/>'
      );
    </xsl:for-each>
    <xsl:for-each select="hostscript/script">
      insert into scripts (address, port, id, output) values (
      '<xsl:value-of select="$var_addr"/>',
      '',
      '<xsl:value-of select="@id"/>',
      '<xsl:call-template name="escapeapos">
        <xsl:with-param name="arg1">
          <xsl:value-of select="@output"/>
        </xsl:with-param>
      </xsl:call-template>'
      );
    </xsl:for-each>
    <xsl:apply-templates />
    go
</xsl:template>

<xsl:template match="elem" />

  <xsl:template match="ports">
    <xsl:variable name="var_address" select="../address/@addr" />
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="port[state[not(contains(@state, 'filtered'))]]">
    <xsl:variable name="var_addr" select="../../address/@addr" />
    <xsl:variable name="var_port" select="@portid" />
    insert into ports (address, state, portid, protocol, service_name,
    state_reason, state_reason_ip, service_product, service_version,
    service_extrainfo)
    values (
    '<xsl:value-of select="$var_addr"/>',
    '<xsl:value-of select="state/@state"/>',
    '<xsl:value-of select="@portid"/>',
    '<xsl:value-of select="@protocol"/>',
    '<xsl:value-of select="service/@name"/>',
    '<xsl:value-of select="state/@reason"/>',
    '<xsl:value-of select="state/@reason_ip"/>',
    '<xsl:call-template name="escapeapos">
        <xsl:with-param name="arg1">
            <xsl:value-of select="service/@product"/>
        </xsl:with-param>
    </xsl:call-template>',
    '<xsl:call-template name="escapeapos">
        <xsl:with-param name="arg1">
            <xsl:value-of select="service/@version"/>
        </xsl:with-param>
    </xsl:call-template>',
    '<xsl:call-template name="escapeapos">
        <xsl:with-param name="arg1">
            <xsl:value-of select="service/@extrainfo"/>
        </xsl:with-param>
    </xsl:call-template>'
    );
    <xsl:for-each select="script">
      insert into scripts (address, port, id, output) values (
      '<xsl:value-of select="$var_addr"/>',
      '<xsl:value-of select="$var_port"/>',
      '<xsl:value-of select="@id"/>',
      '<xsl:call-template name="escapeapos">
        <xsl:with-param name="arg1">
          <xsl:value-of select="@output"/>
        </xsl:with-param>
      </xsl:call-template>'
      );

    </xsl:for-each>

  </xsl:template>

  <xsl:template name="escapeapos">
    <xsl:param name="arg1"/>
    <xsl:variable name="apostrophe">'</xsl:variable>
    <xsl:choose>
      <!-- this string has at least on single quote -->
      <xsl:when test="contains($arg1, $apostrophe)">
        <xsl:if test="string-length(substring-before($arg1, $apostrophe)) > 0">
          <xsl:value-of select="substring-before($arg1, $apostrophe)" disable-output-escaping="yes"/>''</xsl:if>
        <xsl:call-template name="escapeapos">
          <xsl:with-param name="arg1">
            <xsl:value-of select="substring-after($arg1, $apostrophe)" disable-output-escaping="yes"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <!-- no quotes found in string, just print it -->
      <xsl:when test="string-length($arg1) > 0">
        <xsl:value-of select="$arg1"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
