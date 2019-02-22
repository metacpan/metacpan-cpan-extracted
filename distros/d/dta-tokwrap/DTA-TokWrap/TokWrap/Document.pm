## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Document.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: document wrapper

package DTA::TokWrap::Document;
use DTA::TokWrap::Base;
use DTA::TokWrap::Version;
use DTA::TokWrap::Utils qw(:libxml :files :progs :slurp :time :si);
use DTA::TokWrap::Processor::mkindex;
use DTA::TokWrap::Processor::mkbx0;
use DTA::TokWrap::Processor::mkbx;
use DTA::TokWrap::Processor::tokenize;
use DTA::TokWrap::Processor::tokenize::auto;
use DTA::TokWrap::Processor::tokenize::http;
use DTA::TokWrap::Processor::tokenize::waste;
#use DTA::TokWrap::Processor::tokenize::tomasotath_05x;
use DTA::TokWrap::Processor::tokenize::tomasotath_04x;
use DTA::TokWrap::Processor::tokenize::tomasotath_02x;
use DTA::TokWrap::Processor::tokenize::dwds_scanner;
use DTA::TokWrap::Processor::tokenize::dummy;
use DTA::TokWrap::Processor::tokenize1;
use DTA::TokWrap::Processor::tok2xml;
use DTA::TokWrap::Processor::txmlanno;
#use DTA::TokWrap::Processor::standoff;
#use DTA::TokWrap::Processor::standoff::xsl;
use DTA::TokWrap::Processor::addws;
use DTA::TokWrap::Processor::idsplice;
use DTA::TokWrap::Processor::tcfencode;
use DTA::TokWrap::Processor::tcftokenize;
use DTA::TokWrap::Processor::tcfdecode0;
use DTA::TokWrap::Processor::tcfalign;
use DTA::TokWrap::Processor::tcfdecode;

use File::Basename qw(basename dirname);
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================
our @ISA = ('DTA::TokWrap::Base','Exporter');

## $TOKENIZE_CLASS
##  + default tokenizer subclass
our $TOKENIZE_CLASS = $DTA::TokWrap::Processor::tokenize::DEFAULT_SUBCLASS;

## $CX_ID    : {cxdata} index of id field
## $CX_XOFF  : {cxdata} index of XML byte-offset field#
## $CX_XLEN  : {cxdata} index of XML byte-length field
## $CX_TOFF  : {cxdata} index of .tx byte-offset field
## $CX_TLEN  : {cxdata} index of .tx byte-length field
## $CX_TEXT  : {cxdata} index of text / details field(s)
## $CX_ATTRS : {cxdata} index of attribute field(s)
our ($CX_ID,$CX_XOFF,$CX_XLEN,$CX_TOFF,$CX_TLEN,$CX_TEXT,$CX_ATTRS) = (0..6);

our @EXPORT = qw();
our %EXPORT_TAGS = (
		    cx => [qw($CX_ID $CX_XOFF $CX_XLEN $CX_TOFF $CX_TLEN $CX_TEXT)],
		    tok => ['$TOKENIZE_CLASS'],
		   );
$EXPORT_TAGS{all} = [map {@$_} values(%EXPORT_TAGS)];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};

##==============================================================================
## Constructors etc.
##==============================================================================

## $doc = CLASS_OR_OBJECT->new(%args)
## + %args, %$doc
##   (
##    ##-- Document class
##    class => $class,      ##-- delegate call to $class->new(%args)
##
##    ##-- Source data
##    xmlfile => $xmlfile,  ##-- source filename
##    xmlbase => $xmlbase,  ##-- xml:base for generated files (default=basename($xmlfile))
##    xmldata => $xmldata,  ##-- source buffer (for addws, tcfencode)
##
##    ##-- pseudo-make options
##    traceMake => $level,  ##-- log-level for makeKey() trace (e.g. 'debug'; default=undef (none))
##    traceGen  => $level,  ##-- log-level for genKey() trace (e.g. 'trace'; default=undef (none))
##    traceProc => $level,  ##-- log-level for document-called processor calls (default=none)
##    traceLoad => $level,  ##-- log-level for load* trace (default=none)
##    traceSave => $level,  ##-- log-level for save* trace (default=none)
##    genDummy  => $bool,   ##-- if true, generator will not actually run (a la `make -n`)
##
##    ##-- generator data (optional)
##    tw => $tw,              ##-- a DTA::TokWrap object storing individual generators
##    traceOpen  => $level,   ##-- log-lvel for open() trace (e.g. 'info'; default=undef (none))
##    traceClose => $level,   ##-- log-level for close() trace (e.g. 'trace'; default=undef (none))
##
##    ##-- generated data (common)
##    outdir => $outdir,    ##-- output directory for generated data (default=.)
##    tmpdir => $tmpdir,    ##-- temporary directory for generated data (default=$ENV{DTATW_TMP}||$outdir)
##    keeptmp => $bool,     ##-- if true, temporary document-local files will be kept on $doc->close()
##    notmpre => $regex,    ##-- non-temporary file regex
##    notmpkeys => $keys,   ##-- non-temporary keys, space-separated list
##    outbase => $filebase, ##-- output basename (default=`basename $xmlbase .xml`)
##    format => $level,     ##-- default formatting level for XML output
##
##    ##-- mkindex data (see DTA::TokWrap::Processor::mkindex)
##    cxfile => $cxfile,    ##-- character index file (default="$tmpdir/$outbase.cx")
##    cxdata => $cxdata,    ##-- character index data (see loadCxFile() method)
##    sxfile => $sxfile,    ##-- structure index file (default="$tmpdir/$outbase.sx")
##    txfile => $txfile,    ##-- raw text index file (default="$tmpdir/$outbase.tx")
##
##    ##-- mkbx0 data (see DTA::TokWrap::Processor::mkbx0)
##    bx0doc  => $bx0doc,   ##-- pre-serialized block-index XML::LibXML::Document
##    bx0file => $bx0file,  ##-- pre-serialized block-index XML file (default="$outbase.bx0"; optional)
##
##    ##-- mkbx data (see DTA::TokWrap::Processor::mkbx)
##    bxdata  => \@bxdata,  ##-- block-list, see DTA::TokWrap::mkbx::mkbx() for details
##    bxfile  => $bxfile,   ##-- serialized block-index CSV file (default="$tmpdir/$outbase.bx"; optional)
##    txtfile => $txtfile,  ##-- serialized & hinted text file (default="$tmpdir/$outbase.txt"; optional)
##    txtdata => $txtdata,  ##-- serialized & hinted text file (used by tcfencode|tcfdecode|tcfalign, must be loaded explicitly with loadTxtData())
##
##    ##-- tokenize data (see DTA::TokWrap::Processor::tokenize, DTA::TokWrap::Processor::tokenize::dummy)
##    tokdata0 => $tokdata0,  ##-- tokenizer output data (slurped string)
##    tokfile0 => $tokfile0,  ##-- tokenizer output file (default="$tmpdir/$outbase.t0"; optional)
##
##    ##-- post-tokenize data (see DTA::TokWrap::Processor::posttok)
##    tokdata1 => $tokdata1,  ##-- post-tokenizer output data (slurped string)
##    tokfile1 => $tokfile1,  ##-- post-tokenizer output file (default="$tmpdir/$outbase.t1"; optional)
##
##    ##-- tokenizer xml data (see DTA::TokWrap::Processor::tok2xml)
##    xtokdata => $xtokdata,  ##-- XML-ified tokenizer output data
##    xtokfile => $xtokfile,  ##-- XML-ified tokenizer output file (default="$outdir/$outbase.t.xml")
##    #xtokdoc  => $xtokdoc,   ##-- XML::LibXML::Document for $xtokdata (parsed from string)
##
##    ##-- tokenizer xml annotations (see DTA::TokWrap::Processor::txmlanno)
##    axtokdata => $axtokdata,  ##-- optional external XML annotation data (for splicing into $xtokdata)
##    axtokfile => $axtokfile,  ##-- optional external XML annotation file (for splicing into $xtokfile; default="$outdir/$outbase.ta.xml")
##    xtokfile0 => $xtokfile0,  ##-- XML-ified tokenizer output file (default=none or "$outdir/$outbase.t0.xml" if {keeptmp} is true)
##
##    ##-- ws-splice (see DTA::TokWrap::Processor::addws)
##    #cwsdata => $cwsdata,    ##-- ws-spliced output data (xmlfile with <s> and <w> elements)
##    cwsfile => $cwsfile,    ##-- ws-spliced output file (default="$outdir/$outbase.cws.xml")
##
##    ##-- property-splice (see DTA::TokWrap::Processor::idsplice)
##    cwstbasebufr => \$bdata,  ##-- base data-ref for idsplice (xml with //*/@id) [default=\$cwsdata if defined]
##    cwstbasefile => $bfile,   ##-- source file for $bdata [default=$cwsfile]
##    cwstsobufr   => \$sodata, ##-- standoff data-ref for idsplice (xml with //*/@id, additional attributes and content) [default=\$xtokdata]
##    cwstsofile   => $sofile,  ##-- source file for $sodata [default=$xtokfile]
##    cwstbufr     => $wstbufr, ##-- idsplice output buffer (base + id-spliced attributes, content) -- available for override, not used by default
##    cwstfile     => $wstfile, ##-- idsplice output file [default="$outdir/$outbase.cwst.xml"]
##
##    ##-- standoff xml data (see DTA::TokWrap::Processor::standoff -- OBSOLETE)
##    #sosfile => $sosfile,   ##-- sentence standoff file (default="$outdir/$outbase.s.xml")
##    #sowfile => $sowfile,   ##-- token standoff file (default="$outdir/$outbase.w.xml")
##    #soafile => $soafile,   ##-- token-analysis standoff file (default="$outdir/$outbase.a.xml")
##
##    ##-- tcfencode data (see DTA::TokWrap::Processor::tcfencode)
##    tcfdoc   => $tcfdoc,     ##-- XML::LibXML::Document representing TCF-encoded data
##    tcffile  => $tcffile,    ##-- TCF file
##    tcflang  => $lang,       ##-- TCF language attribute (default: 'de')
##
##    ##-- tcftokenize data (see DTA::TokWrap::Processor::tcftokenize)
##    tcftokdoc => $tcftokdoc,    ##-- XML::LibXML::Document representing tokenized TCF data (== $tcfdoc)
##    tcftokfile => $tcftokfile,  ##-- tcf-tokenized file
##
##    ##-- tcfdecode0 data (see DTA::TokWrap::Processor::tcfdecode0)
##    tcfxfile => $tcfxfile,   ##-- tcf-decoded base xml file [default="$tmpdir/$outbase.tcfx"]
##    tcfxdata => $tcfxdata,   ##-- tcf-decoded base xml data
##    tcftfile => $tcftfile,   ##-- tcf-decoded serial text file [default="$tmpdir/$outbase.tcft"]
##    tcftdata => $tcftdata,   ##-- tcf-decoded serial txt data
##    tcfwdata => $tcfwdata,   ##-- tcf-decoded token data, tt-format: "TEXT\tSID/WID\n"
##    tcfwfile => $tcfwfile,   ##-- tcf-decoded token file, tt-format [default="$tmpdir/$outbase.tcfw"]
##    tcfadata => $tcfadata,   ##-- tcf-decoded token attributes for idsplice, data
##    tcfafile => $tcfafile,   ##-- tcf-decoded token attributes for idsplice, file [default="$tmpdir/$outbase.tcfa"]
##
##    ##-- tcfalign data (PROXIED, see DTA::TokWrap::Processor::tcfalign : uses tokdata1,tokfile1)
##    ##-- tcf2txml data (PROXIED, see DTA::TokWrap::Processor::tok2xml : uses tokfile1,cxfile,bxfile,xtokdata)
##    ##-- tcfdecode data
##    tcfcwsfile => $tcfcwsfile, ##-- tcf-decoded+aligned+ws-spliced output file (default="$outdir/$outbase.tcfws.xml")
##   )
sub new {
  my ($that,%opts) = @_;
  if (defined($opts{class})) {
    my $class = $opts{class};
    delete($opts{class});
    return $class->new(%opts);
  }
  return $that->SUPER::new(%opts);
}

## %defaults = CLASS->defaults()
sub defaults {
  return (
	  ##-- inherited defaults (none)
	  #$_[0]->SUPER::defaults(),

	  ##-- source data
	  xmlfile => undef,
	  xmlbase => undef,

	  ##-- pseudo-make options
	  #genDummy => 0,

	  ##-- trace options
	  #traceOpen => 'trace',
	  #traceClose => 'trace',
	  #traceLoad=>'trace',
	  #traceSave=>'trace',
	  #traceProc => 'trace',
	  #traceMake => 'trace',
	  #traceGen => 'trace',

	  ##-- generator data (optional)
	  #tw => undef,

	  ##-- generated data (common)
	  outdir => '.',
	  tmpdir => $ENV{DTATW_TMP},
	  keeptmp => 0,
	  outbase => undef,
	  format  => 0,

	  ##-- mkindex data
	  cxfile => undef,
	  cxdata => undef,
	  sxfile => undef,
	  txfile => undef,

	  ##-- mkbx0 data
	  bx0doc  => undef,
	  bx0file => undef,

	  ##-- mkbx data
	  bxdata => undef,
	  bxfile => undef,
	  txtfile => undef,

	  ##-- tokenizer data
	  tokdata0 => undef,
	  tokfile0 => undef,

	  ##-- post-tokenizer data
	  tokdata1 => undef,
	  tokfile1 => undef,

	  ##-- tokenizer xml-ified data
	  xtokdata => undef,
	  xtokfile => undef,

	  ##-- tokenizer xml annotations
	  axtokdata => undef,
	  axtokfile => undef,
	  xtokfile0 => undef,

	  ##-- ws-splice data
	  #cwsdata => undef,
	  cwsfile => undef,

	  ##-- wst-splice data
	  cwstfile => undef,

	  ##-- standoff data
	  #sosdoc => undef,
	  #sowdoc => undef,
	  #soadoc => undef,
	  ##
	  #sosfile => undef,
	  #sowfile => undef,
	  #soafile => undef,

	  ##-- tcf encoding
	  tcffile => undef,
	  tcflang => 'de',

	  ##-- tcf tokenization
	  tcftokfile => undef,

	  ##-- tcf decoding
	  tcfxfile => undef,
	  tcftfile => undef,
	  tcfwfile => undef,
	  tcfafile => undef,

	  ##-- tcf addws
	  tcfcwsfile => undef,
	 );
}

## $doc = $doc->init()
##  + set computed defaults
sub init {
  my $doc = shift;

  ##-- defaults: source data
  $doc->{xmlfile} = '-' if (!defined($doc->{xmlfile})); ##-- this should really be required
  $doc->{xmlbase} = basename($doc->{xmlfile}) if (!defined($doc->{xmlbase}));

  ##-- defaults: generated data (common)
  ($doc->{outbase} = basename($doc->{xmlbase})) =~ s/\.xml$//i if (!$doc->{outbase});
  if ($doc->{tw}) {
    ##-- propagate from $doc->{tw} to $doc, if available
    $doc->{outdir} = $doc->{tw}{outdir};
    $doc->{tmpdir} = $doc->{tw}{tmpdir};
    $doc->{keeptmp} = $doc->{tw}{keeptmp};
    $doc->{genDummy} = $doc->{tw}{genDummy} if (exists($doc->{tw}{genDummy}) && !exists($doc->{genDummy}));
  }
  $doc->{outdir} = '.' if (!$doc->{outdir});
  $doc->{tmpdir} = $doc->{outdir} if (!$doc->{tmpdir});

  ##-- defaults: mkindex data
  $doc->{cxfile} = $doc->{tmpdir}.'/'.$doc->{outbase}.".cx" if (!$doc->{cxfile});
  $doc->{sxfile} = $doc->{tmpdir}.'/'.$doc->{outbase}.".sx" if (!$doc->{sxfile});
  $doc->{txfile} = $doc->{tmpdir}.'/'.$doc->{outbase}.".tx" if (!$doc->{txfile});

  ##-- defaults: mkbx0 data
  #$doc->{bx0doc} = undef;
  $doc->{bx0file} = $doc->{tmpdir}.'/'.$doc->{outbase}.".bx0" if (!$doc->{bx0file});

  ##-- defaults: mkbx data
  #$doc->{bxdata}  = undef;
  $doc->{bxfile}  = $doc->{tmpdir}.'/'.$doc->{outbase}.".bx" if (!$doc->{bxfile});
  $doc->{txtfile} = $doc->{tmpdir}.'/'.$doc->{outbase}.".txt" if (!$doc->{txtfile});

  ##-- defaults: tokenizer output data (tokenize)
  #$doc->{tokdata0}  = undef;
  $doc->{tokfile0}  = $doc->{tmpdir}.'/'.$doc->{outbase}.".t0" if (!$doc->{tokfile0});

  ##-- defaults: post-tokenizer output data (tokenize1)
  #$doc->{tokdata1}  = undef;
  $doc->{tokfile1}  = $doc->{tmpdir}.'/'.$doc->{outbase}.".t1" if (!$doc->{tokfile1});

  ##-- defaults: tokenizer xml data (tok2xml)
  #$doc->{xtokdata}  = undef;
  #$doc->{xtokfile}  = $doc->{tmpdir}.'/'.$doc->{outbase}.".t.xml" if (!$doc->{xtokfile});
  $doc->{xtokfile}  = $doc->{outdir}.'/'.$doc->{outbase}.".t.xml" if (!$doc->{xtokfile});

  ##-- defaults: tokenizer xml annotations (txmlanno)
  #$doc->{axtokdata} = undef;
  $doc->{axtokfile} = $doc->{tmpdir}.'/'.$doc->{outbase}.".ta.xml" if (!$doc->{axtokfile});
  $doc->{xtokfile0} = $doc->{outdir}.'/'.$doc->{outbase}.".t0.xml" if (!$doc->{xtokfile0} && $doc->{keeptmp});

  ##-- defaults: ws-splice (addws)
  $doc->{cwsfile} = $doc->{outdir}.'/'.$doc->{outbase}.".cws.xml" if (!$doc->{cwsfile});

  ##-- defaults: cwst-splice (idsplice)
  #$doc->{cwstbasebufr} = \$doc->{cwsdata} if (!$doc->{cwstbasebufr}); ##-- see Processor::idsplice::idsplice()
  #$doc->{cwstsobufr}  = \$doc->{xtokdata} if (!$doc->{cwstsobufr});   ##-- see Processor::idsplice::idsplice()
  $doc->{cwstbasefile} = $doc->{cwsfile} if (!$doc->{cwstbasefile});
  $doc->{cwstsofile} = $doc->{xtokfile} if (!$doc->{cwstsofile});
  $doc->{cwstfile} = $doc->{outdir}.'/'.$doc->{outbase}.".cwst.xml" if (!$doc->{cwstfile});

  ##-- defaults: standoff data (standoff)
  #$doc->{sosdoc} = undef;
  #$doc->{sowdoc} = undef;
  #$doc->{soadoc} = undef;
  ##
  #$doc->{sosfile} = $doc->{outdir}.'/'.$doc->{outbase}.".s.xml" if (!$doc->{sosfile});
  #$doc->{sowfile} = $doc->{outdir}.'/'.$doc->{outbase}.".w.xml" if (!$doc->{sowfile});
  #$doc->{soafile} = $doc->{outdir}.'/'.$doc->{outbase}.".a.xml" if (!$doc->{soafile});

  ##-- defaults: tcf encoding (tcfencode)
  $doc->{tcffile} = $doc->{outdir}.'/'.$doc->{outbase}.".tcf" if (!$doc->{tcffile});

  ##-- defaults: tcf tokenization (tcftokenize)
  $doc->{tcftokfile} = $doc->{outdir}.'/'.$doc->{outbase}.".tcftok" if (!$doc->{tcftokfile});

  ##-- defaults: tcf decoding (tcfdecode0, tcfdecode)
  $doc->{tcfxfile} = $doc->{tmpdir}.'/'.$doc->{outbase}.".tcfx" if (!$doc->{tcfxfile});
  $doc->{tcftfile} = $doc->{tmpdir}.'/'.$doc->{outbase}.".tcft" if (!$doc->{tcftfile});
  $doc->{tcfwfile} = $doc->{tmpdir}.'/'.$doc->{outbase}.".tcfw" if (!$doc->{tcfwfile});
  $doc->{tcfafile} = $doc->{tmpdir}.'/'.$doc->{outbase}.".tcfa" if (!$doc->{tcfafile});

  ##-- defaults: tcf-decoded .cws.xml data
  $doc->{tcfcwsfile} = $doc->{outdir}.'/'.$doc->{outbase}.".tcfws.xml" if (!$doc->{tcfcwsfile});

  ##-- return
  return $doc;
}


## undef = $doc->DESTROY()
##  + destructor; implicit close()
sub DESTROY {
  $_[0]->close(1);
}

##==============================================================================
## Methods: logging context
##==============================================================================

sub setLogContext {
  my ($that,$ctx) = @_;
  $ctx = $that->{xmlbase} if (!defined($ctx) && ref($that));
  Log::Log4perl::MDC->put("xmlbase", File::Basename::basename($ctx)) if (defined($ctx));
}

##==============================================================================
## Methods: Pseudo-I/O
##==============================================================================

## $newdoc = CLASS_OR_OBJECT->open($xmlfile,%docNewOptions)
##  + wrapper for CLASS_OR_OBJECT->new(), with some additional sanity checks
sub open {
  my ($doc,$xmlfile,@opts) = @_;
  $doc->setLogContext($xmlfile);
  $doc->logconfess("open(): no XML source file specified") if (!defined($xmlfile) || $xmlfile eq '');
  $doc->logconfess("open(): cannot use standard input '-' as a source file") if ($xmlfile eq '-');
  $doc->logconfess("open(): could not open XML source file '$xmlfile': $!") if (!file_try_open($xmlfile));
  $doc = $doc->new(xmlfile=>$xmlfile,open_stamp=>timestamp(),@opts);
  $doc->vlog($doc->{traceOpen},"open()") if ($doc->{traceOpen});
  return $doc;
}

## $bool = $doc->close()
## $bool = $doc->close($is_destructor)
##  + "closes" document $doc
##  + unlinks any temporary files in $doc unless $tw->{keeptmp} is true
##    - all %$doc keys ending in 'file' are considered 'temporary' files, except:
##      xmlfile, xtokfile, sosfile, sowfile, soafile
##  + also, if $is_destructor is false (default), resets all keys in %$doc to
##    default values (making $doc essentially unuseable)
sub close {
  my ($doc,$is_destructor) = @_;
  $doc->setLogContext();
  $doc->vlog($doc->{traceClose},"close()") if ($doc->{traceClose} && $doc->logInitialized);
  my $rc = 1;
  foreach ($doc->tempfiles()) {
    ##-- unlink temp files
    $doc->vlog($doc->{traceSave},"unlink $_") if ($doc->{traceSave} && $doc->logInitialized);
    do {$doc->logwarn("failed to unlink $_"); $rc=0; } if (-e $_ && !unlink($_));
  }

  ##-- update {tw} profiling information
  if ($doc->{tw}) {
    my $ntoks = $doc->nTokens() || 0;
    my $nxbytes = $doc->nXmlBytes() || 0;
    my ($keystamp,$key,$stamp,$stamp0,$prof);
    foreach $keystamp (
		       #grep {UNIVERSAL::isa($doc->{tw}{$_},'DTA::TokWrap::Processor')} keys(%{$doc->{tw}})
		       grep {$_ =~ /_stamp$/ && defined($doc->{"${_}0"})} keys(%$doc)
		      )
      {
	($key = $keystamp) =~ s/_stamp$//;
	($stamp0,$stamp) = @$doc{"${key}_stamp0","${key}_stamp"};
	next if (!defined($stamp0) || !defined($stamp));  ##-- ignore processors which haven't run for this doc
	next if ($stamp0 < 0 || $stamp < 0);              ##-- (hack): ignore forced pseudo-stamps
	$prof = $doc->{tw}{profile}{$key} = {} if (!defined($prof=$doc->{tw}{profile}{$key}));
	$prof->{ndocs}++;
	$prof->{ntoks}   += $ntoks;
	$prof->{nxbytes} += $nxbytes;
	$prof->{elapsed} += $stamp - $stamp0;
	$prof->{laststamp} = $stamp;
      }
    $prof = $doc->{tw}{profile}{''} = {} if (!defined($prof = $doc->{tw}{profile}{''}));
    $prof->{ndocs}++;
    $prof->{ntoks}   += $ntoks;
    $prof->{nxbytes} += $nxbytes;
    $prof->{laststamp} = timestamp();
    $prof->{elapsed} += $prof->{laststamp}-$doc->{open_stamp}  if (defined($doc->{open_stamp}));
  }

  ##-- stop here for destructor
  delete($doc->{tw});
  return $rc if ($is_destructor);

  ##-- drop $doc references
  %$doc = (ref($doc)||$doc)->defaults();
  return $rc;
}

## @notempkeys = $doc->notempkeys()
##  + returns list of document keys ending 'file' which are not considered "temporary"
##  + used by $doc->tempfiles()
sub notempkeys {
  return (qw(xmlfile xtokfile sosfile sowfile soafile tcffile tcftokfile), (defined($_[0]{notmpkeys}) ? split(' ',$_[0]{notmpkeys}) : qw()))

}

## @tempfiles = $doc->tempfiles()
##  + returns list of temporary filenames which have been generated by $doc,
##    or an empty list if $doc->{keeptmp} is true
##  + checks $doc->{"${filekey}_stamp"} to determine whether this document generated
##    the file named by $doc->{"$filekey"}
##  + implementation: returns values of all %$doc keys ending with 'file' except for
##    those returned by $doc->notempkeys()
##  + used by $doc->close()
sub tempfiles {
  my $doc = shift;
  return qw() if (!ref($doc) || $doc->{keeptmp});

  my %notempkeys = map {$_=>undef} $doc->notempkeys();
  my $notempre   = $doc->{notmpre} ? qr{$doc->{notmpre}} : undef;
  return (
	  grep { !defined($notempre) || $_ !~ m/$notempre/ }
	  grep { $_ =~ m/^$doc->{tmpdir}\// }
	  map { $doc->{$_} }
	  grep { m/file[01]?$/ && defined($doc->{"${_}_stamp"}) && $doc->{"${_}_stamp"} >= 0 && !exists($notempkeys{$_}) }
	  keys(%$doc)
	 );
}

##==============================================================================
## Methods: pseudo-pseudo-make
##==============================================================================

##--------------------------------------------------------------
## Methods: Pseudo-make: Initialization

## %KEYGEN = ($dataKey => $generatorSpec, ...)
##  + maps data keys to the generating processes (subroutines, classes, ...)
##  + $generatorSpec is one of:
##     $key      : calls $doc->can($key)->($doc)
##     \&coderef : calls &coderef($doc)
##     \@array   : array of atomic $generatorSpecs (keys or CODE-refs)
our (%KEYGEN);
BEGIN {
  my ($spec);
  %KEYGEN =
    (
     ##-- real data keys
     xmlfile => sub { -r $_[0]{xmlfile} },

     ##-- aliases
     (map {$_=>'mkindex'} qw(mkindex cx sx tx xx)),
     (map {$_=>[qw(mkbx0 saveBx0File)]} qw(mkbx0 bx0)),
     (map {$_=>[qw(loadBx0File mkbx saveBxFile saveTxtFile)]} qw(mkbx mktxt bx txt)),
     ##
     (map {$_=>[qw(tokenize saveTokFile0)]} qw(mktok0 tokenize0 tok0 t0 tt0)),
     (map {$_=>[qw(tokenize1 saveTokFile1)]} qw(mktok1 tokenize1 tok1 t1 tt1)),
     (map {$_=>[qw(tokenize saveTokFile0 tokenize1 saveTokFile1)]} qw(mktok tokenize tok t tt)),

     (map {$_=>[qw(loadTokFile1 tok2xml txmlanno saveXtokFile)]} qw(mktxml tok2xml xtok txml ttxml tokxml)),

     (map {$_=>[qw(addws)]} qw(addws mkcws cwsxml cws)),

     (map {$_=>[qw(idsplice)]} qw(idsplice splice mkcwst cwstxml cwst mkwst wstxml wst)),

     (map {
       $spec = ["loadXtokFile","so${_}xml"];
       map {$_=>$spec} ("mk${_}xml", "mkso${_}", "so${_}xml","so${_}file","${_}xml")
     } ('s','w','a')),

     #(map {$_=>[qw(loadXtokFile standoff)]} qw(mkstandoff standoff so mkso)),

     'tei2txt' =>[qw(mkindex),
		  qw(mkbx0), #saveBx0File
		  qw(mkbx saveTxtFile), #saveBxFile saveTxtFile
		 ],

     'tei2t' =>[qw(mkindex),
		qw(mkbx0 saveBx0File),
		qw(mkbx saveBxFile saveTxtFile),
		qw(tokenize0 saveTokFile0),
		qw(tokenize1 saveTokFile1),
               ],

     'tei2txml' => [qw(mkindex),
		    qw(mkbx0 saveBx0File),
		    qw(mkbx saveBxFile saveTxtFile),
		    qw(tokenize0 saveTokFile0),
		    qw(tokenize1 saveTokFile1),
		    qw(tok2xml txmlanno saveXtokFile),
		   ],
     'tei2spliced' => [
		       ##-- tei2txml
		       qw(mkindex),
		       qw(mkbx0 saveBx0File),
		       qw(mkbx saveBxFile saveTxtFile),
		       qw(tokenize0 saveTokFile0),
		       qw(tokenize1 saveTokFile1),
		       qw(tok2xml txmlanno saveXtokFile),
		       ##-- addws+splice
		       qw(addws idsplice),
		      ],

     'tei2tcf' =>[qw(mkindex),
		  qw(mkbx0), #saveBx0File
		  qw(mkbx), #saveBxFile saveTxtFile
		  qw(tcfencode saveTcfFile),
		 ],

     'tcfencode' => [qw(tcfencode saveTcfFile)],
     'tcf2tok' => [qw(loadTcfFile tcftokenize saveTcfTokFile)],


     'tcfsplit' => [qw(loadTcfFile tcfdecode0 saveTcfxFile saveTcftFile saveTcfwFile saveTcfaFile)],
     'tcfalign' => [
		    #qw(loadTcfFile tcfdecode0 saveTcfxFile saveTcftFile saveTcfwFile),
		    qw(loadTxtData),
		    qw(tcfalign saveTokFile1),
		   ],
     'tcfdecode' => [qw(tcfdecode),],
     'tcf2tei' => [qw(tcfdecode)],

     all => [qw(mkindex),
	     qw(mkbx0 saveBx0File),
	     qw(mkbx saveBxFile saveTxtFile),
	     qw(tokenize0 saveTokFile0),
	     qw(tokenize1 saveTokFile1),
	     #qw(loadCxFile)
	     qw(tok2xml txmlanno saveXtokFile),
	     qw(addws),
	     #qw(standoff),
	     #qw(idsplice),
	    ],
    );
}

##--------------------------------------------------------------
## Methods: Pseudo-make: (re-)generation

## $bool = $doc->genKey($key)
## $bool = $doc->genKey($key,\%KEYGEN)
##  + (re-)generate a data key (single step only)
##  + $key without a value $KEYGEN{$key} triggers an error
sub genKey {
  my ($doc,$key,$keygen) = @_;
  $doc->setLogContext();
  $doc->vlog($doc->{traceGen},"genKey(".(UNIVERSAL::isa($key,'ARRAY')
					 ? join(' ', '[',@$key,']')
					 : $key).")") if ($doc->{traceGen});
  $keygen = \%KEYGEN if (!$keygen);
  my $gen = exists($keygen->{$key}) ? $keygen->{$key} : $key;

  ##-- puke if no generator is defined
  if (!defined($gen)) {
    $doc->logcarp("genKey($key): no generator defined for key '$key'");
    return undef;
  }
  return $doc->{genDummy} if ($doc->{genDummy});

  my $rc = 1;
  my ($spec,$sub);
  foreach $spec (UNIVERSAL::isa($gen,'ARRAY') ? @$gen : $gen) {
    if (UNIVERSAL::isa($spec,'CODE')) {
      ##-- CODE-ref
      $rc &&= $spec->($doc);
    }
    elsif (defined($sub=$doc->can($spec))) {
      ##-- method name
      $rc &&= $sub->($doc);
    }
    else {
      $doc->logcroak("genKey($key): no method for KEYGEN specification '$spec'");
      $rc = 0;
    }
    last if (!$rc);
  }
  return $rc;
}

## $keyval_or_undef = $doc->makeKey($key)
##  + just an alias for $doc->genKey($key)
##  + see DTA::TokWrap::Document::Maker for a more sophisticated implementation
sub makeKey {
  my ($doc,$key) = @_;
  $doc->vlog($doc->{traceMake},"makeKey($key)") if ($doc->{traceMake});
  return $doc->genKey($key);
}


##==============================================================================
## Methods: Low-Level: generator-subclass wrappers
##==============================================================================

## $doc_or_undef = $doc->mkindex($mkindex)
## $doc_or_undef = $doc->mkindex()
##  + see DTA::TokWrap::Processor::mkindex::mkindex()
sub mkindex {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"mkindex()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{mkindex}) || 'DTA::TokWrap::Processor::mkindex')->mkindex($_[0]);
}

## $doc_or_undef = $doc->mkbx0($mkbx0)
## $doc_or_undef = $doc->mkbx0()
##  + see DTA::TokWrap::Processor::mkbx0::mkbx0()
sub mkbx0 {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"mkbx0()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{mkbx0}) || 'DTA::TokWrap::Processor::mkbx0')->mkbx0($_[0]);
}

## $doc_or_undef = $doc->mkbx($mkbx)
## $doc_or_undef = $doc->mkbx()
##  + see DTA::TokWrap::Processor::mkbx::mkbx()
sub mkbx {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"mkbx()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{mkbx}) || 'DTA::TokWrap::Processor::mkbx')->mkbx($_[0]);
}

## $doc_or_undef = $doc->tokenize($tokenize)
## $doc_or_undef = $doc->tokenize()
##  + see DTA::TokWrap::Processor::tokenize::tokenize()
##  + default tokenizer class is given by package-global $doc->{tokenizeClass}//$TOKENIZE_CLASS
sub tokenize {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"tokenize()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && ($_[0]{tw}{tokenize}||$_[0]{tw}{tokenizeClass})) || $_[0]{tokenizeClass} || "$TOKENIZE_CLASS")->tokenize($_[0]);
}
BEGIN {
  *tokenize0 = \&tokenize;
}

## $doc_or_undef = $doc->tokenize1($tokenize)
## $doc_or_undef = $doc->tokenize1()
##  + see DTA::TokWrap::Processor::tokenize1::tokenize1()
sub tokenize1 {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"tokenize1()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{tokenize1}) || 'DTA::TokWrap::Processor::tokenize1')->tokenize1($_[0]);
}

## $doc_or_undef = $doc->tok2xml($tok2xml)
## $doc_or_undef = $doc->tok2xml()
##  + see DTA::TokWrap::Processor::tok2xml::tok2xml()
sub tok2xml {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"tok2xml()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{tok2xml}) || 'DTA::TokWrap::Processor::tok2xml')->tok2xml($_[0]);
}

## $doc_or_undef = $doc->txmlanno($txmlanno)
## $doc_or_undef = $doc->txmlanno()
##  + see DTA::TokWrap::Processor::txmlanno::txmlanno()
sub txmlanno {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"txmlanno()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{txmlanno}) || 'DTA::TokWrap::Processor::txmlannp')->txmlanno($_[0]);
}

## $doc_or_undef = $doc->addws($addws)
## $doc_or_undef = $doc->addws()
##  + see DTA::TokWrap::Processor::addws::addws()
sub addws {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"addws()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{addws}) || 'DTA::TokWrap::Processor::addws')->addws($_[0]);
}

## $doc_or_undef = $doc->idsplice($idsplice)
## $doc_or_undef = $doc->idsplice()
##  + see DTA::TokWrap::Processor::idsplice::idsplice()
sub idsplice {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"idsplice()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{idsplice}) || 'DTA::TokWrap::Processor::idsplice')->idsplice($_[0]);
}

## $doc_or_undef = $doc->tcfencode($tcfencode)
## $doc_or_undef = $doc->tcfencode()
##  + see DTA::TokWrap::Processor::tcfencode::tcfencode()
sub tcfencode {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"tcfencode()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{tcfencode}) || 'DTA::TokWrap::Processor::tcfencode')->tcfencode($_[0]);
}

## $doc_or_undef = $doc->tcftokenize($tcftokenize)
## $doc_or_undef = $doc->tcftokenize()
##  + see DTA::TokWrap::Processor::tcfencode::tcftokenize()
sub tcftokenize {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"tcftokenize()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{tcftokenize}) || 'DTA::TokWrap::Processor::tcftokenize')->tcftokenize($_[0]);
}

## $doc_or_undef = $doc->tcfdecode0($tcfdecode0, %opts)
## $doc_or_undef = $doc->tcfdecode()
##  + see DTA::TokWrap::Processor::tcfdecode::tcfdecode0()
sub tcfdecode0 {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"tcfdecode0()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{tcfdecode0}) || 'DTA::TokWrap::Processor::tcfdecode0')->tcfdecode0($_[0],@_[2..$#_]);
}

## $doc_or_undef = $doc->tcfalign($tcfalign)
## $doc_or_undef = $doc->tcfalign()
##  + see DTA::TokWrap::Processor::tcfalign::tcfalign()
sub tcfalign {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"tcfalign()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{tcfalign}) || 'DTA::TokWrap::Processor::tcfalign')->tcfalign($_[0]);
}

## $doc_or_undef = $doc->tcfdecode($tcfdecode0)
## $doc_or_undef = $doc->tcfdecode()
##  + see DTA::TokWrap::Processor::tcfdecode::tcfdecode()
sub tcfdecode {
  $_[0]->setLogContext();
  $_[0]->vlog($_[0]{traceProc},"tcfdecode()") if ($_[0]{traceProc});
  return ($_[1] || ($_[0]{tw} && $_[0]{tw}{tcfdecode}) || 'DTA::TokWrap::Processor::tcfdecode')->tcfdecode($_[0]);
}


##==============================================================================
## Methods: Member I/O
##==============================================================================

##----------------------------------------------------------------------
## Methods: Member I/O: input: generic

## $xmldoc_or_undef = $doc->loadFileDoc($key,$filename_or_fh_or_stringref,%xmlparse_opts)
## $xmldoc_or_undef = $doc->loadFileDoc($key)
##  + loads $doc->{"${key}doc"} from $filename_or_fh_or_stringref; default=$doc->{"${key}file"}
sub loadFileDoc {
  my ($doc,$key,$file,%xopts) = @_;
  $doc->setLogContext();

  ##-- get source
  $file = $doc->{$key."file"} if (!$file);
  $doc->logconfess("loadFileDoc($key): no {${key}file} defined") if (!defined($file));
  $doc->vlog($doc->{traceLoad}, "loadFileDoc($key,$file)") if ($doc->{traceLoad});

  my $xmlparser = libxml_parser(%xopts);
  if (UNIVERSAL::isa($file,'SCALAR')) {
    ##-- load from scalar ref
    $doc->{$key."doc"} = $xmlparser->parse_string($$file);
    $doc->{$key."doc_stamp"} = timestamp();
  } elsif (ref($file)) {
    ##-- load from filehandle
    $doc->{$key."doc"} = $xmlparser->parse_fh($file);
    $doc->{$key."doc_stamp"} = timestamp();
  } else {
    ##-- load from named file
    $doc->{$key."doc"} = $xmlparser->parse_file($file);
    $doc->{$key."doc_stamp"} = file_mtime($file);
  }
  $doc->logconfess("loadFileDoc($key): could not parse {${key}file} '$file'") if (!$doc->{$key."doc"});

  return $doc->{"${key}doc"};
}

## \$data_or_undef = $doc->loadFileData($key,$suffix,$filename_or_fh)
## \$data_or_undef = $doc->loadFileData($key,$suffix)
## \$data_or_undef = $doc->loadFileData($key)
##  + loads $doc->{"${key}data"} from $filename_or_fh_or_stringref (default=$doc->{"${key}file"})
sub loadFileData {
  my ($doc,$key,$suff,$file) = @_;
  $suff //= '';
  $doc->setLogContext();

  ##-- get file
  $file = $doc->{"${key}file${suff}"} if (!$file);
  $doc->logconfess("loadFileData($key,$suff): no {${key}file${suff}} defined") if (!defined($file));
  $doc->vlog($doc->{traceLoad}, "loadFileData($key,$suff,$file)") if ($doc->{traceLoad});

  slurp_file($file,\$doc->{"${key}data${suff}"})
    or $doc->logconfess("slurp_file() failed for {${key}file${suff}} '$file': $!");

  $doc->{"${key}file${suff}_stamp"} = file_mtime($file);
  return \$doc->{"${key}data${suff}"};
}

##----------------------------------------------------------------------
## Methods: Member I/O: input: specific

## $bx0doc_or_undef = $doc->loadBx0File($filename_or_fh)
## $bx0doc_or_undef = $doc->loadBx0File()
##  + loads $doc->{bx0doc} from $filename_or_fh (default=$doc->{bx0file})
sub loadBx0File {
  return $_[0]->loadFileDoc('bx0',$_[1],keep_blanks=>0);
}

## $cxdata_or_undef = $doc->loadBxFile($bxfile_or_fh,$txtfile_or_fh)
## $cxdata_or_undef = $doc->loadBxFile()
##  + loads $doc->{bxdata} from @$doc{qw(bxfile txtfile)}
##  + requires $doc->{txfile}
sub loadBxFile {
  my ($doc,$bxfile,$txtfile) = @_;
  $doc->setLogContext();

  ##-- get .bx file
  $bxfile  = $doc->{bxfile}  if (!$bxfile);
  $txtfile = $doc->{txtfile} if (!$txtfile);
  $doc->logconfess("loadBxFile(): no .bx file defined") if (!defined($bxfile));
  $doc->logconfess("loadBxFile(): no .txt file defined") if (!defined($txtfile));
  $doc->vlog($doc->{traceLoad}, "loadBxFile($bxfile, $txtfile)") if ($doc->{traceLoad});

  ##-- load .txt file
  my $txtdata = '';
  slurp_file($txtfile, \$txtdata)
    or $doc->logconfess("slurp_file() failed for .txt file '$txtfile': $!");

  ##-- load .bx file
  my $bxdata = $doc->{bxdata} = [];
  my $fh = ref($bxfile) ? $bxfile : IO::File->new("<$bxfile");
  $doc->logconfess("loadBxFile(): open failed for .bx file '$bxfile': $!") if (!$fh);
  $fh->binmode() if (!ref($bxfile));
  my ($blk);
  while (<$fh>) {
    chomp;
    next if (/^%%/ || /^\s*$/);
    push(@$bxdata,$blk={});
    @$blk{qw(key elt xoff xlen toff tlen otoff otlen bx0off)} = split(/\t/,$_);
    $blk->{bx0off} = 0 if (!defined($blk->{bx0off})); ##-- backwards-compatible hack: unknown .bx0 offset, treated as zero
    $blk->{otext} = substr($txtdata, $blk->{otoff}, $blk->{otlen});
  }
  $fh->close() if (!ref($bxfile));

  $doc->{bxdata_stamp} = file_mtime($txtfile);
  return $doc->{bxdata};
}


## $cxdata_or_undef = $doc->loadCxFile($filename_or_fh)
## $cxdata_or_undef = $doc->loadCxFile()
##  + loads $doc->{cxdata} from $filename_or_fh (default=$doc->{cxfile})
##  + $doc->{cxdata} = [ $cx0, ... ]
##    - where each $cx = [ $id, $xoff,$xlen, $toff,$tlen, $text, @attrs ]
##    - globals $CX_ID, $CX_XOFF, etc. are indices for $cx arrays
sub loadCxFile {
  my ($doc,$file) = @_;
  $doc->setLogContext();

  ##-- get file
  $file = $doc->{cxfile} if (!$file);
  $doc->logconfess("loadCxFile(): no .cx file defined") if (!defined($file));
  $doc->vlog($doc->{traceLoad}, "loadCxFile($file)") if ($doc->{traceLoad});

  my $cx = $doc->{cxdata} = [];
  my $fh = ref($file) ? $file : IO::File->new("<$file");
  $doc->logconfess("loadCxFile(): open failed for .cx file '$file': $!") if (!$fh);
  $fh->binmode() if (!ref($file));
  while (<$fh>) {
    chomp;
    next if (/^%%/ || /^\s*$/);
    push(@$cx, [split(/\t/,$_)]);
  }
  $fh->close() if (!ref($file));

  $doc->{cxdata_stamp} = file_mtime($file);
  return $cx;
}

## \$tokdataX_or_undef = $doc->loadTokFileN($i,$filename_or_fh)
## \$tokdataX_or_undef = $doc->loadTokFileN($i)
##  + loads $doc->{"tokdata${i}"} from $filename_or_fh (default=$doc->{"tokfile${i}"})
##  + obsolete
sub loadTokFileN {
  return $_[0]->loadFileData('tok',@_[1..$#_]);
}

## \$tokdata0_or_undef = $doc->loadTokFile0($filename_or_fh)
## \$tokdata0_or_undef = $doc->loadTokFile0()
##  + loads $doc->{tokdata0} from $filename_or_fh (default=$doc->{tokfile0})
sub loadTokFile0 {
  return $_[0]->loadFileData('tok',0,@_[1..$#_]);
}

## \$tokdata1_or_undef = $doc->loadTokFile1($filename_or_fh)
## \$tokdata1_or_undef = $doc->loadTokFile1()
##  + loads $doc->{tokdata1} from $filename_or_fh (default=$doc->{tokfile1})
sub loadTokFile1 {
  return $_[0]->loadFileData('tok',1,@_[1..$#_]);
}

## \$xtokdata_or_undef = $doc->loadXtokFile($filename_or_fh)
## \$xtokdata_or_undef = $doc->loadXtokFile()
##  + loads $doc->{xtokdata} from $filename_or_fh (default=$doc->{xtokfile})
##  + see also $doc->xtokDoc() [which should be obsolete]
sub loadXtokFile {
  return $_[0]->loadFileData('xtok','',@_[1..$#_]);
}

## \$xmlbuf_or_undef = $doc->loadXmlData($filename_or_fh)
## \$xmlbuf_or_undef = $doc->loadXmlData()
##  + loads $doc->{xmldata} from $filename_or_fh (default=$doc->{xmlfile})
sub loadXmlData {
  return $_[0]->loadFileData('xml','',$_[1]);
}

## \$xmlbuf_or_undef = $doc->loadCwsData($filename_or_fh)
## \$xmlbuf_or_undef = $doc->LoadCwsData()
##  + loads $doc->{cwsdata} from $filename_or_fh (default=$doc->{cwsfile})
##  + should be obsolete
sub loadCwsData {
  return $_[0]->loadFileData('cws','',$_[1]);
}

## \$txtbuf_or_undef = $doc->loadTxtData($filename_or_fh)
## \$txtbuf_or_undef = $doc->loadTxtData()
##  + loads $doc->{txtdata} from $filename_or_fh (default=$doc->{txtfile})
sub loadTxtData {
  return $_[0]->loadFileData('txt','',$_[1]);
}

## \$xmldoc_or_undef = $doc->loadTcfFile($filename_or_fh_or_stringref)
## \$tcfdoc_or_undef = $doc->loadTcfFile()
##  + loads $doc->{tcfdoc} from $filename_or_fh_or_stringref (default=$doc->{tcfdatar} or $doc->{tcffile})
sub loadTcfFile {
  return $_[0]->loadFileDoc('tcf',$_[1],keep_blanks=>0);
}

##----------------------------------------------------------------------
## Methods: Member I/O: output: generic

## $file_or_undef = $doc->saveFileDoc($key,$filename_or_fh_or_stringref,$xmldoc,%saveopts)
## $file_or_undef = $doc->saveFileDoc($key,$filename_or_fh_or_stringref)
## $file_or_undef = $doc->saveFileDoc()
##  + %saveopts:
##     format => $level,  ##-- do output formatting (default=$doc->{format})
##  + $xmldoc defaults to $doc->{"${key}doc"}
##  + $filename_or_fh defaults to $doc->{"${key}file"}
##  + sets $doc->{"${key}file"} if a filename is passed or defaulted
##  + sets $doc->{"${key}file_stamp"}
sub saveFileDoc {
  my ($doc,$key,$file,$xmldoc,%opts) = @_;
  $doc->setLogContext();

  ##-- get xmldoc
  $xmldoc = $doc->{"${key}doc"} if (!$xmldoc);
  $doc->logconfess("saveFileDoc($key): no {${key}doc} key defined") if (!$xmldoc);

  ##-- get file
  $file = $doc->{"${key}file"} if (!defined($file));
  $file = "$doc->{outdir}/$doc->{outbase}.${key}" if (!defined($file));
  $doc->{"${key}file"} = $file if (!ref($file));
  $doc->vlog($doc->{traceSave}, "saveFileDoc($key,$file)") if ($doc->{traceSave});

  ##-- actual save
  my $format = (exists($opts{format}) ? $opts{format} : $doc->{format})||0;
  if (UNIVERSAL::isa($file,'SCALAR')) {
    ##-- save: to string
    $$file = $xmldoc->toString($format);
  }
  elsif (ref($file)) {
    ##-- save: to filehandle
    $xmldoc->toFh($file,$format);
  }
  else {
    ##-- save: to named file
    $xmldoc->toFile($file,$format);
  }

  $doc->{bx0file_stamp} = timestamp(); ##-- stamp
  return $file;
}

## $file_or_undef = $doc->saveFileData($key,$suffix,$filename_or_fh_or_stringref,\$dataref)
## $file_or_undef = $doc->saveFileData($key,$suffix,$filename_or_fh_or_stringref)
## $file_or_undef = $doc->saveFileData($key,$suffix)
##  + $filename_or_fh_or_stringref defaults to $doc->{"${key}file${suffix}"}="$doc->{outdir}/$doc->{outbase}.${key}${suffix}"
##  + \$dataref defaults to \$doc->{"${key}data${suffix}"}
##  + sets $doc->{"${key}file_stamp${suffix}"}
sub saveFileData {
  my ($doc,$key,$suff,$file,$datar) = @_;
  $doc->setLogContext();

  ##-- get data
  $datar = \$doc->{"${key}data${suff}"} if (!$datar);
  $doc->logconfess("saveFileData($key,$suff): no {${key}data${suff}} defined") if (!$datar || !ref($datar) || !defined($$datar));

  ##-- get file
  $file = $doc->{"${key}file${suff}"} if (!defined($file));
  $file = "$doc->{outdir}/$doc->{outbase}.${key}${suff}" if (!defined($file));
  $doc->{"${key}file${suff}"} = $file if (!ref($file));
  $doc->vlog($doc->{traceSave}, "saveFileData($key,$suff,$file)") if ($doc->{traceSave});

  ##-- get filehandle & print
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  $doc->logconfess("saveFileData($key,$suff): failed to open file '$file': $!") if (!$fh);
  $fh->binmode() if (!ref($file));
  $fh->print( $$datar );
  if (!ref($file)) {
    $fh->close()
      or $doc->logconfess("saveFileData($key,$suff): failed to close file '$file': $!");
  }

  $doc->{"${key}file${suff}_stamp"} = timestamp(); ##-- stamp
  return $file;
}


##----------------------------------------------------------------------
## Methods: Member I/O: output: specific

## $file_or_undef = $doc->saveBx0File($filename_or_fh,$bx0doc,%opts)
## $file_or_undef = $doc->saveBx0File($filename_or_fh)
## $file_or_undef = $doc->saveBx0File()
##  + %opts:
##     format => $level,  ##-- do output formatting (default=$doc->{format})
##  + $bx0doc defaults to $doc->{bx0doc}
##  + $filename_or_fh defaults to $doc->{bx0file}="$doc->{outdir}/$doc->{outbase}.bx0"
##  + sets $doc->{bx0file} if a filename is passed or defaulted
##  + sets $doc->{bx0file_stamp}
sub saveBx0File {
  return $_[0]->saveFileDoc('bx0',@_[1..$#_]);
}

## $file_or_undef = $doc->saveBxFile($filename_or_fh,\@blocks)
## $file_or_undef = $doc->saveBxFile($filename_or_fh)
## $file_or_undef = $doc->saveBxFile()
##  + \@blocks defaults to $doc->{bxdata}
##  + $filename_or_fh defaults to $doc->{bxfile}="$doc->{outdir}/$doc->{outbase}.bx"
##  + sets $doc->{bxfile_stamp}
sub saveBxFile {
  my ($doc,$file,$bxdata) = @_;
  $doc->setLogContext();

  ##-- get bxdata
  $bxdata = $doc->{bxdata} if (!$bxdata);
  $doc->logconfess("saveBxFile(): no bxdata defined") if (!$bxdata);

  ##-- get file
  $file = $doc->{bxfile} if (!defined($file));
  $file = "$doc->{outdir}/$doc->{outbase}.bx" if (!defined($file));
  $doc->{bxfile} = $file if (!ref($file));
  $doc->vlog($doc->{traceSave}, "saveBxFile($file)") if ($doc->{traceSave});

  ##-- get filehandle & print
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  $doc->logconfess("saveBxFile(): open failed for output file '$file': $!") if (!$fh);
  $fh->print(
	      "%% XML block list file generated by ", __PACKAGE__, "::saveBxFile() (DTA::TokWrap version $DTA::TokWrap::VERSION)\n",
	      "%% Original source file: $doc->{xmlfile}\n",
	      "%%======================================================================\n",
	      "%% \$KEY\$\t\$ELT\$\t\$XML_OFFSET\$\t\$XML_LENGTH\$\t\$TX_OFFSET\$\t\$TX_LEN\$\t\$TXT_OFFSET\$\t\$TXT_LEN\$\t\$BX0_OFFSET\$\n",
	      (map {join("\t", @$_{qw(key elt xoff xlen toff tlen otoff otlen bx0off)})."\n"} @$bxdata),
	    );
  $fh->close() if (!ref($file));

  $doc->{bxfile_stamp} = timestamp(); ##-- stamp
  return $file;
}

## $file_or_undef = $doc->saveTxtFile($filename_or_fh,\@blocks,%opts)
## $file_or_undef = $doc->saveTxtFile($filename_or_fh)
## $file_or_undef = $doc->saveTxtFile()
##  + %opts:
##      debug=>$bool,  ##-- if true, debugging text will be printed (and saveBxFile() offsets will be wrong)
##  + $filename_or_fh defaults to $doc->{txtfile}="$doc->{outdir}/$doc->{outbase}.txt"
##  + \@blocks defaults to $doc->{bxdata}
##  + sets $doc->{txtfile_stamp}
sub saveTxtFile {
  my ($doc,$file,$bxdata,%opts) = @_;
  $doc->setLogContext();

  ##-- get options
  my $debug_txt = $opts{debug};

  ##-- get bxdata
  $bxdata = $doc->{bxdata} if (!$bxdata);
  $doc->logconfess("saveBxFile(): no bxdata defined") if (!$bxdata);

  ##-- get file
  $file = $doc->{txtfile} if (!defined($file));
  $file = "$doc->{outdir}/$doc->{outbase}.txt" if (!defined($file));
  $doc->{txtfile} = $file if (!ref($file));
  $doc->vlog($doc->{traceSave}, "saveTxtFile($file)") if ($doc->{traceSave});

  ##-- get filehandle & print
  my $fh = ref($file) ? $file : IO::File->new(">$file");
  $fh->binmode() if (!ref($file));
  if ($debug_txt) {
    $fh->print(
	       map {
		 (($debug_txt ? "[$_->{key}:$_->{elt}]\n" : qw()),
		  $_->{otext},
		  ($debug_txt ? "\n[/$_->{key}:$_->{elt}]\n" : qw()),
		 )
	       } @$bxdata
	      );
    $fh->print("\n"); ##-- always terminate text file with a newline
  } else {
    ##-- dump raw text buffer
    $fh->print($doc->{txtdata});
  }
  $fh->close() if (!ref($file));

  $doc->{txtfile_stamp} = timestamp(); ##-- stamp
  return $file;
}

## $file_or_undef = $doc->saveTokFileN($i,$filename_or_fh,\$tokdata)
## $file_or_undef = $doc->saveTokFileN($i,$filename_or_fh)
## $file_or_undef = $doc->saveTokFileN()
##  + $filename_or_fh defaults to $doc->{"tokfile${$i}"}="$doc->{outdir}/$doc->{outbase}.t${i}"
##  + \$tokdata defaults to \$doc->{"tokdata${i}"}
##  + sets $doc->{"tokfile_stamp${i}"}
##  + should be obsolete
sub saveTokFileN {
  return $_[0]->saveFileData('tok',@_[1..$#_]);
}

## $file_or_undef = $doc->saveTokFile0($filename_or_fh,\$tokdata)
## $file_or_undef = $doc->saveTokFile0($filename_or_fh)
## $file_or_undef = $doc->saveTokFile0()
##  + wrapper for $doc->saveTokFileN(0,@_)
sub saveTokFile0 {
  return $_[0]->saveFileData('tok',0,@_[1..$#_]);
}

## $file_or_undef = $doc->saveTokFile1($filename_or_fh,\$tokdata)
## $file_or_undef = $doc->saveTokFile1($filename_or_fh)
## $file_or_undef = $doc->saveTokFile1()
##  + wrapper for $doc->saveTokFileN(1,@_)
sub saveTokFile1 {
  return $_[0]->saveFileData('tok',1,@_[1..$#_]);
}

## $file_or_undef = $doc->saveXtokFile($filename_or_fh,\$xtokdata,%opts)
## $file_or_undef = $doc->saveXtokFile($filename_or_fh)
## $file_or_undef = $doc->saveXtokFile()
##  + %opts:
##    format => $level, ##-- formatting level (default=$doc->{format}) ##-- USELESS!
##  + $filename_or_fh defaults to $doc->{xtokfile}="$doc->{outdir}/$doc->{outbase}.t.xml"
##  + \$xtokdata defaults to \$doc->{xtokdata}
##  + sets $doc->{xtokfile_stamp}
sub saveXtokFile {
  return $_[0]->saveFileData('xtok','',@_[1..$#_]);
}

## $file_or_undef = $doc->saveTcfFile($filename_or_fh,$tcfdoc,%opts)
## $file_or_undef = $doc->saveTcfFile($filename_or_fh)
## $file_or_undef = $doc->saveTcfFile()
##  + %opts:
##    format => $level, ##-- formatting level (default=1)
##  + $filename_or_fh defaults to $doc->{tcffile}="$doc->{outdir}/$doc->{outbase}.tcf"
##  + $tcfdoc defaults to $doc->{tcfdoc}
##  + sets $doc->{tcffile_stamp}
sub saveTcfFile {
  return $_[0]->saveFileDoc('tcf',@_[1..$#_]);
}

## $file_or_undef = $doc->saveTcfTokFile($filename_or_fh,$tcfdoc,%opts)
## $file_or_undef = $doc->saveTcfTokFile($filename_or_fh)
## $file_or_undef = $doc->saveTcfTokFile()
##  + %opts:
##    format => $level, ##-- formatting level (default=1)
##  + $filename_or_fh defaults to $doc->{tcftokfile}="$doc->{outdir}/$doc->{outbase}.tcftok"
##  + $tcftokdoc defaults to $doc->{tcftokdoc}
##  + sets $doc->{tcftokfile_stamp}
sub saveTcfTokFile {
  return $_[0]->saveFileDoc('tcftok',@_[1..$#_]);
}

## $file_or_undef = $doc->saveTcfxFile($filename_or_fh,\$tcfxdata)
## $file_or_undef = $doc->saveTcfxFile($filename_or_fh)
## $file_or_undef = $doc->saveTcfxFile()
##  + $filename_or_fh defaults to $doc->{tcfxfile}="$doc->{tmpdir}/$doc->{outbase}.tcfx"
##  + \$tcfxdata defaults to \$doc->{tcfxdata}
##  + sets $doc->{tcfxfile_stamp}
sub saveTcfxFile {
  return $_[0]->saveFileData('tcfx','',@_[1..$#_]);
}

## $file_or_undef = $doc->saveTcftFile($filename_or_fh,\$tcftdata)
## $file_or_undef = $doc->saveTcft($filename_or_fh)
## $file_or_undef = $doc->saveTcftFile()
##  + $filename_or_fh defaults to $doc->{tcftfile}="$doc->{tmpdir}/$doc->{outbase}.tcft"
##  + \$tcftdata defaults to \$doc->{tcftdata}
##  + sets $doc->{tcftfile_stamp}
sub saveTcftFile {
  return $_[0]->saveFileData('tcft','',@_[1..$#_]);
}

## $file_or_undef = $doc->saveTcfwFile($filename_or_fh,\$tcfwdata)
## $file_or_undef = $doc->saveTcfwFile($filename_or_fh)
## $file_or_undef = $doc->saveTcfwFile()
##  + $filename_or_fh defaults to $doc->{tcfwfile}="$doc->{tmpdir}/$doc->{outbase}.tcfw"
##  + \$tcfwdata defaults to \$doc->{tcfwdata}
##  + sets $doc->{tcfwfile_stamp}
sub saveTcfwFile {
  return $_[0]->saveFileData('tcfw','',@_[1..$#_]);
}

## $file_or_undef = $doc->saveTcfaFile($filename_or_fh,\$tcfadata)
## $file_or_undef = $doc->saveTcfaFile($filename_or_fh)
## $file_or_undef = $doc->saveTcfaFile()
##  + $filename_or_fh defaults to $doc->{tcfafile}="$doc->{outdir}/$doc->{outbase}.tcfa"
##  + $tcfadata defaults to \$doc->{tcfadata}
##  + sets $doc->{tcfafile_stamp}
sub saveTcfaFile {
  #return $_[0]->saveFileDoc('tcfa',@_[1..$#_]);
  return 1 if (exists($_[2]) ? !$_[2] : !defined($_[0]->{tcfadata})); ##-- no tcfadata to save
  return $_[0]->saveFileData('tcfa','',@_[1..$#_]);
}


##==============================================================================
## Methods: Profiling
##==============================================================================

## $ntoks_or_undef = $doc->nTokens()
sub nTokens { return $_[0]{ntoks}; }

## $nxbytes_or_undef = $doc->nXmlBytes()
sub nXmlBytes { return (-s $_[0]{xmlfile}); }

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Document - DTA tokenizer wrappers: document wrapper

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Document;
 
 ##========================================================================
 ## Constructors etc.
 
 $doc = $CLASS_OR_OBJECT->new(%args);
 %defaults = $CLASS->defaults();
 $doc = $doc->init();
 $doc->DESTROY();
 
 ##========================================================================
 ## Methods: Pseudo-I/O
 
 $newdoc = CLASS_OR_OBJECT->open($xmlfile,%docNewOptions);
 $bool = $doc->close();
 @notempkeys = $doc->notempkeys();
 @tempfiles = $doc->tempfiles();
 
 ##========================================================================
 ## Methods: pseudo-pseudo-make
 
 $bool = $doc->genKey($key);
 $keyval_or_undef = $doc->makeKey($key);
 
 ##========================================================================
 ## Methods: Low-Level: generator-subclass wrappers
 
 $doc_or_undef = $doc->mkindex();
 $doc_or_undef = $doc->mkbx0();
 $doc_or_undef = $doc->mkbx();
 $doc_or_undef = $doc->tokenize();
 $doc_or_undef = $doc->tok2xml();
 $doc_or_undef = $doc->txmlanno();
 
 ##========================================================================
 ## Methods: Member I/O
 
 $bx0doc_or_undef    = $doc->loadBx0File();
 $cxdata_or_undef    = $doc->loadBxFile();
 $cxdata_or_undef    = $doc->loadCxFile();
 \$tokdata_or_undef  = $doc->loadTokFile();
 \$xtokdata_or_undef = $doc->loadXtokFile();
 $xtokDoc            = $doc->xtokDoc();
 \$xmlbuf_or_undef   = $doc->loadXmlData();
 \$txtbuf_or_undef   = $doc->loadTxtData();
 
 $file_or_undef = $doc->saveBx0File();
 $file_or_undef = $doc->saveBxFile();
 $file_or_undef = $doc->saveTxtFile();
 $file_or_undef = $doc->saveTokFile();
 $file_or_undef = $doc->saveXtokFile();
 $file_or_undef = $doc->saveTcfFile();
  
 ##========================================================================
 ## Methods: Profiling
 
 $ntoks_or_undef = $doc->nTokens();
 $nxbytes_or_undef = $doc->nXmlBytes();
 


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::Document provides a perl class for representing
a single DTA base-format XML file and associated indices.
Together with the L<DTA::TokWrap|DTA::TokWrap> module, this
class comprises the top-level API of the DTA::TokWrap distribution.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document: Globals
=pod

=head2 Globals

=over 4

=item @ISA

DTA::TokWrap::Document inherits from L<DTA::TokWrap::Base|DTA::TokWrap::Base>.

=item $TOKENIZE_CLASS

$TOKENIZE_CLASS

Default tokenizer sub-processor class
(default='L<DTA::TokWrap::Processor::tokenize|tokenize>').

=item Variables: ($CX_ID,$CX_XOFF,$CX_XLEN,$CX_TOFF,$CX_TLEN,$CX_TEXT,$CX_ATTRS)

Field indices in .cx files generated by the
L<mkindex()|/mkindex> method.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $doc = $CLASS_OR_OBJECT->new(%args);

Low-level constructor for document wrapper object.
You should probably use either
L<DTA::TokWrap-E<gt>open()|DTA::TokWrap/open>
or L<DTA::TokWrap::Document-E<gt>open()|/open>
instead of calling this constructor directly.

%args, %$doc:

 ##-- Document class
 class => $class,      ##-- delegate call to $class->new(%args)
 ##
 ##-- Source data
 xmlfile => $xmlfile,  ##-- source filename
 xmlbase => $xmlbase,  ##-- xml:base for generated files (default=basename($xmlfile))
 xmldata => $xmldata,  ##-- source buffer (for addws, tcfencode)
 ##
 ##-- pseudo-make options
 traceMake => $level,  ##-- log-level for makeKey() trace (e.g. 'debug'; default=undef (none))
 traceGen  => $level,  ##-- log-level for genKey() trace (e.g. 'trace'; default=undef (none))
 traceProc => $level,  ##-- log-level for document-called processor calls (default=none)
 traceLoad => $level,  ##-- log-level for load* trace (default=none)
 traceSave => $level,  ##-- log-level for save* trace (default=none)
 genDummy  => $bool,   ##-- if true, generator will not actually run (a la `make -n`)
 ##
 ##-- generator data (optional)
 tw => $tw,              ##-- a DTA::TokWrap object storing individual generators
 traceOpen  => $leve,    ##-- log-lvel for open() trace (e.g. 'info'; default=undef (none))
 traceClose => $level,   ##-- log-level for close() trace (e.g. 'trace'; default=undef (none))
 ##
 ##-- generated data (common)
 outdir => $outdir,    ##-- output directory for generated data (default=.)
 tmpdir => $tmpdir,    ##-- temporary directory for generated data (default=$ENV{DTATW_TMP}||$outdir)
 keeptmp => $bool,     ##-- if true, temporary document-local files will be kept on $doc->close()
 notmpre => $regex,    ##-- non-temporary filename regex
 notmpkeys => $keys,   ##-- non-temporary keys, space-separated list
 outbase => $filebase, ##-- output basename (default=`basename $xmlbase .xml`)
 format => $level,     ##-- default formatting level for XML output
 ##
 ##-- mkindex data (see DTA::TokWrap::Processor::mkindex)
 cxfile => $cxfile,    ##-- character index file (default="$tmpdir/$outbase.cx")
 cxdata => $cxdata,    ##-- character index data (see loadCxFile() method)
 sxfile => $sxfile,    ##-- structure index file (default="$tmpdir/$outbase.sx")
 txfile => $txfile,    ##-- raw text index file (default="$tmpdir/$outbase.tx")
 ##
 ##-- mkbx0 data (see DTA::TokWrap::Processor::mkbx0)
 bx0doc  => $bx0doc,   ##-- pre-serialized block-index XML::LibXML::Document
 bx0file => $bx0file,  ##-- pre-serialized block-index XML file (default="$outbase.bx0"; optional)
 ##
 ##-- mkbx data (see DTA::TokWrap::Processor::mkbx)
 bxdata  => \@bxdata,  ##-- block-list, see DTA::TokWrap::mkbx::mkbx() for details
 bxfile  => $bxfile,   ##-- serialized block-index CSV file (default="$tmpdir/$outbase.bx"; optional)
 txtfile => $txtfile,  ##-- serialized & hinted text file (default="$tmpdir/$outbase.txt"; optional)
 txtdata => $txtdata,  ##-- serialized & hinted text file (used by tcfencode, must be loaded explicitly with loadTxtData())
 ##
 ##-- tokenize data (see DTA::TokWrap::Processor::tokenize, DTA::TokWrap::Processor::tokenize::dummy)
 tokdata0 => $tokdata0,  ##-- tokenizer output data (slurped string)
 tokfile0 => $tokfile0,  ##-- tokenizer output file (default="$tmpdir/$outbase.t0"; optional)
 ##
 ##-- post-tokenize data (see DTA::TokWrap::Processor::tokenize1)
 tokdata1 => $tokdata1,  ##-- post-tokenizer output data (slurped string)
 tokfile1 => $tokfile1,  ##-- post-tokenizer output file (default="$tmpdir/$outbase.t1"; optional)
 ##
 ##-- tokenizer xml data (see DTA::TokWrap::Processor::tok2xml)
 xtokdata => $xtokdata,  ##-- XML-ified tokenizer output data
 xtokfile => $xtokfile,  ##-- XML-ified tokenizer output file (default="$outdir/$outbase.t.xml")
 xtokdoc  => $xtokdoc,   ##-- XML::LibXML::Document for $xtokdata (parsed from string)
 ##
 ##-- tokenizer xml annotations (see DTA::TokWrap::Processor::txmlanno)
 axtokdata => $axtokdata,  ##-- optional external XML annotation data (for splicing into $xtokdata)
 axtokfile => $axtokfile,  ##-- optional external XML annotation file (for splicing into $xtokfile; default="$outdir/$outbase.ta.xml")
 xtokfile0 => $xtokfile0,  ##-- XML-ified tokenizer output file (default=none or "$outdir/$outbase.t0.xml" if {keeptmp} is true)
 ##
 ##-- ws-splice (see DTA::TokWrap::Processor::addws)
 #cwsdata => $cwsdata,    ##-- ws-spliced output data (xmlfile with <s> and <w> elements)
 cwsfile => $cwsfile,    ##-- ws-spliced output file (default="$outdir/$outbase.cws.xml")
 ##
 ##-- property-splice (see DTA::TokWrap::Processor::idsplice)
 ## cwstbasebufr => \$bdata,  ##-- base data-ref for idsplice (xml with //*/@id) [default=\$cwsdata if defined]
 ## cwstbasefile => $bfile,   ##-- source file for $bdata [default=$cwsfile]
 ## cwstsobufr   => \$sodata, ##-- standoff data-ref for idsplice (xml with //*/@id, additional attributes and content) [default=\$xtokdata]
 ## cwstsofile   => $sofile,  ##-- source file for $sodata [default=$xtokfile]
 ## cwstbufr     => $wstbufr, ##-- idsplice output buffer (base + id-spliced attributes, content) -- available for override, not used by default
 ## cwstfile     => $wstfile, ##-- idsplice output file [default="$outdir/$outbase.cwst.xml"]
 ##
 ##-- tcfencode data (see DTA::TokWrap::Processor::tcfencode)
 tcfdoc   => $tcfdoc,     ##-- XML::LibXML::Document representing TCF-encoded data
 tcffile  => $tcffile,    ##-- TCF file
 tcflang  => $lang,       ##-- TCF language attribute (default: 'de')
 ##
 ##-- tcftokenize data (see DTA::TokWrap::Processor::tcftokenize)
 tcftokdoc => $tcftokdoc,    ##-- XML::LibXML::Document representing tokenized TCF data (== $tcfdoc)
 tcftokfile => $tcftokfile,  ##-- tcf-tokenized file
 ##
 ##-- tcfdecode0 data (see DTA::TokWrap::Processor::tcfdecode0)
 tcfxfile => $tcfxfile,   ##-- tcf-decoded base xml file [default="$tmpdir/$outbase.tcfx"]
 tcfxdata => $tcfxdata,   ##-- tcf-decoded base xml data
 tcftfile => $tcftfile,   ##-- tcf-decoded serial text file [default="$tmpdir/$outbase.tcft"]
 tcftdata => $tcftdata,   ##-- tcf-decoded serial txt data
 tcfwdata => $tcfwdata,   ##-- tcf-decoded token data, tt-format: "TEXT\tSID/WID\n"
 tcfwfile => $tcfwfile,   ##-- tcf-decoded token file, tt-format [default="$tmpdir/$outbase.tcfw"]
 tcfadata => $tcfadata,   ##-- tcf-decoded token attributes for idsplice, data
 tcfafile => $tcfafile,   ##-- tcf-decoded token attributes for idsplice, file [default="$tmpdir/$outbase.tcfa"]
 ##
 ##-- tcfalign data (PROXIED, see DTA::TokWrap::Processor::tcfalign : uses tokdata1,tokfile1)
 ##-- tcf2txml data (PROXIED, see DTA::TokWrap::Processor::tok2xml : uses tokfile1,cxfile,bxfile,xtokdata)
 ##-- tcfdecode data
 tcfcwsfile => $tcfcwsfile, ##-- tcf-decoded+aligned+ws-spliced output file (default="$outdir/$outbase.tcfws.xml")


=item defaults

 %defaults = CLASS->defaults();

Static object defaults.

=item init

 $doc = $doc->init();

Set computed object defaults.

=item DESTROY

 $doc->DESTROY();

Destructor.  Implicitly calls L<close()|/close>.

=back

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document: Methods: Pseudo-I/O
=pod

=head2 Methods: Pseudo-I/O

=over 4

=item open

 $newdoc = $CLASS_OR_OBJECT->open($xmlfile,%docNewOptions);

Wrapper for L<$CLASS_OR_OBJECT-E<gt>new()|/new>, with some additional sanity checks.

=item close

 $bool = $doc->close();
 $bool = $doc->close($is_destructor);

"Closes" document $doc, adding profiling information to
$doc-E<gt>{tw} if present.

Unlinks any temporary files in $doc unless $doc-E<gt>{keeptmp} is true.
All %$doc keys ending in 'file' are considered 'temporary' files, except:
xmlfile, xtokfile, sosfile, sowfile, soafile

If $is_destructor is false (default), resets all keys in %$doc to
default values (thus making $doc essentially unuseable).

=item notempkeys

 @notempkeys = $doc->notempkeys();

Returns list of document keys ending 'file' which are not considered "temporary"
Used by L<$doc-E<gt>tempfiles()|/tempfiles>.

=item tempfiles

 @tempfiles = $doc->tempfiles();

Returns list of temporary filenames which have been generated by $doc,
or an empty list if $doc-E<gt>{keeptmp} is true.  Used by $doc-E<gt>close().

Checks $doc-E<gt>{"${filekey}_stamp"} to determine whether this document generated
the file named by $doc-E<gt>{"$filekey"}.

Implementation: returns values of all %$doc keys ending with 'file' except for
those returned by $doc-E<gt>notempkeys()

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document: Methods: pseudo-pseudo-make
=pod

=head2 Methods: pseudo-pseudo-make

=over 4

=item %KEYGEN

 %KEYGEN = ($dataKey => $generatorSpec, ...)

Low-level hash mapping data keys to the generating processes (subroutines, classes, ...).

$generatorSpec is one of:

 $key      : calls $doc->can($key)->($doc)
 \&coderef : calls &coderef($doc)
 \@array   : array of atomic $generatorSpecs (keys or CODE-refs)

=item genKey

 $bool = $doc->genKey($key);
 $bool = $doc->genKey($key,\%KEYGEN)

(Re-)generate a data key (single step only, ignoring dependencies).
An argument $key without a value $KEYGEN{$key} triggers an error.

=item makeKey

 $keyval_or_undef = $doc->makeKey($key);

Just an alias for $doc-E<gt>genKey($key) here,
but see
L<DTA::TokWrap::Document::Maker|DTA::TokWrap::Document::Maker/makeKey>
for a more sophisticated implementation

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document: Methods: Low-Level: generator-subclass wrappers
=pod

=head2 Methods: Low-Level: generator-subclass wrappers

=over 4

=item mkindex

 $doc_or_undef = $doc->mkindex($mkindex);
 $doc_or_undef = $doc->mkindex();

see L<DTA::TokWrap::Processor::mkindex::mkindex()|DTA::TokWrap::Processor::mkindex/mkindex>.

=item mkbx0

 $doc_or_undef = $doc->mkbx0($mkbx0);
 $doc_or_undef = $doc->mkbx0();

see L<DTA::TokWrap::Processor::mkbx0::mkbx0()|DTA::TokWrap::Processor::mkbx0/mkbx0>

=item mkbx

 $doc_or_undef = $doc->mkbx($mkbx);
 $doc_or_undef = $doc->mkbx();

see L<DTA::TokWrap::Processor::mkbx::mkbx()|DTA::TokWrap::Processor::mkbx/mkbx>.

=item tokenize

 $doc_or_undef = $doc->tokenize($tokenize);
 $doc_or_undef = $doc->tokenize();

see
L<DTA::TokWrap::Processor::tokenize::tokenize()|DTA::TokWrap::Processor::tokenize/tokenize>,
L<DTA::TokWrap::Processor::tokenize::http::tokenize()|DTA::TokWrap::Processor::tokenize::http/tokenize>,
L<DTA::TokWrap::Processor::tokenize::tomasotath::tokenize()|DTA::TokWrap::Processor::tokenize::tomastotath/tokenize>,
L<DTA::TokWrap::Processor::tokenize::dummy::tokenize()|DTA::TokWrap::Processor::tokenize::dummy/tokenize>.

Default tokenizer subclass is given by package-global $TOKENIZE_CLASS.

=item tokenize1

 $doc_or_undef = $doc->tokenize1($tokenize1);
 $doc_or_undef = $doc->tokenize1();

see
L<DTA::TokWrap::Processor::tokenize1::tokenize1()|DTA::TokWrap::Processor::tokenize1/tokenize1>.

=item tok2xml

 $doc_or_undef = $doc->tok2xml($tok2xml);
 $doc_or_undef = $doc->tok2xml();

see L<DTA::TokWrap::Processor::tok2xml::tok2xml()|DTA::TokWrap::Processor::tok2xml/tok2xml>.

=item txmlanno

 $doc_or_undef = $doc->txmlanno($txmlanno);
 $doc_or_undef = $doc->txmlanno();

see L<DTA::TokWrap::Processor::txmlanno::txmlanno()|DTA::TokWrap::Processor::txmlanno/txmlanno>.

=item addws

 $doc_or_undef = $doc->addws($addws);
 $doc_or_undef = $doc->addws();

see L<DTA::TokWrap::Processor::addws::addws()|DTA::TokWrap::Processor::addws/addws>.

=item idsplice

 $doc_or_undef = $doc->idsplice($addws);
 $doc_or_undef = $doc->idsplice();

see L<DTA::TokWrap::Processor::idsplice::idsplice()|DTA::TokWrap::Processor::idsplice/idsplice>.

=item tcfencode

 $doc_or_undef = $doc->tcfencode($tcfencode)
 $doc_or_undef = $doc->tcfencode()

see L<DTA::TokWrap::Processor::tcfencode::tcfencode()|DTA::TokWrap::Processor::tcfencode/tcfencode>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document: Methods: Member I/O
=pod

=head2 Methods: Member I/O

=over 4

=item loadBx0File

 $bx0doc_or_undef = $doc->loadBx0File($filename_or_fh);
 $bx0doc_or_undef = $doc->loadBx0File();

loads $doc-E<gt>{bx0doc} from $filename_or_fh (default=$doc-E<gt>{bx0file})

=item loadBxFile

 $cxdata_or_undef = $doc->loadBxFile($bxfile_or_fh,$txtfile_or_fh);
 $cxdata_or_undef = $doc->loadBxFile();

loads $doc-E<gt>{bxdata} from @$doc{qw(bxfile txtfile)}

requires $doc-E<gt>{txfile}

=item loadCxFile

 $cxdata_or_undef = $doc->loadCxFile($filename_or_fh);
 $cxdata_or_undef = $doc->loadCxFile();

loads $doc-E<gt>{cxdata} from $filename_or_fh (default=$doc-E<gt>{cxfile}).

$doc-E<gt>{cxdata} = [ $cx0, ... ], where:

=over 4

=item *

each $cx = [ $id, $xoff,$xlen, $toff,$tlen, $text, @attrs ]

=item *

package globals $CX_ID, $CX_XOFF, etc. are indices for $cx arrays

=back

=item loadTokFileN

 \$tokdata_or_undef = $doc->loadTokFileN($n,$filename_or_fh);
 \$tokdata_or_undef = $doc->loadTokFileN($n);

loads $doc-E<gt>{"tokdata${n}"} from $filename_or_fh (default=$doc-E<gt>{"tokfile${n}"})

=item loadTokFile0

 \$tokdata0_or_undef = $doc->loadTokFile0(@args)

Wrapper for $doc-E<gt>loadTokFileN(0,@args)

=item loadTokFile1

 \$tokdata1_or_undef = $doc->loadTokFile1(@args)

Wrapper for $doc-E<gt>loadTokFileN(1,@args)

=item loadXtokFile

 \$xtokdata_or_undef = $doc->loadXtokFile($filename_or_fh);
 \$xtokdata_or_undef = $doc->loadXtokFile();

loads $doc-E<gt>{xtokdata} from $filename_or_fh (default=$doc-E<gt>{xtokfile})

see also L<$doc-E<gt>xtokDoc()|/xtokDoc>.


=item xtokDoc

 $xtokDoc = $doc->xtokDoc(\$xtokdata);
 $xtokDoc = $doc->xtokDoc();

parse \$xtokdata (default: \$doc-E<gt>{xtokdata}) string into $doc-E<gt>{xtokdoc}

B<warning>: may call $doc-E<gt>tok2xml()

=item loadXmlData

 $xmlbuf_or_undef = $doc-E<gt>loadXmlData($filename_or_fh)
 $xmlbuf_or_undef = $doc-E<gt>loadXmlData()

loads $doc->{xmldata} from $filename_or_fh (default=$doc-E<gt>{xmlfile}).

=item loadCwsData

 \$xmlbuf_or_undef = $doc->loadCwsData($filename_or_fh)
 \$xmlbuf_or_undef = $doc->LoadCwsData()

B<DEPRECATED>

loads $doc-E<gt>{cwsdata} from $filename_or_fh (default=$doc-E<gt>{cwsfile}).

=item loadTxtData

 \$txtbuf_or_undef = $doc->loadTxtData($filename_or_fh)
 \$txtbuf_or_undef = $doc->loadTxtData()

loads $doc-E<gt>{txtdata} from $filename_or_fh (default=$doc-E<gt>{txtfile})

=item saveBx0File

 $file_or_undef = $doc->saveBx0File($filename_or_fh,$bx0doc,%opts);
 $file_or_undef = $doc->saveBx0File($filename_or_fh);
 $file_or_undef = $doc->saveBx0File();

Saves $bx0doc (default=$doc-E<gt>{bx0doc})
to $filename_or_fh (default=$docE<gt>{bx0file}="$doc-E<gt>{outdir}/$doc-E<gt>{outbase}.bx0"),
and sets both $docE<gt>{bx0file} and $doc-E<gt>{bx0file_stamp}.

%opts:

 format => $level,  ##-- output format (default=$doc-E<gt>{format})

=item saveBxFile

 $file_or_undef = $doc->saveBxFile($filename_or_fh,\@blocks);
 $file_or_undef = $doc->saveBxFile($filename_or_fh);
 $file_or_undef = $doc->saveBxFile();

Saves text-block data \@blocks (default=$doc-E<gt>{bxdata})
to $filename_of_fh (default=$doc-E<gt>{bxfile}),
and sets both $doc-E<gt>{bxfile} and $doc-E<gt>{bxfile_stamp}.

=item saveTxtFile

 $file_or_undef = $doc->saveTxtFile($filename_or_fh,\@blocks,%opts);
 $file_or_undef = $doc->saveTxtFile($filename_or_fh);
 $file_or_undef = $doc->saveTxtFile();

Saves serialized text extracted from \@blocks (default=$doc-E<gt>{bxdata})
to $filename_or_fh (default=$doc-E<gt>{txtfile}="$doc-E<gt>{outdir}/$doc-E<gt>{outbase}.txt"),
and sets both $doc-E<gt>{txtfile} and $doc-E<gt>{txtfile_stamp}.

%opts:

 debug=>$bool,  ##-- if true, debugging text will be printed (and saveBxFile() offsets will be wrong)

=item saveTokFileN

 $file_or_undef = $doc->saveTokFileN($n,$filename_or_fh,\$tokdata);
 $file_or_undef = $doc->saveTokFileN($n,$filename_or_fh);
 $file_or_undef = $doc->saveTokFileN($n);

Saves tokenizer output data string $tokdata (default=$doc-E<gt>{"tokdata${n}"})
to $filename_or_fh (default=$doc-E<gt>{"tokfile${n}"}="$doc-E<gt>{outdir}/$doc-E<gt>{outbase}.t${n}"),
and sets both $doc-E<gt>{"tokfile${n}"} and $doc-E<gt>{"tokfile_stamp${n}"}.


=item saveTokFile0

 $file_or_undef = $doc->saveTokFile0(@args)

Wrapper for $doc-E<gt>saveTokFileN(0,@args)

=item saveTokFile1

 $file_or_undef = $doc->saveTokFile1(@args)

Wrapper for $doc-E<gt>saveTokFileN(1,@args)

=item saveXtokFile

 $file_or_undef = $doc->saveXtokFile($filename_or_fh,\$xtokdata,%opts);
 $file_or_undef = $doc->saveXtokFile($filename_or_fh);
 $file_or_undef = $doc->saveXtokFile();

Saves XML-ified master tokenizer data string $xtokdata (default=$doc-E<gt>{xtokdata})
to $filename_or_fh (default=$doc-E<gt>{xtokfile}="$doc-E<gt>{outdir}/$doc-E<gt>{outbase}.t.xml"),
and sets both $doc-E<gt>{xtokfile} and $doc-E<gt>{xtokfile_stamp}.

=item saveTcfFile

 $file_or_undef = $doc->saveTcfFile($filename_or_fh,$tcfdoc,%opts)
 $file_or_undef = $doc->saveTcfFile($filename_or_fh)
 $file_or_undef = $doc->saveTcfFile()

known %opts:

 format => $level, ##-- formatting level (default=1)

Saves TCF-encoded document $tcfdoc (default=$doc-E<gt>{tcfdoc}) to $filename_or_fh
(default=$doc-E<gt>{tcffile}="$doc-E<gt>{outdir}/$doc-E<gt>{outbase}.t.xml"),
and sets $doc-E<gt>{tcffile_stamp}.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Document: Methods: Profiling
=pod

=head2 Methods: Profiling

=over 4

=item nTokens

 $ntoks_or_undef = $doc->nTokens();

Returns number of tokens in the currently opened document, if known.

=item nXmlBytes

 $nxbytes_or_undef = $doc->nXmlBytes();

Returns the number of bytes in the base-format XML file, if known
(and it B<should> always be known!).

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


