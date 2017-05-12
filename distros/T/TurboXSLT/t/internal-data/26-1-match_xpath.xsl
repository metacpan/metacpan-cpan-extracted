<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:chk="LTR:chk" xmlns:ltr="LTR" exclude-result-prefixes="ltr chk" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

<xsl:template match="xportal">

	<xsl:apply-templates select="subgenres/root_title/subgenre"/>

</xsl:template>

	<xsl:template match="subgenres/root_title/subgenre">1234</xsl:template>
	<xsl:template match="subgenre">5678</xsl:template>
	
</xsl:stylesheet>
