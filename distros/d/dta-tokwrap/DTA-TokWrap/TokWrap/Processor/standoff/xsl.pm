## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Processor::standoff::xsl.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: t.xml -> (s.xml, w.xml, a.xml) via XSL

package DTA::TokWrap::Processor::standoff::xsl;

use DTA::TokWrap::Version;
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:progs :libxml :libxslt :slurp :time);
use DTA::TokWrap::Processor;

use XML::LibXML;
use XML::LibXSLT;
use IO::File;
use File::Basename qw(basename);

use Carp;
use strict;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::TokWrap::Processor);

##==============================================================================
## Constructors etc.
##==============================================================================

## $so = CLASS_OR_OBJ->new(%args)
## %defaults = CLASS->defaults()
##  + %args, %defaults, %$so:
##    (
##     ##
##     ##-- Stylesheet: tx2sx (t.xml -> s.xml)
##     t2s_stylestr  => $stylestr,           ##-- xsl stylesheet string
##     t2s_styleheet => $stylesheet,         ##-- compiled xsl stylesheet
##     ##
##     ##-- Styleheet: tx2wx (t.xml -> w.xml)
##     t2w_stylestr  => $stylestr,           ##-- xsl stylesheet string
##     t2w_styleheet => $stylesheet,         ##-- compiled xsl stylesheet
##     ##
##     ##-- Styleheet: tx2wx (t.xml -> a.xml)
##     t2a_stylestr  => $stylestr,           ##-- xsl stylesheet string
##     t2a_styleheet => $stylesheet,         ##-- compiled xsl stylesheet
##   )
sub defaults {
  my $that = shift;
  return (
	  ##-- inherited
	  $that->SUPER::defaults(),
	 );
}

## $so = $so->init()
sub init {
  my $so = shift;

  ##-- create stylesheet strings
  $so->{t2s_stylestr}   = $so->t2s_stylestr() if (!$so->{t2a_stylestr});
  $so->{t2w_stylestr}   = $so->t2w_stylestr() if (!$so->{t2w_stylestr});
  $so->{t2a_stylestr}   = $so->t2a_stylestr() if (!$so->{t2a_stylestr});

  ##-- compile stylesheets
  #$so->{t2s_stylesheet} = xsl_stylesheet(string=>$so->{t2s_stylestr}) if (!$so->{t2s_stylesheet});
  #$so->{t2w_stylesheet} = xsl_stylesheet(string=>$so->{t2w_stylestr}) if (!$so->{t2w_stylesheet});
  #$so->{t2a_stylesheet} = xsl_stylesheet(string=>$so->{t2a_stylestr}) if (!$so->{t2a_stylesheet});

  return $so;
}

##==============================================================================
## Methods: XSL stylesheets
##==============================================================================

##--------------------------------------------------------------
## Methods: XSL stylesheets: common

## $so_or_undef = $so->ensure_stylesheets()
sub ensure_stylesheets {
  my $so = shift;
  $so->{t2s_stylesheet} = xsl_stylesheet(string=>$so->{t2s_stylestr}) if (!$so->{t2s_stylesheet});
  $so->{t2w_stylesheet} = xsl_stylesheet(string=>$so->{t2w_stylestr}) if (!$so->{t2w_stylesheet});
  $so->{t2a_stylesheet} = xsl_stylesheet(string=>$so->{t2a_stylestr}) if (!$so->{t2a_stylesheet});
  return $so;
}

##--------------------------------------------------------------
## Methods: XSL stylesheets: t2s: t.xml -> s.xml
sub t2s_stylestr {
  my $so = shift;
  return '<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" version="1.0" indent="no" encoding="UTF-8"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- parameters -->
  <xsl:param name="xmlbase" select="/*/@xml:base"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- options -->
  <xsl:strip-space elements="sentences s w a"/>

  <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
  <!-- Mode: main -->

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: root: traverse -->
  <xsl:template match="/*">
    <xsl:element name="sentences">
      <xsl:attribute name="xml:base"><xsl:value-of select="$xmlbase"/></xsl:attribute>
      <xsl:apply-templates select="*"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: s -->
  <xsl:template match="s">
    <xsl:element name="s">
      <xsl:copy-of select="./@xml:id"/>
      <xsl:apply-templates select="*"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: w -->
  <xsl:template match="w">
    <xsl:element name="w">
      <xsl:attribute name="ref">#<xsl:value-of select="./@xml:id"/></xsl:attribute>
      <xsl:apply-templates select="*"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: just recurse -->
  <xsl:template match="*|@*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:apply-templates select="*|@*"/>
  </xsl:template>

</xsl:stylesheet>
';
}

##--------------------------------------------------------------
## Methods: XSL stylesheets: t2w: t.xml -> w.xml
sub t2w_stylestr {
  my $so = shift;
  return '<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" version="1.0" indent="no" encoding="UTF-8"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- parameters -->
  <xsl:param name="xmlbase" select="/*/@xml:base"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- options -->
  <xsl:strip-space elements="sentences s w a"/>

  <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
  <!-- Mode: main -->

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: root: traverse -->
  <xsl:template match="/*">
    <xsl:element name="tokens">
      <xsl:attribute name="xml:base"><xsl:value-of select="$xmlbase"/></xsl:attribute>
      <xsl:apply-templates select="*"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: w -->
  <xsl:template match="w">
    <xsl:element name="w">
      <xsl:copy-of select="@xml:id"/>
      <xsl:copy-of select="@t"/>
      <xsl:call-template name="w-expand-c"/>
      <xsl:apply-templates select="*"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: just recurse -->
  <xsl:template match="*|@*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- named: w-ref -->
  <xsl:template name="w-expand-c">
    <xsl:param name="cs" select="concat(@c,\' \')"/>
    <xsl:if test="$cs != \'\'">
      <xsl:element name="c">
	<xsl:attribute name="ref">#<xsl:value-of select="substring-before($cs,\' \')"/></xsl:attribute>
      </xsl:element>
      <xsl:call-template name="w-expand-c">
	<xsl:with-param name="cs" select="substring-after($cs,\' \')"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
';
}

##--------------------------------------------------------------
## Methods: XSL stylesheets: t2w: t.xml -> a.xml
sub t2a_stylestr {
  my $so = shift;
  return '<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" version="1.0" indent="no" encoding="UTF-8"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- parameters -->
  <xsl:param name="xmlbase" select="/*/@xml:base"/>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- options -->
  <xsl:strip-space elements="sentences s w a"/>

  <!--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++-->
  <!-- Mode: main -->

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: root: traverse -->
  <xsl:template match="/*">
    <xsl:element name="tokens">
      <xsl:attribute name="xml:base"><xsl:value-of select="$xmlbase"/></xsl:attribute>
      <xsl:apply-templates select="*"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: w -->
  <xsl:template match="w">
    <xsl:element name="w">
      <xsl:attribute name="ref">#<xsl:value-of select="@xml:id"/></xsl:attribute>
      <!--<xsl:copy-of select="@t"/>-->  <!-- DEBUG: copy text -->
      <xsl:apply-templates select="*"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: w/a -->
  <xsl:template match="w/a">
    <xsl:element name="a">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="*|text()"/>
    </xsl:element>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: template: w/a/text() -->
  <xsl:template match="w/a/text()">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->
  <!-- main: default: just recurse -->
  <xsl:template match="*|@*|text()|processing-instruction()|comment()" priority="-1">
    <xsl:apply-templates select="*"/>
  </xsl:template>

</xsl:stylesheet>
';
}

##--------------------------------------------------------------
## Methods: XSL stylesheets: debug

## undef = $so->dump_string($str,$filename_or_fh)
sub dump_string {
  my ($so,$str,$file) = @_;
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  $fh->print($str);
  $fh->close() if (!ref($file));
}

## undef = $so->dump_t2s_stylesheet($filename_or_fh)
sub dump_t2s_stylesheet {
  $_[0]->dump_string($_[0]{t2s_stylestr}, $_[1]);
}

## undef = $so->dump_t2w_stylesheet($filename_or_fh)
sub dump_t2w_stylesheet {
  $_[0]->dump_string($_[0]{t2w_stylestr}, $_[1]);
}

## undef = $so->dump_t2a_stylesheet($filename_or_fh)
sub dump_t2a_stylesheet {
  $_[0]->dump_string($_[0]{t2a_stylestr}, $_[1]);
}

##==============================================================================
## Methods: document processing: apply stylesheets
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->process($doc)
##  + DTA::TokWrap::Processor API
BEGIN { *process = \&standoff; }

## $doc_or_undef = $CLASS_OR_OBJECT->standoff($doc)
##  + wrapper for sosxml(), sowxml(), soaxml()
sub standoff {
  my ($so,$doc) = @_;
  $doc->setLogContext();
  $so = $so->new if (!ref($so));
  return $so->sosxml($doc) && $so->sowxml($doc) && $so->soaxml($doc);
}

## $doc_or_undef = $CLASS_OR_OBJECT->sosxml($doc)
## + $doc is a DTA::TokWrap::Document object
## + (re-)creates s.xml standoff document $doc->{sosdoc} from $doc->{xtokdoc}
## + %$doc keys:
##    xtokdoc  => $xtokdoc,  ##-- (input) XML-ified tokenizer output data, as XML::LibXML::Document
##    xtokdata => $xtokdata, ##-- (input) fallback: string source for $xtokdoc
##    sosdoc   => $sosdoc,   ##-- (output) standoff sentence data, refers to 'sowdoc'
##    sosxml_stamp0 => $f,   ##-- (output) timestamp of operation begin
##    sosxml_stamp  => $f,   ##-- (output) timestamp of operation end
##    sosdoc_stamp => $f,    ##-- (output) timestamp of operation end
sub sosxml {
  my ($so,$doc) = @_;
  $doc->setLogContext();

  ##-- log, stamp
  $so->vlog($so->{traceLevel},"sosxml()");
  $doc->{sosxml_stamp0} = timestamp();

  ##-- sanity check(s)
  $so = $so->new() if (!ref($so));
  $so->logconfess("sosxml(): could not compile XSL stylesheet(s)")
    if (!$so->ensure_stylesheets());
  $so->logconfess("sosxml(): no xtokdoc key defined")
    if (!$doc->{xtokdoc});
  my $xtdoc = $doc->{xtokdoc};

  ##-- apply XSL stylesheet
  $doc->{sosdoc} = $so->{t2s_stylesheet}->transform($xtdoc,
						    xmlbase=>("'".basename($doc->{sowfile})."'"),
						   )
    or $so->logconfess("sosxml(): could not apply t2s_stylesheet: $!");

  $doc->{sosxml_stamp} = $doc->{sosdoc_stamp} = timestamp(); ##-- stamp

  return $doc;
}

## $doc_or_undef = $CLASS_OR_OBJECT->sowxml($doc)
## + $doc is a DTA::TokWrap::Document object
## + (re-)creates w.xml standoff document $doc->{sowdoc} from $doc->{xtokdoc}
## + %$doc keys:
##    xtokdoc  => $xtokdoc,  ##-- (input) XML-ified tokenizer output data, as XML::LibXML::Document
##    xtokdata => $xtokdata, ##-- (input) fallback: string source for $xtokdoc
##    sowdoc   => $sowdoc,   ##-- (output) standoff token data, refers to 'sowdoc'
##    sowxml_stamp0 => $f,   ##-- (output) timestamp of operation begin
##    sowxml_stamp  => $f,   ##-- (output) timestamp of operation end
##    sowdoc_stamp => $f,    ##-- (output) timestamp of operation end
sub sowxml {
  my ($so,$doc) = @_;
  $doc->setLogContext();

  ##-- log, stamp
  $so->vlog($so->{traceLevel},"sowxml()");
  $doc->{sowxml_stamp0} = timestamp();

  ##-- sanity check(s)
  $so = $so->new() if (!ref($so));
  $so->logconfess("sowxml(): could not compile XSL stylesheet(s)")
    if (!$so->ensure_stylesheets());
  $so->logconfess("sowxml(): no xtokdoc key defined")
    if (!$doc->{xtokdoc});
  my $xtdoc = $doc->{xtokdoc};

  ##-- apply XSL stylesheet
  $doc->{sowdoc} = $so->{t2w_stylesheet}->transform($xtdoc,
						   xmlbase=>("'".$doc->{xmlbase}."'"),
						  )
    or $so->logconfess("sowxml(): could not apply t2w_stylesheet: $!");


  $doc->{sowxml_stamp} = $doc->{sowdoc_stamp} = timestamp(); ##-- stamp

  return $doc;
}

## $doc_or_undef = $CLASS_OR_OBJECT->soaxml($doc)
## + $doc is a DTA::TokWrap::Document object
## + (re-)creates a.xml standoff document $doc->{soadoc} from $doc->{xtokdoc}
## + %$doc keys:
##    xtokdoc  => $xtokdoc,  ##-- (input) XML-ified tokenizer output data, as XML::LibXML::Document
##    xtokdata => $xtokdata, ##-- (input) fallback: string source for $xtokdoc
##    soadoc   => $soadoc,   ##-- (output) standoff token-analysis data, refers to 'sowdoc'
##    soaxml_stamp0 => $f,   ##-- (output) timestamp of operation begin
##    soaxml_stamp  => $f,   ##-- (output) timestamp of operation end
##    soadoc_stamp => $f,    ##-- (output) timestamp of operation end
sub soaxml {
  my ($so,$doc) = @_;
  $doc->setLogContext();

  ##-- log, stamp
  $so->vlog($so->{traceLevel},"soaxml()");
  $doc->{soaxml_stamp0} = timestamp();

  ##-- sanity check(s)
  $so = $so->new() if (!ref($so));
  $so->logconfess("soaxml(): could not compile XSL stylesheet(s)")
    if (!$so->ensure_stylesheets());
  $so->logconfess("soaxml(): no xtokdoc key defined")
    if (!$doc->{xtokdoc});
  my $xtdoc = $doc->{xtokdoc};

  ##-- apply XSL stylesheet
  $doc->{soadoc} = $so->{t2a_stylesheet}->transform($xtdoc,
						   xmlbase=>("'".basename($doc->{sowfile})."'"),
						  )
    or $so->logconfess("soaxml(): could not apply t2a_stylesheet: $!");

  $doc->{soaxml_stamp} = $doc->{soadoc_stamp} = timestamp(); ##-- stamp

  return $doc;
}

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Processor::standoff::xsl - DTA tokenizer wrappers: t.xml -> (s.xml, w.xml, a.xml) via XSL

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::standoff::xsl;
 
 $so = DTA::TokWrap::Processor::standoff::xsl->new(%opts);
 $doc_or_undef = $so->sosxml($doc);
 $doc_or_undef = $so->sowxml($doc);
 $doc_or_undef = $so->soaxml($doc);
 $doc_or_undef = $so->standoff($doc);
 
 ##-- debugging
 undef = $so->dump_t2s_stylesheet($filename_or_fh);
 undef = $so->dump_t2w_stylesheet($filename_or_fh);
 undef = $so->dump_t2a_stylesheet($filename_or_fh);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

This module is deprecated;
prefer L<DTA::TokWrap::Processor::standoff|DTA::TokWrap::Processor::standoff>.

DTA::TokWrap::Processor::standoff::xsl provides an object-oriented
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor> wrapper
for generation of various standoff XML formats
for L<DTA::TokWrap::Document|DTA::TokWrap::Document> objects via
(slow) XSL stylesheet transformations.

Most users should use the high-level
L<DTA::TokWrap|DTA::TokWrap> wrapper class
instead of using this module directly.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::standoff::xsl: Constants
=pod

=head2 Constants

=over 4

=item @ISA

DTA::TokWrap::Processor::standoff::xsl
inherits from
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::standoff::xsl: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $so = $CLASS_OR_OBJECT->new(%args);

Constructor.

%args, %$so:

 ##-- Stylesheet: tx2sx (t.xml -> s.xml)
 t2s_stylestr  => $stylestr,           ##-- xsl stylesheet string
 t2s_styleheet => $stylesheet,         ##-- compiled xsl stylesheet
 ##
 ##-- Styleheet: tx2wx (t.xml -> w.xml)
 t2w_stylestr  => $stylestr,           ##-- xsl stylesheet string
 t2w_styleheet => $stylesheet,         ##-- compiled xsl stylesheet
 ##
 ##-- Styleheet: tx2wx (t.xml -> a.xml)
 t2a_stylestr  => $stylestr,           ##-- xsl stylesheet string
 t2a_styleheet => $stylesheet,         ##-- compiled xsl stylesheet

=item defaults

 %defaults = CLASS->defaults();

Static class-dependent defaults.

=item init

 $so = $so->init();

Dynamic object-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::standoff::xsl: Methods: XSL stylesheets
=pod

=head2 Methods: XSL stylesheets

Low-level utility methods.

The stylesheets returned may or may not accurately
reflect the documents generated by the
L<sosxml()|/sosxml>, L<sowxml()|/sowxml>,
and L<soaxml()|/soaxml> methods.


=over 4

=item ensure_stylesheets

 $so_or_undef = $so->ensure_stylesheets();

Ensures that required XSL stylesheets have been compiled.

=item t2s_stylestr

 $xsl_str = $mbx0->t2s_stylestr();

Returns XSL stylesheet string for generation of
sentence-level standoff XML (.s.xml)
from "master" tokenized XML (.t.xml).

=item t2w_stylestr

 $xsl_str = $mbx0->t2w_stylestr();

Returns XSL stylesheet string for generation of
token-level standoff XML (.w.xml)
from "master" tokenized XML (.t.xml).

=item t2a_stylestr

 $xsl_str = $mbx0->t2a_stylestr();

Returns XSL stylesheet string for generation of
token-analysis-level standoff XML (.a.xml)
from "master" tokenized XML (.t.xml).

=item dump_t2s_stylesheet

 $so->dump_t2s_stylesheet($filename_or_fh);

Dumps the generated sentence-level standoff stylesheet to $filename_or_fh.

=item dump_t2w_stylesheet

 $so->dump_t2w_stylesheet($filename_or_fh);

Dumps the generated token-level standoff stylesheet to $filename_or_fh.

=item dump_t2a_stylesheet

 $so->dump_t2a_stylesheet($filename_or_fh);

Dumps the generated token-analysis-level standoff stylesheet to $filename_or_fh.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::standoff::xsl: Methods: mkbx0 (apply stylesheets)
=pod

=head2 Methods: top-level

=over 4

=item standoff

 $doc_or_undef = $CLASS_OR_OBJECT->standoff($doc);

Wrapper for L<sosxml()|/sosxml()>, L<sowxml()|/sowxml>, L<soaxml()|/soaxml>.

=item sosxml

 $doc_or_undef = $CLASS_OR_OBJECT->sosxml($doc);

Generate sentence-level standoff for the
L<DTA::TokWrap::Document|DTA::TokWrap::Document> object $doc.

Relevant %$doc keys:

 xtokdoc  => $xtokdoc,  ##-- (input) XML-ified tokenizer output data, as XML::LibXML::Document
 xtokdata => $xtokdata, ##-- (input) fallback: string source for $xtokdoc
 sosdoc   => $sosdoc,   ##-- (output) standoff sentence data, refers to $doc->{sowfile}
 ##
 sosxml_stamp0 => $f,   ##-- (output) timestamp of operation begin
 sosxml_stamp  => $f,   ##-- (output) timestamp of operation end
 sosdoc_stamp => $f,    ##-- (output) timestamp of operation end

=item sowxml

 $doc_or_undef = $CLASS_OR_OBJECT->sowxml($doc);

Generate token-level standoff for the
L<DTA::TokWrap::Document|DTA::TokWrap::Document> object $doc.

Relevant %$doc keys:

 xtokdoc  => $xtokdoc,  ##-- (input) XML-ified tokenizer output data, as XML::LibXML::Document
 xtokdata => $xtokdata, ##-- (input) fallback: string source for $xtokdoc
 sowdoc   => $sowdoc,   ##-- (output) standoff token data, refers to $doc->{xmlfile}
 ##
 sowxml_stamp0 => $f,   ##-- (output) timestamp of operation begin
 sowxml_stamp  => $f,   ##-- (output) timestamp of operation end
 sowdoc_stamp => $f,    ##-- (output) timestamp of operation end

=item soaxml

 $doc_or_undef = $CLASS_OR_OBJECT->soaxml($doc);

Generate token-analysis-level standoff for the
L<DTA::TokWrap::Document|DTA::TokWrap::Document> object $doc.

Relevant %$doc keys:

 xtokdoc  => $xtokdoc,  ##-- (input) XML-ified tokenizer output data, as XML::LibXML::Document
 xtokdata => $xtokdata, ##-- (input) fallback: string source for $xtokdoc
 soadoc   => $soadoc,   ##-- (output) standoff token-analysis data, refers to $doc->{sowdoc}
 ##
 sowxml_stamp0 => $f,   ##-- (output) timestamp of operation begin
 sowxml_stamp  => $f,   ##-- (output) timestamp of operation end
 sowdoc_stamp => $f,    ##-- (output) timestamp of operation end

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## See Also
##======================================================================

=pod

=head1 SEE ALSO

L<DTA::TokWrap::Intro(3pm)|DTA::TokWrap::Intro>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
...

=cut

##======================================================================
## See Also
##======================================================================

=pod

=head1 SEE ALSO

L<DTA::TokWrap::Intro(3pm)|DTA::TokWrap::Intro>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
...

=cut

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


