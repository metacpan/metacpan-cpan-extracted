<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
	
	<xsl:template match="/">
		<xsl:call-template name="test"/>
	</xsl:template>
		
	<xsl:template name="test">	
			<xsl:variable name="cont">
					<span class="content">
						<span class="auth_txt">1111111111111<br/>2222222222222<br />3333333333333</span>
					</span>
			</xsl:variable>
			
		<xsl:copy-of select="$cont"/><br/><br/>		
		<xsl:value-of select="$cont"/>
		
	</xsl:template>

</xsl:stylesheet>

