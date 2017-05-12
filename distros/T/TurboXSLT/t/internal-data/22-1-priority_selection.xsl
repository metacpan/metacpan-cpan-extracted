<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="/"> 
		 <xsl:apply-templates select="/xportal[ajax-only]"/> 
		 <xsl:apply-templates select="/xportal[not(ajax-only)]"/> 
		 
	</xsl:template>
	
	<xsl:template match="/xportal[ajax-only]">111</xsl:template>
	<xsl:template match="/xportal[not(ajax-only)]">222</xsl:template>
	<xsl:template match="xportal-page">333</xsl:template>


</xsl:stylesheet>
