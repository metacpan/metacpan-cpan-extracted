<?xml version="1.0"?>
<!--

    This stylesheet is used by IRSpy to map the internal mixed Zeerex/IRSpy
    record format into the Zeerex record which we store.

-->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:irspy="http://indexdata.com/irspy/1.0"
    xmlns="http://explain.z3950.org/dtd/2.0/"
    xmlns:explain="http://explain.z3950.org/dtd/2.0/"
    exclude-result-prefixes="irspy explain"
    version="1.0">

  <xsl:output indent="yes"
      method="xml"
      version="1.0"
      encoding="UTF-8"/>

  <xsl:strip-space elements="*"/>

  <xsl:variable name="old_indexes" select="/*/explain:indexInfo/explain:index"/>
  <xsl:variable name="use_attr_names" select="document('use-attr-names.xml')"/>
  <xsl:variable name="ping_date" select="/*/irspy:status/irspy:probe[last()]"/>


  <xsl:template match="/*">
    <explain>
      <xsl:call-template name="insert-zeerexBase"/>
      <xsl:call-template name="insert-indexInfo"/>
      <xsl:call-template name="insert-recordInfo"/>
      <xsl:call-template name="insert-configInfo"/>
      <xsl:call-template name="insert-irspySection"/>
    </explain>
  </xsl:template>


  <xsl:template name="insert-zeerexBase">
    <xsl:copy-of select="explain:serverInfo"/>
    <xsl:copy-of select="explain:databaseInfo"/>
    <metaInfo>
      <dateModified><xsl:value-of select="$ping_date"/></dateModified>
    </metaInfo>
  </xsl:template>


  <xsl:template name="insert-indexInfo">
    <indexInfo>
      <xsl:choose>

        <!-- Check that search was actually probed -->
        <xsl:when test="/*/irspy:status/irspy:search">
          <xsl:for-each select="/*/irspy:status/irspy:search">
            <xsl:variable name="set" select="@set"/>
            <xsl:variable name="ap" select="@ap"/>
            <xsl:variable name="old"
                select="$old_indexes[explain:map/explain:attr/@set = $set and
                                     explain:map/explain:attr/text() = $ap]"/>
            <xsl:choose>
              <xsl:when test="$old">
                <xsl:call-template name="insert-index-section">
                  <xsl:with-param name="title" select="$old/explain:title"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="insert-index-section"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:when>

        <!-- If not, insert what we already had... -->
        <xsl:otherwise>
          <xsl:copy-of
                select="explain:indexInfo/explain:index[@search='true']"/>
        </xsl:otherwise>
      </xsl:choose>
    </indexInfo>
  </xsl:template>


  <xsl:template name="insert-recordInfo">
    <recordInfo>
      <xsl:choose>

        <!-- Did we actually probe record syntaxes? -->
        <xsl:when test="/*/irspy:status/irspy:record_fetch">
          <xsl:for-each select="/*/irspy:status/irspy:record_fetch[@ok = 1]">
            <recordSyntax name="{@syntax}">
              <elementSet name="F"/> <!-- FIXME: This should be probed too -->
            </recordSyntax>
          </xsl:for-each>
        </xsl:when>

        <!-- If not, use the existing test report... -->
        <xsl:otherwise>
          <xsl:copy-of select="explain:recordInfo/*"/>
        </xsl:otherwise>
      </xsl:choose>
    </recordInfo>
  </xsl:template>


  <xsl:template name="insert-configInfo">
    <configInfo>
      <xsl:choose>
        <xsl:when test="/*/irspy:status/irspy:init_opt">
          <xsl:for-each select="/*/irspy:status/irspy:init_opt">
            <supports type="z3950_{@option}">1</supports>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="explain:configInfo/*"/>
        </xsl:otherwise>
      </xsl:choose>
    </configInfo>
  </xsl:template>


  <!-- 
       Here we list the bits and pieces of the irspy:status element which we
       want to keep in the persistent version of the zeerex record.
  -->
  <xsl:template name="insert-irspySection">
    <irspy:status>
      <xsl:copy-of select="*/irspy:libraryType"/>
      <xsl:copy-of select="*/irspy:country"/>
      <xsl:copy-of select="*/irspy:probe"/>

      <xsl:call-template name="insert-latest-nodes">
        <xsl:with-param name="nodes" select="*/irspy:boolean"/>
        <xsl:with-param name="what" select="'boolean'"/>
      </xsl:call-template>
      
      <xsl:call-template name="insert-latest-nodes">
        <xsl:with-param name="nodes" select="*/irspy:named_resultset"/>
        <xsl:with-param name="what" select="'named_resultset'"/>
      </xsl:call-template>
      
      <xsl:call-template name="insert-latest-nodes">
        <xsl:with-param name="nodes" select="*/irspy:explain"/>
        <xsl:with-param name="what" select="'explain'"/>
      </xsl:call-template>

      <xsl:call-template name="insert-latest-nodes">
        <xsl:with-param name="nodes" select="*/irspy:serverImplementationId"/>
        <xsl:with-param name="what" select="'serverImplementationId'"/>
      </xsl:call-template>

      <xsl:call-template name="insert-latest-nodes">
        <xsl:with-param name="nodes" select="*/irspy:serverImplementationName"/>
        <xsl:with-param name="what" select="'serverImplementationName'"/>
      </xsl:call-template>

      <xsl:call-template name="insert-latest-nodes">
        <xsl:with-param name="nodes"
                    select="*/irspy:serverImplementationVersion"/>
        <xsl:with-param name="what" select="'serverImplementationVersion'"/>
      </xsl:call-template>

      <xsl:call-template name="insert-latest-nodes">
        <xsl:with-param name="nodes" select="*/irspy:multiple_opac"/>
        <xsl:with-param name="what" select="'multiple_opac'"/>
      </xsl:call-template>

      <xsl:call-template name="insert-latest-nodes">
        <xsl:with-param name="nodes" select="*/irspy:search_bath"/>
        <xsl:with-param name="what" select="'search_bath'"/>
      </xsl:call-template>
    </irspy:status>
  </xsl:template>


  <!-- 
       NB: This template assumes that the irspy:probe nodes come in ascending
       order. If this is not the case, this template has to do some kind of
       sorting which makes the whole thing more complicated.

       Dec 12, 2006: Anders
  -->
  <xsl:template name="insert-latest-nodes">
    <xsl:param name="nodes"/>
    <xsl:param name="what" select="'unspecified'"/>
    <xsl:param name="i" select="count(*/irspy:probe[@ok='1'])"/>
    <xsl:variable name="date"
        select="*/irspy:probe[@ok='1'][$i]"/>
    <xsl:variable name="latest"
        select="$nodes[irspy:strcmp(text(), $date) >= 0]"/>

    <xsl:choose>
      <xsl:when test="$latest">
        <xsl:copy-of select="$latest"/>
      </xsl:when>
      <!-- <xsl:when test="$i > 0 and $i &lt; 200"> -->
      <xsl:when test="$i > 0">
        <xsl:call-template name="insert-latest-nodes">
          <xsl:with-param name="what" select="$what"/>
          <xsl:with-param name="nodes" select="$nodes"/>
          <xsl:with-param name="i" select="$i - 1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <irspy:missing what="{$what}" when="{$ping_date}"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template match="node() | @*">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>


  <xsl:template name="insert-index-section">
    <xsl:param name="update" select="."/>
    <xsl:param name="title">
      <xsl:call-template name="insert-index-title">
        <xsl:with-param name="update" select="$update"/>
      </xsl:call-template>
    </xsl:param>

    <xsl:if test="$update/@ok = 1">
      <index search="true">
        <title primary="true" lang="en"><xsl:value-of select="$title"/></title>
        <map primary="true">
          <attr type="1" set="{$update/@set}">
            <xsl:value-of select="$update/@ap"/>
          </attr>
        </map>
      </index>
    </xsl:if>
  </xsl:template>


  <xsl:template name="insert-index-title">
    <xsl:param name="update"/>
    <xsl:variable name="name"
                select="$use_attr_names/*/map[@attr = $update/@ap and
                                              @set = $update/@set]/@name"/>

    <xsl:choose>
      <xsl:when test="string-length($name) &gt; 0"><xsl:value-of
                                            select="$name"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$update/@ap"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="*"/>

</xsl:stylesheet>
