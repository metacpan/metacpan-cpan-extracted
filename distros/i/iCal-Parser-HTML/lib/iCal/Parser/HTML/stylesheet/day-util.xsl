<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:date="http://exslt.org/dates-and-times"
		xmlns:f="http://exslt.org/functions"
		xmlns:my="uri:local"
		extension-element-prefixes="date f"
		version="1.0">

   <xsl:import href="cal-util.xsl"/>
   <xsl:param name="debug" select="0"/>

   <xsl:variable name="add-span" select="1"/>
   <xsl:output method="xml"
	       doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
	       doctype-system=
	       "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
	       encoding="utf-8"
	       indent="yes"
	       omit-xml-declaration="yes"
	       />

   <xsl:template match="text()"/>

   <xsl:template name="hour">
      <xsl:param name="hour"/>
      <xsl:call-template name="half-hour">
	 <xsl:with-param name="h" select="$hour"/>
	 <xsl:with-param name="q" select="'00'"/>
      </xsl:call-template>
      <xsl:if test="$hour &lt; 23">
	 <xsl:call-template name="hour">
	    <xsl:with-param name="hour" select="$hour+1"/>
	 </xsl:call-template>
      </xsl:if>
   </xsl:template>

   <xsl:template name="hour-legend">
      <xsl:param name="h"/>
      <xsl:param name="q"/>
      <xsl:if test="$q = 0">
	 <xsl:variable name="night">
	    <xsl:if test="$h > 11"> night</xsl:if>
	 </xsl:variable>
	 <th class="hour-legend{$night}" rowspan="2">
	    <xsl:value-of select="my:ampm(concat($h,':',$q))"/>
	 </th>
      </xsl:if>
   </xsl:template>

   <xsl:template name="hour-events">
      <xsl:param name="h"/>
      <xsl:param name="q"/>
      <xsl:variable name="qstart" 
		    select="concat(@date,'T',$h,':',$q,':00')"/>
      <xsl:variable name="qsec" select="date:seconds($qstart)"/>
      <xsl:variable name="nodes" 
		    select="event[not(@all-day) 
			    and date:seconds(dtstart) &lt; $qsec+1800
			    and date:seconds(dtend) > $qsec]"/>
      <xsl:variable name="count" select="count($nodes)"/>
      <xsl:variable name="span" select="my:conflict()+$add-span"/>

      <xsl:if test="$debug > 0">
	 <xsl:message>
	    <xsl:value-of select="concat($qstart,' ',$span)"/>
	 </xsl:message>
      </xsl:if>

      <xsl:if test="$count = 0">
	 <td class="half-hour{$q}" colspan="{$span}">
	    <xsl:if test="$debug > 0">
	       <xsl:value-of  select="concat('A',$span)"/>
	    </xsl:if>
	    <xsl:text>&#xA0;</xsl:text>
	 </td>
      </xsl:if>
      <xsl:for-each select="$nodes">
	 <xsl:variable name="pos" select="position()"/>
	 <xsl:variable name="l" select="hours*2+.5"/>
	 <xsl:variable name="len">
	    <xsl:choose>
	       <xsl:when test="substring-before($l,'.')">
		  <xsl:value-of select="substring-before($l,'.')"/>
	       </xsl:when>
	       <xsl:otherwise><xsl:value-of select="$l"/></xsl:otherwise>
	    </xsl:choose>
	 </xsl:variable>
	 <xsl:variable name="start" select="date:seconds(dtstart)"/>
	 <xsl:variable name="end" select="date:seconds(dtend)"/>
	 <xsl:variable name="id" select="@uid"/>
	 <xsl:variable name="col">
	    <xsl:choose>
	       <xsl:when test="@conflict-number">
		  <xsl:value-of select="@conflict-number+1"/>
	       </xsl:when>
	       <xsl:otherwise>1</xsl:otherwise>
	    </xsl:choose>
	 </xsl:variable>
	 <xsl:variable name="left-fill"
		       select="count(../event[@uid != $id and not(@all-day) 
			       and date:seconds(dtstart) &lt;= $start
			       and date:seconds(dtend) > $start
			       and date:seconds(dtend) &lt;= $qsec])"/>
	 <xsl:variable name="right-overlap"
		       select="count(../event[not(@all-day) 
			       and date:seconds(dtstart) > $start 
			       and date:seconds(dtstart) &lt; $end])"/>
	 <xsl:if test="$debug > 1">
	    <xsl:message>
	       <xsl:value-of select="concat(' ',$pos,' ',$col,' ',$count,' ',
				     $left-fill,' ',$right-overlap,' ',summary)"/>
	    </xsl:message>
	 </xsl:if>
	 <xsl:if test="$left-fill > 0 and $pos = 1">
	    <td class="half-hour{$q} fill" colspan="{$left-fill}">
	       <xsl:if test="$debug > 0">
		  <xsl:value-of select="concat('L',$left-fill,' ',
					date:time($qstart))"/>
	       </xsl:if>
	       <xsl:text>&#xA0;</xsl:text>
	    </td>
	 </xsl:if>
	 <xsl:if test="$debug > 1">
	    <xsl:message>
	       <xsl:value-of select="concat(' ',$qstart,' ',dtstart,' ',dtend)"/>
	    </xsl:message>
	 </xsl:if>
	 <xsl:variable name="colspan">
	    <xsl:if test="$right-overlap=0 and $pos = last()
			  and $col &lt; $span">
	       <xsl:value-of select="$span - $col + 1"/>
	    </xsl:if>
	 </xsl:variable>
	 <xsl:if test="date:seconds(dtstart) >= $qsec and
		       date:seconds(dtstart) &lt; $qsec+1800">
	    <td class="half-hour{$q}{my:cal-index(@idref)}" rowspan="{$len}">
	       <xsl:if test="$colspan > 0">
		  <xsl:attribute name="colspan">
		     <xsl:value-of select="$colspan"/>
		  </xsl:attribute>
	       </xsl:if>
	       <div class="event-time{my:cal-index(@idref)}">
		  <xsl:value-of 
		    select="my:ampm(my:time(dtstart))"/> -
		  <xsl:value-of 
		    select="my:ampm(my:time(dtend))"/>
	       </div>
	       <p class="summary">
	       <xsl:value-of select="summary" disable-output-escaping="yes"/>
	       </p>
	       <xsl:call-template name="details"/>
	    </td>
	 </xsl:if>
	 <xsl:if test="$pos = $count and $right-overlap > 0 and $col != $span">
	    <td class="half-hour{$q} fill" colspan="{$span - $col}">
	       <xsl:if test="$debug > 0">
		  <xsl:value-of select="concat('R',$span - $col,' ',date:time($qstart))"/>
	       </xsl:if>
	       <xsl:text>&#xA0;</xsl:text>
	    </td>
	 </xsl:if>
      </xsl:for-each>
   </xsl:template>

   <xsl:template name="details">
      <xsl:if test="location">
	 <p class="location">(<xsl:value-of select="location"/>)</p>
      </xsl:if>

      <xsl:apply-templates select="attendees"/>

      <p class="description">
	 <xsl:value-of select="description" disable-output-escaping="yes"/>
      </p>
   </xsl:template>

   <xsl:template match="location">
   </xsl:template>

   <xsl:template match="attendees">
      <p class="attendees">
	 [<xsl:apply-templates select="../organizer"/><xsl:apply-templates/>]
      </p>      
   </xsl:template>

   <xsl:template match="organizer">
      <xsl:call-template name="cn">
	 <xsl:with-param name="type" select="'organizer'"/>
      </xsl:call-template>
   </xsl:template>

   <xsl:template match="attendee">
      <xsl:call-template name="cn">
	 <xsl:with-param name="type" select="'attendee'"/>
      </xsl:call-template>
   </xsl:template>

   <xsl:template name="cn">
      <xsl:param name="type"/>
      <xsl:variable name="mailto" select="value"/>
      <xsl:text> </xsl:text>
      <xsl:choose>
	 <xsl:when test="starts-with($mailto,'mailto')">
	    <a href="{$mailto}" class="{$type}">
	       <xsl:value-of select="cn"/>
	    </a>
	 </xsl:when>
	 <xsl:otherwise>
	    <span class="{$type}">
	       <xsl:value-of select="cn"/>
	    </span>
	 </xsl:otherwise>
      </xsl:choose>
      <xsl:text> </xsl:text>
   </xsl:template>

</xsl:stylesheet>
