<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output
    method="xml"
    version="1.0"
    indent="yes"
    encoding="UTF-8"
    />

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- parameters -->
  <!--<xsl:param name="path" select="//text/w"/>-->

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- options -->
  <!--<xsl:strip-space elements="head body form entry sense add q bibl author title ref"/>-->

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- Templates: root: traverse -->
  <xsl:template match="/">
   <xsl:apply-templates/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- Templates: text: insert <lb/> for newlines -->
  <xsl:template match="text()">
    <xsl:call-template name="insert-lb"/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- Templates: named: insert-lb -->
  <xsl:template name="insert-lb">
   <xsl:param name="text" select="."/>
   <xsl:choose>
     <xsl:when test="contains($text, '&#xa;')">
       <xsl:value-of select="substring-before($text, '&#xa;')"/>
       <lb/>
       <xsl:text>&#xa;</xsl:text>
       <xsl:call-template name="insert-lb">
	 <xsl:with-param name="text" select="substring-after($text,'&#xa;')"/>
       </xsl:call-template>
     </xsl:when>
     <xsl:otherwise>
       <xsl:value-of select="$text"/>
     </xsl:otherwise>
   </xsl:choose>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- Templates: default: copy -->
  <xsl:template match="*|@*|text()|processing-instruction()|comment()" priority="-1">
   <xsl:copy>
     <xsl:apply-templates select="*|@*|text()|processing-instruction()|comment()"/>
   </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
