<?xml version="1.0" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />


<xsl:template match="/html">
<information>
	<xsl:apply-templates />
</information>
</xsl:template>


<xsl:template match="select[@name = 'newday']">
<days>
	<xsl:for-each select="./option">
	<day timestamp="{./@value}"><xsl:value-of select="."/></day>
	</xsl:for-each>
</days>
</xsl:template>


<xsl:template match="select[@name = 'tvchannelid']">
<programs>
	<xsl:for-each select="./option">
	<program id="{./@value}"><xsl:value-of select="." /></program>
	</xsl:for-each>
</programs>
</xsl:template>


<xsl:template match="text()"/>


</xsl:stylesheet>