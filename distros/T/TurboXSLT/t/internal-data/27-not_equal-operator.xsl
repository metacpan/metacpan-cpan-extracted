<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:chk="LTR:chk" xmlns:ltr="LTR" exclude-result-prefixes="ltr chk" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

<xsl:template match="xportal">

		<xsl:call-template name="cross-corners">
			<xsl:with-param name="id">sortby</xsl:with-param>
			<xsl:with-param name="content">12345</xsl:with-param>
		</xsl:call-template>

</xsl:template>

	<xsl:template name="cross-corners">
		<xsl:param name="content"/>
		<xsl:param name="class"/>
		<xsl:param name="id" select="0"/>
		<div class="corners {$class}">
			<xsl:if test="$id != 0"><xsl:attribute name="id"><xsl:copy-of select="$id"/></xsl:attribute><xsl:attribute name="style">color:blue;</xsl:attribute></xsl:if>
			<xsl:copy-of select="$content"/>
		</div>
	</xsl:template>
	
</xsl:stylesheet>
