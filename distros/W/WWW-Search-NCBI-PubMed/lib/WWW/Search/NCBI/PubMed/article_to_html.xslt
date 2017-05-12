<?xml version='1.0' encoding='utf-8' ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" version="1.0"/>
  <xsl:template match="/">
    <HTML>
      <BODY STYLE="font-family:Arial, helvetica, sans-serif; font-size:12pt; background-color:#EEEEEE">

		<DIV STYLE="background-color:blue; color:white; padding:4px">
			<xsl:value-of select="/PubMedArticle/MedlineCitation/Article/ArticleTitle"/>
		</DIV>

		<DIV STYLE="background-color:yellow; color:black; padding:4px">
			<xsl:value-of select="/PubMedArticle/MedlineCitation/Article/Abstract/AbstractText"/>
		</DIV>

		<xsl:for-each select="/PubMedArticle/MedlineCitation/Article/AuthorList/Author">
			<SPAN STYLE="font-weight:bold; color:black">
				<xsl:value-of select="LastName"/>-<xsl:value-of select="Initials"/>,
			</SPAN>
		</xsl:for-each>

 			<DIV STYLE="margin-left:20px; margin-bottom:1em; font-size:10pt">
			</DIV>

      </BODY>
    </HTML>
  </xsl:template>
</xsl:stylesheet>
