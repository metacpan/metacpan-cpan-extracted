<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 <xsl:template match="SCHADSTOFFBELASTUNG">
   <BLOCKQUOTE>

   <TT><B>Belastungsgebiet(e):</B></TT>
   <xsl:apply-templates/>

   </BLOCKQUOTE>
 </xsl:template>

 <xsl:template match="BELASTUNGSGEBIET">
        <TT><xsl:value-of select="."/></TT><BR/>
 </xsl:template>
</xsl:stylesheet>
