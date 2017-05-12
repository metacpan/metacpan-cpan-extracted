<?xml version="1.0" encoding="iso-8859-1"?>
<!-- $Id: test.xsl 56 2008-06-23 16:54:31Z adam $ -->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	exclude-result-prefixes="xsl"
	>
<xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>

<xsl:template match="/">
	<div>
	<xsl:apply-templates select="rss"/>
	</div>
</xsl:template>

<xsl:template match="rss">
	<xsl:apply-templates select="channel"/>
	
</xsl:template>

<xsl:template match="channel">
	<xsl:variable name="link" select="link"/>
	<xsl:variable name="description" select="description"/>
	<h3><a href="{$link}" title="{$description}"><xsl:value-of select="title" /></a></h3>
	<hr/>
	<ul><xsl:apply-templates select="item"/></ul>
</xsl:template>

<xsl:template match="item">
	<xsl:variable name="item_link" select="link"/>
	<xsl:variable name="item_title" select="description"/>
	<li><a href="{$item_link}" title="{$item_title}"><xsl:value-of select="title"/></a></li>
</xsl:template>

</xsl:stylesheet>
