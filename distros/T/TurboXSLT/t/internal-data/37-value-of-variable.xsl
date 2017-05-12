<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">
<xsl:template match="/">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="alphabet_authors">
	<xsl:call-template name="author_groupping_links"><xsl:with-param name="letter" select="letter/@c"/></xsl:call-template>
</xsl:template>

	<xsl:template name="author_groupping_links">
		<xsl:param name="letter"/>
		<div class="a_groupping_links">
			<xsl:variable name="prev">
				<xsl:choose>
					<xsl:when test="/xportal/formdata/@alph_pagenumber"><xsl:value-of select="author_split[@alph_pagenumber = /xportal/formdata/@alph_pagenumber]/preceding::*[1]/@alph_pagenumber"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="author_split/preceding::*[1]/@alph_pagenumber"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="next">
				<xsl:choose>
					<xsl:when test="/xportal/formdata/@alph_pagenumber"><xsl:value-of select="author_split[@alph_pagenumber = /xportal/formdata/@alph_pagenumber]/following::*[1]/@alph_pagenumber"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="author_split/following::*[1]/@alph_pagenumber"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			[<xsl:value-of select="$prev"/>__<xsl:value-of select="$next"/>]
			<xsl:if test="$prev > 0"><a href="#">previous</a></xsl:if>
			<xsl:if test="/xportal/formdata/@alph_pagenumber and $prev = 0"><a href="#">previous</a></xsl:if>
			<xsl:if test="$next > 0"><a href="#">next</a></xsl:if>
		</div>
	</xsl:template>
</xsl:stylesheet>
