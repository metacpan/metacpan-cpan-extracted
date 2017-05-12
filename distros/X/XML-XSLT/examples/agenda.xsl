<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:template match='/'>
    <xsl:apply-templates select="AGENDA" />
  </xsl:template>

  <xsl:template match='AGENDA'>
  <xsl:comment> AGENDA </xsl:comment>

    <HTML>
      <HEAD>
        <BASE HREF="http://www.sci.kun.nl/sigma/"/>
        <TITLE><xsl:value-of select="@NAME"/> Agenda</TITLE>
      </HEAD>
      <BODY BGCOLOR="#EEEEEE" BACKGROUND="gifs/achtergrond.gif">
        <TABLE WIDTH="100%">


        <xsl:apply-templates select='MAAND[1]'/>
        <xsl:comment> /MAAND </xsl:comment>

        </TABLE>
      </BODY>
    </HTML>

  <xsl:comment> /AGENDA </xsl:comment>
  </xsl:template>

  <xsl:template match='MAAND'>
          <xsl:comment> MAAND </xsl:comment>

            <TR>
              <TD COLSPAN="4">
                <BR />
                <H3><A NAME="{@NAAM}"><xsl:value-of select='@NAAM'/></A></H3>
              </TD>
            </TR>

            <xsl:apply-templates select='PUNT' />
            <xsl:comment> /PUNT </xsl:comment>

  </xsl:template>

  <xsl:template match='PUNT'>
            <xsl:comment> PUNT </xsl:comment>

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
                    <xsl:when test='LINK/@URL'>
                      <A HREF="{LINK/@URL}"><B>
                        <xsl:value-of select='TITEL'/></B>
                      </A>
                      <BR />
                    </xsl:when>
                    <xsl:otherwise>
                      <B><xsl:value-of select='TITEL'/></B>
                      <BR />
                    </xsl:otherwise>
                  </xsl:choose>
                  <I>

                    <xsl:apply-templates select='INFO'/>
                    <xsl:comment> /INFO </xsl:comment>

                    <xsl:if test='COMMENTAAR'>
                      <xsl:value-of select='COMMENTAAR'/><BR />
                    </xsl:if>
                  </I>
                </TD>
                <TD WIDTH="15%" VALIGN="Top" ALIGN="Right">
                  <B><I><xsl:value-of select='ORG'/></I></B>
                </TD>
              </TR>

  </xsl:template>

  <xsl:template match='INFO'>
                    <xsl:comment> INFO </xsl:comment>

                      <xsl:choose>
                        <xsl:when test='TIJD'>
                          <xsl:value-of select='TIJD'/><BR />
                        </xsl:when>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test='PLAATS'>
                          <xsl:value-of select='PLAATS'/><BR />
                        </xsl:when>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test='INSCHRIJVEN'>
                          <xsl:value-of select='INSCHRIJVEN'/><BR />
                        </xsl:when>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test='CONTACT'>
                          <xsl:value-of select='CONTACT'/><BR />
                        </xsl:when>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test='PRIJS'>
                          <xsl:value-of select='PRIJS'/><BR />
                        </xsl:when>
                      </xsl:choose>

  </xsl:template>
</xsl:stylesheet>
