<?xml version="1.0" encoding="UTF-8"?>
<!-- See the ZeeRex profile at http://srw.cheshire3.org/profiles/ZeeRex/ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:z="http://indexdata.dk/zebra/xslt/1"
                xmlns:e="http://explain.z3950.org/dtd/2.0/"
                xmlns:i="http://indexdata.com/irspy/1.0"
                version="1.0">
 <xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
 <xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
 <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>
 <!-- Disable all default text node output -->
 <xsl:template match="text()"/>
 <!-- Match on ZeeRex XML record -->
 <xsl:template match="//e:explain">
  <xsl:variable name="id"><xsl:value-of select="concat(
	e:serverInfo/@protocol, ':',
	e:serverInfo/e:host, ':',
	e:serverInfo/e:port, '/',
	e:serverInfo/e:database)"/></xsl:variable>
  <z:record id="{$id}" type="update">

   <!-- Well, not quite _anywhere_.  Only textual fields are indexed -->
   <z:index name="cql:anywhere" type="w">
    <xsl:value-of select="e:serverInfo/e:host"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="e:serverInfo/e:port"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="e:serverInfo/e:database"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="e:databaseInfo/e:title"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="e:databaseInfo/e:description"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="e:databaseInfo/e:author"/>
   </z:index>

   <z:index name="rec:authorityIndicator" type="0">
    <xsl:value-of select="@authoritative"/>
   </z:index>

   <z:index name="rec:id" type="u">
    <xsl:value-of select="$id"/>
   </z:index>

   <z:index name="rec:id_raw" type="0">
    <xsl:value-of select="$id"/>
   </z:index>

   <!-- serverInfo -->
   <z:index name="net:protocol" type="w">
    <xsl:value-of select="e:serverInfo/@protocol"/>
   </z:index>
   <z:index name="net:version" type="0">
    <xsl:value-of select="e:serverInfo/@version"/>
   </z:index>
   <z:index name="net:method" type="w">
    <xsl:value-of select="e:serverInfo/@method"/>
   </z:index>
   <z:index name="net:host" type="0">
    <xsl:value-of select="e:serverInfo/e:host"/>
   </z:index>
   <z:index name="net:host" type="s">
    <xsl:value-of select="e:serverInfo/e:host"/>
   </z:index>
   <z:index name="net:port" type="0">
    <xsl:value-of select="e:serverInfo/e:port"/>
   </z:index>
   <z:index name="net:port" type="s">
    <xsl:value-of select="e:serverInfo/e:port"/>
   </z:index>
   <z:index name="net:path" type="0">
    <xsl:value-of select="e:serverInfo/e:database"/>
   </z:index>
   <z:index name="net:path" type="s">
    <xsl:value-of select="e:serverInfo/e:database"/>
   </z:index>
   <z:index name="zeerex:reliability" type="n">
    <xsl:value-of select="e:serverInfo/e:reliability"/>
   </z:index>
   <z:index name="dc:date" type="d">
    <xsl:value-of select="e:serverInfo/e:database/@lastUpdate"/>
   </z:index>
   <z:index name="zeerex:numberOfRecords" type="n">
    <xsl:value-of select="e:serverInfo/e:database/@numRecs"/>
   </z:index>

   <!-- databaseInfo -->
   <z:index name="dc:title" type="w">
    <xsl:value-of select="e:databaseInfo/e:title"/>
   </z:index>
   <z:index name="dc:title" type="s">
    <xsl:value-of select="e:databaseInfo/e:title"/>
   </z:index>
   <z:index name="dc:description" type="w">
    <xsl:value-of select="e:databaseInfo/e:description"/>
   </z:index>
   <z:index name="dc:creator" type="w">
    <xsl:value-of select="e:databaseInfo/e:author"/>
   </z:index>
   <z:index name="dc:creator" type="s">
    <xsl:value-of select="e:databaseInfo/e:author"/>
   </z:index>
   <z:index name="dc:language" type="w">
    <xsl:value-of select="e:databaseInfo/e:langUsage"/>
   </z:index>

   <!-- metaInfo -->
   <z:index name="rec:lastModificationDate" type="d">
    <!-- ### Can Zebra handle this ISO-format date? -->
    <xsl:value-of select="e:metaInfo/e:dateModified"/>
   </z:index>

   <!-- indexInfo -->
   <xsl:for-each select="e:indexInfo/e:index/e:map/e:attr">
    <z:index name="zeerex:index" type="w">
     <xsl:value-of select="."/>
    </z:index>
   </xsl:for-each>

   <!-- recordInfo -->
   <z:index name="zeerex:recordSyntax" type="w">
    <xsl:value-of select="e:recordInfo/e:recordSyntax/@name"/>
    <!-- ### But @identifier is an OID for Z39.50 -->
   </z:index>

   <!-- schemaInfo -->
   <z:index name="zeerex:schema" type="0">
    <xsl:value-of select="e:schemaInfo/e:schema/@identifier"/>
    <!-- ### Really?  Identifier? -->
   </z:index>

   <!-- supportsInfo -->
   <xsl:for-each select="e:configInfo/e:supports[@type='relationModifier']">
    <z:index name="zeerex:supports_relationModifier" type="0">
     <xsl:value-of select="."/>
    </z:index>
   </xsl:for-each>
   <xsl:for-each select="e:configInfo/e:supports[@type='booleanModifier']">
    <z:index name="zeerex:supports_booleanModifier" type="0">
     <xsl:value-of select="."/>
    </z:index>
   </xsl:for-each>
   <xsl:for-each select="e:configInfo/e:supports[@type='maskingCharacter']">
    <z:index name="zeerex:supports_maskingCharacter" type="0">
     <xsl:value-of select="."/>
    </z:index>
   </xsl:for-each>
   <!-- Many more could be added as required -->

   <!-- extensions -->
   <z:index name="zeerex:libType" type="0">
    <xsl:value-of select="i:status/i:libraryType"/>
   </z:index>
   <z:index name="zeerex:country" type="0">
    <xsl:value-of select="i:status/i:country"/>
   </z:index>
   <z:index name="zeerex:disabled" type="0">
    <xsl:value-of select="i:status/i:disabled"/>
   </z:index>

  </z:record>
 </xsl:template>
</xsl:stylesheet>
