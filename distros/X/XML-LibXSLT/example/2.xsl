<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [
  <!ENTITY foo "fooooo!">
]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html"/>

  <xsl:template match="/">
    <html><body>&foo;<xsl:copy/><xsl:apply-templates/></body></html>
  </xsl:template>

</xsl:stylesheet>
