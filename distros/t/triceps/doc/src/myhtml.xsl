<?xml version='1.0'?>
<xsl:stylesheet  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    version="1.0">

<xsl:import href="http://docbook.sourceforge.net/release/xsl/1.75.2/html/docbook.xsl"/>

<xsl:param name="use.extensions">0</xsl:param>
<xsl:param name="body.font.master">10</xsl:param>

<xsl:param name="page.width">8.5in</xsl:param>
<xsl:param name="page.height">11in</xsl:param>

<xsl:param name="page.margin.inner">1in</xsl:param>
<xsl:param name="page.margin.outer">0.75in</xsl:param>
<xsl:param name="page.margin.top">0.75in</xsl:param>
<xsl:param name="body.margin.top">0in</xsl:param>
<xsl:param name="header.rule">0</xsl:param>
<xsl:param name="double.sided">1</xsl:param>
<!-- double.sided crashes FOP without this -->
<xsl:param name="fop1.extensions">1</xsl:param>
<xsl:param name="body.start.indent">0pt</xsl:param>
<xsl:param name="section.autolabel">1</xsl:param>
<xsl:param name="section.label.includes.component.label">1</xsl:param>
<xsl:param name="insert.xref.page.number">maybe</xsl:param>
<xsl:param name="insert.link.page.number">maybe</xsl:param>
<xsl:param name="ulink.hyphenate.chars">/&amp;?%=</xsl:param>
<xsl:param name="ulink.hyphenate">&#x200B;</xsl:param>
<xsl:param name="toc.section.depth">2</xsl:param>
<xsl:param name="formal.title.placement">
	figure after
	example before
	equation after
	table before
	procedure before
</xsl:param>
<xsl:param name="footer.column.widths">20 1 1</xsl:param>
<!-- <xsl:param name="bibliography.numbered">1</xsl:param> -->
<xsl:param name="bibliography.style">iso690</xsl:param>
<xsl:param name="variablelist.as.blocks">1</xsl:param>

<!-- Auto-wrapping in listings -->
<xsl:attribute-set name="monospace.verbatim.properties">
	<xsl:attribute name="wrap-option">wrap</xsl:attribute>
	<!-- hyphenation is not supported by FOP -->
	<!-- <xsl:attribute name="hyphenation-character">\</xsl:attribute> -->
</xsl:attribute-set>
<xsl:attribute-set name="monospace.verbatim.properties">
	<xsl:attribute name="font-size">9pt</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="footnote.mark.properties">
	<xsl:attribute name="font-size">6pt</xsl:attribute>
</xsl:attribute-set>
<!-- this was for the diagnostics of too long lines in examples
<xsl:param name="shade.verbatim">1</xsl:param>
-->

<!-- center the figures -->
<!--
<xsl:attribute-set name="figure.properties">
	<xsl:attribute name="text-align">center</xsl:attribute>
</xsl:attribute-set>
-->


<xsl:param name="local.l10n.xml" select="document('')"/>

<!-- custom format for page references -->
<!--
<l:i18n xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0">
  <l:l10n language="en">
    <l:context name="xref">
      <l:template name="page.citation" text=" (p. %p)"/>
    </l:context>
  </l:l10n>
</l:i18n>
-->

<!-- make the pageabbrev empty, since there are no pages in HTML -->
<l:i18n xmlns:l="http://docbook.sourceforge.net/xmlns/l10n/1.0"> 
  <l:l10n language="en"> 
    <l:context name="xref"> 
      <l:template name="pageabbrev" text=""/>
    </l:context>    
  </l:l10n>
</l:i18n>

<!-- custom running headers and footers -->
<xsl:template name="header.content">  
	<xsl:param name="pageclass" select="''"/>
	<xsl:param name="sequence" select="''"/>
	<xsl:param name="position" select="''"/>
	<xsl:param name="gentext-key" select="''"/>
</xsl:template>  

<xsl:template name="footer.content">  
	<xsl:param name="pageclass" select="''"/>
	<xsl:param name="sequence" select="''"/>
	<xsl:param name="position" select="''"/>
	<xsl:param name="gentext-key" select="''"/>

	<fo:block>
		<xsl:if test="$pageclass != 'titlepage'">
			<!-- sequence can be odd, even, first, blank -->
			<!-- position can be left, center, right -->
			<xsl:choose>

				<xsl:when test="$sequence = 'odd' and $position = 'left'">
					<fo:retrieve-marker retrieve-class-name="section.head.marker"
						retrieve-position="first-including-carryover"
						retrieve-boundary="page-sequence"/>
				</xsl:when>

				<xsl:when test="$sequence = 'odd' and $position = 'center'">
					<xsl:call-template name="draft.text"/>
				</xsl:when>

				<xsl:when test="$sequence = 'odd' and $position = 'right'">
					<fo:page-number/> 
				</xsl:when>

				<xsl:when test="$sequence = 'even' and $position = 'left'">  
					<fo:page-number/>
				</xsl:when>

				<xsl:when test="$sequence = 'even' and $position = 'center'">
					<xsl:call-template name="draft.text"/>
				</xsl:when>

				<xsl:when test="$sequence = 'even' and $position = 'right'">
					<xsl:apply-templates select="." mode="titleabbrev.markup"/> 
				</xsl:when>

				<xsl:when test="$sequence = 'first' and $position = 'left'">
				</xsl:when>

				<xsl:when test="$sequence = 'first' and $position = 'right'">  
					<fo:page-number/>
				</xsl:when>

				<xsl:when test="$sequence = 'first' and $position = 'center'"> 
					<!--
					<xsl:value-of 
					select="ancestor-or-self::book/bookinfo/corpauthor"/> 
					-->
				</xsl:when>

				<xsl:when test="$sequence = 'blank' and $position = 'left'">
					<fo:page-number/>
				</xsl:when>

				<xsl:when test="$sequence = 'blank' and $position = 'center'">
					<!--
					<xsl:text>This page intentionally left blank</xsl:text>
					-->
				</xsl:when>

				<xsl:when test="$sequence = 'blank' and $position = 'right'">
				</xsl:when>

			</xsl:choose>
		</xsl:if>
	</fo:block>
</xsl:template>

<xsl:attribute-set name="footer.content.properties">
	<xsl:attribute name="font-family">Helvetica</xsl:attribute>
	<xsl:attribute name="font-size">9pt</xsl:attribute>
	<xsl:attribute name="font-weight">bold</xsl:attribute>
</xsl:attribute-set>

<!-- borders around figures and examples -->
<xsl:attribute-set name="figure.properties">
	<xsl:attribute name="border">0.2pt solid</xsl:attribute>
	<xsl:attribute name="padding">0.1in</xsl:attribute>
</xsl:attribute-set>
<xsl:attribute-set name="example.properties">
	<xsl:attribute name="border">0.2pt solid</xsl:attribute>
	<xsl:attribute name="padding">0.1in</xsl:attribute>
</xsl:attribute-set>

<!-- set the titles of the figures and examples -->
<xsl:attribute-set name="formal.title.properties" 
		use-attribute-sets="normal.para.spacing">
	<xsl:attribute name="font-size">10pt</xsl:attribute>
	<xsl:attribute name="hyphenate">false</xsl:attribute>
	<!--
	<xsl:attribute name="font-weight">bold</xsl:attribute>
	<xsl:attribute name="space-after.minimum">0.4em</xsl:attribute>
	<xsl:attribute name="space-after.optimum">0.6em</xsl:attribute>
	<xsl:attribute name="space-after.maximum">0.8em</xsl:attribute>
	-->
</xsl:attribute-set>

<!-- sorting for bibliography, but it doesn't work with numbering -->
<xsl:template match="bibliodiv">
	<xsl:variable name="lang">
		<xsl:call-template name="l10n.language"/>
	</xsl:variable>
	<fo:block>
		<xsl:attribute name="id">
			<xsl:call-template name="object.id"/>
		</xsl:attribute>
		<!-- <xsl:call-template name="bibliodiv.titlepage"/> -->
		<xsl:apply-templates 
		select="*[not(self::biblioentry) and not(self::bibliomixed)]"/>
		<xsl:apply-templates select="biblioentry|bibliomixed">
			<xsl:sort select="*//author[1]//surname"
				lang="$lang"
				data-type="text" order="ascending"/>
		</xsl:apply-templates>
	</fo:block>
</xsl:template>

<!-- should format the preferred index entries but has no effect -->
<!--
<xsl:attribute-set name="index.preferred.page.properties">
	<xsl:attribute name="font-weight">bold</xsl:attribute>
    <xsl:attribute name="font-style">italic</xsl:attribute>
</xsl:attribute-set>
-->

<!-- prevent hyphenation in titles -->
<xsl:attribute-set name="section.title.properties">
  <xsl:attribute name="hyphenate">false</xsl:attribute>
</xsl:attribute-set>


</xsl:stylesheet>
