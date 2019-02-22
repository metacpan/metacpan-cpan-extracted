## -*- Mode: CPerl; coding: utf-8; -*-

## File: DTA::TokWrap::Processor::tok2xml.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Descript: DTA tokenizer wrappers: xml + t.xml --> cws.xml

package DTA::TokWrap::Processor::addws;

use DTA::TokWrap::Version;
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:progs :files :slurp :time);
use DTA::TokWrap::Processor;

use IO::File;
use XML::Parser;
use Carp;
use strict;

#use utf8;
use bytes;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::TokWrap::Processor);

##-- constants for accessing $wseg,$sseg structures
our $SEG_XREF = 0;
our $SEG_XOFF = 1;
our $SEG_XLEN = 2;
our $SEG_SEGI = 3;
our $SEG_SID   = 4;
our $SEG_SBEGI = 5;
our $SEG_SPRVI = 6;
our $SEG_SNXTI = 7;
our $SEG_SEND  = 8;

##==============================================================================
## Constructors etc.
##==============================================================================

## $p = CLASS_OR_OBJ->new(%args)
## %defaults = CLASS->defaults()
##  + static class-dependent defaults
##  + %args, %defaults, %$p:
##    (
##     ##-- configuration options
##     wIdAttr => $attr,	##-- attribute in which to place literal id for <w>-fragments
##     sIdAttr => $attr,	##-- attribute in which to place literal id for <s>-fragments
##     wExtAttrs => $regex,     ##-- //w attributes to include (default='^(?:t|b)=')
##     sExtAttrs => $regex,     ##-- //s attributes to include (default='^(?:pn)=')
##     addwsInfo => $level, 	##-- log-level for summary (default='debug')
##
##     ##-- low-level data
##     xprs => $xprs,		##-- low-level XML::Parser object
##     w_segs => \@w_segs,	##-- @w_segs = ( $w1seg1, ..., $wIseg1, ..., $wIseg2, ..., $wNsegN )
##				##     + where:
##				##       $wXsegX = [$xref,$xoff,$xlen,$segi, $sid,$sbegi,$sprvi,$snxti,$send]
##				##         $xref = $str, ##-- xml:id of the <w> to which this segment belongs
##				##         $xoff = $int, ##-- byte offset in $srcbuf of this <w>-segment's contents
##				##         $xlen = $int, ##-- byte length in $srcbuf of this <w>-segment's contents
##				##         $segi = $int, ##-- original segment index (+1): 1 <= $segi <= $wid2nsegs{$xref}
##				##         $sid  = $str, ##-- xml:id of the <s> element to which this <w> belongs
##				##         $sbegi = $int,  ##-- <s>-segment index (+1) to be opened before this token
##				##			   ##   : 1 <= $ssegi <= $wid2nsegs{$xref} [see find_s_segments()]
##				##         $sprvi = $int,  ##-- previous <s>-segment index (+1)
##				##         $snxti = $int,  ##-- next <s>-segment index (+1)
##				##         $send  = $bool, ##-- true iff the enclosing <s>-segment should be closed after this <w>-segment
##				##     + @w_segs is sorted in logical (serialized) order
##    wid2nsegs => \%wid2nsegs, ##
##    sid2nsegs => \%sid2nsegs, ##
##    )
sub defaults {
  my $that = shift;
  return (
	  ##-- inherited
	  $that->SUPER::defaults(),

	  ##-- user attributes
	  sIdAttr => 'id',
	  wIdAttr => 'id',
	  sExtAttrs => '^(?:pn)=',
	  wExtAttrs => '^(?:t|b)=',
	  addwsInfo => 'debug',

	  ##-- low-level
	 );
}

## $p = $p->init()
##  compute dynamic object-dependent defaults
#sub init {
#  my $p = shift;
#  return $p;
#}

##==============================================================================
## Methods: Utils
##==============================================================================

##----------------------------------------------------------------------
## $xp = $p->xmlParser()
##   + returns cached $p->{xprs} if available, otherwise creates new one
sub xmlParser {
  my $p = shift;
  return $p->{xprs} if (ref($p) && defined($p->{xprs}));

  ##-- labels
  my $prog = ref($p).": ".Log::Log4perl::MDC->get('xmlbase');

  ##--------------------------------------------------------------
  ## XML::Parser handlers (for standoff .t.xml file WITH //w/@xb attribute)
  my ($_xp, $_elt, %_attrs);
  my ($wid,$sid);  ##-- id of currently open <w> (rsp. <s>), or undef
  my ($nw);	   ##-- number of tokens (//w elements) parsed
  my ($ns);	   ##-- number of sentences (//s elements) parsed
  my ($w_segs,$wid2nsegs,$sid2nsegs) = @$p{qw(w_segs wid2nsegs sid2nsegs)} = ([],{},{});
  my ($sid2attrs,$wid2attrs,$wid2content) = @$p{qw(sid2attrs wid2attrs wid2content)} = ({},{},{});
  my $wattrs_re = $p->{wExtAttrs} ? qr{$p->{wExtAttrs}} : undef;
  my $sattrs_re = $p->{sExtAttrs} ? qr{$p->{sExtAttrs}} : undef;

  ##----------------------------
  ## undef = cb_init($expat)
  my $cb_init = sub {
    $wid        = undef;
    $nw         = 0;
    $ns         = 0;
    @$w_segs    = qw();
    %$wid2nsegs = qw();
    %$sid2nsegs = qw();
    %$sid2attrs = qw();
    %$wid2attrs = qw();
    %$wid2content = qw();
  };

  ##----------------------------
  ## undef = cb_start($expat, $elt,%attrs)
  my ($xb,$xbi,@xbs);
  my $cb_start = sub {
    #($_xp,$_elt,%_attrs) = @_;
    %_attrs = @_[2..$#_];
    if ($_[1] eq 'w') {
      $wid = $_attrs{'id'} || $_attrs{'xml:id'};
      ++$nw;
      if (defined($xb=$_attrs{'xb'})) {
	##-- v0.34-1 .t.xml format: xml-bytes in //w/@xb
	$xbi = 0;
	foreach (split(/\s+/,$xb)) {
	  if (/^([0-9]+)\+([0-9]+)/) {
	    push(@$w_segs,[$wid,$1,$2,++$xbi, $sid,undef,undef,undef,undef]);
	  } else {
	    $_[0]->xpcroak("$prog: could not parse //w/\@xb attribute");
	  }
	}
	$wid2nsegs->{$wid} = $xbi;
	$wid2attrs->{$wid} = ($wattrs_re
			      ? join('', map {m{$wattrs_re} ? " $_" : qw()} ($_[0]->original_string =~ m{(?<=\s)\w+=\"[^\"]*\"}g))
			      : '');
      }
      else {
	$_[0]->xpcroak("$prog: no //w/\@xb attribute defined (do you have DTA::TokWrap >= v0.34-1?)");
      }
    }
    elsif ($_[1] eq 's') {
      $sid = $_attrs{'id'} || $_attrs{'xml:id'};
      $sid2attrs->{$sid} = ($sattrs_re
			    ? join('', map {m{$sattrs_re} ? " $_" : qw()} ($_[0]->original_string =~ m{(?<=\s)\w+=\"[^\"]*\"}g))
			    : '');
      ++$ns;
    }
    else {
      $_[0]->default_current();
    }
  };

  ##----------------------------
  ## undef = cb_end($expat,$elt)
  my $cb_end = sub {
    if    ($_[1] eq 'w') { $wid=undef; }
    elsif ($_[1] eq 's') { $sid=undef; }
    else { $_[0]->default_current(); }
  };

  ##----------------------------
  ## undef = cb_default($expat,$string)
  my $cb_default = sub {
    $wid2content->{$wid} .= $_[0]->original_string() if (defined($wid) && $_[1] !~ /^\s*$/);
  };


  ##----------------------------
  ## undef = cb_final($expat)
  my $cb_final = sub {
    #@w_segs = sort {$a->[$SEG_XOFF] <=> $b->[$SEG_XOFF]} @w_segs; ##-- NOT HERE
    @$p{qw(ns nw w_segs wid2nsegs sid2nsegs)} = ($ns,$nw,$w_segs,$wid2nsegs,$sid2nsegs);
    @$p{qw(sid2attrs wid2attrs wid2content)}  = ($sid2attrs,$wid2attrs,$wid2content);
  };

  ##----------------------------
  ##-- initialize XML::Parser (for .t.xml file)
  $p->{xprs} = XML::Parser->new(
				 ErrorContext => 1,
				 ProtocolEncoding => 'UTF-8',
				 #ParseParamEnt => '???',
				 Handlers => {
					      Init  => $cb_init,
					      Start => $cb_start,
					      End   => $cb_end,
					      Default => $cb_default,
					      Final => $cb_final,
					     },
			   )
    or $p->logconfess("couldn't create XML::Parser for standoff file");

  return $p->{xprs};
}

##----------------------------------------------------------------------
## Subs: compute //s segment attributes in @{$p->{w_segs}}

## undef = $p->find_s_segments()
##  + ppulates @$seg[$SEG_SXLEN,$SEG_SSEGI] for segments in @w_segs=@{$p->{w_segs}}
##  + assumes @w_segs is sorted on serialized (text) document order
sub find_s_segments {
  my $p = shift;
  my $pseg = undef;
  my $off  = 0;
  my ($wxref,$wxoff,$wxlen,$wsegi, $sid);
  my ($ssegi);
  my $sid2cur = {}; ##-- $sid => [$seg_open,$seg_close]
  my $sid2nsegs = $p->{sid2nsegs};
  %$sid2nsegs = qw();
  my $srcbufr = $p->{srcbufr};
  foreach (@{$p->{w_segs}}) {
    ($wxref,$wxoff,$wxlen,$wsegi, $sid) = @$_;

    if ($sid && ($pseg=$sid2cur->{$sid})
	&& $wxoff >= $off
	&& substr($$srcbufr, $off, ($wxoff-$off)) =~ m{^(?:
							 (?:\s)                  ##-- non-markup
						         |(?:<[^>]*/>)           ##-- empty element
							 |(?:<!--[^>]*-->)       ##-- comment
							 |(?:<c\b[^>]*>\s*</c>)  ##-- c (whitespace-only)
							 #|(?:<w\b[^>]*>\s*</w>)  ##-- w-tag (e.g. from OCR)
							)*$}sx
       ) {
      ##-- extend current <s>-segment to enclose this <w>-segment
      $pseg->[1][$SEG_SEND] = 0;
      $pseg->[1]            = $_;
      $_->[$SEG_SEND]       = 1;
     }
    elsif ($sid) {
      ##-- new <s>-segment beginning at this <w>-segment
      $_->[$SEG_SBEGI] = ++$sid2nsegs->{$sid};
      $_->[$SEG_SEND] = 1;
      if ($pseg) {
	$pseg->[0][$SEG_SNXTI] = $_->[$SEG_SBEGI];
	$_->[$SEG_SPRVI]       = $pseg->[0][$SEG_SBEGI];
      }
      $sid2cur->{$sid} = [$_,$_];
    }
    else {
      ##-- no <s>-segment at all at this <w>-segment
      $_->[$SEG_SBEGI] = $_->[$SEG_SEND] = undef;
    }

    $off = $wxoff + $wxlen;
  }
}


##----------------------------------------------------------------------
## Subs: splice segments into base document

## undef = splice_segments($outfh)
##  + splices final segments from @w_segs=@{$p->{w_segs}} into $srcbuf; dumping output to $outfh
##  + sorts @w_segs on xml offset ($SEG_OFF)
sub splice_segments {
  my ($p,$outfh) = @_;
  $p->logconfess("splice_segments(): \$outfh not defined") if (!defined($outfh));
  my ($xref_this,$xref_prev,$xref_next);
  my ($xref,$xoff,$xlen,$segi, $sid,$sbegi,$sprvi,$snxti,$send);
  my ($nwsegs,$nssegs);
  my $off = 0;
  my ($wIdAttr,$sIdAttr)  = @$p{qw(wIdAttr sIdAttr)};
  my ($w_segs,$wid2nsegs,$srcbufr) = @$p{qw(w_segs wid2nsegs srcbufr)};
  my ($sid2attrs,$wid2attrs,$wid2content) = @$p{qw(sid2attrs wid2attrs wid2content)};

  @$w_segs = sort {$a->[$SEG_XOFF] <=> $b->[$SEG_XOFF]} @$w_segs; ##-- sort in source-document order
  foreach (@$w_segs) {
    ##-- common vars
    ($xref,$xoff,$xlen,$segi, $sid,$sbegi,$sprvi,$snxti,$send) = @$_;
    $nwsegs  = $wid2nsegs->{$xref};

    ##-- splice in prefix
    $outfh->print(substr($$srcbufr, $off, ($xoff-$off)));

    ##-- maybe splice in <s>-start-tag
    if ($sbegi) {
      if (!$sprvi && !$snxti) {
	##-- //s-start-tag: single-element item
	$outfh->print("<s $sIdAttr=\"$sid\"", ($sid2attrs->{$sid}//''), ">");
      } else {
	##-- //s-start-tag: multi-segment item
	$xref_this = "${sid}".($sprvi ? "_$sbegi" : '');
	$xref_prev = "${sid}".(($sprvi||1)==1 ? '' : "_${sprvi}");
	$xref_next = "${sid}_".($snxti||'');

	if (!$sprvi) {
	  ##-- //s-start-tag: multi-segment item: initial segment
	  $outfh->print("<s $sIdAttr=\"$xref_this\" next=\"#$xref_next\"", ($sid2attrs->{$sid}//''), ">"); #." part=\"I\""
	} elsif (!$snxti) {
	  ##-- //s-start-tag: multi-segment item: final segment
	  $outfh->print("<s $sIdAttr=\"$xref_this\" prev=\"#$xref_prev\">"); #." part=\"F\" $s_refAttr=\"#$xref\""
	} else {
	  ##-- //s-start-tag: multi-segment item: middle segment
	  $outfh->print("<s $sIdAttr=\"$xref_this\" prev=\"#$xref_prev\" next=\"#$xref_next\">"); #."part=\"M\" $s_refAttr=\"#$xref\""
	}
      }
    }

    ##-- splice in <w>-start-tag
    ## + CHANGED Tue, 20 Mar 2012 16:28:51 +0100 (moocow): dta-tokwrap v0.28
    ##    - use @prev,@next attributes for segmentation
    ##    - keep old @part attributes for compatibility (but throw out $w_refAttr ("n"))
    if ($nwsegs==1) {
      ##-- //w-start-tag: single-segment item
      $outfh->print("<w $wIdAttr=\"$xref\"", ($wid2attrs->{$xref}//''), ">", (defined($wid2content->{$xref}) ? $wid2content->{$xref} : qw()));
    } else {
      ##-- //w-start-tag: multi-segment item
      $xref_this = "${xref}".($segi>1 ? ("_".($segi-1)) : '');
      $xref_prev = "${xref}".($segi>2 ? ("_".($segi-2)) : '');
      $xref_next = "${xref}_${segi}";

      if ($segi==1) {
	##-- //w-start-tag: multi-segment item: initial segment
	$outfh->print("<w $wIdAttr=\"$xref_this\" next=\"#$xref_next\"", ($wid2attrs->{$xref}//''), ">",  #." part=\"I\""
		      (defined($wid2content->{$xref}) ? $wid2content->{$xref} : qw()),
		     );
      } elsif ($segi==$nwsegs) {
	##-- //w-start-tag: multi-segment item: final segment
	$outfh->print("<w $wIdAttr=\"$xref_this\" prev=\"#$xref_prev\">"); #." part=\"F\" $w_refAttr=\"#$xref\""
      } else {
	##-- //w-start-tag: multi-segment item: middle segment
	$outfh->print("<w $wIdAttr=\"$xref_this\" prev=\"#$xref_prev\" next=\"#$xref_next\">"); #." part=\"M\" $w_refAttr=\"#$xref\""
      }
    }

    ##-- //w-segment: splice in content and end-tag(s)
    $outfh->print(substr($$srcbufr,$xoff,$xlen),
		  "</w>",
		  ($send ? "</s>" : qw()));

    ##-- update offset
    $off = $xoff+$xlen;
  }

  ##-- splice in post-token material
  $outfh->print(substr($$srcbufr, $off,length($$srcbufr)-$off));
}


##==============================================================================
## Methods: Document Processing
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->addws($doc,%opts)
## + $doc is a DTA::TokWrap::Document object
## + %opts : document-key overrides
##    xmlkey  => $xmldatakey, ##-- override 'xmldata', 'xmlfile' keys (default='xml')
##    xtokkey => $xtokkey,    ##-- override 'xtokdata', 'xtokfile' keys
##    cwskey  => $cwskey,     ##-- override 'cwsfile', 'cwsfh' keys
## + %$doc keys:
##    xmldata => $xmldata,   ##-- (input) source xml file
##    xtokdata => $xtokdata, ##-- (input) standoff xml-ified tokenizer output: data
##    xtokfile => $xtokfile, ##-- (input) standoff xml-ified tokenizer output: file (only if $xtokdata is missing)
##    cwsfile  => $cwsfile,  ##-- (output) back-spliced xml file
##    cwsfh    => $cwsfh,    ##-- (output) back-spliced xml handle (overrides $cwsfile)
##    addws_stamp0 => $f,    ##-- (output) timestamp of operation begin
##    addws_stamp  => $f,    ##-- (output) timestamp of operation end
##    cwsdata_stamp => $f,   ##-- (output) timestamp of operation end
sub addws {
  my ($p,$doc,%opts) = @_;
  $doc->setLogContext();

  ##-- defaults
  my $xmlkey  = $opts{xmlkey} // $p->{xmlkey} // 'xml';
  my $xtokkey = $opts{xtokkey} // $p->{xtokkey} // 'xtok';
  my $cwskey = $opts{cwskey} // $p->{cwskey} // 'cws';

  ##-- log, stamp
  $p->vlog($p->{traceLevel},"addws(): xmlkey=$xmlkey, xtokkey=$xtokkey, cwskey=$cwskey");
  $doc->{addws_stamp0} = timestamp();

  ##-- sanity check(s)
  $p = $p->new() if (!ref($p));
  ##
  $doc->loadFileData($xmlkey,'') if (!$doc->{"${xmlkey}data"}); ##-- slurp xml source buffer
  $p->logconfess("addws(): no ${xmlkey}data key defined") if (!$doc->{"${xmlkey}data"});
  my $xprs = $p->xmlParser() or $p->logconfes("addws(): could not get XML parser");

  ##-- splice: parse standoff
  $p->vlog($p->{traceLevel},"addws(): parse standoff xml");
  if (defined($doc->{"${xtokkey}data"})) {
    $xprs->parse($doc->{"${xtokkey}data"});
  } else {
    $xprs->parsefile($doc->{"${xtokkey}file"});
  }

  ##-- compute //s segments
  $p->vlog($p->{traceLevel},"addws(): search for //s segments");
  $p->{srcbufr} = \$doc->{"${xmlkey}data"};
  $p->find_s_segments();

  ##-- reprt final assignment
  if (defined($p->{addwsInfo})) {
    my $nseg_w = scalar(@{$p->{w_segs}});
    my $ndis_w = scalar(grep {$_>1} values %{$p->{wid2nsegs}});
    my $pdis_w = ($p->{nw}==0 ? 'NaN' : 100*$ndis_w/$p->{nw});
    ##
    my $nseg_s = 0; $nseg_s += $_ foreach (values %{$p->{sid2nsegs}});
    my $ndis_s = scalar(grep {$_>1} values %{$p->{sid2nsegs}});
    my $pdis_s = ($p->{ns}==0 ? 'NaN' : 100*$ndis_s/$p->{ns});
    ##
    my $dfmt = "%".length($p->{nw})."d";
    $p->vlog($p->{addwsInfo}, sprintf("$dfmt token(s)    in $dfmt segment(s): $dfmt discontinuous (%5.1f%%)", $p->{nw}, $nseg_w, $ndis_w, $pdis_w));
    $p->vlog($p->{addwsInfo}, sprintf("$dfmt sentence(s) in $dfmt segment(s): $dfmt discontinuous (%5.1f%%)", $p->{ns}, $nseg_s, $ndis_s, $pdis_s));
  }

  ##-- output: splice in <w> and <s> segments
  my $cwsfile = $doc->{"${cwskey}file"} // '/dev/null';
  $p->vlog($p->{traceLevel},"addws(): creating $cwsfile");
  my $cwsfh = defined($doc->{"${cwskey}fh"}) ? $doc->{"${cwskey}fh"} : IO::File->new(">$cwsfile");
  $p->logconfess("could not open cwsfile '$cwsfile' for write: $!") if (!defined($cwsfh));
  $p->splice_segments($cwsfh);
  $cwsfh->close();

  ##-- finalize
  $doc->{addws_stamp} = timestamp(); ##-- stamp
  return $doc;
}

1; ##-- be happy
__END__
