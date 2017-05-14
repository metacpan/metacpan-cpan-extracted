<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:lc="http://xml.juniper.net/junos/to_be_replaced/dtd/junos-routing.dtd">
<xsl:output method="html" omit-xml-declaration="yes"/>

  <xsl:template match='/'>
    <HTML>
      <HEAD>
	<SCRIPT LANGUAGE="JavaScript" SRC="js/sorttable.js"></SCRIPT>
	<STYLE>
	  .bg {font:9pt Verdana,Arial,Helvetica; background-color:#0D479D; color:white}
	  .rel {position:relative; width:100%;}
	  .abs {position:absolute; width:100%;}
	  .right {text-align:right;}
	  .left {text-align:left;}
	  .center {text-align:center;}
	  A.sort {font:bold italic 9pt Verdana,Arial,Helvetica; text-decoration:none; color:white; cursor:hand; text-align:left;}
	  TD {font:9pt Verdana,Arial,Helvetica; color:black}
          H2 {font:bold 18pt Verdana,Arial,Helvetica; background-color:#0D479D; color:white}
	</STYLE>
        <TITLE>Junoscript Example: Unestablished BGP Peers</TITLE>

        <xsl:apply-templates select="lc:bgp-information" />
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
	      <P><BR/><BR/><BR/><BR/><BR/>This example uses the Javascript functions in Matt Kruse's sorttable.js.<BR/><BR/>Click on the column headers to sort by that field.</P>
	    </TD>
	    <TD class="bg" VALIGN="top">


	<TABLE BORDER="0" WIDTH="100%" cellspacing="0">
	  <TR>
	    <TD><B><I><a class="sort" href="javascript:SortRows(bgptab, 0)">Address</a></I></B></TD>
	    <TD><B><I><a class="sort" href="javascript:SortRows(bgptab, 1)">AS</a></I></B></TD>
	    <TD><B><I><a class="sort" href="javascript:SortRows(bgptab, 2)">State</a></I></B></TD>
	    <TD><B><I><a class="sort" href="javascript:SortRows(bgptab, 3)">Last State</a></I></B></TD>
	    <TD><B><I><a class="sort" href="javascript:SortRows(bgptab, 4)">Last Event</a></I></B></TD>
	    <TD><B><I><a class="sort" href="javascript:SortRows(bgptab, 5)">Last Error</a></I></B></TD>
	  </TR>
	  <SCRIPT>bgptab.WriteRows()</SCRIPT>
        </TABLE>
	    </TD>
	</TR>
	</TABLE>
      </BODY>
    </HTML>

  </xsl:template>

  <xsl:template match='lc:bgp-information'>
    <SCRIPT LANGUAGE="JavaScript">
      var bgptab = new SortTable('bgptab');
      var color2 = 'eeeeee';
      var color1 = 'ffffff';
      var color = color1;
      bgptab.AddColumn('Address', '', 'left', '');
      bgptab.AddColumn('AS', '', 'left', 'numeric');
      bgptab.AddColumn('State', '', 'left', '');
      bgptab.AddColumn('Last State', '', 'left', '');
      bgptab.AddColumn('Last Event', '', 'left', '');
      bgptab.AddColumn('Last Error', '', 'left', '');

       <xsl:for-each select="lc:bgp-peer">
          <xsl:sort data-type="number" select="lc:peer-as"/>
	  <xsl:if test="lc:peer-state!='Established'">
	      bgptab.AddLine('<xsl:value-of select="lc:peer-address"/>', '<xsl:value-of select="lc:peer-as"/>', '<xsl:value-of select="lc:peer-state"/>', '<xsl:value-of select="lc:last-state"/>', '<xsl:value-of select="lc:last-event"/>', '<xsl:value-of select="lc:last-error"/>');
	      bgptab.AddLineProperties('BGCOLOR=' + color);
	      if (color == color1) {
		color = color2;
	      } else {
		color = color1;
	      }
	  </xsl:if>
       </xsl:for-each>
     </SCRIPT>
  </xsl:template>

</xsl:stylesheet>
