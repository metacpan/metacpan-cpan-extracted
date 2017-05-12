<?xml version="1.0"?>

<xsl:stylesheet
    version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<xsl:import href="import.xsl"/>
<xsl:include href="include.xsl"/>

<xsl:output
    indent="yes"
    omit-xml-declaration="yes"
    media-type="text/html"
    doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
/>

<xsl:template match="/">
    <html>
        <title>
            <xsl:value-of select="doc/title"/>
        </title>
        <body>
            <h1>Test</h1>
        </body>
    </html>
</xsl:template>

</xsl:stylesheet>

