<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!--xsl:include href="cml.xsl"/-->
  <xsl:include href="http://www.sci.kun.nl/sigma/Persoonlijk/egonw/xslt/examples/cml.xsl"/>

  <xsl:template match='AGENDA'><!-- AGENDA -->

    <HTML>
      <HEAD>
        <BASE HREF="http://www.sci.kun.nl/sigma/"/>
        <TITLE><xsl:value-of select="@NAME"/> Agenda</TITLE>
      </HEAD>
      <BODY BGCOLOR="#EEEEEE" BACKGROUND="gifs/achtergrond.gif">
        <TABLE WIDTH="100%">

	<xsl:choose>
          <xsl:when test="@NAME='Sigma'">
            <A NAME="{@NAME}"><xsl:value-of select='@NAME'/></A>
          </xsl:when>
        </xsl:choose>

        <!--xsl:apply-templates select="MAAND"/--><!-- /MAAND -->
        <!--xsl:value-of select="MAAND"/--><!-- /MAAND -->
        <!--xsl:call-template name="agenda"/--><!-- /MAAND -->

        <!--xsl:copy-of select="MAAND/PUNT"/-->
        <xsl:copy select="MAAND/PUNT"/>

        </TABLE>
      </BODY>
    </HTML>

  <!-- /AGENDA -->
  </xsl:template>

  <xsl:template name='agenda'>
        <xsl:apply-templates select="MAAND"/><!-- /MAAND -->
        <!--xsl:value-of select="MAAND"/--><!-- /MAAND -->
  </xsl:template>

  <xsl:template match='MAAND'><!-- MAAND -->

            <TR>
              <TD COLSPAN="4">
                <BR></BR>
                <H3><A NAME="{@NAAM}"><xsl:value-of select='@NAAM'/></A></H3>
              </TD>
            </TR>

            <!--xsl:apply-templates select="PUNT"/--><!-- /PUNT -->

  </xsl:template>

  <xsl:template match='PUNT'><!-- PUNT -->

              <TR>
                <TD WIDTH="1%" VALIGN="Top" ALIGN="Right">
                  <IMG SRC="/sigma/gifs/dots/greendot.gif" SIZE="50%"/>
                </TD>
                <TD WIDTH="20%" VALIGN="Top">
                  <xsl:value-of select='DATUM'/>
                </TD>
                <TD WIDTH="10%" VALIGN="Top" ALIGN="Right">
                  <I><xsl:value-of select='@TYPE'/></I>
                </TD>    
                <TD WIDTH="35%" VALIGN="Top">
                  <xsl:choose>
                    <xsl:when test='LINK'>
                      <A HREF="{LINK/@URL}"><B>
                        <xsl:value-of select='TITEL'/></B>
                      </A>
                      <BR></BR>
                    </xsl:when>
                    <xsl:otherwise>
                      <B><xsl:value-of select='TITEL'/></B>
                      <BR></BR>
                    </xsl:otherwise>
                  </xsl:choose>
                  <I>

                    <xsl:apply-templates select="INFO"/><!-- /INFO -->

                    <xsl:choose>
                      <xsl:when test='COMMENTAAR'>
                        <xsl:value-of select='COMMENTAAR'/><BR></BR>
                      </xsl:when>
                    </xsl:choose>
                  </I>
                </TD>
                <TD WIDTH="15%" VALIGN="Top" ALIGN="Right">
                  <B><I><xsl:value-of select='ORG'/></I></B>
                </TD>
              </TR>

  </xsl:template>

  <xsl:template match='INFO'><!-- INFO -->

                      <xsl:choose>
                        <xsl:when test='TIJD'>
                          <xsl:value-of select='TIJD'/><BR></BR>
                        </xsl:when>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test='PLAATS'>
                          <xsl:value-of select='PLAATS'/><BR></BR>
                        </xsl:when>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test='INSCHRIJVEN'>
                          <xsl:value-of select='INSCHRIJVEN'/><BR></BR>
                        </xsl:when>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test='CONTACT'>
                          <xsl:value-of select='CONTACT'/><BR></BR>
                        </xsl:when>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test='PRIJS'>
                          <xsl:value-of select='PRIJS'/><BR></BR>
                        </xsl:when>
                      </xsl:choose>

  </xsl:template>
</xsl:stylesheet>
