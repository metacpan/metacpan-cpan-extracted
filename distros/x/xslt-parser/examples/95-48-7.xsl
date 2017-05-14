<xsl:stylesheet>
  <xsl:template match="/">
    <xsl:processing-instruction name="cml">version="1.0" encoding="ISO-8859-1"</xsl:processing-instruction>
    <![CDATA[<!DOCTYPE molecule SYSTEM "cml.dtd" []>]]>
    <xsl:sub-template match='CML'>
      <xsl:sub-template match='MOL'>
	<molecule id="{@ID}">
	  <xsl:for-each select="XVAR">
	    <xsl:choose>
	      <xsl:when test=".[@BUILTIN='BOILINGPOINT']">
        	<float title="BoilingPoint" units="degrees Celsius"><xsl:value-of select="."/></float>
	      </xsl:when>
	      <xsl:when test=".[@BUILTIN='MELTINGPOINT']">
        	<float title="MeltingPoint" units="degrees Celsius"><xsl:value-of select="."/></float>
	      </xsl:when>
	    </xsl:choose>
	  </xsl:for-each>
	</molecule>
      </xsl:sub-template>
    </xsl:sub-template>
  </xsl:template>
</xsl:stylesheet>



