<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = '1.0'
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/"
    xmlns="http://docbook.org/ns/docbook"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:xlink="http://www.w3.org/1999/xlink">

<xsl:output method="xml" encoding="UTF-8" indent="yes"
 />

<xsl:template match="/">
        <xsl:apply-templates select="//fic:body" />
</xsl:template>

<xsl:template match="fic:body">
    <article>
        <xsl:attribute name="xml:id">
            <xsl:value-of select="@xml:id" />
        </xsl:attribute>
        <xsl:attribute name="xml:lang">
            <xsl:value-of select="@xml:lang" />
        </xsl:attribute>
        <xsl:attribute name="version">5.0</xsl:attribute>
        <db:info>
            <db:title>
                <xsl:value-of select="fic:title" />
            </db:title>
        </db:info>
        <xsl:apply-templates select="fic:section" />
    </article>
</xsl:template>

<xsl:template match="fic:section">
    <section>
        <xsl:copy-of select="@xml:id" />
        <xsl:if test="@xml:lang">
            <xsl:copy-of select="@xml:lang" />
        </xsl:if>
        <!-- Make the title the title attribute or "ID" if does not exist. -->
        <db:info>
            <db:title>
                <xsl:choose>
                    <xsl:when test="fic:title">
                        <xsl:value-of select="fic:title" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@xml:id" />
                    </xsl:otherwise>
                </xsl:choose>
            </db:title>
        </db:info>
        <xsl:apply-templates select="fic:section|fic:blockquote|fic:p|fic:ol|fic:ul|fic:programlisting" />
    </section>
</xsl:template>

<xsl:template match="fic:p">
    <db:para>
        <xsl:apply-templates />
    </db:para>
</xsl:template>

<xsl:template match="fic:b">
    <db:emphasis role="bold">
        <xsl:apply-templates/>
    </db:emphasis>
</xsl:template>

<xsl:template name="common_attributes">
    <xsl:if test="@xlink:href">
        <xsl:copy-of select="@xlink:href" />
    </xsl:if>
    <xsl:if test="@xml:lang">
        <xsl:copy-of select="@xml:lang" />
    </xsl:if>
    <xsl:if test="@xml:id">
        <xsl:copy-of select="@xml:id" />
    </xsl:if>
</xsl:template>

<xsl:template match="fic:blockquote">
    <db:blockquote>
        <xsl:call-template name="common_attributes" />
        <xsl:apply-templates/>
    </db:blockquote>
</xsl:template>

<xsl:template match="fic:i">
    <db:emphasis>
        <xsl:apply-templates/>
    </db:emphasis>
</xsl:template>

<xsl:template match="fic:ol">
    <db:orderedlist>
        <xsl:apply-templates/>
    </db:orderedlist>
</xsl:template>

<xsl:template match="fic:ul">
    <db:itemizedlist>
        <xsl:apply-templates/>
    </db:itemizedlist>
</xsl:template>

<xsl:template match="fic:programlisting">
    <db:programlisting>
        <xsl:apply-templates/>
    </db:programlisting>
</xsl:template>

<xsl:template match="fic:li">
    <db:listitem>
        <xsl:apply-templates/>
    </db:listitem>
</xsl:template>

<xsl:template match="fic:span">
    <xsl:variable name="tag_name">
        <xsl:choose>
            <xsl:when test="@xlink:href">
                <xsl:value-of select="'db:link'" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'db:phrase'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$tag_name}">
        <xsl:call-template name="common_attributes" />
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>

</xsl:stylesheet>
