<?xml version="1.0"?>
  <xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:lc="http://xml.juniper.net/junos/to_be_replaced/dtd/junos-chassis.dtd">
  <xsl:output method="html" omit-xml-declaration="yes"/>

  <xsl:template match='/'>
    <xsl:apply-templates select="lc:chassis-inventory" />
  </xsl:template>

  <xsl:template match='lc:chassis-inventory'>
    <xsl:apply-templates select="lc:chassis" />
  </xsl:template>

  <xsl:template match='lc:chassis'>
  <xsl:comment> chassis </xsl:comment>

    <HTML>
      <HEAD>
        <TITLE>Junoscript Example: Hardware Inventory</TITLE>
      </HEAD>
      <BODY BGCOLOR="#FFFFFF" font="Arial">

	<TABLE BORDER="0">
	  <TR>	
	    <TD>
	      <IMG BORDER="0" SRC="banner_logo.gif"/>
	    </TD>
	    <TD>
	      <H2>Junoscript Example: Hardware Inventory</H2>
	    </TD>
	  </TR>
	</TABLE>

	<P>The following is the hardware Inventory of the router you specified.  You'll see the same output by issuing the command <b>'show chassis hardware'</b> on the CLI.</P>

	<TABLE BORDER="0" WIDTH="100%" cellspacing="0">
	  <TR>
	    <TD><B><I>Item</I></B></TD>
	    <TD><B><I>Version</I></B></TD>
	    <TD><B><I>Part Number</I></B></TD>
	    <TD><B><I>Serial Number</I></B></TD>
	    <TD><B><I>Description</I></B></TD>
	  </TR>
          <TR>
            <TD>
              <xsl:value-of select='lc:name'/>
            </TD>
            <TD>
              <xsl:value-of select='lc:version'/>
            </TD>
            <TD>
              <xsl:value-of select='lc:part-number'/>
            </TD>
            <TD>
              <xsl:value-of select='lc:serial-number'/>
            </TD>
            <TD>
              <xsl:value-of select='lc:description'/>
            </TD>
          </TR>

          <xsl:apply-templates select='lc:chassis-module'/>
          <xsl:comment> /chassis-module </xsl:comment>

        </TABLE>
      </BODY>
    </HTML>

  <xsl:comment> /chassis </xsl:comment>
  </xsl:template>

  <xsl:template match='lc:chassis-module'>
            <xsl:comment> chassis-module </xsl:comment>

              <TR>
                <TD>
                  <xsl:value-of select='lc:name'/>
                </TD>
                <TD>
                    <xsl:value-of select='lc:version'/>
                </TD>
                <TD>
                  <xsl:value-of select='lc:part-number'/>
                </TD>
                <TD>
                  <xsl:value-of select='lc:serial-number'/>
                </TD>
                <TD>
                  <xsl:value-of select='lc:description'/>
                </TD>
              </TR>

              <xsl:apply-templates select='lc:chassis-sub-module'/>

  </xsl:template>

  <xsl:template match='lc:chassis-sub-module'>
            <xsl:comment> chassis-sub-module </xsl:comment>

              <TR>
                <TD>
                  <li><xsl:value-of select='lc:name'/></li>
                </TD>
                <TD>
                  <xsl:value-of select='lc:version'/>
                </TD>
                <TD>
                  <xsl:value-of select='lc:part-number'/>
                </TD>
                <TD>
                  <xsl:value-of select='lc:serial-number'/>
                </TD>
                <TD>
                  <xsl:value-of select='lc:description'/>
                </TD>
              </TR>

  </xsl:template>

</xsl:stylesheet>
