<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" version="1.0">
<xsl:output method="text" omit-xml-declaration="yes" indent="no" xml:space="preserve"/>

<xsl:template match="/PubmedArticleSet">

  <xsl:for-each select="PubmedArticle/MedlineCitation">

    <xsl:text>Title: </xsl:text><xsl:value-of select="Article/ArticleTitle"/>

    <xsl:text>
Abstract: 
</xsl:text><xsl:value-of select="Article/Abstract/AbstractText"/>

    <xsl:text>
Date: </xsl:text><xsl:value-of select="Article/Journal/JournalIssue/PubDate/Year"/>-<xsl:value-of select="Article/Journal/JournalIssue/PubDate/Month"/>

    <xsl:text>
Journal: </xsl:text><xsl:value-of select="MedlineJournalInfo/MedlineTA"/>

    <xsl:text>
Type: </xsl:text><xsl:value-of select="Article/PublicationTypeList/PublicationType"/>

    <xsl:text>
Author: </xsl:text>
	<xsl:for-each select="Article/AuthorList/Author">
		<xsl:value-of select="LastName"/>-<xsl:value-of select="Initials"/>
		<xsl:choose>
			<xsl:when test="position()!=last()">
				<xsl:text>, </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>.</xsl:text>		     
			</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>

  </xsl:for-each>
</xsl:template>
</xsl:stylesheet>
