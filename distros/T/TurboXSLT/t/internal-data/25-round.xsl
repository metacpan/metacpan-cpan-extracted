<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:chk="LTR:chk" xmlns:ltr="LTR" exclude-result-prefixes="ltr chk" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

<xsl:template match="/">

	<xsl:call-template name="format_price_number"/>

</xsl:template>

	<xsl:template name="format_price_number">
		<xsl:param name="price">100.00</xsl:param>
		<xsl:value-of select="$price"></xsl:value-of><br/>
		<xsl:value-of select="round($price)"/><br/>
		<xsl:choose>
			<xsl:when test="round($price) != $price">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	
	
</xsl:stylesheet>
