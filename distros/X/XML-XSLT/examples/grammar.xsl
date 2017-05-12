<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match='/'>
    <HTML>
      <HEAD>
        <TITLE>Example application of XML::XSLT</TITLE>
      </HEAD>
      <BODY BGCOLOR="#EEEEEE" BACKGROUND="gifs/achtergrond.gif">
        <CENTER>
          <H1>Example application of XML::XSLT</H1>
          <I>Extraction of grammar rules from Recommendations</I>
        </CENTER>

        <xsl:for-each select=".//prod">
          [<xsl:value-of select="position()" />] <xsl:value-of select="lhs" /> ::= <xsl:apply-templates select=".//rhs" /> <BR />
        </xsl:for-each>

      </BODY>
    </HTML>
  </xsl:template>

  <xsl:template match='rhs'>
    <xsl:value-of select="." />
  </xsl:template>
</xsl:stylesheet>
