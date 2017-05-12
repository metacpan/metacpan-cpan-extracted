<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rss="http://purl.org/rss/1.0/"
  xmlns:rss09="http://my.netscape.com/rdf/simple/0.9/"
  version="1.0"
  exclude-result-prefixes="xsl rdf dc rss rss09">
	<xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>
<!-- 
    $Id: example-4.xsl 79 2008-07-01 19:45:17Z adam $

The XSLT stylesheet listed below should be able to read any of the 7 versions of RSS feed currently
available and convert them consistently to a XHTML fragment. Becasue of the differences in RSS, it is not
easy to convert all elements of each RSS standard into another standard, but it is practicle for the
limited purposes of simple display in a web browser.

-->
	<xsl:template match="/">
		<div>
		<xsl:apply-templates select="rdf:RDF/rss:channel"/>
		<xsl:apply-templates select="rdf:RDF/rss09:channel"/>
		<xsl:apply-templates select="rss/channel"/>
		<xsl:if test="rdf:RDF/rss:item">
			<ul><xsl:apply-templates select="rdf:RDF/rss:item"/></ul>
		</xsl:if>
		<xsl:if test="rdf:RDF/rss09:item">
			<ul><xsl:apply-templates select="rdf:RDF/rss09:item"/></ul>
		</xsl:if>
		</div>
	</xsl:template>
	<xsl:template match="rss:channel">
		<xsl:variable name="link" select="rss:link"/>
		<xsl:variable name="description" select="rss:description"/>
		<xsl:variable name="image" select="/rdf:RDF/rss:image/rss:url"/>
		<xsl:if test="$image">	
			<img src="{$image}" style="float: right; margin: 2px;"/>
		</xsl:if>
		<h3><a href="{$link}" title="{$description}"><xsl:value-of select="rss:title"/></a></h3>
		<hr/>
	</xsl:template>
	<xsl:template match="rss09:channel">
		<xsl:variable name="link" select="rss09:link"/>
		<xsl:variable name="description" select="rss09:description"/>
		<xsl:variable name="image" select="/rdf:RDF/rss09:image/rss09:url"/>
		<xsl:if test="$image">	
			<img src="{$image}" style="float: right; margin: 2px;"/>
		</xsl:if>
		<h3><a href="{$link}" title="{$description}"><xsl:value-of select="rss09:title"/></a></h3>
		<hr/>
	</xsl:template>
	<xsl:template match="channel">
		<xsl:variable name="link" select="link"/>
		<xsl:variable name="description" select="description"/>
		<xsl:variable name="image" select="image/url"/>
		<xsl:if test="$image">	
			<img src="{$image}" style="float: right; margin: 2px;"/>
		</xsl:if>
		<h3><a href="{$link}" title="{$description}"><xsl:value-of select="title"/></a></h3>
		<hr/>
		<ul><xsl:apply-templates select="item"/></ul>
	</xsl:template>
	<xsl:template match="item">
		<xsl:variable name="item_link" select="link"/>
		<xsl:variable name="item_title" select="description"/>
		<li><a href="{$item_link}" title="{$item_title}"><xsl:value-of select="title"/></a></li>
	</xsl:template>
	<xsl:template match="rss:item">
		<xsl:variable name="item_link" select="rss:link"/>
		<xsl:variable name="item_title" select="rss:description"/>
		<li><a href="{$item_link}" title="{$item_title}"><xsl:value-of select="rss:title"/></a></li>
	</xsl:template>
	<xsl:template match="rss09:item">
		<xsl:variable name="item_link" select="rss09:link"/>
		<xsl:variable name="item_title" select="rss09:description"/>
		<li><a href="{$item_link}" title="{$item_title}"><xsl:value-of select="rss09:title"/></a></li>
	</xsl:template>
	</xsl:stylesheet>
