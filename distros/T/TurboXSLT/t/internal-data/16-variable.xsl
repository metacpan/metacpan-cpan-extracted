<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">

<xsl:template match="test">

		<xsl:variable name="t_name"><xsl:value-of select="@arts_count"/>1 11</xsl:variable>
		
		<xsl:value-of select="$t_name"/>
		
</xsl:template>

</xsl:stylesheet>
