<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output encoding="utf-8"/>

<xsl:template match="/">
  <xsl:apply-templates select="$foo"/>
</xsl:template>

</xsl:stylesheet>
