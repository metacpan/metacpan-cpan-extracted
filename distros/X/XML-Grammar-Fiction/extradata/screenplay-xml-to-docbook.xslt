<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = '1.0'
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:sp="http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/"
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//OASIS//DTD DocBook XML V4.3//EN"
 doctype-system="/usr/share/sgml/docbook/xml-dtd-4.3/docbookx.dtd"
 />

<xsl:template match="/">
        <xsl:apply-templates select="//sp:body" />
</xsl:template>

<xsl:template match="sp:body">
    <article>
        <xsl:attribute name="id">
            <xsl:value-of select="@id" />
        </xsl:attribute>
        <xsl:apply-templates select="sp:scene" />
    </article>
</xsl:template>

<xsl:template match="sp:scene">
    <section>
        <xsl:attribute name="id">
            <xsl:value-of select="@id" />
        </xsl:attribute>
        <!-- Make the title the title attribute or "ID" if does not exist. -->
        <title>
            <xsl:choose>
                <xsl:when test="@title">
                    <xsl:value-of select="@title" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@id" />
                </xsl:otherwise>
            </xsl:choose>
        </title>
        <xsl:apply-templates select="sp:scene|sp:description|sp:saying" />
    </section>
</xsl:template>

<xsl:template match="sp:description">
    <section role="description" id="{generate-id()}">
        <title></title>
            <xsl:apply-templates />
    </section>
</xsl:template>

<xsl:template match="saying">
    <section role="sp:saying" id="{generate-id()}">
        <title></title>
        <xsl:apply-templates />
    </section>
</xsl:template>

<xsl:template match="para">
    <para>
        <xsl:if test="local-name(..) = 'saying'">
            <emphasis role="bold"><xsl:value-of select="../@character" />: </emphasis>
        </xsl:if>
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=1] = .">
            [
        </xsl:if>
        <xsl:apply-templates />
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=last()] = .">
            ]
        </xsl:if>
    </para>
</xsl:template>

<xsl:template match="sp:ulink">
    <ulink>
        <xsl:attribute name="url">
            <xsl:value-of select="@url" />
        </xsl:attribute>
    </ulink>
</xsl:template>

<xsl:template match="sp:bold">
    <emphasis role="bold">
        <xsl:apply-templates />
    </emphasis>
</xsl:template>

<xsl:template match="sp:inlinedesc">
    <phrase>[<xsl:apply-templates />]</phrase>
</xsl:template>

</xsl:stylesheet>
