<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">
	<xsl:template match="/a">
	<out>
			<xsl:choose>
					<xsl:when test="@maxdownloads - @val &lt;= 0">fail</xsl:when>
					<xsl:otherwise>pass</xsl:otherwise>
			</xsl:choose>
		</out>
	</xsl:template>
</xsl:stylesheet>