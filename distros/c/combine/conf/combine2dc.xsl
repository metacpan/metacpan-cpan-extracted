<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output indent="yes" method="xml" omit-xml-declaration="yes" version="1.0" encoding="UTF-8"/>

  <!-- disable all default text node output -->
  <xsl:template match="text()"/>

  <!-- match on alvis xml record -->
  <xsl:template match="//documentRecord">
    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" >

     <xsl:for-each select="metaData/meta[starts-with(@name,'dc:')]">
       <xsl:element name="{@name}">
         <xsl:value-of select="."/>
       </xsl:element>
     </xsl:for-each>

     <xsl:if test = "count(metaData/meta[@name='dc:title'])=0">
      <dc:title transl="yes">
        <xsl:value-of select="metaData/meta[@name='title']"/>
      </dc:title> 
     </xsl:if>

     <xsl:if test = "count(metaData/meta[@name='dc:description'])=0">
      <dc:description>
        <xsl:value-of
            select="substring(normalize-space(documentText), 0, 500)"/>
      </dc:description>
     </xsl:if>

     <xsl:if test = "count(modifiedDate)>0">
      <dc:date>
        <xsl:value-of 
            select="modifiedDate"/>
      </dc:date>
     </xsl:if>

     <xsl:if test = "(count(metaData/meta[@name='dc:format'])=0) and (count(metaData/meta[@name='content-type'])>0)">
      <dc:format>
        <xsl:value-of
            select="metaData/meta[@name='content-type']"/>
      </dc:format>
     </xsl:if>

<!--      <dc:identifier> <xsl:value-of select="@id"/> </dc:identifier>-->

    <xsl:if test="string(metaData/meta[@name='dc:identifier'])!=string(urls/url)">
      <dc:identifier>
        <xsl:value-of select="urls/url"/>
      </dc:identifier>
    </xsl:if>

    <xsl:if test="string(metaData/meta[@name='dc:language'])!=string(property[@name='language'])">
      <dc:language>
        <xsl:value-of select="property[@name='language']"/>
      </dc:language>
     </xsl:if>

    </metadata>
  </xsl:template>


</xsl:stylesheet>
