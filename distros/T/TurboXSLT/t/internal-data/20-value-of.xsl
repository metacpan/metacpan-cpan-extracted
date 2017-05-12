<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
	
	<xsl:template match="/">
		<xsl:call-template name="test"><xsl:with-param name="type">book</xsl:with-param></xsl:call-template>
	</xsl:template>
		
	<xsl:template name="test">	
			<xsl:param name="type"/>
			
			<xsl:call-template name="sub">
				<xsl:with-param name="id">a_buybtn_<xsl:value-of select="$type"/></xsl:with-param>
			</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="sub">
		<xsl:param name="id"/>
		<xsl:value-of select="$id"/>
	</xsl:template>

</xsl:stylesheet>

