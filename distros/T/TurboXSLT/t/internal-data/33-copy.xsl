<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
	<xsl:template match="data">
		<xsl:apply-templates select="page-native-text/*" mode="online-reading"/>
	</xsl:template>
	<xsl:template match="node()|@*" mode="online-reading">
		<xsl:copy>
			<xsl:apply-templates select="node()|@*" mode="online-reading"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
