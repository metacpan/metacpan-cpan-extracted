<?xml version="1.0" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />

<xsl:template match="/">
<ergebnisse>
	<xsl:apply-templates />
</ergebnisse>
</xsl:template>

<xsl:template match="table[(@width = 590) and (contains(./tr[3]/td, 'Spieltag'))]">
	<xsl:for-each select="./tr[contains(./td, 'Spieltag')]">

	<xsl:variable name="tr" select="following-sibling::tr[position() &lt; 7]"/>

	<spieltag datum="{substring-before(substring-after(normalize-space(./td[1]), '( '), ' )')}">
		<xsl:for-each select="$tr">

		<xsl:if test="./td[1]/b">

		<spiel nummer="{./td[1]/b}">
			<datum><xsl:value-of select="./td[2]/font[1]"/></datum>
			<uhrzeit><xsl:value-of select="./td[2]/font[2]"/></uhrzeit>
			<heim-mannschaft>
				<name><xsl:value-of select="normalize-space(./td[4])"/></name>
				<punkte><xsl:value-of select="substring-before(./td[6], ':')"/></punkte>
			</heim-mannschaft>
			<auswaerts-mannschaft>
				<name><xsl:value-of select="normalize-space(./td[5])"/></name>
				<punkte><xsl:value-of select="substring-after(./td[6], ':')"/></punkte>
			</auswaerts-mannschaft>
		</spiel>
		
		</xsl:if>
		
		</xsl:for-each>
	</spieltag>

	</xsl:for-each>
	
</xsl:template>

<xsl:template match="text()"/>

</xsl:stylesheet>