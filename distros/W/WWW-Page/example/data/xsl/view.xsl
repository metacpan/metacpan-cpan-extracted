<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output
	encoding="UTF-8"
/>

<xsl:include href="misc.xsl"/>

<xsl:template match="/page">
	<html>
		<head>
			<title>
				<xsl:choose>
					<xsl:when test="content/current-view/message/@type = 'single-message'">
						<xsl:value-of select="content/current-view/message/title/text()" disable-output-escaping="yes"/>
					</xsl:when>
					<xsl:when test="content/current-view/group-keyword">
						<xsl:text>Everything we know about </xsl:text>
						<xsl:value-of select="content/current-view/group-keyword/text()" disable-output-escaping="yes"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="manifest/title/text()"/>

						<xsl:if test="content/month-view">
							<xsl:text> &#8212; </xsl:text>
							<xsl:call-template name="month-name">
								<xsl:with-param name="month" select="content/month-view/@month"/>
							</xsl:call-template>
							<xsl:text> </xsl:text>
							<xsl:value-of select="content/month-view/@year"/>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</title>
			<link rel="alternate" type="application/rss+xml" title="RSS" href="/rss/" />
			<link rel="stylesheet" type="text/css" href="/css/main.css" />
		</head>
		<body>
			<xsl:if test="manifest/request/uri/text() = '/'">
				<div id="rss-link">
					<a href="/rss/">RSS</a>
				</div>
			</xsl:if>
			<div class="top">
				<xsl:choose>
					<xsl:when test="manifest/request/uri/text() = '/'">
						<xsl:value-of select="manifest/title/text()"/>
					</xsl:when>
					<xsl:when test="content/month-view">
						<a href="/">
							<xsl:value-of select="manifest/title/text()"/>
						</a>
						<xsl:text> / </xsl:text>
						<xsl:call-template name="show-month-title"/>
					</xsl:when>
					<xsl:when test="content/current-view/group-keyword">
						<a href="/">
							<xsl:value-of select="/page/manifest/title/text()"/>
						</a>
						<xsl:text> / about </xsl:text>
						<xsl:value-of select="content/current-view/group-keyword/text()" disable-output-escaping="yes"/>
					</xsl:when>
					<xsl:otherwise>
						<a href="/">
							<xsl:value-of select="/page/manifest/title/text()"/>
						</a>
					</xsl:otherwise>
				</xsl:choose>
			</div>

			<xsl:apply-templates select="/page/content"/>

			<div class="footer">
				<xsl:if test="/page/manifest/date/@year != 2007">
					<xsl:text>2007&#8212;</xsl:text>
				</xsl:if>
				<xsl:value-of select="/page/manifest/date/@year"/>
				<br />
				<xsl:text>Test site</xsl:text>
			</div>

		</body>
	</html>
</xsl:template>

<xsl:template match="/page/content">
	<div class="content">
		<xsl:apply-templates/>

		<xsl:if test="/page/manifest/request/uri/text() != '/'">
			<div>
				<xsl:if test="month-view">
					<xsl:call-template name="month-navigator"/>
				</xsl:if>
			</div>
		</xsl:if>

		<xsl:if test="/page/manifest/request/uri/text() != '/' and not (starts-with (/page/manifest/request/uri/text(), '/search/'))">
			<xsl:call-template name="search-form"/>
		</xsl:if>			
	</div>
</xsl:template>

<xsl:template match="group-keyword"/>

<xsl:template match="message">
	<div class="message">
		<h1>
			<xsl:choose>
				<xsl:when test="../keyword-map">
					<a href="/{@uri}/">
						<xsl:value-of select="title/text()" disable-output-escaping="yes"/>
					</a>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="title/text()" disable-output-escaping="yes"/>
				</xsl:otherwise>
			</xsl:choose>
		</h1>
		<xsl:value-of select="content/text() | content/*" disable-output-escaping="yes"/>

		<xsl:choose>
			<xsl:when test="keywords/item">
				<p class="keywords">
					<xsl:for-each select="keywords/item">
						<a href="/{@uri}/">
							<xsl:value-of select="text()" disable-output-escaping="yes"/>
						</a>
						<xsl:if test="position() != last()">
							<xsl:text>, </xsl:text>
						</xsl:if>
					</xsl:for-each>
					<xsl:text>&#160;&#8212; </xsl:text>
					<xsl:call-template name="message-date"/>
				</p>
			</xsl:when>
			<xsl:when test="../keyword-map">
				<p class="keywords">
					<xsl:for-each select="../keyword-map/item[@message-id = current()/@id]">
						<xsl:choose>
							<xsl:when test="@uri = /page/content/current-view/group-keyword/@uri">
								<b>
									<xsl:value-of select="/page/manifest/keyword-list/item[@uri = current()/@uri]/text()" disable-output-escaping="yes"/>
								</b>
							</xsl:when>
							<xsl:otherwise>
								<a href="/{@uri}/">
									<xsl:value-of select="/page/manifest/keyword-list/item[@uri = current()/@uri]/text()" disable-output-escaping="yes"/>
								</a>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:choose>
							<xsl:when test="position() != last()">
								<xsl:text>, </xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text>&#160;&#8212; </xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
					<xsl:call-template name="message-date"/>
				</p>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="message-date"/>
			</xsl:otherwise>
		</xsl:choose>
	</div>
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

<xsl:template name="show-month-title">
	<xsl:call-template name="month-name">
		<xsl:with-param name="month" select="/page/content/month-view/@month"/>
	</xsl:call-template>

	<xsl:text> </xsl:text>
	<xsl:value-of select="/page/content/month-view/@year"/>
</xsl:template>

<xsl:template match="content/tag-cloud">
	<div class="common-navigation">
		<xsl:variable name="max" select="@max"/>
		<xsl:variable name="min" select="@min"/>

		<p>Deeper navigation&#8212;through the list of tags, the calendar, or&#160;search.</p>
		<xsl:call-template name="search-form"/>
			
		<table>
			<tr>
				<td width="60%">
					<div class="tag-cloud">
						<xsl:for-each select="item">
							<span class="nobr">
								<a href="/{@uri}/">
									<xsl:attribute name="class">
										<xsl:text>sz</xsl:text>
										<xsl:value-of select="round (10 * (@count - $min) div $max)"/>
									</xsl:attribute>
									<xsl:value-of select="text()" disable-output-escaping="yes"/>
								</a>
								<xsl:text>&#160;&#160;</xsl:text>
							</span>
							<xsl:text> </xsl:text>
						</xsl:for-each>
					</div>
				</td>
				<td>
					<xsl:call-template name="month-calendar"/>
				</td>
			</tr>
		</table>
		<br />
	</div>
</xsl:template>

<xsl:template match="content/month-calendar"/>

<xsl:template name="month-calendar">
	<xsl:variable name="month-calendar" select="/page/content/month-calendar"/>
	<div class="calendar">
		<div>
			<b>
				<xsl:value-of select="$month-calendar/item[1]/@year"/>
				<br />
			</b>
			<xsl:for-each select="$month-calendar/item">
				<a href="/{@year}/{@month}/">
					<xsl:call-template name="month-name">
						<xsl:with-param name="month" select="@month"/>
					</xsl:call-template>
				</a>
				<br />
				<xsl:if test="@year != following-sibling::item[1]/@year">
					<xsl:text disable-output-escaping="yes">
						&lt;/div&gt;
						&lt;div&gt;
					</xsl:text>
					<b>
						<xsl:value-of select="following-sibling::item[1]/@year"/>
					</b>
					<br />
				</xsl:if>
			</xsl:for-each>
		</div>
	</div>
	<br clear="all" />
</xsl:template>

<xsl:template name="month-navigator">
	<p>
		<xsl:variable name="current-month" select="/page/content/month-calendar/item[/page/content/month-view/@year and @month = /page/content/month-view/@month]"/>
		
		<xsl:variable name="prev" select="/page/content/month-calendar/item[generate-id (preceding-sibling::item[1]) = generate-id ($current-month)]"/>
		<xsl:variable name="next" select="/page/content/month-calendar/item[generate-id (following-sibling::item[1]) = generate-id ($current-month)]"/>

		<xsl:if test="$prev">
			<a href="/{$prev/@year}/{$prev/@month}/">
				<xsl:attribute name="title">
					<xsl:call-template name="month-name">
						<xsl:with-param name="month" select="$prev/@month"/>
					</xsl:call-template>
					<xsl:text> </xsl:text>
					<xsl:value-of select="$prev/@year"/>
				</xsl:attribute>
				<xsl:text>&#8592;</xsl:text>
			</a>
			<xsl:text>&#160; </xsl:text>
		</xsl:if>

		<xsl:call-template name="month-name">
			<xsl:with-param name="month" select="/page/content/month-view/@month"/>
		</xsl:call-template>
		<xsl:text>&#160;</xsl:text>
		<xsl:value-of select="/page/content/month-view/@year"/>

		<xsl:if test="$next">
			<xsl:text>&#160; </xsl:text>
			<a href="/{$next/@year}/{$next/@month}/">
				<xsl:attribute name="title">
					<xsl:call-template name="month-name">
						<xsl:with-param name="month" select="$next/@month"/>
					</xsl:call-template>
					<xsl:text> </xsl:text>
					<xsl:value-of select="$next/@year"/>
				</xsl:attribute>
				<xsl:text>&#8594;</xsl:text>
			</a>
		</xsl:if>
	</p>
	<br />
</xsl:template>

<xsl:template match="content/search-keywords">
	<xsl:call-template name="search-form">
		<xsl:with-param name="value" select="../search-results/query/text()"/>
	</xsl:call-template>

	<xsl:if test="item">
		<div class="search-keywords">
			<xsl:text>Look also our articles about </xsl:text>
			<xsl:for-each select="item">
				<a href="/{@uri}/">
					<xsl:value-of select="text()"/>
				</a>
				<xsl:choose>
					<xsl:when test="position() = last() - 1">
						<xsl:text> and </xsl:text>
					</xsl:when>
					<xsl:when test="position() != last()">
						<xsl:text>, </xsl:text>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</div>
	</xsl:if>
</xsl:template>

<xsl:template match="content/search-results">
	<xsl:choose>
		<xsl:when test="item">
			<ul class="search-results">
				<xsl:apply-templates select="item"/>
			</ul>
		</xsl:when>
		<xsl:otherwise>
			<p>Nothing found.</p>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="search-results/item">
	<li>
		<h4>
			<a href="/{@uri}/">
				<xsl:value-of select="title/* | title/text()" disable-output-escaping="yes"/>
			</a>
		</h4>
		<p>
			<xsl:value-of select="content/* | content/text()" disable-output-escaping="yes"/>
		</p>
	</li>
</xsl:template>

<xsl:template name="search-form">
	<xsl:param name="value" select="''"/>
	
	<div id="ysearchmod">
	   <form action="/search/">
		   <div id="ysearchautocomplete">   
			   <input id="ysearchinput" type="search" name="text" value="{$value}" maxlength="100" results="10" />
		   </div>  
	   </form>  
	</div>
</xsl:template>

</xsl:stylesheet>
