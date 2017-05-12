<?xml version="1.0" ?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="sprockets">
    <xsl:apply-templates />
</xsl:template>

<xsl:template match="doodads">
    <div class="blart">
        <xsl:for-each select="thingy">
            <div id="panel_{@ID}" class="upper">
                <h3><xsl:value-of select="@name" /></h3>
            </div>
        </xsl:for-each>
    </div>
</xsl:template>

</xsl:stylesheet>
