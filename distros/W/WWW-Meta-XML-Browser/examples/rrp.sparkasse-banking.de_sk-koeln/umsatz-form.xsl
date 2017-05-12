<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />

<xsl:template match="/">
<www-meta-xml-browser-request url="{./html/body/form/@action}" method="{./html/body/form/@method}" stylesheet="umsatz.xsl">
	<content><xsl:apply-templates select="./html/body/form"/></content>
</www-meta-xml-browser-request>
</xsl:template>


<xsl:template match="input|select">
<xsl:choose>
	<xsl:when test="name() = 'input'">
		&amp;<xsl:value-of select="./@name"/>=<xsl:value-of select="./@value"/>
	</xsl:when>
	<xsl:when test="name() = 'select'">
		&amp;<xsl:value-of select="./@name"/>=
		<xsl:choose>
			<xsl:when test="./@name = 'zeitraum'">
				<xsl:value-of select="./option/@value"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="./option">
					<xsl:if test="./@selected">
						<xsl:value-of select="./@value"/>
					</xsl:if>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:when>
	<xsl:otherwise/>
</xsl:choose>
</xsl:template>

<xsl:template match="text()"/>

</xsl:stylesheet>