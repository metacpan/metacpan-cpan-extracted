<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:chk="LTR:chk" xmlns:ltr="LTR" exclude-result-prefixes="ltr chk" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

<xsl:template match="biblio_genres">
				<xsl:call-template name="genre-synonym">
					<xsl:with-param name="genre" select="subgenres/root_title | genre_title"/>
				</xsl:call-template>
</xsl:template>

	<xsl:template name="genre-synonym">
		<xsl:param name="genre"/>
		<xsl:value-of select="local-name($genre)"/><br/>
	</xsl:template>

</xsl:stylesheet>
