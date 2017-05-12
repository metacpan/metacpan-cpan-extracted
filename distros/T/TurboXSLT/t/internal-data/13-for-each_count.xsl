<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">

<xsl:template match="/">
<xsl:value-of select="count(/subgenres/subgenre/genre_type)"/><br/><br/>

<xsl:for-each select="/subgenres/subgenre/genre_type">
<xsl:value-of select="@arts_count"/><br/>
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
