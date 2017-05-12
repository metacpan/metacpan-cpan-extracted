<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">

<xsl:template match="/collection/book">
      <xsl:apply-templates select="title"/>
</xsl:template>

<xsl:template match="title">
  <div style="color:blue">
    Title: <xsl:value-of select="."/>
  </div>
</xsl:template>

<xsl:include href="8xslincludefile.xml" />

</xsl:stylesheet>