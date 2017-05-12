<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ex="http://explain.z3950.org/dtd/2.0/"
    version="1.0">

  <xsl:output indent="yes"
        method="xml"
        version="1.0"
        encoding="UTF-8"/>

  <xsl:template match="node() | @*">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/> 
    </xsl:copy>
  </xsl:template>

  <!-- Suppress authentication info -->
  <xsl:template match="/ex:explain/ex:serverInfo/ex:authentication"/>

</xsl:stylesheet>
