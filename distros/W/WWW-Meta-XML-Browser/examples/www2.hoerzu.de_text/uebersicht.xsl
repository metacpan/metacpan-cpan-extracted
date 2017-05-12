<?xml version="1.0" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" />

<xsl:variable name="CHANNEL-SELECT-NAME">tvchannelid</xsl:variable>
<xsl:variable name="DATE-SELECT-NAME">newday</xsl:variable>
<xsl:variable name="BROADCAST-INDICATOR">* </xsl:variable>
<xsl:variable name="BROADCAST-TIME-INDICATOR"> Uhr , </xsl:variable>
<xsl:variable name="END-OF-BROADCAST-INDICATOR"> .</xsl:variable>
<xsl:variable name="END-OF-BROADCAST-LISTING-INDICATOR">Zum Auswahl</xsl:variable>
<xsl:variable name="BASE-HREF">http://www2.hoerzu.de/text/tv-programm/</xsl:variable>

<xsl:template match="/html">
	<channel-day>
		<channel><xsl:value-of select="./body/form/select[@name = $CHANNEL-SELECT-NAME]/option[@selected]"/></channel>
		<date><xsl:value-of select="./body/form/select[@name = $DATE-SELECT-NAME]/option[@selected]"/></date>
		<broadcasts>
			<xsl:apply-templates />
		</broadcasts>
	</channel-day>
</xsl:template>


<xsl:template match="p[contains(., $BROADCAST-INDICATOR)]">
	<xsl:call-template name="text-splitter">
		<xsl:with-param name="TEXT"><xsl:value-of select="substring-after(., $BROADCAST-INDICATOR)"/></xsl:with-param>
		<xsl:with-param name="SPLIT-TOKEN"><xsl:value-of select="$BROADCAST-INDICATOR"/></xsl:with-param>
	</xsl:call-template>
</xsl:template>


<xsl:template name="text-splitter">
	<xsl:param name="TEXT"/>
	<xsl:param name="SPLIT-TOKEN"/>

	<xsl:choose>
		<xsl:when test="contains($TEXT, $SPLIT-TOKEN)">
			<xsl:call-template name="broadcast-builder">
				<xsl:with-param name="TOKEN"><xsl:value-of select="normalize-space(substring-before($TEXT, $SPLIT-TOKEN))"/></xsl:with-param>
			</xsl:call-template>
		
			<xsl:call-template name="text-splitter">
				<xsl:with-param name="TEXT"><xsl:value-of select="substring-after($TEXT, $SPLIT-TOKEN)"/></xsl:with-param>
				<xsl:with-param name="SPLIT-TOKEN"><xsl:value-of select="$SPLIT-TOKEN"/></xsl:with-param>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="broadcast-builder">
				<xsl:with-param name="TOKEN"><xsl:value-of select="normalize-space(substring-before($TEXT, $END-OF-BROADCAST-LISTING-INDICATOR))"/></xsl:with-param>
			</xsl:call-template>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<xsl:template name="broadcast-builder">
	<xsl:param name="TOKEN"/>
	<xsl:variable name="TOKEN"><xsl:value-of select="substring($TOKEN, 1, (string-length($TOKEN) - string-length($END-OF-BROADCAST-INDICATOR)))"/></xsl:variable>
	
	<xsl:variable name="TIME"><xsl:value-of select="substring-before($TOKEN, $BROADCAST-TIME-INDICATOR)"/></xsl:variable>
	<xsl:variable name="TITLE-AND-TYPE"><xsl:value-of select="substring-after($TOKEN, $BROADCAST-TIME-INDICATOR)"/></xsl:variable>
	
	<broadcast>
		<xsl:if test="/html/body/p[2]/a[contains(., $TOKEN)]">
			<xsl:attribute name="details"><xsl:value-of select="$BASE-HREF"/><xsl:value-of select="/html/body/p[2]/a[contains(., $TOKEN)]/@href"/></xsl:attribute>
		</xsl:if>
		
		<time><xsl:value-of select="$TIME"/></time>
		<xsl:call-template name="title-type-splitter">
			<xsl:with-param name="TITLE"/>
			<xsl:with-param name="TYPE"><xsl:value-of select="$TITLE-AND-TYPE"/></xsl:with-param>
			<xsl:with-param name="SPLIT-TOKEN"> , </xsl:with-param>
		</xsl:call-template>
	</broadcast>
</xsl:template>


<xsl:template name="title-type-splitter">
	<xsl:param name="TITLE"/>
	<xsl:param name="TYPE"/>
	<xsl:param name="SPLIT-TOKEN"/>

	<xsl:choose>
		<xsl:when test="contains($TYPE, $SPLIT-TOKEN)">		
			<xsl:call-template name="title-type-splitter">
				<xsl:with-param name="TITLE"><xsl:value-of select="substring-before($TYPE, $SPLIT-TOKEN)"/><xsl:value-of select="$SPLIT-TOKEN"/></xsl:with-param>
				<xsl:with-param name="TYPE"><xsl:value-of select="substring-after($TYPE, $SPLIT-TOKEN)"/></xsl:with-param>
				<xsl:with-param name="SPLIT-TOKEN"><xsl:value-of select="$SPLIT-TOKEN"/></xsl:with-param>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<title><xsl:value-of select="substring($TITLE, 1, (string-length($TITLE) - string-length($SPLIT-TOKEN)))"/></title>
			<type><xsl:value-of select="$TYPE"/></type>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<xsl:template match="text()" />


</xsl:stylesheet>