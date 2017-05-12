<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/Alpha/Charlie">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        </head>
        <body>
ancestor: <xsl:value-of select="count(India/ancestor::*)"/><br/>
ancestor-or-self: <xsl:value-of select="count(India/ancestor-or-self::*)"/><br/>
child: <xsl:value-of select="count(child::*)"/><br/>
descendant: <xsl:value-of select="count(descendant::*)"/><br/>
descendant-or-self: <xsl:value-of select="count(descendant-or-self::*)"/><br/>
following: <xsl:value-of select="count(following::*)"/><br/>
following-sibling: <xsl:value-of select="count(following-sibling::*)"/><br/>
parent: <xsl:value-of select="name(India/parent::*)"/><br/>
preceding: <xsl:value-of select="count(preceding::*)"/><br/>
preceding-sibling: <xsl:value-of select="count(preceding-sibling::*)"/><br/>
self: <xsl:value-of select="name(self::*)"/>
        </body>
    </xsl:template>
</xsl:stylesheet>
