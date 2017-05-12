<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">
<xsl:template match="test">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	</head>
	<body>
		<xsl:choose>
			<xsl:when test="sub_test/@username != 0">1</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose><br/>
		<xsl:choose>
			<xsl:when test="sub_test[1]/@username != 0">1</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose><br/>
		<xsl:choose>
			<xsl:when test="sub_test[3]/@username != 0">1</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose><br/>
	</body>
</xsl:template>
</xsl:stylesheet>
