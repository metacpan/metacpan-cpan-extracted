<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:chk="LTR:chk" xmlns:ltr="LTR" exclude-result-prefixes="ltr chk" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

<xsl:template match="test">
<xsl:variable name="atypes" select="genre_book/@type"/>
<xsl:value-of select="$atypes"/><br/>

<xsl:variable name="has-texts" select="$atypes[. = 0]"/>
<xsl:value-of select="$has-texts"/><br/>

<xsl:if test="$has-texts">123<br/></xsl:if>

<xsl:variable name="has-audios" select="$atypes[. = 1]"/>

<xsl:if test="$has-audios">456<br/></xsl:if>

<xsl:call-template name="print-list">
<xsl:with-param name="list">
<xsl:if test="$has-texts">
<item>electron books</item>
</xsl:if>
<xsl:if test="$has-audios">
<item>audio</item>
</xsl:if>
</xsl:with-param>
</xsl:call-template>

</xsl:template>

	
	
<xsl:template name="print-list">
<xsl:param name="list"/>
<xsl:param name="node-list" select="exsl:node-set($list)"/>
<xsl:param name="use-conjunction" select="true()"/>

<xsl:for-each select="$node-list/*">
<xsl:copy-of select="node()"/><br />
<xsl:if test="count($node-list/*) &gt; 1">
<xsl:choose>
<xsl:when test="position() = last() - 1 and $use-conjunction"> and </xsl:when>
<xsl:when test="position() != last()">, </xsl:when>
</xsl:choose>
</xsl:if>
</xsl:for-each>
</xsl:template>
	
</xsl:stylesheet>
