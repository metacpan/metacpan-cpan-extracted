<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
<!--
     XSL stylesheet for converting XML representation of a DTD back to a DTD
     Brendt Wohlberg     21 October 2009
  -->

<xsl:output method="text" omit-xml-declaration="yes" standalone="no"/>


<!-- Template matching top level dtd element -->
<xsl:template match="dtd">
  <xsl:apply-templates select="*"/> <!-- Ensure only element nodes matched -->
</xsl:template>


<!-- Template matching a comment -->
<xsl:template match="comment">
  <xsl:text>&lt;!--</xsl:text>
  <xsl:value-of select="."/>
  <xsl:text>--&gt;</xsl:text>
</xsl:template>


<!-- Template matching a wspace element -->
<xsl:template match="wspace">
  <xsl:value-of select="."/>
</xsl:template>


<!-- Template matching an element -->
<xsl:template match="element">
  <xsl:text>&lt;!ELEMENT</xsl:text>
  <xsl:value-of select="@ltws"/><xsl:value-of select="@name"/> 
  <xsl:value-of select="contentspec/@ltws"/>
  <xsl:value-of select="contentspec"/>
  <xsl:text>&gt;</xsl:text>
</xsl:template>


<!-- Template matching an attribute list -->
<xsl:template match="attlist">
  <xsl:text>&lt;!ATTLIST</xsl:text>
  <xsl:value-of select="@ltws"/><xsl:value-of select="@name"/>
  <xsl:for-each select="attdefs/attdef">
    <xsl:value-of select="@ltws"/><xsl:value-of select="@name"/>
    <xsl:value-of select="atttype/@ltws"/><xsl:value-of select="atttype"/>
    <xsl:value-of select="defaultdecl/@ltws"/>
    <xsl:value-of select="defaultdecl"/>
  </xsl:for-each>
  <xsl:text>&gt;</xsl:text>
</xsl:template>


<!-- Template matching an entity definition -->
<xsl:template match="entity">
  <xsl:text>&lt;!ENTITY</xsl:text>
  <xsl:value-of select="@tstr"/><xsl:value-of select="@ltws"/>
  <xsl:value-of select="@name"/>
  <xsl:apply-templates select="internal|external"/>
  <xsl:value-of select="@rtws"/>
  <xsl:text>&gt;</xsl:text>
</xsl:template>

<xsl:template match="internal">
  <xsl:value-of select="@ltws"/>
  <xsl:value-of select="@qchar"/>
  <xsl:value-of select="."/>
  <xsl:value-of select="@qchar"/>
</xsl:template>

<xsl:template match="external">
  <xsl:value-of select="@ltws"/>
  <xsl:choose>
    <xsl:when test="public">
      <xsl:text>PUBLIC</xsl:text>
    </xsl:when>
    <xsl:when test="system">
      <xsl:text>SYSTEM</xsl:text>
    </xsl:when>
  </xsl:choose>
  <xsl:apply-templates select="public|system"/>
</xsl:template>

<xsl:template match="external/public">
  <xsl:value-of select="@ltws"/>
  <xsl:value-of select="@qchar"/>
  <xsl:value-of select="."/>
  <xsl:value-of select="@qchar"/>
</xsl:template>

<xsl:template match="external/system">
  <xsl:value-of select="@ltws"/>
  <xsl:value-of select="@qchar"/>
  <xsl:value-of select="."/>
  <xsl:value-of select="@qchar"/>
</xsl:template>


<!-- Template matching parameter entity ref -->
<xsl:template match="peref">
  <xsl:value-of select="unparsed"/>
</xsl:template>


<!-- Template matching a notation definition -->
<xsl:template match="notation">
  <xsl:text>&lt;!NOTATION</xsl:text>
  <xsl:value-of select="unparsed"/>
  <xsl:text>&gt;</xsl:text>
</xsl:template>


<!-- Template matching a pi -->
<xsl:template match="pi">
  <xsl:text>&lt;?</xsl:text>
  <xsl:value-of select="unparsed"/>
  <xsl:text>?&gt;</xsl:text>
</xsl:template>


<!-- Template matching an ignore section -->
<xsl:template match="ignore">
  <xsl:value-of select="@ltdlm"/>
  <xsl:value-of select="."/>
  <xsl:text>]]&gt;</xsl:text>
</xsl:template>

<!-- Template matching an include section -->
<xsl:template match="include">
  <xsl:value-of select="@ltdlm"/>
  <xsl:apply-templates select="*"/>
  <xsl:text>]]&gt;</xsl:text>
</xsl:template>



</xsl:stylesheet>
