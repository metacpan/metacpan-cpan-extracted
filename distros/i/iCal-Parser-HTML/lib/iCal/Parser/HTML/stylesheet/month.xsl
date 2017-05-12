<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:date="http://exslt.org/dates-and-times"
		xmlns:my="uri:local"
		extension-element-prefixes="date my"
		version="1.0">

   <xsl:import href="cal-util.xsl"/>
   <xsl:import href="month-util.xsl"/>

   <!-- xsd:date values -->
   <xsl:param name="year" select="date:year()"/>
   <xsl:param name="month" select="date:month-in-year()"/>

   <xsl:template name="caltype">Monthly</xsl:template>

   <xsl:template name="day-name-row">
      <tr class="day-names"><th>&#xA0;</th><th>Mon</th><th>Tue</th><th>Wed</th>
      <th>Thu</th><th>Fri</th><th>Sat</th><th>Sun</th></tr>
   </xsl:template>

   <xsl:template match="ical">
      <xsl:variable name="date" select="my:ymd2date($year,$month)"/>
      <xsl:call-template name="sidebar">
	 <xsl:with-param name="start-date" select="$date"/>
      </xsl:call-template>
      <div class="calendar">
	 <xsl:call-template name="month-calendar">
	    <xsl:with-param name="start-date" select="$date"/>
	    <xsl:with-param name="type" select="'month'"/>
	 </xsl:call-template>
      </div>
   </xsl:template>

   <xsl:template match="day">
	 <xsl:apply-templates/>
   </xsl:template>

   <xsl:template match="event">
      <xsl:variable name="time" select="my:ampm(my:time(dtstart),true())"/>
      <xsl:variable name="all-day">
	 <xsl:if test="@all-day"> all-day</xsl:if>
      </xsl:variable>
      <p class="month-event{my:cal-index(@idref)}{$all-day}">
	 <xsl:if test="$all-day = ''">
	    <xsl:value-of select="$time"/>
	    <xsl:text> </xsl:text>
	 </xsl:if>
	 <xsl:value-of select="summary" disable-output-escaping="yes"/>
      </p>
   </xsl:template>

</xsl:stylesheet>
