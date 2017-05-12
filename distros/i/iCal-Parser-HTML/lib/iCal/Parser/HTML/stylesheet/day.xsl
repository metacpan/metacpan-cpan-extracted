<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:date="http://exslt.org/dates-and-times"
		xmlns:my="uri:local"
		extension-element-prefixes="date my"
		version="1.0">

   <xsl:include href="day-util.xsl"/>

   <xsl:param name="date" select="substring(date:date(),1,10)"/>

   <xsl:template name="caltype">Daily</xsl:template>

   <xsl:template match="ical">
      <xsl:apply-templates 
	select="//day[@date=$date 
		and ancestor::month/@month=date:month-in-year($date)]"/>
   </xsl:template>
   
   <xsl:template match="day">
      <xsl:call-template name="sidebar">
	 <xsl:with-param name="start-date" 
			 select="concat(substring(@date,1,8),'01')"/>

      </xsl:call-template>
      <div class="calendar">
	 <h1><xsl:value-of select="my:format-date(@date,true())"/></h1>
	 <xsl:call-template name="wmy-nav">
	    <xsl:with-param name="type" select="'day'"/>
	    <xsl:with-param name="date" select="@date"/>
	 </xsl:call-template>

	 <table class="day" summary="daily calendar">
	    <colgroup>
	       <col class="hour-legend"/>
	       <col class="day" span="{my:conflict()+$add-span}"/>
	    </colgroup>
	    <xsl:call-template name="all-day"/>
	    <xsl:call-template  name="hour">
	       <xsl:with-param name="hour" select ="0"/>
	    </xsl:call-template>
	 </table>
      </div>
   </xsl:template>   

   <xsl:template name="half-hour">
      <xsl:param name="h"/>
      <xsl:param name="q"/>
      <xsl:variable name="hh">
	 <xsl:if test="string-length($h) &lt; 2">0</xsl:if>
	 <xsl:value-of select="$h"/>
      </xsl:variable>
      <tr id="H{$hh}{$q}">
	 <xsl:call-template name="hour-legend">
	    <xsl:with-param name="h" select="$hh"/>
	    <xsl:with-param name="q" select="$q"/>
	 </xsl:call-template>
	 <xsl:call-template name="hour-events">
	    <xsl:with-param name="h" select="$hh"/>
	    <xsl:with-param name="q" select="$q"/>
	 </xsl:call-template>
      </tr>

      <xsl:if test="$q &lt; 30">
	 <xsl:call-template name="half-hour">
	    <xsl:with-param name="h" select="$h"/>
	    <xsl:with-param name="q" select="$q+30"/>
	 </xsl:call-template>
      </xsl:if>
   </xsl:template>

   <xsl:template name="all-day">
      <xsl:variable name="colspan" select="my:conflict()+$add-span"/>
      <xsl:for-each select="event[@all-day]">
	 <tr class="all-day">
	    <th><xsl:if test="position()=1">All Day</xsl:if></th>
	    <td class="all-day{my:cal-index(@idref)}" colspan="{$colspan}">
	       <xsl:value-of select="summary" disable-output-escaping="yes"/>
	    </td>
	 </tr>
      </xsl:for-each>
      <tr class="all-day-sep"><td colspan="{$colspan+1}"></td></tr>
   </xsl:template>

</xsl:stylesheet>
