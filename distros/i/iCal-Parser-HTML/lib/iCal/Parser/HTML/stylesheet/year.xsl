<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:date="http://exslt.org/dates-and-times"
		xmlns:my="uri:local"
		extension-element-prefixes="date my"
		version="1.0">

   <xsl:import href="cal-util.xsl"/>
   <xsl:param name="year" select="date:year()"/>

   <xsl:template name="caltype">Yearly</xsl:template>

   <xsl:template match="ical">
      <div class="calendar">
	 <h1><xsl:value-of select="$year"/></h1>
	 <xsl:call-template name="wmy-nav">
	    <xsl:with-param name="type" select="'year'"/>
	    <xsl:with-param name="date" select="$year"/>
	 </xsl:call-template>
	 <table class="year" summary="{$year}">
	    <xsl:call-template name="row">
	       <xsl:with-param name="start" select="concat($year,'-01-01')"/>
	    </xsl:call-template>
	 </table>
      </div>
   </xsl:template>

   <xsl:template name="row">
      <xsl:param name="start"/>
      <xsl:variable name="next" select="date:add($start,'P3M')"/>
      <tr>
	 <xsl:call-template name="month">
	    <xsl:with-param name="start" select="$start"/>
	 </xsl:call-template>
      </tr>
      <xsl:if test="date:year($next) = $year">
	 <xsl:call-template name="row">
	    <xsl:with-param name="start" select="$next"/>
	 </xsl:call-template>
      </xsl:if>
   </xsl:template>

   <xsl:template name="month">
      <xsl:param name="start"/>
      <xsl:variable name="next" select="date:add($start,'P1M')"/>
      <td class="year">
	 <xsl:call-template name="month-calendar">
	    <xsl:with-param name="start-date" select="$start"/>
	    <xsl:with-param name="type" select="'year'"/>
	 </xsl:call-template>
      </td>
      <xsl:if test="date:month-in-year($start) mod 3 != 0">
	 <xsl:call-template name="month">
	    <xsl:with-param name="start" select="$next"/>
	 </xsl:call-template>
      </xsl:if>
   </xsl:template>

   <xsl:template match="day">
      <xsl:if test="count(event)">
	 <xsl:value-of select="count(event)"/>
      </xsl:if>
   </xsl:template>

   <xsl:template name="day-name-row">
      <tr class="day-names"><th>&#xA0;</th><th>Mon</th><th>Tue</th><th>Wed</th>
      <th>Thu</th><th>Fri</th><th>Sat</th><th>Sun</th></tr>
   </xsl:template>

</xsl:stylesheet>
