<?xml version="1.0"  encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" encoding="UTF-8"/>

<!-- default rules: passthrough -->

<xsl:template match="/">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="*">
    <xsl:copy select=".">
        <xsl:copy-of select="namespace::*"/>
        <xsl:apply-templates select="@*"/>
        <xsl:apply-templates/>
    </xsl:copy>
</xsl:template>

<xsl:template match="@*">
  <xsl:copy>
    <xsl:copy-of select="namespace::*"/>
    <xsl:value-of select="."/>
  </xsl:copy>
</xsl:template>

<xsl:template match="text()">
    <xsl:value-of select="."/>
</xsl:template>

<!-- Automatically calculate the correct value for the total-slides tag -->

<!-- Must be modified:
  +1 if slideshow title page is used
     +count(//slideset) if slideset title pages are used
-->

<xsl:template match="total-slides">
  <total-slides><xsl:value-of select="count(//slide)+1"/></total-slides>
</xsl:template>

<!-- Table of contents tag -->

<xsl:template match="toc">
	<xsl:variable name="maxlevel">
		<xsl:choose>
			<xsl:when test="@maxlevel"><xsl:value-of select="@maxlevel"/></xsl:when>
			<xsl:otherwise>2</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:for-each select="/*">
		<xsl:call-template name="toc">
			<xsl:with-param name="maxlevel" select="$maxlevel"/>
		</xsl:call-template>
	</xsl:for-each>
</xsl:template>

<xsl:template name="toc">
	<xsl:param name="maxlevel" select="2"/>
	<xsl:param name="prefix" select="''"/>
	<xsl:param name="level" select="0"/>
	<xsl:if test="$level &lt; $maxlevel">
		<list ordered="ordered">
		<xsl:for-each select="slide[./title]|slideset[./title]">
			<xsl:variable name="newprefix" select="concat($prefix,count(preceding-sibling::slide[./title]|preceding-sibling::slideset[./title])+1,'.')"/>
			<point><xsl:copy-of select="title/*|title/text()"/></point>
			<xsl:if test="self::slideset">
				<xsl:call-template name="toc">
					<xsl:with-param name="maxlevel" select="$maxlevel"/>
					<xsl:with-param name="prefix" select="$newprefix"/>
					<xsl:with-param name="level" select="$level+1"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>
		</list>
	</xsl:if>
</xsl:template>

<!-- Example 1: modifying appearance of existing elements -->

<xsl:template match="point">
  <point>
    <xsl:apply-templates select="@*"/>
    <span style='font-family:serif'>
      <xsl:apply-templates/>
    </span>
  </point>
</xsl:template>

<!-- Example 2: creating new elements -->

<xsl:template match="colour">
  <span style='color:{@name}'>
    <xsl:apply-templates/>
  </span>
</xsl:template>

<!-- Example 3: disabling slideset title pages -->

<xsl:template match="slideset">
  <slideset type='empty'>
    <xsl:apply-templates/>
  </slideset>
</xsl:template>


<!-- Example 4: Creating a completely custom page layout -->

<xsl:template match="slide/title"/>

<xsl:template match="slide">
  <slide type='empty'>
    <xsl:apply-templates select="@transition"/>
    <box x="0" y="-4" width="612" height="470">
      <value type='background'/>
    </box>
    <box x="430" y="0" width="182" height="10">
      <value type='logo'/>
    </box>
    <rect x="20" y="30" width="572" height="40" style="stroke: black"/>
    <box x="0" y="400" width="612" height="100">
      <plain>
        <span style="stroke: black; fill: red; font: italic 28pt serif; font-weight: bold;">
          <xsl:copy-of select="title/text()|title/*"/>
        </span>
      </plain>
    </box>
    <box x="0" y="350" width="612" height="350">
      <xsl:apply-templates select="@default-transition"/>
      <xsl:apply-templates/>
    </box>
  </slide>
</xsl:template>

</xsl:stylesheet>
