<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = '1.0'
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    xmlns:vrd="http://www.shlomifish.org/open-source/projects/XML-Grammar/Vered/"
    xmlns="http://docbook.org/ns/docbook"
    xmlns:xlink="http://www.w3.org/1999/xlink">

<xsl:output method="xml" encoding="UTF-8" indent="yes"
 />

<xsl:template match="/vrd:document">
    <article>
        <xsl:if test="@xml:id">
            <xsl:attribute name="xml:id">
                <xsl:value-of select="@xml:id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:attribute name="xml:lang">
            <xsl:value-of select="@xml:lang" />
        </xsl:attribute>
        <xsl:attribute name="version">5.0</xsl:attribute>
        <info xml:id="main_document_id">
            <title>
                <xsl:value-of select="vrd:info/vrd:title" />
            </title>
            <authorgroup>
                <author>
                    <personname>
                        <firstname>
                            <xsl:choose>
                                <xsl:when test="vrd:info/vrd:author/vrd:personname/vrd:firstname">
                                    <xsl:value-of select="vrd:info/vrd:author/vrd:personname/vrd:firstname" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>Unknown</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </firstname>
                        <surname>
                            <xsl:choose>
                                <xsl:when test="vrd:info/vrd:author/vrd:personname/vrd:surname">
                                    <xsl:value-of select="vrd:info/vrd:author/vrd:personname/vrd:surname" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>Unknown</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </surname>
                    </personname>
                    <affiliation>
                        <address>
                            <email>
                                <xsl:choose>
                                    <xsl:when test="vrd:info/vrd:author/vrd:email">
                                        <xsl:value-of select="vrd:info/vrd:author/vrd:email" />
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>me@example.com</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </email>
                            <xsl:if test="vrd:info/vrd:author/vrd:uri[@type='homepage']">
                                <uri>
                                    <xsl:attribute name="type">
                                        <xsl:text>homepage</xsl:text>
                                    </xsl:attribute>
                                    <xsl:attribute name="xlink:href">
                                        <xsl:value-of select="vrd:info/vrd:author/vrd:uri[@type='homepage']/@xlink:href"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="vrd:info/vrd:author/vrd:uri[@type='homepage']/text()"/>
                                </uri>
                            </xsl:if>
                        </address>
                    </affiliation>
                </author>
             </authorgroup>

        <copyright>
            <year>
                <xsl:choose>
                    <xsl:when test="vrd:info/vrd:copyright/vrd:year">
                        <xsl:value-of select="vrd:info/vrd:copyright/vrd:year" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>2021</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </year>
            <holder>
                <xsl:choose>
                    <xsl:when test="vrd:info/vrd:copyright/vrd:holder">
                        <xsl:value-of select="vrd:info/vrd:copyright/vrd:holder" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>Unknown</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </holder>
        </copyright>
        <legalnotice xml:id="main_legal_notice">
            <xsl:choose>
                <xsl:when test="vrd:info/vrd:legalnotice">
                    <xsl:apply-templates select="vrd:info/vrd:legalnotice/*" />
                </xsl:when>
                <xsl:otherwise>
                    <para>
                        This document is copyrighted by Unknown.
                    </para>
                </xsl:otherwise>
            </xsl:choose>
        </legalnotice>

        </info>
        <xsl:apply-templates select="vrd:body/vrd:preface" />
        <xsl:apply-templates select="vrd:body/vrd:section" />
    </article>
</xsl:template>

<xsl:template match="vrd:preface">
    <section role="introduction">
        <xsl:call-template name="preface_or_section" />
    </section>
</xsl:template>

<xsl:template name="preface_or_section">
    <xsl:copy-of select="@xml:id" />
    <xsl:if test="@xml:lang">
        <xsl:copy-of select="@xml:lang" />
    </xsl:if>
    <info>
        <title>
            <xsl:choose>
                <xsl:when test="vrd:info/vrd:title">
                    <xsl:value-of select="vrd:info/vrd:title" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@xml:id" />
                </xsl:otherwise>
            </xsl:choose>
        </title>
    </info>
    <xsl:apply-templates select="vrd:section|vrd:blockquote|vrd:p|vrd:ol|vrd:ul|vrd:programlisting|vrd:item" />
</xsl:template>

<xsl:template match="vrd:section">
    <section>
        <xsl:call-template name="preface_or_section" />
    </section>
</xsl:template>

<xsl:template match="vrd:item">
    <section role="item">
        <xsl:call-template name="common_attributes" />
        <!-- TODO : extract this info thing into a common named
        xsl:template. -->
        <info>
            <title>
                <xsl:choose>
                    <xsl:when test="vrd:info/vrd:title">
                        <xsl:value-of select="vrd:info/vrd:title" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@xml:id" />
                    </xsl:otherwise>
                </xsl:choose>
            </title>
        </info>
        <xsl:apply-templates select="vrd:blockquote|vrd:p|vrd:ol|vrd:ul|vrd:programlisting|vrd:code_blk|vrd:bad_code" />
        <xsl:apply-templates select="vrd:item" />
    </section>
</xsl:template>

<xsl:template match="vrd:bad_code">
    <programlisting role="bad_code">
        <xsl:attribute name="language">
            <xsl:value-of select="@syntax" />
        </xsl:attribute>
        <xsl:text xml:space="preserve"># Bad code

</xsl:text>
        <xsl:apply-templates/>
    </programlisting>
</xsl:template>

<xsl:template match="vrd:code_blk">
    <programlisting>
        <xsl:attribute name="language">
            <xsl:value-of select="@syntax" />
        </xsl:attribute>
        <xsl:apply-templates xml:space="preserve"/>
    </programlisting>
</xsl:template>

<xsl:template match="vrd:p">
    <para>
        <xsl:apply-templates />
    </para>
</xsl:template>

<xsl:template match="vrd:b|vrd:strong">
    <emphasis role="bold">
        <xsl:apply-templates/>
    </emphasis>
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

<xsl:template match="vrd:blockquote">
    <blockquote>
        <xsl:call-template name="common_attributes" />
        <xsl:apply-templates/>
    </blockquote>
</xsl:template>

<xsl:template match="vrd:i|vrd:em">
    <emphasis>
        <xsl:apply-templates/>
    </emphasis>
</xsl:template>

<xsl:template match="vrd:code">
    <code>
        <xsl:apply-templates/>
    </code>
</xsl:template>

<xsl:template match="vrd:pdoc">
    <xsl:variable name="d">
        <xsl:value-of select="@d" />
    </xsl:variable>
    <link role="perldoc">
        <xsl:attribute name="xlink:href">
            <xsl:text>http://perldoc.perl.org/</xsl:text>
            <xsl:value-of select="$d" />
            <xsl:text>.html</xsl:text>
        </xsl:attribute>
        <xsl:value-of select="$d" />
        <xsl:apply-templates/>
    </link>
</xsl:template>

<xsl:template match="vrd:pdoc_f">
    <xsl:variable name="f">
        <xsl:value-of select="@f" />
    </xsl:variable>
    <link role="perldoc_func">
        <xsl:attribute name="xlink:href">
            <xsl:text>http://perldoc.perl.org/functions/</xsl:text>
            <xsl:value-of select="$f" />
            <xsl:text>.html</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </link>
</xsl:template>

<xsl:template match="vrd:cpan_mod">
    <link role="cpan_module">
        <xsl:attribute name="xlink:href">
            <xsl:text>http://metacpan.org/module/</xsl:text>
            <xsl:value-of select="@m" />
        </xsl:attribute>
        <xsl:apply-templates/>
    </link>
</xsl:template>

<xsl:template match="vrd:cpan_self_mod">
    <xsl:variable name="module">
        <xsl:value-of select="@m" />
    </xsl:variable>
    <link role="cpan_module">
        <xsl:attribute name="xlink:href">
            <xsl:text>http://metacpan.org/module/</xsl:text>
            <xsl:value-of select="$module" />
        </xsl:attribute>
        <xsl:value-of select="$module" />
    </link>
</xsl:template>

<xsl:template match="vrd:cpan_self_dist">
    <xsl:variable name="dist">
        <xsl:value-of select="@d" />
    </xsl:variable>
    <link role="cpan_dist">
        <xsl:attribute name="xlink:href">
            <xsl:text>http://metacpan.org/release/</xsl:text>
            <xsl:value-of select="$dist" />
        </xsl:attribute>
        <xsl:value-of select="$dist" />
    </link>
</xsl:template>

<xsl:template match="vrd:filepath">
    <filename>
        <xsl:apply-templates/>
    </filename>
</xsl:template>

<xsl:template match="vrd:ol">
    <orderedlist>
        <xsl:apply-templates/>
    </orderedlist>
</xsl:template>

<xsl:template match="vrd:ul">
    <itemizedlist>
        <xsl:apply-templates/>
    </itemizedlist>
</xsl:template>

<xsl:template match="vrd:programlisting">
    <programlisting>
        <xsl:apply-templates/>
    </programlisting>
</xsl:template>

<xsl:template match="vrd:li">
    <listitem>
        <xsl:apply-templates/>
    </listitem>
</xsl:template>

<xsl:template match="vrd:a">
    <xsl:element name="link">
        <xsl:call-template name="common_attributes" />
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>

<xsl:template match="vrd:span">
    <xsl:variable name="tag_name">
        <xsl:choose>
            <xsl:when test="@xlink:href">
                <xsl:value-of select="'link'" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'phrase'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$tag_name}">
        <xsl:call-template name="common_attributes" />
        <xsl:apply-templates/>
    </xsl:element>
</xsl:template>

</xsl:stylesheet>
