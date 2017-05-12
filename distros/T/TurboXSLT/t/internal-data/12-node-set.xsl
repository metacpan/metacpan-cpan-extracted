<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

<!--  Test exslt:node-set applied to a result tree fragment  -->
<xsl:variable name="tree">
   <a>
      <b>
         <c>
            <d />
         </c>
      </b>
   </a>
</xsl:variable>
<xsl:template match="/">
   <out>
      <xsl:value-of select="count(exsl:node-set(//*))" /><br/>
      <xsl:value-of select="count(exsl:node-set($tree)//*)"/>
   </out>
   
</xsl:template>

</xsl:stylesheet>
