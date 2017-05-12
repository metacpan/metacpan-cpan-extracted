<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />

<xsl:template match="/">
<www-meta-xml-browser-request url="{substring-before(/html/frameset/frameset[2]/frame[2]/@src, '?')}" method="get" stylesheet="umsatz-form.xsl">
	<content><xsl:value-of select="substring-after(/html/frameset/frameset[2]/frame[2]/@src, '?')"/></content>
</www-meta-xml-browser-request>			
</xsl:template>

<xsl:template match="text()"/>

</xsl:stylesheet>