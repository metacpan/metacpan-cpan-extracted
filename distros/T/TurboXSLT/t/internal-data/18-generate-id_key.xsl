<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:chk="LTR:chk" xmlns:ltr="LTR" exclude-result-prefixes="ltr chk" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">
<!-- Для уникальных тайпов -->
<xsl:key name="genkey" match="/biblio_genres/subgenres/root_title/subgenre/genre_type" use="@type"/>

<xsl:template match="biblio_genres">
	<xsl:call-template name="sort_genre_by"/>
</xsl:template>

<xsl:template name="sort_genre_by">
		<xsl:value-of select="count(subgenres/root_title/subgenre/genre_type[generate-id() = generate-id( key ('genkey', @type) [1] ) ])"/><br/>
</xsl:template>


</xsl:stylesheet>
