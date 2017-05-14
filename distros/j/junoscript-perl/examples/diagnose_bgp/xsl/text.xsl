<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:lc="http://xml.juniper.net/junos/to_be_replaced/dtd/junos-routing.dtd" 
    xmlns:junos="http://xml.juniper.net/junos/5.1I0/dtd/junos.dtd">
<xsl:output method="text" omit-xml-declaration="yes"/>

  <xsl:template match='/'>
    <xsl:text>Address&#x9;&#x9;&#x9;AS&#x9;State&#x9;Last St&#x9;Last Event&#x9;Last Error&#xa;</xsl:text>
    <xsl:text>-------&#x9;&#x9;&#x9;--&#x9;-----&#x9;-------&#x9;----------&#x9;----------&#xa;</xsl:text>
     <xsl:for-each select="lc:bgp-information/lc:bgp-peer">
        <xsl:sort data-type="number" select="lc:peer-as"/>
        <xsl:if test="lc:peer-state!='Established'">
	  <xsl:value-of select='lc:peer-address'/><xsl:text>&#x9;</xsl:text>
          <xsl:if test="string-length(lc:peer-address) &lt; 16">
	    <xsl:text>&#x9;</xsl:text>
          </xsl:if>
          <xsl:value-of select='lc:peer-as'/><xsl:text>&#x9;</xsl:text><xsl:value-of select='lc:peer-state'/><xsl:text>&#x9;</xsl:text><xsl:value-of select='lc:last-state'/><xsl:text>&#x9;</xsl:text><xsl:value-of select='lc:last-event'/><xsl:text>&#x9;</xsl:text>
          <xsl:if test="string-length(lc:last-event) &lt; 8">
	    <xsl:text>&#x9;</xsl:text>
          </xsl:if>
          <xsl:value-of select='lc:last-error'/>
	  <xsl:text>&#xa;</xsl:text>
	</xsl:if>
     </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
