<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:template match="recense" name="recense">
	 <rec><xsl:apply-templates/></rec>
</xsl:template>
	<xsl:template match="p">
		<p>
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	<xsl:template match="strong|b">
		<b>
			<xsl:apply-templates/>
		</b>
	</xsl:template>
	<xsl:template match="empty-line|p[. = '' and not(*)]">
		<br/>
	</xsl:template>

</xsl:stylesheet>
