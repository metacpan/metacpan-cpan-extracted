<?xml version='1.0'?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version='1.0'>
  <xsl:import 
    href="http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl"/>

  <!-- Parameters -->  
  <xsl:param name="generate.section.toc.level" select="1"/>
  <xsl:param name="fop.extensions" select="1"/>
  <xsl:param name="section.autolabel" select="1"/>
  <xsl:param name="shade.verbatim" select="1"/>
  <xsl:param name="paper.type" select="'A4'"/>
  <xsl:param name="footer.rule" select="0"/>
  <xsl:param name="graphic.default.extension" select="'gif'"/>
  <xsl:param name="admon.graphics.extension" select="'gif'"/>
  <xsl:param name="callout.graphics.extension" select="'.gif'"/>

  <xsl:attribute-set name="verbatim.properties">
    <xsl:attribute name="space-before.minimum">0.8em</xsl:attribute>
    <xsl:attribute name="space-before.optimum">1em</xsl:attribute>
    <xsl:attribute name="space-before.maximum">1.2em</xsl:attribute>
  </xsl:attribute-set>
  
</xsl:stylesheet>