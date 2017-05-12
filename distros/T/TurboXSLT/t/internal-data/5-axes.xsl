<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ltr="LTR">
<xsl:template match="test">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	</head>
	<body>
		<xsl:value-of select="not(not(.//@param1))"/><br />
		<xsl:value-of select="not(not(descendant-or-self::node()/@param1))"/><br />
		<xsl:value-of select="not(not(descendant-or-self::*/@param1))"/><br />
	</body>
</xsl:template>
</xsl:stylesheet>
