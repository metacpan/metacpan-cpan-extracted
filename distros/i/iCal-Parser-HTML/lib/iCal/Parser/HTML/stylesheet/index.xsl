<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		version="1.0">

   <xsl:output method="xml"
	       doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
	       doctype-system=
	       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
	       encoding="utf-8"
	       indent="yes"
	       omit-xml-declaration="yes"
	       />

   <xsl:template match="text()"/>
   <xsl:template match="/">
      <html lang="en" xml:lang="en">
	 <head>
	    <!-- $Id: index.xsl 1 2005-03-19 23:14:58Z rick $ -->
	    <meta http-equiv="Content-Type" content="text/html; 
						     charset=UTF-8" />
	    <link rel="stylesheet" type="text/css" href="calendar.css"/>
	    <title class="index">Calendar Index</title>
	 </head>
	 <body class="index">
	    <h1>Select Calendars</h1>
	    <form method="post">
	       <p>
		  <xsl:apply-templates/>
	       </p>
	       <input type="reset"/>
	       <xsl:text>&#x0A;</xsl:text>
	       <input type="submit" name="submit" value="Submit"/>
	    </form>
	 </body>
      </html>
   </xsl:template>
   
   <xsl:template match="file">
      <input type="checkbox" name="file" value="{.}"/>
      <xsl:value-of select="."/><br/>
      </xsl:template>

</xsl:stylesheet>
