<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:date="http://exslt.org/dates-and-times"
		xmlns:my="uri:local"
		extension-element-prefixes="date my"
		version="1.0">

   <xsl:template name="month-calendar">
      <xsl:param name="start-date"/>
      <xsl:param name="type"/>
	 <xsl:variable name="wd" select="date:day-in-week($start-date)"/>
	 <xsl:variable name="offset">
	    <xsl:choose>
	       <xsl:when test="$wd = 2">-P0D</xsl:when>
	       <xsl:when test="$wd = 1">-P6D</xsl:when>
	       <xsl:otherwise>-P<xsl:value-of select="$wd - 2"/>D</xsl:otherwise>
	    </xsl:choose>
	 </xsl:variable>
	 <xsl:variable name="title" select=
		       "concat(date:month-name($start-date),' ',date:year($start-date))"/>
      <div class="{$type}-calendar">
	 <xsl:variable name="not-year" select="$type != 'year'"/>
	 <xsl:variable name="not-sidebar" select="$type != 'sidebar'"/>
	 <xsl:variable name="size">
	    <xsl:choose>
	       <xsl:when test="$not-year and $not-sidebar">1</xsl:when>
	       <xsl:otherwise>2</xsl:otherwise>
	    </xsl:choose>
	 </xsl:variable>
	 <xsl:element name="h{$size}">
	    <xsl:copy-of select="my:href('month',$start-date,$title,$not-sidebar)"/>
	 </xsl:element>
	 <xsl:if test="$not-year and $not-sidebar">
	    <xsl:call-template name="wmy-nav">
	       <xsl:with-param name="type" select="$type"/>
	       <xsl:with-param name="date" select="$start-date"/>
	    </xsl:call-template>
	 </xsl:if>
      <table class="{$type}-calendar" summary="{$title}">
	 <colgroup>
	    <xsl:if test="$not-sidebar">
	       <col class="week-legend"/>
	    </xsl:if>
	    <col class="day" span="7"/>
	 </colgroup>
	 
	 <xsl:choose>
	    <xsl:when test="$type = 'sidebar'">
	       <tr class="day-names"><th>M</th><th>T</th><th>W</th>
	       <th>T</th><th>F</th><th>S</th><th>S</th></tr>
	    </xsl:when>
	    <xsl:otherwise>
	       <xsl:call-template name="day-name-row"/>
	    </xsl:otherwise>
	 </xsl:choose>

	 <xsl:call-template name="week">
	    <xsl:with-param name="start-date" select="date:add($start-date,$offset)"/>
	    <xsl:with-param name="month" select="date:month-in-year($start-date)"/>
	    <xsl:with-param name="this-month" select="date:month-in-year($start-date)"/>
	    <xsl:with-param name="type" select="$type"/>
	 </xsl:call-template>
      </table>
      </div>
   </xsl:template>

   <xsl:template name="week">
      <xsl:param name="start-date"/>
      <xsl:param name="this-month"/>
      <xsl:param name="type"/>
      <tr>
	 <xsl:if test="my:monday-week($start-date) = 
		       my:monday-week(ancestor-or-self::week/day[1]/@date)">
	    <xsl:attribute name="class">this-week</xsl:attribute>
	 </xsl:if>
	 <xsl:if test="$type != 'sidebar'">
	    <td class="week">
	       <xsl:copy-of select="my:href('week',$start-date,
				     date:week-in-year($start-date))"/></td>
	 </xsl:if>
	 <xsl:call-template name="day">
	    <xsl:with-param name="start-date" select="$start-date"/>
	    <xsl:with-param name="month" select="$month"/>
	    <xsl:with-param name="this-month" select="$this-month"/>
	    <xsl:with-param name="type" select="$type"/>
	 </xsl:call-template>
      </tr>
      <xsl:variable name="next-week" select="date:add($start-date,'P7D')"/>
      <xsl:if test="date:month-in-year($next-week) = $month">
	 <xsl:call-template name="week">
	    <xsl:with-param name="start-date"  select="$next-week"/>
	    <xsl:with-param name="month" select="$month"/>
	    <xsl:with-param name="this-month" select="$this-month"/>
	    <xsl:with-param name="type" select="$type"/>
	 </xsl:call-template>
      </xsl:if>
   </xsl:template>

   <xsl:template name="day">
      <xsl:param name="start-date"/>
      <xsl:param name="this-month"/>
      <xsl:param name="type"/>

      <xsl:variable name="wd" select="date:day-in-week($start-date)"/>
      <xsl:variable name="tomorrow" select="date:add($start-date,'P1D')"/>
      <xsl:variable name="class">
	 <xsl:if test="$start-date=substring(date:date(),1,10)">today </xsl:if>
	 <xsl:if test="$start-date=@date">this-day </xsl:if>
	 <xsl:if test="date:month-in-year($start-date) 
		       != $this-month">ignore </xsl:if>
      </xsl:variable>
      <td>
	 <xsl:if test="string-length($class) > 0">
	    <xsl:attribute name="class">
	       <!-- remove trailing space -->
	       <xsl:value-of select="substring($class,1,
				     string-length($class)-1)"/>
	    </xsl:attribute>
	 </xsl:if>
	 <p class="daynum">
	    <xsl:copy-of select="my:href('day',$start-date,
				  date:day-in-month($start-date))"/>
	 </p>
	 <xsl:if test="$type != 'sidebar'">
	    <xsl:apply-templates select="//month[@month=$month]//day[@date=$start-date]"/>
	 </xsl:if>
      </td>
      <xsl:if test="date:day-in-week($start-date) > 1">
	 <xsl:call-template name="day">
	    <xsl:with-param name="start-date" select="$tomorrow"/>
	    <xsl:with-param name="today" select="$today"/>
	    <xsl:with-param name="month" select="$month"/>
	    <xsl:with-param name="this-month" select="$this-month"/>
	    <xsl:with-param name="type" select="$type"/>
	 </xsl:call-template>
      </xsl:if>
   </xsl:template>

</xsl:stylesheet>
