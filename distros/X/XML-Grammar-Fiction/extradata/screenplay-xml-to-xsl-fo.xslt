<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = '1.0'
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:fo='http://www.w3.org/1999/XSL/Format'
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />

<xsl:template match="/">
        <xsl:apply-templates select="//body" />
</xsl:template>

<xsl:template match="body">
    <fo:root>
            <xsl:attribute name="id">
                <xsl:value-of select="@id" />
            </xsl:attribute>
            <fo:layout-master-set>
                <fo:simple-page-master master-name="A4">
                    <fo:region-body />
                </fo:simple-page-master>
            </fo:layout-master-set>
            <fo:page-sequence master-reference="A4">
                <fo:flow flow-name="xsl-region-body">
                    <xsl:apply-templates select="scene" />
                </fo:flow>
            </fo:page-sequence>
    </fo:root>
</xsl:template>

<xsl:template match="scene">
    <fo:block>
        <!-- Make the title the title attribute or "ID" if does not exist. -->
        <xsl:element name="h{count(ancestor-or-self::scene)}">
            <xsl:attribute name="id">
                <xsl:value-of select="@id" />
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@title">
                    <xsl:value-of select="@title" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@id" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
        <xsl:apply-templates select="scene|description|saying" />
    </fo:block>
</xsl:template>

<xsl:template match="description">
    <div class="description">
        <xsl:apply-templates />
    </div>
</xsl:template>

<xsl:template match="saying">
    <div class="saying">
        <xsl:apply-templates />
    </div>
</xsl:template>

<xsl:template match="para">
    <p>
        <xsl:if test="local-name(..) = 'saying'">
            <strong class="sayer"><xsl:value-of select="../@character" />:</strong>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=1] = .">
            [
        </xsl:if>
        <xsl:apply-templates />
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=last()] = .">
            ]
        </xsl:if>
    </p>
</xsl:template>

<xsl:template match="ulink">
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="@url" />
        </xsl:attribute>
        <xsl:apply-templates />
    </a>
</xsl:template>

<xsl:template match="bold">
    <strong class="bold">
        <xsl:apply-templates />
    </strong>
</xsl:template>

<xsl:template match="inlinedesc">
    <span class="inlinedesc">[<xsl:apply-templates />]</span>
</xsl:template>

<xsl:template match="br">
    <br />
</xsl:template>

</xsl:stylesheet>
