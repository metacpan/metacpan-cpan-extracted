<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:date="http://exslt.org/dates-and-times"
		xmlns:dyn="http://exslt.org/dynamic"
		xmlns:my="uri:local"
		extension-element-prefixes="date my dyn"
		version="1.0">

   <xsl:import href="day-util.xsl"/>
   <xsl:param name="week"/>
   
   <xsl:template name="caltype">Weekly</xsl:template>

   <xsl:template match="ical">
      <xsl:apply-templates select="//week[@week=$week]"/>
   </xsl:template>

   <xsl:template match="week">
      <xsl:variable name="start-date" select="day[1]/@date"/>
      <xsl:call-template name="sidebar">
	 <xsl:with-param name="start-date" 
			 select="concat(substring(day[1]/@date,1,8),'01')"/>
      </xsl:call-template>
      <div class="calendar">
      <h1><xsl:value-of select="my:format-date($start-date)"/> - <xsl:value-of 
	 select="my:format-date(day[7]/@date)"/></h1>
      <xsl:call-template name="wmy-nav">
	 <xsl:with-param name="type" select="'week'"/>
	 <xsl:with-param name="date" select="$start-date"/>
      </xsl:call-template>

	 <table class="week" summary="weekly calendar">
	    <colgroup>
	       <col class="hour-legend"/>
	       <xsl:for-each select="day">
		  <col class="day" span="{my:conflict()+$add-span}"/>
	       </xsl:for-each>
	    </colgroup>
	    <tr>
	       <th class="day-legend">&#xA0;</th>
	       <xsl:for-each select="day">
		  <xsl:variable name="span" select="my:conflict()+1"/>
		  <xsl:variable name="text">
		     <xsl:value-of select="substring(date:day-name(@date),1,3)"/>
		     <xsl:text> </xsl:text>
		     <xsl:value-of select="date:day-in-month(@date)"/>
		  </xsl:variable>
		  <th colspan="{$span}" class="day-legend">
		     <xsl:copy-of select="my:href('day',@date,$text)"/>
		  </th>
	       </xsl:for-each>
	    </tr>
	    <xsl:call-template name="all-day"/>
	    <xsl:call-template  name="hour">
	       <xsl:with-param name="hour" select ="0"/>
	    </xsl:call-template>
	 </table>
      </div>
   </xsl:template>
   
   <xsl:template name="all-day">
      <xsl:for-each select="day/event[@all-day]">
	 <xsl:variable name="id" select="@uid"/>
	 <xsl:if test="not(preceding::event[@uid = $id and ../../@week=$week])">
	    <tr class="all-day">
	       <th><xsl:if test="position()=1">All Day</xsl:if></th>
	       <xsl:variable name="start" select="date:seconds(date:date(dtstart))"/>
	       <xsl:for-each select="../../day[date:seconds(@date) &lt; $start]">
		  <td class="all-day" colspan="{my:conflict()+1}">&#xA0;</td>
	       </xsl:for-each>
	       <xsl:variable name="s">
		  <xsl:for-each select="../../day[date:seconds(@date) >= $start]">
		     <xsl:if test="event[@uid=$id]">
			<xsl:value-of select="concat('+',my:conflict()+1)"/>
		     </xsl:if>
		  </xsl:for-each>
	       </xsl:variable>
	       <xsl:variable name="len" select="dyn:evaluate(substring($s,2))"/>
	       <td class="all-day{my:cal-index(@idref)}" colspan="{$len}">
		  <xsl:value-of select="summary" disable-output-escaping="yes"/>
	       </td>
	       <xsl:for-each select="../../day[date:seconds(@date) >= $start]">
		  <xsl:if test="not(event[@uid=$id])">
		     <td class="all-day" colspan="{my:conflict()+1}">&#xA0;</td>
		  </xsl:if>
	       </xsl:for-each>
	    </tr>
	 </xsl:if>
      </xsl:for-each>
      <xsl:variable name="s">
	 <xsl:for-each select="day">
	    <xsl:value-of select="concat('+',my:conflict()+1)"/>
	 </xsl:for-each>
      </xsl:variable>
      <tr class="all-day-sep">
	 <td colspan="{dyn:evaluate(substring($s,2))+1}"></td>
      </tr>
   </xsl:template>

   <xsl:template name="half-hour">
      <xsl:param name="h"/>
      <xsl:param name="q"/>
      <xsl:variable name="hh">
	 <xsl:if test="string-length($h) &lt; 2">0</xsl:if>
	 <xsl:value-of select="$h"/>
      </xsl:variable>
      <tr>
	 <xsl:call-template name="hour-legend">
	    <xsl:with-param name="h" select="$hh"/>
	    <xsl:with-param name="q" select="$q"/>
	 </xsl:call-template>

	 <xsl:for-each select="day">
	    <xsl:call-template name="hour-events">
	       <xsl:with-param name="h" select="$hh"/>
	       <xsl:with-param name="q" select="$q"/>
	    </xsl:call-template>
	 </xsl:for-each>
      </tr>
      <xsl:if test="$q &lt; 30">
	 <xsl:call-template name="half-hour">
	    <xsl:with-param name="h" select="$h"/>
	    <xsl:with-param name="q" select="$q+30"/>
	 </xsl:call-template>
      </xsl:if>
   </xsl:template>

   <xsl:template name="details"/>

</xsl:stylesheet>
