<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" exclude-result-prefixes="fo ltr chk" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR" xmlns:chk="LTR:chk">

	<xsl:decimal-format name="rub" decimal-separator="," grouping-separator=" " zero-digit="0"/>
	
<xsl:template match="/">
	<xsl:value-of select="format-number(10,'0','rub')"/><br/>
	<xsl:value-of select="format-number(20,'0','rub')"/><br/>
</xsl:template>

</xsl:stylesheet>
