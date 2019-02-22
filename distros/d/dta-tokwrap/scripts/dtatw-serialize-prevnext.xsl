<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" version="1.0" indent="yes" encoding="UTF-8"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- template: root: traverse -->
  <xsl:template match="/*" priority="100">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
    </xsl:copy>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- templates: next -->
  <xsl:template match="*[@next and not(@prev)]" priority="10">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()"/>
      <xsl:message>chain start with id=<xsl:value-of select="@xml:id"/>&#10;</xsl:message>
      <xsl:call-template name="chain.next">
	<xsl:with-param name="nextid" select="@next"/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@prev]" priority="10">
    <!-- ignore -->
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- templates: NAMED: chain.next -->
  <xsl:template name="chain.next">
    <xsl:param name="nextid" select="./@next"/>
    <xsl:message>chaining with nextid=<xsl:value-of select="$nextid"/>&#10;</xsl:message>
    <xsl:if test="$nextid">
      <xsl:variable name="nextnod" select="id($nextid)"/>
      <xsl:apply-templates select="$nextnod/*|$nextnod/text()"/>
      <xsl:call-template name="chain.next">
	<xsl:with-param name="nextid" select="$nextnod/@next"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- templates: DEFAULT: copy -->
  <xsl:template match="*|@*|text()|comment()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="*|@*|text()|comment()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
