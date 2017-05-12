<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output
	encoding="UTF-8"
/>

<xsl:include href="misc.xsl"/>

<xsl:template match="/page">
	<rss version="2.0">
		<channel>
			<title>
				<xsl:value-of select="/page/manifest/title/text()"/>
			</title>
			<link>
				<xsl:text>http://</xsl:text>
				<xsl:value-of select="/page/manifest/request/server/text()"/>
				<xsl:text>/</xsl:text>
			</link>
			<description>Test site.</description>
			<language>en-gb</language>
			<pubDate>
				<xsl:value-of select="/page/content/rss-view/pub-date/text()"/>
			</pubDate>
			<lastBuildDate>
				<xsl:value-of select="/page/content/rss-view/pub-date/text()"/>
			</lastBuildDate> 

			<xsl:apply-templates select="/page/content"/>
		</channel>
	</rss>
</xsl:template>

<xsl:template match="/page/content">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="/page/content/rss-view/pub-date"/>

<xsl:template match="/page/content/rss-view/message">
	<item>
		<title>
			<xsl:value-of select="title/text()" disable-output-escaping="yes"/>
		</title>
		<link>
			<xsl:text>http://</xsl:text>
			<xsl:value-of select="/page/manifest/request/server/text()"/>
			<xsl:text>/</xsl:text>
			<xsl:value-of select="@uri"/>
			<xsl:text>/</xsl:text>
		</link>
		<description>
			<xsl:copy-of select="content/text() | content/*" disable-output-escaping="yes"/>
		</description>
		<pubDate>
			<xsl:value-of select="@date"/>
		</pubDate>
		<author></author>
	</item>
</xsl:template>

<xsl:template name="message-date">
	<span class="date">
		<xsl:value-of select="@day"/>
		<xsl:text>&#160;</xsl:text>
		<xsl:call-template name="month-name">
			<xsl:with-param name="month" select="@month"/>
		</xsl:call-template>
		<xsl:text>&#160;</xsl:text>
		<xsl:value-of select="@year"/>
	</span>
</xsl:template>

</xsl:stylesheet>
