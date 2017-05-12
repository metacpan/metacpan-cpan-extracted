<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version='1.0'>
<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/html/chunk.xsl"/>
<!-- Parameters -->

<xsl:param name="chunk.first.sections" select="1"/>
<xsl:param name="chunk.section.depth" select="2"/>
<xsl:param name="toc.section.depth" select="1"/>
<xsl:param name="section.autolabel" select="0"/>
<xsl:param name="generate.section.toc.level" select="1"/>
<xsl:param name="base.dir" select="'chunks/'"/>
<xsl:param name="use.id.as.filename" select="'1'"/>


<xsl:attribute-set name="body.attrs">
  <xsl:attribute name="bgcolor">white</xsl:attribute>
  <xsl:attribute name="text">black</xsl:attribute>
  <xsl:attribute name="link">#0000FF</xsl:attribute>
  <xsl:attribute name="vlink">#840084</xsl:attribute>
  <xsl:attribute name="alink">#0000FF</xsl:attribute>
</xsl:attribute-set>

</xsl:stylesheet>