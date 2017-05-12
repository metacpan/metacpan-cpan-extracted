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

<xsl:variable name="STATIC_CACHE_BUSTER" select="/w:page/w:static-mtime/text()"/>

<xsl:template match="/w:page">
    <xsl:apply-templates select="w:content/xhtml:*"/>
</xsl:template>

<xsl:template name="page-header">
</xsl:template>

<xsl:template name="page-footer">
    <xsl:choose>
        <xsl:when test="/w:page/w:run-env/text() = 'development'">
            <script src="https://code.jquery.com/jquery-1.10.2.min.js"></script>
            <script src="/static/js/bootstrap.js"></script>
        </xsl:when>
        <xsl:otherwise>
            <script src="https://code.jquery.com/jquery-1.10.2.min.js"></script>
            <script src="/static/meon-Web-merged.js?t={$STATIC_CACHE_BUSTER}"></script>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="extra-headers">
    <xsl:choose>
        <xsl:when test="/w:page/w:run-env/text() = 'development'">
            <link href="/static/css/bootstrap.css" rel="stylesheet"/>
        </xsl:when>
        <xsl:otherwise>
            <link href="/static/meon-Web-merged.css?t={$STATIC_CACHE_BUSTER}" rel="stylesheet"/>
        </xsl:otherwise>
    </xsl:choose>

    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.3.0/respond.min.js"></script>
    <![endif]-->
</xsl:template>

</xsl:stylesheet>
