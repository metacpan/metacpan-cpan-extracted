<xsl:stylesheet version = '1.0'
     xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
     xmlns="http://www.w3.org/1999/xhtml">

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//W3C//DTD XHTML 1.1//EN"
 doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
 />

<xsl:template match="/">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">
<head>
<title>Create a Great Personal Home Site</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
    <xsl:apply-templates select="//product-syndication/data/cat" />
</body>
</html>
</xsl:template>

<xsl:template match="cat">
    <div class="prod_cat">
        <xsl:attribute name="id">
            <xsl:value-of select="@id" />
        </xsl:attribute>
    <xsl:element name="h{count(ancestor-or-self::cat)+1}">
        <xsl:value-of select="title" />
    </xsl:element>
    <xsl:apply-templates mode="copy-no-ns"
        select="desc/*" />
    <xsl:if test="desc/@appendtoc">
        <xsl:apply-templates mode="gen-toc" select="." />
    </xsl:if>

    <xsl:apply-templates select="prod|cat|set" />
    </div>
</xsl:template>

<xsl:template match="prod">
    <div class="prod">
        <xsl:attribute name="id"><xsl:value-of select="@id" /></xsl:attribute>
        <div class="head">
            <xsl:call-template name="prod_common" />
        </div>
        <div class="desc">
            <xsl:apply-templates mode="copy-no-ns"
                select="desc/*" />
        </div>
        <xsl:if test="ref">
            <div class="affil">
                <ul>
                    <xsl:apply-templates select="ref" />
                </ul>
            </div>
        </xsl:if>
    </div>
</xsl:template>
<xsl:template mode="copy-no-ns" match="*">
    <xsl:element name="{local-name()}">
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates mode="copy-no-ns"/>
    </xsl:element>
</xsl:template>

<xsl:template match="ref">
    <li>
        <a>
            <xsl:attribute name="href">
                <xsl:value-of select="@href" />
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@affil = 'amazon'">
                    <xsl:text>Amazon</xsl:text>
                </xsl:when>
                <xsl:when test="@affil = 'bn'">
                    <xsl:text>Barnes &amp; Noble</xsl:text>
                </xsl:when>
            </xsl:choose>
        </a>
    </li>
</xsl:template>

<xsl:template match="set">
    <div class="prod_set">
        <xsl:attribute name="id">
            <xsl:value-of select="@id" />
        </xsl:attribute>
        <p class="title">
            <strong><xsl:value-of select="title" /></strong>
        </p>
        <div class="head">
            <ul>
                <xsl:apply-templates select="prod" mode="in-set" />
            </ul>
        </div>
        <div class="desc">
            <xsl:apply-templates mode="copy-no-ns"
                select="desc/*" />
        </div>
    </div>
</xsl:template>

<xsl:template match="prod" mode="in-set">
    <li>
        <xsl:attribute name="id">
            <xsl:value-of select="@id" />
        </xsl:attribute>
        <xsl:call-template name="prod_common" />
    </li>
</xsl:template>

<xsl:template name="prod_common">
    <p class="prod_img">
        <xsl:if test="not (isbn/@disable = 1)">
            <xsl:element name="a">
                <xsl:attribute name="href">
                    <xsl:text>http://www.amazon.com/exec/obidos/ASIN/</xsl:text>
                    <xsl:value-of select="isbn" />
                    <xsl:text>/ref=nosim/shlomifishhom-20/</xsl:text>
                </xsl:attribute>
                <xsl:element name="img">
                    <xsl:attribute name="alt">
                        <xsl:text>Preview</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="src">
                        <xsl:text>images/</xsl:text>
                        <xsl:value-of select="@id" />
                        <xsl:text>.jpg</xsl:text>
                    </xsl:attribute>
                </xsl:element>
            </xsl:element>
        </xsl:if>
    </p>
    <p class="prod_title">
        <xsl:choose>
            <xsl:when test="not (isbn/@disable = 1)">
            <xsl:element name="a">
                <xsl:attribute name="href">
                    <xsl:text>http://www.amazon.com/exec/obidos/ASIN/</xsl:text>
                    <xsl:value-of select="isbn" />
                    <xsl:text>/ref=nosim/shlomifishhom-20/</xsl:text>
                </xsl:attribute>
                <xsl:value-of select="title" />
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="title" />
        </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="creator">
            <br />
            <xsl:value-of select="creator" />
        </xsl:if>
        <xsl:apply-templates select="rellink" />
        </p>
</xsl:template>

<xsl:template match="rellink">
    <br />
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="@href" />
        </xsl:attribute>
        <xsl:value-of select="@text" />
    </a>
</xsl:template>

<xsl:template mode="gen-toc" match="cat">
    <ul>
        <xsl:apply-templates mode="gen-toc-sub" select="cat|prod|set" />
    </ul>
</xsl:template>

<xsl:template mode="gen-toc-sub" match="cat|prod|set">
    <li>
        <a>
            <xsl:attribute name="href">
                <xsl:value-of select="concat('#', @id)" />
            </xsl:attribute>
            <xsl:value-of select="title" />
        </a>
        <xsl:if test="local-name(.) != 'set'">
            <xsl:if test="cat|prod|set">
                <br />
                <ul>
                    <xsl:apply-templates mode="gen-toc-sub" select="cat|prod|set" />
                </ul>
            </xsl:if>
        </xsl:if>
    </li>
</xsl:template>

</xsl:stylesheet>
