<?xml version='1.0'?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version='1.0'>
  <xsl:import 
    href="http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl"/>

  <!-- Parameters -->  
  <xsl:param name="generate.section.toc.level" select="1"/>

  <!-- XEP -->
  <xsl:param name="xep.extensions" select="1"/>

  <!--  <xsl:param name="passivetex.extensions" select="1"/> -->
  <xsl:param name="section.autolabel" select="1"/>
  <xsl:param name="shade.verbatim" select="1"/>

  <!--  <xsl:param name="body.font.family" select="'Palatino'"/> -->
  <xsl:param name="paper.type" select="'A4'"/>
  <xsl:param name="footer.rule" select="0"/>

  <xsl:param name="title.margin.left">0pt</xsl:param>
  
  <!-- implicitni zarovnavani textu -->
  <xsl:param name="alignment">justify</xsl:param>
  
  <!-- body indentation -->
  <xsl:param name="body.start.indent" select="'0pt'"/>


  <xsl:attribute-set name="verbatim.properties">
    <xsl:attribute name="space-before.minimum">0.8em</xsl:attribute>
    <xsl:attribute name="space-before.optimum">1em</xsl:attribute>
    <xsl:attribute name="space-before.maximum">1.2em</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="monospace.verbatim.properties" 
    use-attribute-sets="verbatim.properties monospace.properties">
    <xsl:attribute name="text-align">start</xsl:attribute>
    <xsl:attribute name="wrap-option">wrap</xsl:attribute>
    <xsl:attribute name="font-size">9pt</xsl:attribute>
  </xsl:attribute-set>


<!-- index -->

<xsl:param name="make.index.markup" select="1"/>

<xsl:attribute-set name="xep.index.item.properties">
  <xsl:attribute name="merge-subsequent-page-numbers">true</xsl:attribute>
  <xsl:attribute name="link-back">true</xsl:attribute>
</xsl:attribute-set>
  
</xsl:stylesheet>
