<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:z="http://indexdata.dk/zebra/xslt/1"
                xmlns:e="http://explain.z3950.org/dtd/2.0/"
                version="1.0">

 <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>
 <!-- Disable all default text node output -->
 <xsl:template match="text()"/>
 <!-- Match on ZeeRex XML record -->

 <xsl:template match="//e:explain">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"
	z:id="{concat(e:serverInfo/@protocol, ':',
		      e:serverInfo/e:host, ':',
		      e:serverInfo/e:port, '/',
		      e:serverInfo/e:database)}">
   <dc:title>
    <xsl:value-of select="e:databaseInfo/e:title"/>
   </dc:title>
   <dc:creator>
    <xsl:value-of select="e:databaseInfo/e:author"/>
   </dc:creator>
   <!-- Subject -->
   <dc:description>
    <xsl:value-of select="e:databaseInfo/e:description"/>
   </dc:description>
   <!-- Publisher -->
   <!-- Contributor -->
   <dc:date>
    <xsl:value-of select="e:serverInfo/e:database/@lastUpdate"/>
   </dc:date>
   <dc:type>Service</dc:type>
   <!-- Format -->
   <dc:identifier>
    <xsl:value-of select="concat(
			  e:serverInfo/e:host, ':',
			  e:serverInfo/e:port, '/',
			  e:serverInfo/e:database)"/>
   </dc:identifier>
   <!-- Source -->
   <dc:language>
    <xsl:value-of select="e:databaseInfo/e:langUsage"/>
   </dc:language>
   <!-- Relation -->
   <!-- Coverage -->
   <!-- Rights -->
  </metadata>
 </xsl:template>
</xsl:stylesheet>
