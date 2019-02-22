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
  <!-- Templates: c: assign id -->
  <xsl:template match="c"> <!-- [not(@xml:id)] -->
    <xsl:element name="c">
      <xsl:attribute name="xml:id"><xsl:value-of select="generate-id(.)"/></xsl:attribute>
      <xsl:apply-templates select="@*[name()!='xml:id']|*|text()|processing-instruction()|comment()"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- Templates: default: copy -->
  <xsl:template match="*|@*|text()|processing-instruction()|comment()" priority="-1">
   <xsl:copy>
     <xsl:apply-templates select="*|@*|text()|processing-instruction()|comment()"/>
   </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
