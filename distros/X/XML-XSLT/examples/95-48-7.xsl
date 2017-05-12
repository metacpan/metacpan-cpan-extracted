<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <xsl:processing-instruction name="cml">version="1.0" encoding="ISO-8859-1"</xsl:processing-instruction>
    <![CDATA[<!DOCTYPE molecule SYSTEM "cml.dtd" []>]]>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="MOL">
    <molecule id="{@ID}">
      <xsl:apply-templates/>
    </molecule>
  </xsl:template>

  <xsl:template match="XVAR">
	<xsl:choose>
	  <xsl:when test="./[@BUILTIN='BOILINGPOINT']">
            <float title="BoilingPoint" units="degrees Celsius"><xsl:value-of select="."/></float>
	  </xsl:when>
	  <xsl:when test="./[@BUILTIN='MELTINGPOINT']">
            <float title="MeltingPoint" units="degrees Celsius"><xsl:value-of select="."/></float>
	  </xsl:when>
	</xsl:choose>
  </xsl:template>
</xsl:stylesheet>
