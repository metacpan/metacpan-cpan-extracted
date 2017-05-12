<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
	<xsl:template match="data">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="trigger">
		/<xsl:call-template name="adaptive_top_header"/>/
	</xsl:template>
	<xsl:template match="contents">
		\<xsl:call-template name="adaptive_top_header"/>\
	</xsl:template>
	<xsl:template name="adaptive_top_header">
		<xsl:variable name="hiddendata">
			<xsl:call-template name="user_account_bonus"><xsl:with-param name="show_decimal" select="1"/></xsl:call-template>
		</xsl:variable>
		[<xsl:value-of select="$hiddendata"/>]
	</xsl:template>
	<xsl:template name="user_account_bonus">
		<xsl:param name="show_decimal"/>
		=<xsl:value-of select="/data/contents/@amount"/>=<xsl:value-of select="$show_decimal"/>
	</xsl:template>
</xsl:stylesheet>
