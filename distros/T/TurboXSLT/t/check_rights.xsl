<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:template match="/">
    <xsl:if test="chk:check_rights('sopelka')">Kh-h-h-h<br/>Pf-f-f-f</xsl:if>
    <xsl:if test="chk:check_rights('microphone')">karaoke</xsl:if>
    <xsl:if test="chk:check_rights('r2d2')">bip-bip-bip<br/></xsl:if>
    <xsl:if test="chk:check_rights('lightsaber') or chk:check_rights('use_force')">cool</xsl:if>
    <xsl:if test="chk:check_rights('dreem_GOD_power')">I am GOD! Bha-ha-ha-ha!</xsl:if>
  </xsl:template>
</xsl:stylesheet>
