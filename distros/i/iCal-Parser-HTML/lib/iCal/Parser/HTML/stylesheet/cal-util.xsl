<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:date="http://exslt.org/dates-and-times"
		xmlns:f="http://exslt.org/functions"
		xmlns:my="uri:local"
		extension-element-prefixes="date f my"
		version="1.0">

   <xsl:import href="month-util.xsl"/>

   <xsl:param name="start"/>
   <xsl:param name="end"/>
   <xsl:param name="ampm"/>
   <xsl:param name="max-text" select="20"/>
   <xsl:param name="base-url"/>
   <xsl:param name="no-links" select="string-length($base-url) = 0"/>
   <xsl:variable name="need-semi" 
		 select="not($no-links) 
			 and substring($base-url,string-length($base-url)) != '?'"/>
   <xsl:param name="today" 
	      select="concat(date:year(),'-',date:month-in-year(),'-',
		      date:day-in-month())"/>

   <xsl:output method="xml"
	       doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
	       doctype-system=
	       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
	       encoding="utf-8"
	       indent="yes"
	       omit-xml-declaration="yes"
	       />

   <xsl:template match="text()"/>
   <xsl:template match="/">
      <html lang="en" xml:lang="en">
	 <head>
	    <!-- $Id: cal-util.xsl 1 2005-03-19 23:14:58Z rick $ -->
	    <meta http-equiv="Content-Type" content="text/html; 
						     charset=UTF-8" />
	    <link rel="stylesheet" type="text/css" href="calendar.css"/>
	    <title><xsl:call-template name="caltype"/> Calendar</title>
	 </head>
	 <body>
	    <xsl:apply-templates/>
	 </body>
      </html>
   </xsl:template>

   <xsl:template name="sidebar">
      <xsl:param name="start-date"/>
      <div class="sidebar">
	 <div class="legend">
	    <h2 class="legend-head">Legend</h2>
	    <xsl:apply-templates select="//calendar"/>
	 </div>
	 <div class="todo">
	    <h2>Todo</h2>
	    <table class="todo" summary="Todos">
	       <colgroup>
		  <col class="summary"/>
		  <col class="priority"/>
		  <col class="due"/>
	       </colgroup>
	       <tr><th>&#xA0;</th><th>Pri</th><th>Due</th></tr>
	       <xsl:apply-templates select="//todo"/>
	    </table>
	 </div>
	 <div class="sidebar-calendar-group">
	    <xsl:call-template name="month-calendar">
	       <xsl:with-param name="start-date" select="date:add($start-date,'-P1M')"/>
	       <xsl:with-param name="type" select="'sidebar'"/>
	    </xsl:call-template>
	    <xsl:call-template name="month-calendar">
	       <xsl:with-param name="start-date" select="$start-date"/>
	       <xsl:with-param name="type" select="'sidebar'"/>
	    </xsl:call-template>
	    <xsl:call-template name="month-calendar">
	       <xsl:with-param name="start-date" select="date:add($start-date,'P1M')"/>
	       <xsl:with-param name="type" select="'sidebar'"/>
	    </xsl:call-template>
	 </div>
      </div>
   </xsl:template>

   <xsl:template match="todo">
      <tr class="todo{my:cal-index(@idref)}">
	 <td>
	    <xsl:call-template name="todo-status"/>
	    <xsl:value-of select="summary" disable-output-escaping="yes"/>
	 </td>
	 <td>
	    <xsl:call-template name="todo-status">
	       <xsl:with-param name="extra" select="'priority'"/>
	    </xsl:call-template>
	    <xsl:if test="priority &lt; 99">
	       <xsl:value-of select="priority"/>
	    </xsl:if>
	 </td>
	 <td>
	    <xsl:call-template name="todo-status"/>
	    <xsl:value-of select="date:date(due)"/>
	 </td>
      </tr>
   </xsl:template>
   
   <xsl:template name="todo-status">
      <xsl:param name="extra"/>
      <xsl:variable name="class">
	 <xsl:if test="status">
	    <xsl:value-of select="status"/>
	    <xsl:if test="$extra">
	       <xsl:text> </xsl:text>
	    </xsl:if>
	 </xsl:if>
	 <xsl:value-of select="$extra"/>
      </xsl:variable>
      <xsl:if test="$class">
	 <xsl:attribute name="class">
	    <xsl:value-of select="$class"/>
	 </xsl:attribute>
      </xsl:if>
   </xsl:template>

   <xsl:template match="calendar">
      <p class="calendar-{@index} legend" title="{@description}">
	 <xsl:value-of select="@name"/>
      </p>
   </xsl:template>

   <xsl:template name="wmy-nav">
      <xsl:param name="type"/>
      <xsl:param name="date"/>
      <xsl:if test="not($no-links)">
	 <xsl:variable name="duration">
	    <xsl:choose>
	       <xsl:when test="$type='day'">P1D</xsl:when>
	       <xsl:when test="$type='week'">P7D</xsl:when>
	       <xsl:when test="$type='month'">P0Y1M</xsl:when>
	       <xsl:otherwise>P1Y</xsl:otherwise>
	    </xsl:choose>
	 </xsl:variable>

	 <div class="nav">
	    <xsl:copy-of select="my:href($type,date:add(
				 $date,concat('-',$duration)),'&lt;')"/>
	    <xsl:if test="$type = 'day'">
	       <xsl:copy-of select="my:href('week',$date,'week')"/>
	    </xsl:if>
	    <xsl:if test="$type='day' or $type='week'">
	       <xsl:copy-of select="my:href('month',$date,'month')"/>
	    </xsl:if>
	    <xsl:if test="$type='day' or $type='week' or $type='month'">
	       <xsl:copy-of select="my:href('year',$date,'year')"/>
	    </xsl:if>
	    <xsl:copy-of 
	      select="my:href($type,date:add($date,$duration),'&gt;')"/>
	 </div>
      </xsl:if>
   </xsl:template>

   <f:function name="my:cal-index">
      <xsl:param name="calid"/>
      <xsl:variable name="calendar" select="/ical/calendar[@id=$calid]/@index"/>
      <f:result select="concat(' calendar-',$calendar)"/>
   </f:function>

   <f:function name="my:in-range">
      <xsl:param name="date"/>
      <f:result select=
		"(not($start) or substring(date:difference($start,$date),1,1)!='-')
		 and (not($end) or substring(date:difference($end,$date),1,1)='-')"
		/>
   </f:function>

   <f:function name="my:next-day">
      <xsl:param name="prev" select="preceding-sibling::*[1]/dtstart"/>
      <f:result select="date:difference(date:date(dtstart),
			date:date($prev)) != 'P0D'"/>
   </f:function>

   <f:function name="my:time">
      <xsl:param name="time"/>
      <f:result select="substring(date:time($time),1,5)"/>
   </f:function>

   <f:function name="my:full-day">
      <xsl:param name="date"/>
      <xsl:variable name="fmt" select=
		    "concat(date:day-abbreviation($date),', ',
		     date:month-abbreviation($date),' ',
		     date:day-in-month($date),', ',
		     date:year($date))"/>
      <f:result select="$fmt"/>
   </f:function>

   <f:function name="my:ampm">
      <xsl:param name="time"/>
      <xsl:param name="show-ind" select="false()"/>

      <xsl:variable name="minute" select="substring-after($time,':')"/>
      <xsl:variable name="hr" select="substring-before($time,':')"/>
      <xsl:variable name="hour">
	 <xsl:choose>
	    <xsl:when test="starts-with($hr,'0')">
	       <xsl:value-of select="substring($hr,2)"/>
	    </xsl:when>
	    <xsl:otherwise>
	       <xsl:value-of select="$hr"/>
	    </xsl:otherwise>
	 </xsl:choose>
      </xsl:variable>
      <xsl:variable name="ind">
	 <xsl:choose>
	    <xsl:when test="not($show-ind)"/>
	    <xsl:when test="not($ampm)"/>
	    <xsl:when test="$hour &lt; 12">AM</xsl:when>
	    <xsl:otherwise>PM</xsl:otherwise>
	 </xsl:choose>
      </xsl:variable>
      
      <xsl:variable name="h">
	 <xsl:choose>
	    <xsl:when test="not($ampm)"><xsl:value-of select="$hour"/></xsl:when>
	    <xsl:when test="$hour > 12">
	       <xsl:variable name="th" select="$hour - 12"/>
	       <xsl:if test="string-length($th) &lt; 2">0</xsl:if>
	       <xsl:value-of select="$th"/>
	    </xsl:when>
	    <xsl:when test="$hour = 0">12</xsl:when>
	    <xsl:otherwise><xsl:value-of select="$hour"/></xsl:otherwise>
	 </xsl:choose>
      </xsl:variable>

      <f:result select="concat($h,':',$minute,$ind)"/>
   </f:function>
   
   <f:function name="my:next-month">
      <xsl:param name="month"/>
      <xsl:param name="year"/>
      <xsl:variable name="y">
	 <xsl:choose>
	    <xsl:when test="$month &lt; 12">
	       <xsl:value-of select="$year"/>
	    </xsl:when>
	    <xsl:otherwise>
	       <xsl:value-of select="$year+1"/>
	    </xsl:otherwise>
	 </xsl:choose>
      </xsl:variable>
      <xsl:variable name="m">
	 <xsl:choose>
	    <xsl:when test="$month &lt; 12">
	       <xsl:value-of select="$month + 1"/>
	    </xsl:when>
	    <xsl:otherwise>
	       <xsl:value-of select="1"/>
	    </xsl:otherwise>
	 </xsl:choose>
      </xsl:variable>
      <f:result select="concat('#A',$y,$m)"/>
   </f:function>

   <f:function name="my:prev-month">
      <xsl:param name="month"/>
      <xsl:param name="year"/>
      <xsl:variable name="y">
	 <xsl:choose>
	    <xsl:when test="$month > 1">
	       <xsl:value-of select="$year"/>
	    </xsl:when>
	    <xsl:otherwise>
	       <xsl:value-of select="$year - 1"/>
	    </xsl:otherwise>
	 </xsl:choose>
      </xsl:variable>
      <xsl:variable name="m">
	 <xsl:choose>
	    <xsl:when test="$month > 1">
	       <xsl:value-of select="$month - 1"/>
	    </xsl:when>
	    <xsl:otherwise>
	       <xsl:value-of select="12"/>
	    </xsl:otherwise>
	 </xsl:choose>
      </xsl:variable>
      <f:result select="concat('#A',$y,$m)"/>
   </f:function>

   <f:function name="my:next-year">
      <xsl:param name="year"/>
      <f:result select="concat('#A',$year + 1)"/>
   </f:function>

   <f:function name="my:prev-year">
      <xsl:param name="year"/>
      <f:result select="concat('#A',$year - 1)"/>
   </f:function>

   <f:function name="my:truncate">
      <xsl:param name="text"/>
      <xsl:param name="width" select="$max-text"/>
      <f:result>
	 <xsl:choose>
	    <xsl:when test="string-length($text) &lt;= $width">
	       <xsl:value-of select="$text"/>
	    </xsl:when>
	    <xsl:otherwise>
	       <xsl:value-of select="concat(substring($text,1,$width),'...')"/>
	    </xsl:otherwise>
	 </xsl:choose>
      </f:result>
   </f:function>

   <f:function name="my:ymd2date">
      <xsl:param name="year"/>
      <xsl:param name="month"/>
      <xsl:param name="day" select="'01'"/>
      <xsl:variable name="m">
	 <xsl:if test="string-length($month) &lt; 2">0</xsl:if>
	 <xsl:value-of select="$month"/>
      </xsl:variable>
      <xsl:variable name="d">
	 <xsl:if test="string-length($day) &lt; 2">0</xsl:if>
	 <xsl:value-of select="$day"/>
      </xsl:variable>
	 
      <f:result select="concat($year,'-',$m,'-',$d)"/>
   </f:function>

   <f:function name="my:format-date">
      <xsl:param name="date"/>
      <xsl:param name="full" select="false()"/>
      <f:result>
	 <xsl:if test="$full">
	    <xsl:value-of select="date:day-name($date)"/>
	    <xsl:text>, </xsl:text>
	 </xsl:if>
	 <xsl:value-of select="date:month-name($date)"/>
	 <xsl:text> </xsl:text>
	 <xsl:value-of select="date:day-in-month($date)"/>
	 <xsl:text>, </xsl:text>
	 <xsl:value-of select="date:year($date)"/>
      </f:result>
   </f:function>

   <f:function name="my:conflict">
      <xsl:choose>
	 <xsl:when test="@conflict">
	    <f:result select="@conflict"/>
	 </xsl:when>
	 <xsl:otherwise>
	    <f:result select="0"/>
	 </xsl:otherwise>
      </xsl:choose>
   </f:function>

   <f:function name="my:monday-week">
      <xsl:param name="date" select="date:date()"/>
      <xsl:variable name="wk" select="date:week-in-year($date)"/>
      <xsl:variable name="dy" select="date:day-in-week($date)"/>
	 <xsl:choose>
	    <xsl:when test="$dy=1">
	       <f:result select="$wk - 1"/>
	    </xsl:when>
	    <xsl:otherwise>
	       <f:result select="$wk"/>
	    </xsl:otherwise>
	 </xsl:choose>
   </f:function>
   
   <f:function name="my:href">
      <xsl:param name="type"/>
      <xsl:param name="date"/>
      <xsl:param name="text"/>
      <xsl:param name="nolink" select="false()"/>

      <f:result>
      <xsl:choose>
	 <xsl:when test="$no-links or $nolink">
	    <xsl:value-of select="$text"/>
	 </xsl:when>
	 <xsl:otherwise>
	    <!-- use ;, same as CGI.pm -->
	    <xsl:variable name="semi">
	       <xsl:if test="$need-semi">;</xsl:if>
	    </xsl:variable>
	    <a href="{$base-url}{$semi}type={$type};date={$date}" class="{$type}">
	       <xsl:value-of select="$text"/>
	    </a>
	 </xsl:otherwise>
      </xsl:choose>
      </f:result>
   </f:function>

</xsl:stylesheet>
