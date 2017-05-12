<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" indent="yes" encoding="UTF-8" />

<xsl:template match='/'>
	<xsl:apply-templates/>
</xsl:template>



<xsl:template match="finanzstatus">
	<section name="Stadtsparkasse Köln">
		<table name="Konten">
			<table-header>
				<column name="Nummer" width="0.5cm"/>
				<column name="Art" width="9cm"/>
				<column name="Name" width="2cm"/>
				<column name="Haben" width="2cm"/>
				<column name="Soll" width="2cm"/>
			</table-header>
			<table-body>
		
				<xsl:for-each select="./konto">
		
					<row>
						<cell><xsl:value-of select="./nummer"/></cell>
						<cell><xsl:value-of select="./art"/></cell>
						<cell><xsl:value-of select="./name"/></cell>
						<cell><xsl:value-of select="./haben"/></cell>
						<cell><xsl:value-of select="./soll"/></cell>
					</row>
					
				</xsl:for-each>
					
			</table-body>
		</table>
	</section>
</xsl:template>



<xsl:template match="*"/>

</xsl:stylesheet>
