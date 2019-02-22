<?xml version="1.0" encoding="UTF-8"?>
<!--
 ! File: dtatw-txmlsort.xsl
 ! Author: Bryan Jurish (moocow@cpan.org)
 ! Description:
 !   + sort dta-tokwrap *.t.xml files sentence-wise in source-document order
 !   + uses //s/w/@xb attribute (source xml-byte offset+length) to determine
 !     source-document order
 !   + only really useful if you're calling dtatw-tok2xml by hand, since
 !     the DTA::TokWrap::Processor::tok2xml perl module sorts using native perl
 !     code which is about 10x faster than xsltproc for this script
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- options -->
  <!--<xsl:strip-space elements="sentences s w a"/>-->

  <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
  <!-- Mode: main -->

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: root: copy attributes and sort sentences -->
  <xsl:template match="/*">
    <xsl:comment> sorted in sentence-wise source-document order by dtatw-txmlsort.xsl </xsl:comment>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="s">
	<xsl:sort select="number(substring-before(w[position()=1]/@xb,'+'))" data-type="number" order="ascending"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: copy -->
  <xsl:template match="@*|*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*|*|text()|processing-instruction()|comment()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>