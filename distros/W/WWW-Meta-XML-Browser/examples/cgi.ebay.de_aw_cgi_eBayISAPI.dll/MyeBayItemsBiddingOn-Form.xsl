<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />

<xsl:template match="/">
	<xsl:apply-templates select="descendant::form[1]" />
</xsl:template>



<xsl:template match="form">
	<xsl:variable name="DAYS" select="substring-before(substring-after(., 'maximal '), ' Tage')"/>

	<www-meta-xml-browser-request url="{./@action}" method="{./@method}" stylesheet="MyeBayItemsBiddingOn.xsl">
		<content>
			<xsl:for-each select="descendant::input">
				<xsl:if test="./@name">
					<xsl:choose>
						<xsl:when test="./@name = 'dayssince'">
							&amp;<xsl:value-of select="./@name"/>=<xsl:value-of select="$DAYS"/>
						</xsl:when>
						<xsl:otherwise>
							&amp;<xsl:value-of select="./@name"/>=<xsl:value-of select="./@value"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>			
			</xsl:for-each>
		</content>
	</www-meta-xml-browser-request>

</xsl:template>



<xsl:template match="text()"/>

</xsl:stylesheet>