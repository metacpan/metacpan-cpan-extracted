<?xml version="1.0"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/TR/WD-xsl">

  <xsl:template match="*">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="/">
    <HTML>
    <HEAD>      
      <xsl:if test="molecule[@convention='DictOrgChem']">
        <base href="http://www.sci.kun.nl/sigma/Chemisch/Woordenboek/"/>
        <link rel="stylesheet" href="http://www.sci.kun.nl/sigma/Chemisch/Woordenboek/gui/styles/woc.css" type="text/css"/>
      </xsl:if>
    </HEAD>
    <BODY>
      <H1>Physical Properties</H1>
      <xsl:apply-templates/>
    </BODY>
    </HTML>
  </xsl:template>

  <xsl:template match="molecule">
    <b>Chemical:</b> <xsl:value-of select="@id"/><p/>
    <ul><xsl:apply-templates/></ul>
  </xsl:template>

  <xsl:template match="float">
    <b><xsl:value-of select="@title"/>:</b> <xsl:value-of/> <xsl:value-of select="@units"/><br/>
  </xsl:template>

  <xsl:template match="string">
    <b><xsl:value-of select="@title"/>:</b> <xsl:value-of/><br/>
  </xsl:template>

</xsl:stylesheet>
