<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" indent="yes" encoding="UTF-8" />

<xsl:template match='/'>
	<xsl:apply-templates/>
</xsl:template>



<xsl:template match="/mein-ebay">
	<section name="Mein eBay">
		<xsl:apply-templates select="./ich-biete[count(./artikel-liste/artikel) &gt; 0]"/>
		<xsl:apply-templates select="./ich-habe-gekauft[count(./artikel-liste/artikel) &gt; 0]"/>
		<xsl:apply-templates select="./ich-beobachte[count(./artikel-liste/artikel) &gt; 0]"/>
	</section>
</xsl:template>



<xsl:template match="ich-biete">
	<table name="Ich biete">
		<table-header>
			<column name="" width="0.5cm"/>
			<column name="Name" width="9cm"/>
			<column name="Nummer" width="2cm"/>
		</table-header>
		<table-body>
	
			<xsl:for-each select="./artikel-liste/artikel">
	
				<row>
					<cell><xsl:value-of select="position()"/></cell>
					<cell><xsl:value-of select="./name"/></cell>
					<cell><xsl:value-of select="./nummer"/></cell>
				</row>
				
			</xsl:for-each>
	
		</table-body>
	</table>
</xsl:template>



<xsl:template match="ich-habe-gekauft">
	<table name="Ich habe gekauft">
		<table-header>
			<column name="" width="0.5cm"/>
			<column name="Name" width="9cm"/>
			<column name="Nummer" width="2cm"/>
		</table-header>
		<table-body>
	
			<xsl:for-each select="./artikel-liste/artikel">
	
				<row>
					<cell><xsl:value-of select="position()"/></cell>
					<cell><xsl:value-of select="./name"/></cell>
					<cell><xsl:value-of select="./nummer"/></cell>
				</row>
				
			</xsl:for-each>
	
		</table-body>
	</table>
</xsl:template>



<xsl:template match="ich-beobachte">
	<table name="Ich beobachte">
		<table-header>
			<column name="" width="0.5cm"/>
			<column name="Name" width="9cm"/>
			<column name="Nummer" width="2cm"/>
		</table-header>
		<table-body>
	
			<xsl:for-each select="./artikel-liste/artikel">
	
				<row>
					<cell><xsl:value-of select="position()"/></cell>
					<cell><xsl:value-of select="./name"/></cell>
					<cell><xsl:value-of select="./nummer"/></cell>
				</row>
				
			</xsl:for-each>
	
		</table-body>
	</table>
</xsl:template>



<xsl:template match="*"/>

</xsl:stylesheet>
