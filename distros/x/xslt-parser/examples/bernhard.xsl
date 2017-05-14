 <xsl:sub-template match="SCHADSTOFFBELASTUNG">
   <BLOCKQUOTE>

   <TT><B>Belastungsgebiet(e):</B></TT>
   <xsl:for-each select="BELASTUNGSGEBIET">
        <TT><xsl:value-of select="."/></TT><BR/>
   </xsl:for-each>

   </BLOCKQUOTE>
 </xsl:sub-template>
