<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">

	<xsl:template match="arts">		
		<xsl:for-each select="/arts/sequence/book">
			<xsl:variable name="this_class_arts" select="."/>
			<xsl:value-of select="$this_class_arts"/><br/>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>