<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.1"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

   <xsl:template match="/">
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <link rel="stylesheet" type="text/css" href="xslt.css" />
          <title><xsl:value-of select="/pod/head/title" /></title>
        </head>
        <body>
          <xsl:apply-templates />
        </body>
      </html>
   </xsl:template>

   <xsl:template match="head/title">
     <h1>NAME</h1>
     <xsl:apply-templates />
   </xsl:template>

   <xsl:template match="sect1/title">
     <h1><xsl:value-of select="." /></h1>
   </xsl:template>

   <xsl:template match="sect2/title">
     <h2><xsl:value-of select="." /></h2>
   </xsl:template>

   <xsl:template match="para">
     <p><xsl:value-of select="." /></p>
   </xsl:template>

   <xsl:template match="list">
     <ul>
       <xsl:apply-templates />
     </ul>
   </xsl:template>

   <xsl:template match="item">
     <li>
       <xsl:apply-templates />
     </li>
   </xsl:template>

   <xsl:template match="itemtext">
     <b><xsl:value-of select="." /></b>
   </xsl:template>

   <xsl:template match="verbatim">
     <pre>
     <xsl:value-of select="." />
     </pre>
   </xsl:template>
</xsl:stylesheet>
