<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output indent="yes" method="xml" omit-xml-declaration="yes" version="1.0" encoding="UTF-8"/>

  <!-- disable all default text node output -->
  <xsl:template match="text()"/>

  <!-- match on Combine xml record -->
  <xsl:template match="//documentRecord">
    <documentRecord><xsl:attribute  name="id">
      <xsl:value-of select="@id"/> </xsl:attribute>
    <acquisition>
    <acquisitionData>
      <xsl:copy-of select="modifiedDate"/>
      <xsl:copy-of select="checkedDate"/>
      <xsl:copy-of select="expiryDate"/>
      <xsl:copy-of select="httpServer"/>
      <xsl:copy-of select="urls"/>
    </acquisitionData>
    <xsl:copy-of select="originalDocument"/>
    <xsl:copy-of select="canonicalDocument"/>
      <xsl:copy-of select="metaData"/>
      <xsl:copy-of select="links"/>
      <analysis>
        <xsl:copy-of select="property"/>
        <xsl:copy-of select="topic"/>
      </analysis>
    </acquisition>
    </documentRecord>
  </xsl:template>

</xsl:stylesheet>
