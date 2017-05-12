<?xml version="1.0"?>

<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:w="http://web.meon.eu/"
    exclude-result-prefixes="w"
>

<xsl:import href="lib/html-page.xsl" />

<xsl:output
    method="html"
    indent="yes"
    omit-xml-declaration="yes"
    doctype-system="about:legacy-compat"
/>

<xsl:template match="/w:page">
    <div class="page-content">
        <xsl:apply-templates select="w:content/xhtml:*"/>
    </div>
</xsl:template>

<xsl:template name="page-header">
    <div class="page-header"></div>
</xsl:template>

<xsl:template name="page-footer">
    <div class="page-footer"></div>
</xsl:template>

<xsl:template name="extra-headers">
</xsl:template>

</xsl:stylesheet>
