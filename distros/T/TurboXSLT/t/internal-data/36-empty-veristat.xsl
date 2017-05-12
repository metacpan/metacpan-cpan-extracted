<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">
<xsl:template match="/">
	<xsl:apply-templates/>
</xsl:template>
<xsl:template match="gift_cards">
		<div id="giftcard">
			<xsl:variable name="giftcard_bg_img">img/gift_cards/card-<xsl:choose>
			<xsl:when test="/xportal/formdata/@card_nom"><xsl:value-of select="number(cards/card[@price=/xportal/formdata/@card_nom]/@nom)"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="number(cards/card[1]/@nom)"/></xsl:otherwise>
			</xsl:choose>.jpg</xsl:variable>
			<xsl:attribute name="style">background-image:url(<xsl:value-of select="ltr:veristat($giftcard_bg_img)" />);</xsl:attribute>
			[<xsl:value-of select="$giftcard_bg_img"/>]
		</div>
</xsl:template>
</xsl:stylesheet>
