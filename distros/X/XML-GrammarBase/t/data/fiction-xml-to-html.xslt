<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = '1.0'
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/"
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//W3C//DTD XHTML 1.1//EN"
 doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
 />

<xsl:template match="/">
        <xsl:apply-templates select="//fic:body" />
</xsl:template>

<xsl:template match="fic:body">
    <html>
        <head>
            <title>
                <xsl:value-of select="fic:title" />
            </title>
        </head>
        <body>
            <div class="fiction story">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="@xml:id" />
                </xsl:attribute>
                <!-- TODO : duplicate code between here and fic:section.
                    Abstract into a common functionality!
                -->
                <xsl:element name="h{count(ancestor-or-self::fic:section|ancestor-or-self::fic:body)}">
                    <xsl:value-of select="fic:title" />
                </xsl:element>

                <xsl:apply-templates select="fic:section" />
            </div>
        </body>
    </html>
</xsl:template>

<xsl:template match="fic:section">
    <div class="fiction section">
        <xsl:if test="@xml:id">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="@xml:id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:element name="h{count(ancestor-or-self::fic:section|ancestor-or-self::fic:body)}">
            <xsl:value-of select="fic:title" />
        </xsl:element>
        <xsl:apply-templates select="fic:section|fic:p" />
    </div>
</xsl:template>

<xsl:template match="fic:p">
    <p>
        <xsl:apply-templates/>
    </p>
</xsl:template>

<xsl:template match="fic:b">
    <b>
        <xsl:apply-templates/>
    </b>
</xsl:template>

<xsl:template match="fic:i">
    <i>
        <xsl:apply-templates/>
    </i>
</xsl:template>

</xsl:stylesheet>
