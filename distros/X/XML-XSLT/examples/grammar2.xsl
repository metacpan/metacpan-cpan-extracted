<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match="text()|@*" />
  <!-- this ensures that all nodes other than the ones for which templates are given
       below, are 'skipped' and no content is passed to output -->

  <xsl:template match='/'>
    <HTML>
      <HEAD>
        <TITLE>Example application of XML::XSLT</TITLE>
      </HEAD>
      <BODY BGCOLOR="#EEEEEE" BACKGROUND="gifs/achtergrond.gif">
        <CENTER>
          <H1>Example application of XML::XSLT</H1>
          <I>Extraction of grammar rules from Recommendations using 'Lazy' evaluation</I>
          (all nodes of the trees are parsed and templates are searched for. Most
          likely very slow compared to the other version, which directly selects all
          prod nodes that are present in the document tree)
        </CENTER>

        <xsl:apply-templates />
        <!-- add `select="//prod"' to speed up -->

      </BODY>
    </HTML>
  </xsl:template>

  <xsl:template match='prod'>
    [<xsl:value-of select="position()" />] <xsl:value-of select="lhs" /> ::= <xsl:apply-templates  /> <BR />
    <!-- add `select="rhs"' to apply-templates to speed parsing up -->
  </xsl:template>

  <xsl:template match='rhs'>
    <xsl:value-of select="." />
  </xsl:template>
</xsl:stylesheet>
