<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">

<xsl:template match="test">
	<xsl:call-template name="in_basket"/>
</xsl:template>

	<xsl:template name="in_basket">
		<xsl:param name="delivered"><xsl:if test="basket_delivery_item">1</xsl:if></xsl:param>
		<xsl:if test="$delivered != 1">put</xsl:if><br/>
		[<xsl:value-of select="$delivered"/>]
	</xsl:template>
	
</xsl:stylesheet>
