<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">
	<!-- данные формы -->
	<xsl:variable name="form" select="1"/>
	
	<xsl:template match="/">
		<xsl:apply-templates/>		
	</xsl:template>

	<xsl:template match="/xportal/author_ratings">	
		<xsl:variable name="form" select="2"/>
		<xsl:value-of select="$form"/><br/>		
	</xsl:template>
	
	<xsl:template match="/xportal/com_messages">
		<xsl:value-of select="$form"/><br/>
	</xsl:template>

</xsl:stylesheet>
