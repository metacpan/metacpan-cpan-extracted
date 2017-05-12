<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!--
	*** Stylesheet to convert Apache "in the news" XML data into the page
	*** www.apache.org/in_the_news.html
	***
	*** To output all stories in 2000 use yearfrom=2000, yearto=2000
	*** To output all stories 1999,2000 use yearfrom=1999, yearto=2000
	***
	*** Mark Cox, mjc@apache.org, mjc@redhat.com, Mar 2001 -->

<xsl:output method="html"/>
<xsl:param name="yearfrom" select="number(2000)"/>
<xsl:param name="yearto" select="number(2001)"/>

<xsl:template match="/">
	<HTML>
	<HEAD>
	<TITLE>Apache in the News</TITLE>
        <!-- This file is automatically created from a XML source, please
             don't edit this file directly-->
	</HEAD>
	<!-- Background white, links blue (unvisited), navy (visited), red (active) -->
	<BODY BGCOLOR="#FFFFFF" TEXT="#000000" LINK="#0000FF" VLINK="#000080" ALINK="#FF0000">
	<IMG SRC="images/apache_sub.gif" ALT=""/>

	<H2>Apache in the News <xsl:value-of select="$yearfrom"/>
	<xsl:if test="$yearto!=$yearfrom">
        <xsl:text>-</xsl:text>
	<xsl:value-of select="$yearto"/>
        </xsl:if>
	</H2>
	<P>
	Since becoming the #1 Web server, Apache has featured in a number
	of reviews and articles.  If you have seen a story about Apache on
	the Web or in the press
	<A HREF="mailto:mjc@apache.org">let us know</A>
	so that we can include it here.
	</P>
	<P>
	Also check out the <A HREF="awards.html">awards won by the Apache software</A>.
	</P>
	<HR/>

	<xsl:apply-templates select="//item">
	<xsl:sort order="descending" data-type="text" select="date"/>
	</xsl:apply-templates>

	<HR/>
	</BODY>
	</HTML>
</xsl:template>

<xsl:template match="item">
        <xsl:variable name="year" select="number(substring(date,1,4))"/>
	<xsl:if test="($year>=$yearfrom) and ($year&lt;=$yearto)">
		<P><STRONG>
		<CITE><xsl:value-of select="publication"/></CITE>,
		<xsl:apply-templates select="date"/>
		"<a href="{url}"><xsl:value-of select="title"/></a>"
		</STRONG></P>
		<BLOCKQUOTE>
		<xsl:value-of select="comment"/>
		<EM><xsl:value-of select="quote"/></EM>
		</BLOCKQUOTE>
	</xsl:if>
</xsl:template>

<xsl:template match="date">
        <xsl:param name="date" select="."/>
        <xsl:variable name="day" select="number(substring($date,7,2))"/>
        <xsl:variable name="month" select="number(substring($date,5,2))"/>
        <xsl:variable name="year" select="number(substring($date,1,4))"/>

	<xsl:if test="$day>0">
        <xsl:value-of select="$day" />
        <xsl:text> </xsl:text>
        </xsl:if>

        <xsl:choose>
                <xsl:when test="$month= 1">January</xsl:when>
                <xsl:when test="$month= 2">February</xsl:when>
                <xsl:when test="$month= 3">March</xsl:when>
                <xsl:when test="$month= 4">April</xsl:when>
                <xsl:when test="$month= 5">May</xsl:when>
                <xsl:when test="$month= 6">June</xsl:when>
                <xsl:when test="$month= 7">July</xsl:when>
		<xsl:when test="$month= 8">August</xsl:when>
		<xsl:when test="$month= 9">September</xsl:when>
		<xsl:when test="$month=10">October</xsl:when>
		<xsl:when test="$month=11">November</xsl:when>
		<xsl:when test="$month=12">December</xsl:when>
	</xsl:choose>

	<xsl:if test="$year>0">
	<xsl:text> </xsl:text>
	<xsl:value-of select="$year" />
        <xsl:text>: </xsl:text>
	</xsl:if>
</xsl:template>

</xsl:stylesheet>



