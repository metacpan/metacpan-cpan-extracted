<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />

<xsl:template match="/">
<mein-ebay>
	<xsl:apply-templates />
</mein-ebay>
</xsl:template>



<xsl:template match="table[contains(./tr/td[2]/a/b/span, 'Ich biete')]">
	<xsl:variable name="TABLE" select="following-sibling::table[./tr][2]"/>

	<ich-biete>

		<artikel-liste>

			<xsl:for-each select="$TABLE/tr[./td/@width = '100%']">
				<xsl:variable name="TR" select="following-sibling::tr[1]"/>

				<artikel>
					<xsl:if test="$TR/td[3]/font/@color = '#339933'">
						<xsl:attribute name="hoechstbietend">1</xsl:attribute>
					</xsl:if>
					<name><xsl:value-of select="./td/div/a"/></name>
					<nummer><xsl:value-of select="$TR/td[1]"/></nummer>
					<startpreis><xsl:value-of select="$TR/td[2]"/></startpreis>			
					<aktueller-preis><xsl:value-of select="$TR/td[3]"/></aktueller-preis>			
					<mein-hoechstgebot><xsl:value-of select="$TR/td[4]"/></mein-hoechstgebot>
					<menge><xsl:value-of select="$TR/td[5]"/></menge>
					<anzahl-der-gebote><xsl:value-of select="$TR/td[6]"/></anzahl-der-gebote>
					<anfangsdatum><xsl:value-of select="$TR/td[7]"/></anfangsdatum>
					<enddatum><xsl:value-of select="$TR/td[8]"/></enddatum>
					<verbleibende-zeit><xsl:value-of select="$TR/td[9]"/></verbleibende-zeit>
				</artikel>

			</xsl:for-each>

		</artikel-liste>

		<zusammenfassung>
			<xsl:variable name="TR" select="$TABLE/tr[@bgcolor = '#ffffe6']"/>
			
			<xsl:for-each select="$TR">
				<xsl:choose>
					<xsl:when test="contains(./td, 'Alle Angebote')">
						<alle-angebote>
							<startpreis><xsl:value-of select="./td[2]"/></startpreis>			
							<aktueller-preis><xsl:value-of select="./td[3]"/></aktueller-preis>			
							<mein-hoechstgebot><xsl:value-of select="./td[4]"/></mein-hoechstgebot>
							<gesamtmenge><xsl:value-of select="./td[5]"/></gesamtmenge>
							<anzahl-der-gebote><xsl:value-of select="./td[6]"/></anzahl-der-gebote>
						</alle-angebote>
					</xsl:when>
					<xsl:when test="contains(./td, 'chstbietende bin')">
						<artikel-hoechstbietend>
							<startpreis><xsl:value-of select="./td[2]"/></startpreis>			
							<aktueller-preis><xsl:value-of select="./td[3]"/></aktueller-preis>			
							<mein-hoechstgebot><xsl:value-of select="./td[4]"/></mein-hoechstgebot>
							<gesamtmenge><xsl:value-of select="./td[5]"/></gesamtmenge>
							<anzahl-der-gebote><xsl:value-of select="./td[6]"/></anzahl-der-gebote>
						</artikel-hoechstbietend>
					</xsl:when>
					<xsl:otherwise/>
				</xsl:choose>
			</xsl:for-each>
			
		</zusammenfassung>

	</ich-biete>
</xsl:template>



<xsl:template match="table[contains(./tr/td[2]/div/a/b/span, 'Ich habe gekauft')]">
	<xsl:variable name="TABLE" select="following-sibling::table[./tr][2]"/>

	<ich-habe-gekauft>

		<artikel-liste>

			<xsl:for-each select="$TABLE/tr/form/td/table/tr[./td/div/input/@type = 'checkbox']">
				<xsl:variable name="TR" select="following-sibling::tr[1]"/>

				<artikel>
					<name><xsl:value-of select="./td[1]/div/a"/></name>
					<nummer><xsl:value-of select="$TR/td[2]"/></nummer>
					<enddatum><xsl:value-of select="$TR/td[3]"/></enddatum>			
					<verkaufspreis><xsl:value-of select="$TR/td[4]/font/b"/></verkaufspreis>
					<mein-hoechstgebot><xsl:value-of select="$TR/td[5]"/></mein-hoechstgebot>
					<anzahl><xsl:value-of select="$TR/td[6]"/></anzahl>
					<verkaeufer><xsl:value-of select="$TR/td[7]/a"/></verkaeufer>
										
					<xsl:choose>
						<xsl:when test="contains($TR/td[8]/a/img[2]/@src, 'paynow.gif')">
							<status>Bezahlung und Versand</status>
							<status-url><xsl:value-of select="$TR/td[8]/a/@href"/></status-url>
						</xsl:when>
						<xsl:when test="$TR/td[8]/a">
							<status><xsl:value-of select="$TR/td[8]/a"/></status>
							<status-url><xsl:value-of select="$TR/td[8]/a/@href"/></status-url>
						</xsl:when>
						<xsl:otherwise><status><xsl:value-of select="$TR/td[8]"/></status></xsl:otherwise>
					</xsl:choose>

					<xsl:choose>
						<xsl:when test="$TR/td[9]/a">
							<bewertung><xsl:value-of select="$TR/td[9]/a"/></bewertung>
							<bewertung-url><xsl:value-of select="$TR/td[9]/a/@href"/></bewertung-url>
						</xsl:when>
						<xsl:otherwise><bewertung><xsl:value-of select="$TR/td[9]"/></bewertung></xsl:otherwise>
					</xsl:choose>
										
				</artikel>

			</xsl:for-each>

		</artikel-liste>

		<zusammenfassung>
			<ich-habe-gekauft>
				<xsl:variable name="TR" select="$TABLE/tr/form/td/table/tr[@bgcolor = 'ffffe6']"/>

				<verkaufspreis><xsl:value-of select="$TR/td[2]"/></verkaufspreis>
				<mein-hoechstgebot><xsl:value-of select="$TR/td[3]"/></mein-hoechstgebot>
				<gesamtmenge><xsl:value-of select="$TR/td[4]"/></gesamtmenge>
			</ich-habe-gekauft>
		</zusammenfassung>

	</ich-habe-gekauft>
</xsl:template>



<xsl:template match="table[contains(./tr/td[2]/div/a/b/span, 'Ich beobachte')]">
	<xsl:variable name="TABLE" select="following-sibling::table[./tr][1]"/>

	<ich-beobachte>

		<artikel-liste>
		
			<xsl:for-each select="$TABLE/tr/form/td/table/tr[./td/input/@type = 'checkbox']">
				<xsl:variable name="TR" select="following-sibling::tr[1]"/>
			
				<artikel>
					<name><xsl:value-of select="./td[2]"/></name>
					<nummer><xsl:value-of select="$TR/td[2]"/></nummer>
					<xsl:choose>
						<!-- 1. Fall: Bieten & Sofort-Kaufen -->
						<xsl:when test="$TR/td[4]/a/text() and $TR/td[4]/a/img">
							<preis><xsl:value-of select="$TR/td[3]/b"/></preis>
							<sofort-kaufen><xsl:value-of select="$TR/td[3]/text()"/></sofort-kaufen>
							<anzahl-der-gebote><xsl:value-of select="$TR/td[4]/a/text()"/></anzahl-der-gebote>
						</xsl:when>
						<!-- 2. Fall: Nur Bieten -->
						<xsl:when test="$TR/td[4]/a/text()">
							<preis><xsl:value-of select="$TR/td[3]/b"/></preis>					
							<anzahl-der-gebote><xsl:value-of select="$TR/td[4]/a/text()"/></anzahl-der-gebote>
						</xsl:when>
						<!-- 3. Fall: Nur Sofort-Kaufen -->
						<xsl:when test="$TR/td[4]/a/img">
							<sofort-kaufen><xsl:value-of select="$TR/td[3]/b"/></sofort-kaufen>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
					
					<verbleibende-zeit><xsl:value-of select="normalize-space($TR/td[5])"/></verbleibende-zeit>
					<verkaeufer><xsl:value-of select="$TR/td[6]"/></verkaeufer>

					<xsl:choose>
						<!-- 1. Fall: Bieten & Sofort-Kaufen -->
						<xsl:when test="count($TR/td[7]/a) = 2">
							<gebot-url><xsl:value-of select="$TR/td[7]/a[1]/@href"/></gebot-url>
							<sofort-kaufen-url><xsl:value-of select="$TR/td[7]/a[2]/@href"/></sofort-kaufen-url>
						</xsl:when>
						<!-- 2. Fall: Nur Bieten -->
						<xsl:when test="contains($TR/td[7]/a/img/@src, 'BidNow_graphic.gif')">
							<gebot-url><xsl:value-of select="$TR/td[7]/a/@href"/></gebot-url>
						</xsl:when>
						<!-- 3. Fall: Nur Sofort-Kaufen -->
						<xsl:when test="contains($TR/td[7]/a/img/@src, 'bin_button.gif')">
							<sofort-kaufen-url><xsl:value-of select="$TR/td[7]/a/@href"/></sofort-kaufen-url>
						</xsl:when>
						<xsl:otherwise/>
					</xsl:choose>
					
				</artikel>
							
			</xsl:for-each>

		</artikel-liste>
	
	</ich-beobachte>
</xsl:template>



<xsl:template match="text()"/>

</xsl:stylesheet>