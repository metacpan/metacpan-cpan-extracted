<?xml version="1.0"?>

<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:w="http://web.meon.eu/"
    exclude-result-prefixes="w"
>

<xsl:output
    method="html"
    indent="yes"
    omit-xml-declaration="yes"
    doctype-system="about:legacy-compat"
/>

<xsl:template match="/">
  <html lang="en">
      <xsl:call-template name="html-head" />
  <body>
      <xsl:call-template name="page-header"/>
      <xsl:apply-templates />
      <xsl:call-template name="page-footer"/>
  </body>
  </html>
</xsl:template>

<xsl:template name="html-head">
  <head>
    <meta charset="utf-8"/>
    <title><xsl:copy-of select="w:page/w:meta/w:title/text()" /></title>
    <meta name="description" content=""/>
    <meta name="author" content="meon-Web"/>
    <meta name="viewport" content="width=1024, user-scalable=yes"/>
    <meta name="HandheldFriendly" content="true"/>
    <meta name="MobileOptimized" content="1024"/>

    <link rel="shortcut icon" href="/favicon.ico"/>
    <xsl:call-template name="extra-headers" />
  </head>
</xsl:template>

<xsl:template name="page-header">
</xsl:template>

<xsl:template name="extra-headers">
</xsl:template>

<xsl:template name="page-footer">
</xsl:template>

<xsl:template match="xhtml:*">
   <xsl:copy><!--copy node being visited-->
     <xsl:copy-of select="@*"/><!--copy of all attributes-->
     <xsl:apply-templates/><!--process the children-->
   </xsl:copy>
</xsl:template>

</xsl:stylesheet>
