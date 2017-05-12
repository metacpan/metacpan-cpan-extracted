<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output indent="yes" method="xml" omit-xml-declaration="yes" version="1.0" encoding="UTF-8"/>

  <!-- disable all default text node output -->
  <xsl:template match="text()"/>

  <xsl:template match="/documentCollection"/>

  <!-- match on Combine xml record 
       Mappings to Solr standard example schema ver 1.1 as per below
  -->
  <xsl:template match="//documentRecord">
<doc>
 <field name="id">
  <xsl:value-of select="@id"/>
 </field>
 <field name="name">
       <xsl:choose>
       <xsl:when test="count(metaData/meta[@name='dc:title'])>0">
         <xsl:value-of select="normalize-space(metaData/meta[@name='dc:title'])"/>
       </xsl:when>
       <xsl:when test="count(metaData/meta[@name='title'])>0">
         <xsl:value-of select="normalize-space(metaData/meta[@name='title'])"/>
       </xsl:when>
       <xsl:otherwise><xsl:value-of select="urls/url"/></xsl:otherwise>
       </xsl:choose>
 </field>
 <field name="text">
  <xsl:value-of select="normalize-space(canonicalDocument/section)"/>
 </field>
 <field name="url_s">
  <xsl:value-of select="urls/url"/>
 </field>
<!--
 <field name="timestamp">
  <xsl:value-of select="modifiedDate"/>
 </field>
-->
 <field name="features">
  <xsl:value-of select="metaData/meta[@name='dc:description']"/>
 </field>
 <field name="features">
  <xsl:value-of select="metaData/meta[@name='dc:subject']"/>
 </field>
 <field name="features">
  <xsl:value-of select="headings"/>
 </field>
 <field name="features">
  <xsl:value-of select="links/inlinks/link/anchorText"/>
 </field>
 <field name="lang_s">
  <xsl:value-of select="property[@name='lang']"/>
 </field>
 <field name="country_s">
  <xsl:value-of select="property[@name='country']"/>
 </field>
</doc>
  </xsl:template>

</xsl:stylesheet>

