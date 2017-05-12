<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:chk="LTR:chk" xmlns:ltr="LTR" exclude-result-prefixes="ltr chk" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

<xsl:template match="test">
	<xsl:variable name="atypes" select="genre_book/@type"/>
	<xsl:value-of select="$atypes"/><br/>
	
	<xsl:variable name="has-texts" select="$atypes[. = 0]"/>
	<xsl:value-of select="$has-texts"/><br/>
	
	<xsl:if test="$has-texts">
		123<br/>
	</xsl:if>
	
	<xsl:variable name="has-audios" select="$atypes[. = 1]"/>
		
	<xsl:if test="$has-audios">
		456
	</xsl:if>
</xsl:template>
</xsl:stylesheet>
