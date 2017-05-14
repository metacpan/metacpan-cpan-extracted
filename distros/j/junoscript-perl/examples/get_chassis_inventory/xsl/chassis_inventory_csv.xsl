<?xml version="1.0"?>
  <xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:lc="http://xml.juniper.net/junos/to_be_replaced/dtd/junos-chassis.dtd"
    xmlns:junos="http://xml.juniper.net/junos/5.1I0/dtd/junos.dtd">
  <xsl:output method="text" omit-xml-declaration="yes"/>

  <xsl:template match='/'>
    <xsl:text>CHASSIS,MODULE,SUBMODULE,VERSION,PARTNUMBER,SERIALNUMBER,DESCRIPTION</xsl:text>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select='lc:chassis-inventory/lc:chassis'/>
  </xsl:template>

  <xsl:template match='lc:chassis-inventory/lc:chassis'>
    <xsl:value-of select='lc:name'/>,,,,<xsl:value-of select='lc:part-number'/>,<xsl:value-of select='lc:serial-number'/>,<xsl:value-of select='lc:description'/> 
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="lc:chassis-module" />
  </xsl:template>

  <xsl:template match='lc:chassis-module'>
    <xsl:value-of select='../lc:name'/>,<xsl:value-of select='lc:name'/>,,<xsl:value-of select='lc:version'/>,<xsl:value-of select='lc:part-number'/>,<xsl:value-of select='lc:serial-number'/>,<xsl:value-of select='lc:description'/>
    <xsl:text>&#xa;</xsl:text>
    <xsl:apply-templates select="lc:chassis-sub-module" />
  </xsl:template>

  <xsl:template match='lc:chassis-sub-module'>
    <xsl:value-of select='../../lc:name'/>,<xsl:value-of select='../lc:name'/>,<xsl:value-of select='lc:name'/>,<xsl:value-of select='lc:version'/>,<xsl:value-of select='lc:part-number'/>,<xsl:value-of select='lc:serial-number'/>,<xsl:value-of select='lc:description'/>
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
