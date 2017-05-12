<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">

<xsl:include href="29/1/11/111/29.xml"/>

<xsl:template match="/">
222
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="basic_arts">
<xsl:apply-templates select="art" mode="map"/>
</xsl:template>

<xsl:template match="art" mode="map">
<xsl:apply-templates select="." mode="basic_block_pos1"/>
</xsl:template>

<xsl:template match="art" mode="basic_block_pos1">	
11111<br/>
<xsl:apply-templates mode="pos1_type1"/>
</xsl:template>

<xsl:template match="like_basic" mode="pos1_type1">
<xsl:call-template name="row1_type2"><xsl:with-param name="nnode" select="."/></xsl:call-template>
</xsl:template>

<xsl:template name="row1_type2">
<xsl:param name="nnode" select="."/>
<xsl:variable name="node" select="$nnode/../banner/text_html/hidden"/>
<li class="row1_type2 row1">
<xsl:apply-templates select="$nnode/art[position() &lt; 3]" mode="row1_col1"><xsl:with-param name="description">1</xsl:with-param></xsl:apply-templates>
<xsl:copy-of select="$node/*"/>
</li>
</xsl:template>

<xsl:template match="art" mode="row1_col1">
<xsl:param name="class"/>
<xsl:param name="description">0</xsl:param>
<div><xsl:attribute name="class">book_item number<xsl:value-of select="position()"/> <xsl:if test="$class"><xsl:text> </xsl:text><xsl:value-of select="$class"/></xsl:if></xsl:attribute>
<div class="caption_txt">
<xsl:value-of select="@reason_name"/>
</div>
</div>
</xsl:template>
	
</xsl:stylesheet>