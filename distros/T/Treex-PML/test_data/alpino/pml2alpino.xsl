<?xml version="1.0" encoding="utf-8"?>
<!-- -*- mode: xsl; coding: utf8; -*- -->
<!-- Author: pajas@ufal.mff.cuni.cz -->

<xsl:stylesheet
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform' 
  xmlns:pml='http://ufal.mff.cuni.cz/pdt/pml/'
  version='1.0'>
<xsl:output method="xml" encoding="UTF-8" indent="yes"/>
<xsl:namespace-alias stylesheet-prefix="pml" result-prefix="#default"/>
<xsl:strip-space elements="*"/>

<xsl:template match="/">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="pml:head">
</xsl:template>

<xsl:template match="pml:alpino_ds_pml">
  <alpino_ds version="{pml:version}">
    <xsl:apply-templates select="pml:trees"/>
    <xsl:apply-templates select="pml:sentence"/>
    <xsl:apply-templates select="pml:comments"/>
  </alpino_ds>
</xsl:template>

<xsl:template match="*">
  <xsl:element name="{name()}">
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates/>
  </xsl:element>
</xsl:template>

<xsl:template match="pml:trees/pml:LM">
  <node>
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates/>
  </node>
</xsl:template>
<xsl:template match="pml:trees[pml:LM]">
  <xsl:apply-templates/>
</xsl:template>
<xsl:template match="pml:trees[@*]">
  <node>
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates/>
  </node>
</xsl:template>
<xsl:template match="pml:trees[not(@*) and not(pml:LM)]">
</xsl:template>

<xsl:template match="pml:children/pml:LM">
  <node>
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates/>
  </node>
</xsl:template>
<xsl:template match="pml:children[pml:LM]">
  <xsl:apply-templates/>
</xsl:template>
<xsl:template match="pml:children[@*]">
  <node>
    <xsl:apply-templates select="@*"/>
    <xsl:apply-templates/>
  </node>
</xsl:template>
<xsl:template match="pml:children[not(@*) and not(pml:LM)]">
</xsl:template>


<xsl:template match="@*">
  <xsl:copy/>
</xsl:template>


</xsl:stylesheet>
