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
    <title><xsl:copy-of select="w:page/w:meta/w:title/text()" /></title>
    <meta charset="utf-8"/>
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <meta name="description" content=""/>
    <meta name="author" content=""/>
    <link rel="shortcut icon" href="/static/docs-assets/ico/favicon.png"/>

    <xsl:call-template name="extra-headers" />
    <xsl:call-template name="document-headers" />
  </head>
</xsl:template>

<xsl:template name="page-header">
</xsl:template>

<xsl:template name="extra-headers">
</xsl:template>

<xsl:template name="document-headers">
    <xsl:copy-of select="w:page/w:meta/w:head/w:*" />
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
