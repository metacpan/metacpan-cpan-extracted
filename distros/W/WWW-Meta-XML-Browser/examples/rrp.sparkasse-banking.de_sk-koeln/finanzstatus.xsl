<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />

<xsl:template match="/">
<finanzstatus>
	<xsl:apply-templates />
</finanzstatus>
</xsl:template>

<xsl:template match="tr[(./td/table/@width = 545) and (./td/table/@cellpadding = 2)]">
<xsl:choose>
	<xsl:when test="count(./td/table/tr) = 2">	
		<konto>

			<xsl:variable name="TR" select="following-sibling::tr[2]"/>

			<xsl:variable name="ART" select="$TR/td/font/text()[2]"/>

			<nummer><xsl:value-of select="$TR/td/font/text()[1]"/></nummer>
			<art><xsl:value-of select="$ART"/></art>
			<name><xsl:value-of select="$TR/td/font/text()[3]"/></name>
			<haben><xsl:value-of select="./td/table/tr/td[4]"/></haben>
			<soll><xsl:value-of select="./td/table/tr[2]/td[2]"/></soll>
			
			<xsl:if test="$ART = 'PRIVATGIRO'">
				<xsl:variable name="UMSATZ_URL" select="$TR/td[3]/a[2]/@href"/>
			
				<www-meta-xml-browser-request url="{substring-before($UMSATZ_URL, '?')}" method="get" stylesheet="umsatz-frames.xsl">
					<content><xsl:value-of select="substring-after($UMSATZ_URL, '?')"/></content>
				</www-meta-xml-browser-request>			
			</xsl:if>
			
		</konto>
	</xsl:when>
	<xsl:otherwise>
		<uebersicht>
			<haben><xsl:value-of select="./td/table/tr/td[3]"/></haben>
			<soll><xsl:value-of select="./td/table/tr[2]/td[2]"/></soll>
			<gesamt><xsl:value-of select="./td/table/tr[3]/td[2]"/></gesamt>
		</uebersicht>
	</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template match="text()"/>

</xsl:stylesheet>