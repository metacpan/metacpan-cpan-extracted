<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:lc="http://xml.juniper.net/junos/to_be_replaced/dtd/junos-routing.dtd">
<xsl:output method="html" omit-xml-declaration="yes"/>

  <xsl:template match='/'>
    <HTML>
      <HEAD>
	<STYLE>
	  .bg {font:9pt Verdana,Arial,Helvetica; background-color:#0D479D; color:white}
	  .rel {position:relative; width:100%;}
	  .abs {position:absolute; width:100%;}
	  .right {text-align:right;}
	  .left {text-align:left;}
	  .center {text-align:center;}
	  .header {font:bold italic 9pt Verdana,Arial,Helvetica; text-decoration:none; color:white; text-align:left;}
	  .data1 {font:9pt Verdana,Arial,Helvetica; background-color:white; color:black}
	  .data2 {font:9pt Verdana,Arial,Helvetica; background-color:#EEEEEE; color:black}
          H2 {font:bold 18pt Verdana,Arial,Helvetica; background-color:#0D479D; color:white}
	</STYLE>
        <TITLE>Junoscript Example: Unestablished BGP Peers</TITLE>
      </HEAD>

      <BODY BGCOLOR="#0D479D" font="Arial">

	<TABLE WIDTH="100%" CELLSPACING="0">
	  <TR>	
	    <TD class="bg"/>
	    <TD>
	      <H2>Junoscript Example: Unestablished BGP Peers</H2>
	    </TD>
	  </TR>
	  <TR>
	    <TD class="bg" WIDTH="120" VALIGN="top">
	      <P><BR/><BR/><BR/><BR/><BR/>This is a list of unestablished BGP peers sorted by AS values.</P>
	    </TD>
	    <TD class="bg" VALIGN="top">
	      <TABLE BORDER="0" WIDTH="100%" cellspacing="0">
	        <TR>
	          <TD class="header">Address</TD>
	          <TD class="header">AS</TD>
	          <TD class="header">State</TD>
	          <TD class="header">Last State</TD>
	          <TD class="header">Last Event</TD>
	          <TD class="header">Last Error</TD>
	        </TR>
                <xsl:apply-templates select="lc:bgp-information" />
              </TABLE>
	    </TD>
	  </TR>
	</TABLE>
      </BODY>
    </HTML>

  </xsl:template>

  <xsl:template match='lc:bgp-information'>
     <xsl:for-each select="lc:bgp-peer">
        <xsl:sort data-type="number" select="lc:peer-as"/>
        <xsl:if test="lc:peer-state!='Established'">
	  <TR>
	    <TD class="data1"><xsl:value-of select='lc:peer-address'/></TD>
	    <TD class="data1"><xsl:value-of select='lc:peer-as'/></TD>
	    <TD class="data1"><xsl:value-of select='lc:peer-state'/></TD>
	    <TD class="data1"><xsl:value-of select='lc:last-state'/></TD>
	    <TD class="data1"><xsl:value-of select='lc:last-event'/></TD>
	    <TD class="data1"><xsl:value-of select='lc:last-error'/></TD>
	  </TR>
	</xsl:if>
     </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
