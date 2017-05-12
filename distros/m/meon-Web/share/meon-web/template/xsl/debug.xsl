<?xml version="1.0"?>

<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns="http://www.eusahub.com/"
	xmlns:e="http://www.eusahub.com/"
>

<xsl:output 
	method="xml"
	indent="yes"
	media-type="text/xml"
/>

<xsl:template match="/">
	<xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet> 
