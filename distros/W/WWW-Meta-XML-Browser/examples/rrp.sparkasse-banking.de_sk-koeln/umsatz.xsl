<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />

<xsl:template match="/">
<details>
	<xsl:apply-templates/>
</details>
</xsl:template>



<xsl:template match="tr[contains(./td, 'Vorgemerkte')]">
	<xsl:variable name="TRS" select="following-sibling::tr[position() &lt; (count(following-sibling::tr[contains(./td, 'Gebuchte')]/preceding-sibling::*))]"/>

	<vorgemerkte-umsaetze>

		<xsl:for-each select="$TRS[(count(./td) = 4) and (./@bgcolor != '#3660AA')]">
			<umsatz>
				<wertstellung><xsl:value-of select="./td[2]"/></wertstellung>
				<verwendungszweck>
					<xsl:for-each select="./td[3]/font/text()">
						<zeile><xsl:value-of select="."/></zeile>
					</xsl:for-each>
				</verwendungszweck>
				<betrag><xsl:value-of select="./td[4]"/></betrag>
			</umsatz>
		</xsl:for-each>

	</vorgemerkte-umsaetze>
	
	<xsl:apply-templates/>	
</xsl:template>



<xsl:template match="tr[contains(./td, 'Gebuchte')]">
	<xsl:variable name="TRS" select="following-sibling::tr"/>

	<umsaetze>

		<xsl:for-each select="$TRS[(count(./td) = 4) and (./@bgcolor != '#3660AA')]">
			<umsatz>
				<buchung><xsl:value-of select="./td[1]"/></buchung>
				<wertstellung><xsl:value-of select="./td[2]"/></wertstellung>
				<verwendungszweck>
					<xsl:for-each select="./td[3]/font/text()">
						<zeile><xsl:value-of select="."/></zeile>
					</xsl:for-each>
				</verwendungszweck>
				<betrag><xsl:value-of select="./td[4]"/></betrag>
			</umsatz>
		</xsl:for-each>

	</umsaetze>
	
	<xsl:apply-templates/>	
</xsl:template>



<xsl:template match="table[./@bgcolor = '#9AAFD4']">
	<umsatzinformationen>
		<saldo datum="{substring-after(./tr[2]/td[2], 'am ')}"><xsl:value-of select="./tr[2]/td[4]"/></saldo>
		<saldo datum="{substring-after(./tr[3]/td[2], 'am ')}"><xsl:value-of select="./tr[3]/td[4]"/></saldo>

		<xsl:choose>		
			<xsl:when test="./tr[5]/td[4]">
				<anzahl-vorgemerkte-posten><xsl:value-of select="./tr[4]/td[4]"/></anzahl-vorgemerkte-posten>
				<anzahl-gebuchte-posten><xsl:value-of select="./tr[5]/td[4]"/></anzahl-gebuchte-posten>
			</xsl:when>
			<xsl:otherwise>
				<anzahl-gebuchte-posten><xsl:value-of select="./tr[4]/td[4]"/></anzahl-gebuchte-posten>
			</xsl:otherwise>
		</xsl:choose>
			
	</umsatzinformationen>
</xsl:template>



<xsl:template match="text()"/>

</xsl:stylesheet>