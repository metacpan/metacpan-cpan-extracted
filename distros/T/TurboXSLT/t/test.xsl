<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:template match="foo">
		<FOO>фуу
                <xsl:apply-templates/>
		</FOO>
	</xsl:template>
	<xsl:template match="bar">
		<BAR>
			<xsl:apply-templates/>
		</BAR>
	</xsl:template>
	<xsl:template match="xxx">
		<XXX>
			<xsl:value-of select="ltr:my_callback('my','path',@t)"/>
		</XXX>
	</xsl:template>
</xsl:stylesheet>
