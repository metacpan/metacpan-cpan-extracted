<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:chk="LTR:chk" xmlns:ltr="LTR" exclude-result-prefixes="ltr chk" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">
<xsl:decimal-format name="filesize" decimal-separator="," grouping-separator=" "/>
<xsl:template match="test">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	</head>
	<body>
		format-number: <xsl:value-of select="format-number(@min,' 00', 'filesize')"/><br/>
		format-number: <xsl:value-of select="format-number(@sec,' 00', 'filesize')"/><br/>
		format-number: <xsl:value-of select="format-number(@cash_1,' # ##0,00', 'filesize')"/><br/>
		format-number: <xsl:value-of select="format-number(@cash_2,' # ##0,00', 'filesize')"/><br/>
		format-number: <xsl:value-of select="format-number(@cash_3,'0,00','filesize')"/><br/>
		translate: <xsl:value-of select="translate(@chars, ':', '')"/><br/>
		substring: <xsl:value-of select="substring(@chars1, string-length(@chars1) - 5, 2)"/><br/>
		substring: <xsl:value-of select="substring(@chars1, string-length(@chars1) - 3, 2)"/><br/>
	</body>
</xsl:template>
</xsl:stylesheet>
