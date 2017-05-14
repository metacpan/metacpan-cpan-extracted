<xsl:template match='AGENDA'><!-- AGENDA -->

  <HTML>
    <HEAD>
      <BASE HREF="http://www.sci.kun.nl/sigma/"/>
      <TITLE><xsl:value-of select='{NAME}'/> Agenda</TITLE>
    </HEAD>
    <BODY BGCOLOR="#EEEEEE" BACKGROUND="gifs/achtergrond.gif">
      <TABLE WIDTH="100%">


        <xsl:for-each select='MAAND'><!-- MAAND -->

          <TR>
            <TD COLSPAN="4">
              <BR></BR>
              <H3><A NAME="{@NAAM}"><xsl:value-of select='{NAAM}'/></A></H3>
            </TD>
          </TR>

          <xsl:for-each select='PUNT'><!-- PUNT -->

            <TR>
              <TD WIDTH="1%" VALIGN="Top" ALIGN="Right">
                <IMG SRC="/sigma/gifs/dots/greendot.gif" SIZE="50%"/>
              </TD>
              <TD WIDTH="20%" VALIGN="Top">
                <xsl:value-of select='DATUM'/>
              </TD>
              <TD WIDTH="10%" VALIGN="Top" ALIGN="Right">
                <I><xsl:value-of select='{TYPE}'/></I>
              </TD>    
              <TD WIDTH="35%" VALIGN="Top">
                <xsl:choose>
                  <xsl:when test='LINK'>
                    <A HREF="{LINK@URL}"><B>
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

                  <xsl:sub-template match='INFO'><!-- INFO -->

                    <xsl:when test='TIJD'>
                      <xsl:value-of select='TIJD'/><BR></BR>
                    </xsl:when>
                    <xsl:when test='PLAATS'>
                      <xsl:value-of select='PLAATS'/><BR></BR>
                    </xsl:when>
                    <xsl:when test='INSCHRIJVEN'>
                      <xsl:value-of select='INSCHRIJVEN'/><BR></BR>
                    </xsl:when>
                    <xsl:when test='CONTACT'>
                      <xsl:value-of select='CONTACT'/><BR></BR>
                    </xsl:when>
                    <xsl:when test='PRIJS'>
                      <xsl:value-of select='PRIJS'/><BR></BR>
                    </xsl:when>

                  </xsl:sub-template><!-- /INFO -->

                  <xsl:when test='COMMENTAAR'>
                    <xsl:value-of select='COMMENTAAR'/><BR></BR>
                  </xsl:when>
                </I>
              </TD>
              <TD WIDTH="15%" VALIGN="Top" ALIGN="Right">
                <B><I><xsl:value-of select='ORG'/></I></B>
              </TD>
            </TR>

          </xsl:for-each><!-- /PUNT -->

        </xsl:for-each><!-- /MAAND -->

      </TABLE>
    </BODY>
  </HTML>

</xsl:template><!-- /AGENDA -->
