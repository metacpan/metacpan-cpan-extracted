<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version = '1.0'
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns="http://www.w3.org/1999/xhtml"
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//W3C//DTD XHTML 1.1//EN"
 doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
 />

<xsl:param name="fortune.id"></xsl:param>
<xsl:param name="filter-facts-list.id"></xsl:param>
<xsl:param name="filter.lang">en-US</xsl:param>

<!-- The purpose of this function is to recursively copy elements without a
namespace-->
<xsl:template mode="copy-html-ns" match="*">
    <xsl:element xmlns="http://www.w3.org/1999/xhtml" name="{local-name()}">
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates mode="copy-html-ns"/>
    </xsl:element>
</xsl:template>

<xsl:template name="copy_html_ns_by_name">
    <xsl:element xmlns="http://www.w3.org/1999/xhtml" name="{local-name()}">
            <xsl:copy-of select="@*" />
            <xsl:call-template name="copy_html_ns_by_name" />
    </xsl:element>
</xsl:template>

<xsl:template match="/collection">
    <html xml:lang="en-US">
        <head>
            <title>Fortunes</title>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        </head>
        <body>
            <xsl:choose>
                <xsl:when test="$fortune.id">
                    <xsl:apply-templates select="list/fortune[@id=$fortune.id]" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="list/fortune" />
                </xsl:otherwise>
            </xsl:choose>
        </body>
    </html>
</xsl:template>

<xsl:template match="/facts">
    <html>
        <xsl:attribute name="xml:lang">
            <xsl:value-of select="$filter.lang" />
        </xsl:attribute>
        <head>
            <title>Facts</title>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        </head>
        <body>
            <xsl:choose>
                <xsl:when test="$fortune.id">
                    <xsl:apply-templates select="list/*[(self::f or self::fact) and @id=$fortune.id]" />
                </xsl:when>
                <xsl:when test="$filter-facts-list.id">
                    <xsl:apply-templates select="list[@xml:id=$filter-facts-list.id]" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="list" />
                </xsl:otherwise>
            </xsl:choose>
        </body>
    </html>
</xsl:template>

<xsl:template match="/facts/list">
    <div class="list">
        <xsl:attribute name="xml:lang">
            <xsl:value-of select="$filter.lang" />
        </xsl:attribute>
        <h3 id="{@xml:id}"><xsl:value-of select="@title" /></h3>
        <div class="main_facts_list">
            <ul>
                <xsl:apply-templates select="*[self::f or self::fact][*[self::l or self::lang]/@xml:lang = $filter.lang]" />
            </ul>
        </div>
    </div>
</xsl:template>

<xsl:template match="/facts/list/*[self::f or self::fact]">
    <li class="fact">
        <xsl:apply-templates select="*[self::l or self::lang][@xml:lang = $filter.lang]"/>
    </li>
</xsl:template>

<xsl:template match="/facts/list/*[self::f or self::fact]/*[self::l or self::lang]">
    <blockquote>
        <xsl:apply-templates select="body/*" mode="copy-html-ns"/>
    </blockquote>
    <xsl:call-template name="render_info" />
</xsl:template>

<xsl:template match="fortune">
    <div class="fortune">
        <h3 id="{@id}"><xsl:call-template name="get_header" /></h3>
        <xsl:choose>
            <xsl:when test="irc">
                <xsl:apply-templates select="irc" />
            </xsl:when>
            <xsl:when test="raw">
                <xsl:apply-templates select="raw" />
            </xsl:when>
            <xsl:when test="quote">
                <xsl:apply-templates select="quote" />
            </xsl:when>
            <xsl:when test="screenplay">
                <xsl:apply-templates select="screenplay" mode="screenplay_wrapper"/>
            </xsl:when>

        </xsl:choose>
    </div>
</xsl:template>

<xsl:template match="body">
    <xsl:apply-templates select="saying|me_is|joins|leaves" />
</xsl:template>

<xsl:template match="saying|me_is|joins|leaves">
    <tr>
        <xsl:attribute name="class">
            <xsl:value-of select="name(.)" />
        </xsl:attribute>
        <td class="who">
            <xsl:choose>
                <xsl:when test="name(.) = 'me_is'">
                    <xsl:text>* </xsl:text>
                </xsl:when>
                <xsl:when test="name(.) = 'joins'">
                    <xsl:text>→</xsl:text>
                </xsl:when>
                <xsl:when test="name(.) = 'leaves'">
                    <xsl:text>←</xsl:text>
                </xsl:when>
            </xsl:choose>
            <xsl:value-of select="@who" />
        </td>
        <td class="text">
            <xsl:value-of select="." />
        </td>
    </tr>
</xsl:template>

<xsl:template name="get_irc_default_header">
    <xsl:choose>
        <xsl:when test="info">
            <xsl:if test="info/tagline">
                <xsl:value-of select="info/tagline" /> on
            </xsl:if>
            <xsl:if test="info/network">
                <xsl:value-of select="info/network" />'s
            </xsl:if>
            <xsl:value-of select="info/channel" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>Unknown Subject</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="get_header">
    <xsl:choose>
        <xsl:when test="meta/title">
            <xsl:value-of select="meta/title" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="get_irc_default_header" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="render_info">
    <xsl:if test="info/*">
        <table class="info">
            <tbody>
                <xsl:apply-templates select="info/*" mode="raw_info_subs"/>
            </tbody>
        </table>
    </xsl:if>
</xsl:template>

<xsl:template match="raw">
    <pre class="raw">
        <xsl:value-of select="body/text"/>
    </pre>
    <xsl:call-template name="render_info" />
</xsl:template>

<xsl:template match="quote">
    <blockquote>
        <xsl:apply-templates select="body/*" mode="copy-html-ns"/>
    </blockquote>
    <xsl:call-template name="render_info" />
</xsl:template>


<xsl:template match="irc">
    <table class="irc-conversation">
        <tbody>
            <xsl:apply-templates select="body"/>
        </tbody>
    </table>
    <xsl:call-template name="render_info" />
</xsl:template>

<xsl:template match="screenplay" mode="screenplay_wrapper">
    <xsl:apply-templates select="." mode="screenplay_driver"/>
</xsl:template>

<xsl:template match="screenplay" mode="screenplay_driver">
    <div class="screenplay">
        <xsl:apply-templates select="body/*" mode="screenplay"/>
    </div>
    <xsl:call-template name="render_info" />
</xsl:template>

<xsl:template match="*" name="raw_info_subs" mode="raw_info_subs">
    <tr class="{name(.)}">
        <td class="field">
            <b>
                <xsl:choose>
                    <xsl:when test="name(.) = 'author'">
                        <xsl:text>Author</xsl:text>
                    </xsl:when>
                    <xsl:when test="name(.) = 'work'">
                        <xsl:text>Work</xsl:text>
                    </xsl:when>
                    <xsl:when test="name(.) = 'network'">
                        <xsl:text>Network</xsl:text>
                    </xsl:when>
                    <xsl:when test="name(.) = 'channel'">
                        <xsl:text>Channel</xsl:text>
                    </xsl:when>
                    <xsl:when test="name(.) = 'tagline'">
                        <xsl:text>Tagline</xsl:text>
                    </xsl:when>

                    <xsl:otherwise>
                        <xsl:value-of select="name(.)" />
                    </xsl:otherwise>
                </xsl:choose>
            </b>
        </td>
        <td class="value">
            <xsl:choose>
                <xsl:when test="@href">
                    <a href="{@href}">
                        <xsl:value-of select="." />
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="." />
                </xsl:otherwise>
            </xsl:choose>
        </td>
    </tr>
</xsl:template>

<xsl:template match="description" mode="screenplay">
    <div class="description">
        <xsl:apply-templates  mode="screenplay"/>
    </div>
</xsl:template>


<xsl:template match="saying" mode="screenplay">
    <div class="saying">
        <xsl:apply-templates mode="screenplay"/>
    </div>
</xsl:template>

<xsl:template match="para" mode="screenplay">
    <p>
        <xsl:if test="local-name(..) = 'saying'">
            <strong class="sayer">
                <xsl:value-of select="../@character" />
                <xsl:text>: </xsl:text>
            </strong>
        </xsl:if>
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=1] = .">
            <xsl:text>[</xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="screenplay"/>
        <xsl:if test="local-name(..) = 'description' and ../child::para[position()=last()] = .">
            <xsl:text>]</xsl:text>
        </xsl:if>
    </p>
</xsl:template>

<xsl:template match="ulink" mode="screenplay">
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="@url" />
        </xsl:attribute>
        <xsl:apply-templates  mode="screenplay"/>
    </a>
</xsl:template>

<xsl:template match="bold" mode="screenplay">
    <strong class="bold">
        <xsl:apply-templates  mode="screenplay"/>
    </strong>
</xsl:template>

<xsl:template match="italics" mode="screenplay">
    <em class="italics">
        <xsl:apply-templates  mode="screenplay"/>
    </em>
</xsl:template>

<xsl:template match="inlinedesc" mode="screenplay">
    <span class="inlinedesc">[<xsl:apply-templates mode="screenplay"/>]</span>
</xsl:template>

<xsl:template match="br" mode="screenplay">
    <br />
</xsl:template>

</xsl:stylesheet>
