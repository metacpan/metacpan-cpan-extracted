<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="month-name">
	<xsl:param name="month"/>

	<xsl:choose>
		<xsl:when test="$month = 1">January</xsl:when>
		<xsl:when test="$month = 2">February</xsl:when>
		<xsl:when test="$month = 3">March</xsl:when>
		<xsl:when test="$month = 4">April</xsl:when>
		<xsl:when test="$month = 5">May</xsl:when>
		<xsl:when test="$month = 6">June</xsl:when>
		<xsl:when test="$month = 7">July</xsl:when>
		<xsl:when test="$month = 8">August</xsl:when>
		<xsl:when test="$month = 9">September</xsl:when>
		<xsl:when test="$month = 10">October</xsl:when>
		<xsl:when test="$month = 11">November</xsl:when>
		<xsl:when test="$month = 12">December</xsl:when>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>
