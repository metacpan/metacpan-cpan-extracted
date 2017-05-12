<?xml version="1.0" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />

<xsl:template match="/">
<aktuell>
	<xsl:apply-templates />
</aktuell>
</xsl:template>

<!-- Tabelle matchen -->
<xsl:template match="table[(./@width = 380) and (./tr[1]/td[1]) = '01.']">
<tabelle>
	<xsl:for-each select="./tr">
	<tabellenplatz id="{substring-before(./td[1], '.')}">
		<verein><xsl:value-of select="./td[2]"/></verein>
		<spiele><xsl:value-of select="./td[3]"/></spiele>
		<xxx><xsl:value-of select="./td[4]"/></xxx>
		<punkte>
			<erzielt><xsl:value-of select="substring-before(./td[5], ':')"/></erzielt>
			<erhalten><xsl:value-of select="substring-after(./td[5], ':')"/></erhalten>
		</punkte>
		<spielpunkte>
			<erzielt><xsl:value-of select="substring-before(./td[6], ':')"/></erzielt>
			<erhalten><xsl:value-of select="substring-after(./td[6], ':')"/></erhalten>
		</spielpunkte>
	</tabellenplatz>
	</xsl:for-each>
</tabelle>
</xsl:template>

<xsl:template match="a[normalize-space(./text()) = 'Spielplan / bisherige Ergebnisse']">
<www-meta-xml-browser-request url="http://www.wbv-online.de/ligen/{substring-before(./@href, '?')}" method="get" stylesheet="liga_spielplan.xsl" container="xxx">
	<content><xsl:value-of select="substring-after(./@href, '?')"/></content>
</www-meta-xml-browser-request>
</xsl:template>

<xsl:template match="text()"/>

</xsl:stylesheet>