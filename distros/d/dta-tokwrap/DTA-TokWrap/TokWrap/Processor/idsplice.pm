## -*- Mode: CPerl; coding: utf-8; -*-

## File: DTA::TokWrap::Processor::idsplice.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Descript: DTA tokenizer wrappers: base.xml + so.xml -> base+so.xml
##  + splices in attributes and content from selected so.xml into base.xml by id-matching
##  + formerly implemented in external script dtatw-splice.perl

package DTA::TokWrap::Processor::idsplice;

use DTA::TokWrap::Version;
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:progs :files :slurp :time :xmlutils :numeric);
use DTA::TokWrap::Processor;

use IO::Handle;
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

##==============================================================================
## Constructors etc.
##==============================================================================

## $p = CLASS_OR_OBJ->new(%args)
## %defaults = CLASS->defaults()
##  + static class-dependent defaults
##  + %args, %defaults, %$p:
##    (
##     ##-- configuration options
##     soIgnoreAttrs => \@attrs,	##-- standoff attributes to ignore (default:none)
##     soIgnoreElts  => \%elts,		##-- standoff elements to ignore (default:none)
##     soKeepText    => $keepText,	##-- retain standoff text content? (default:true)
##     soKeepBlanks  => $keepBlanks,	##-- retain standoff whitespace? (default:false)
##     wrapOldContent => $elt,		##-- element in which to wrap old base content (default:undef:none)
##     spliceInfo => $level, 		##-- log-level for summary (default='debug')
##
##     ##-- low-level data
##     xp_so   => $xp_so,	##-- XML::Parser object for standoff file
##     xp_base => $xp_base,	##-- XML::Parser object for base file
##     outfh => $fh,		##-- output handle
##    )
sub defaults {
  my $that = shift;
  return (
	  ##-- inherited
	  $that->SUPER::defaults(),

	  ##-- user attributes
	  soIgnoreAttrs => [],
	  soIgnoreElts  => {},
	  soKeepText    => 1,
	  soKeepBlanks  => 0,
	  wrapOldContent => undef,
	  spliceInfo => 'debug',

	  ##-- low-level
	 );
}

##----------------------------------------------------------------------
## $p = $p->init()
##  compute dynamic object-dependent defaults
sub init {
  my $p = shift;

  ##-- parse: soIgnoreAttrs
  if (defined($p->{soIgnoreAttrs}) && !UNIVERSAL::isa($p->{soIgnoreAttrs},'ARRAY')) {
    if (!ref($p->{soIgnoreAttrs})) {
      $p->{soIgnoreAttrs} = [grep {defined($_)} split(/[\s\,\|]+/,$p->{soIgnoreAttrs})];
    } elsif (UNIVERSAL::isa($p->{soIgnoreAttrs},'HASH')) {
      $p->{soIgnoreAttrs} = [keys %{$p->{soIgnoreAttrs}}];
    } else {
      $p->logconfess("init(): could not parse soIgnoreAttrs=$p->{soIgnoreAttrs} as ARRAY");
    }
  }

  ##-- parse: soIngoreElts
  if (defined($p->{soIgnoreElts}) && !UNIVERSAL::isa($p->{soIgnoreElts},'HASH')) {
    if (!ref($p->{soIgnoreElts})) {
      $p->{soIgnoreElts} = {map {($_=>undef)} grep {defined($_)} split(/[\s\,\|]+/,$p->{soIgnoreElts})};
    } elsif (UNIVERSAL::isa($p->{soIgnoreAttrs},'ARRAY')) {
      $p->{soIgnoreElts} = {map {($_=>undef)} @{$p->{soIgnoreElts}}};
    } else {
      $p->logconfess("init(): could not parse soIgnoreElts=$p->{soIgnoreElts} as HASH");
    }
  }

  return $p;
}

##==============================================================================
## Methods: Utils
##==============================================================================

##----------------------------------------------------------------------
## ($xp_so,$xp_base) = $p->xmlParsers()
##   + returns cached @$p{qw(xp_so xp_base)} if available, otherwise creates new ones
sub xmlParsers {
  my $p = shift;
  return @$p{qw(xp_so xp_base)} if (ref($p) && defined($p->{xp_so}) && defined($p->{xp_base}));

  ##-- labels
  my $prog = ref($p).": ".(Log::Log4perl::MDC->get('xmlbase')||'');

  ##--------------------------------------------------------------
  ## closure variables
  my ($_xp, $_elt, %_attrs);
  my @xids = qw();        ##-- stack of nearest-ancestor (xml:)?id values; 1 entry for each currently open element
  my $xid = undef;    	  ##-- (xml:)?id of most recently opened element with an id
  my %so_attrs = qw();	  ##-- %so_attrs   = ($id => \%attrs, ...)
  my %so_content = qw();  ##-- %so_content = ($id => $content, ...)
  my ($soIgnoreAttrs,$soIgnoreElts,$soKeepText,$soKeepBlanks); ##-- options

  ##--------------------------------------------------------------
  ## XML::Parser: standoff

  ##----------------------------
  ## undef = cb_init($expat)
  my $so_cb_init = sub {
    #($_xp) = @_;
    $soIgnoreAttrs = $p->{soIgnoreAttrs} || [];
    $soIgnoreElts  = $p->{soIgnoreElts}  || {};
    $soKeepText    = $p->{soKeepText};
    $soKeepBlanks  = $p->{soKeepBlanks};
    @xids       = qw();
    $xid        = undef;
    %so_attrs   = qw();
    %so_content = qw();

    ##-- debug
    $p->{so_attrs}   = \%so_attrs;
    $p->{so_content} = \%so_content;
    $p->{xids}       = \@xids;
    $p->{xidr}       = \$xid;
  };

  ##----------------------------
  ## undef = cb_start($expat, $elt,%attrs)
  my ($eid);
  my $so_cb_start = sub {
    %_attrs = @_[2..$#_];
    if (defined($eid = $_attrs{'id'} || $_attrs{'xml:id'})) {
      delete(@_attrs{qw(id xml:id),@$soIgnoreAttrs});
      $so_attrs{$eid} = {%_attrs} if (%_attrs);
      $xid = $eid;
    }
    push(@xids,$xid);
    $_[0]->default_current if (!defined($eid) && !exists($soIgnoreElts->{$_[1]}));
  };

  ##----------------------------
  ## undef = cb_end($expat,$elt)
  my $so_cb_end = sub {
    $eid=pop(@xids);
    $xid=$xids[$#xids];
    $_[0]->default_current if (!exists($soIgnoreElts->{$_[1]}) && (!defined($eid) || !defined($xid) || $eid eq $xid));
  };

  ##----------------------------
  ### undef = cb_char($expat,$string)
  my $so_cb_char = sub {
    $_[0]->default_current() if ($soKeepText);
  };

  ##----------------------------
  ## undef = cb_default($expat, $str)
  my $so_cb_default = sub {
    $so_content{$xid} .= $_[0]->original_string if (defined($xid));
  };

  ##----------------------------
  ## undef = cb_final($expat)
  my ($content);
  my $so_cb_final = sub {
    if (!$soKeepBlanks) {
      foreach $xid (keys %so_content) {
	$content = $so_content{$xid};
	$content =~ s/\s+/ /sg;
	if ($content =~ /^\s*$/) {
	  delete($so_content{$xid});
	} else {
	  $so_content{$xid} = $content;
	}
      }
    }
  };

  ##----------------------------
  ## XML::Parser: standoff: init
  $p->{xp_so} = XML::Parser->new(
				 ErrorContext => 1,
				 ProtocolEncoding => 'UTF-8',
				 #ParseParamEnt => '???',
				 Handlers => {
					      Init  => $so_cb_init,
					      Start => $so_cb_start,
					      End   => $so_cb_end,
					      Char  => $so_cb_char,
					      Default => $so_cb_default,
					      Final => $so_cb_final,
					     },
			   )
    or $p->logconfess("couldn't create XML::Parser for standoff file");


  ##--------------------------------------------------------------
  ## XML::Parser: base

  my ($n_merged_attrs,$n_merged_content,$old_content_elt,@wrapstack);
  my ($outfh);

  ##----------------------------
  ## undef = cb_init($expat)
  my $base_cb_init = sub {
    #($_xp) = @_;
    $n_merged_attrs = 0;
    $n_merged_content = 0;
    $old_content_elt = $p->{wrapOldContent};
    @wrapstack = qw();
    $outfh     = $p->{outfh};

    ##-- debug
    $p->{wrapstack} = \@wrapstack;
    $p->{n_merged_attrs_ref} = \$n_merged_attrs;
    $p->{n_merged_content_ref} = \$n_merged_content;
  };

  ##----------------------------
  ## undef = cb_final($expat)
  my $base_cb_final = sub {
    $p->{nMergedAttrs}   = $n_merged_attrs;
    $p->{nMergedContent} = $n_merged_content;
  };

  ##----------------------------
  ## undef = cb_start($expat, $elt,%attrs)
  my ($is_empty, $so_attrs, $id);
  my $base_cb_start = sub {
    #($_xp,$_elt,%_attrs) = @_;
    %_attrs = @_[2..$#_];
    push(@wrapstack,undef);
    return $_[0]->default_current if (!defined($id=$_attrs{'id'} || $_attrs{'xml:id'}));

    ##-- merge in standoff attributes if available (clobber)
    if (defined($so_attrs=$so_attrs{$id})) {
      %_attrs = (%_attrs, %$so_attrs);
      $n_merged_attrs++;
    }
    $outfh->print(join(' ',"<$_[1]", map {"$_=\"".xmlesc($_attrs{$_}).'"'} keys %_attrs)) if ($outfh);

    ##-- merge in standoff content if available (prepend)
    $is_empty = ($_[0]->original_string =~ m|/>$|);
    $wrapstack[$#wrapstack] = $old_content_elt if (!$is_empty);
    if (defined($content=$so_content{$id})) {
      $outfh->print(">", $content, ($is_empty ? "</$_[1]>" : ($old_content_elt ? "<$old_content_elt>" : qw()))) if ($outfh);
      $n_merged_content++;
    }
    elsif ($is_empty && $outfh) {
      $outfh->print("/>");
    }
    elsif ($outfh) {
      $outfh->print(">", ($old_content_elt ? "<$old_content_elt>" : qw()));
    }
  };

  ##----------------------------
  ## undef = cb_end($expat, $elt)
  my ($wrap);
  my $base_cb_end = sub {
    #($_xp,$_elt) = @_;
    $wrap = pop(@wrapstack);
    $outfh->print("</$wrap>") if ($wrap && $outfh);
    $_[0]->default_current;
  };

  ##----------------------------
  ## undef = cb_default($expat, $str)
  my $base_cb_default = sub {
    $outfh->print($_[0]->original_string) if ($outfh);
  };

  ##----------------------------
  ## XML::Parser: standoff: init
  $p->{xp_base} = XML::Parser->new(
				  ErrorContext => 1,
				  ProtocolEncoding => 'UTF-8',
				  #ParseParamEnt => '???',
				  Handlers => {
					       Init    => $base_cb_init,
					       Final   => $base_cb_final,
					       Start   => $base_cb_start,
					       End     => $base_cb_end,
					       Default => $base_cb_default,
					      },
			       )
    or $p->logconfess("couldn't create XML::Parser for base file");


  ##--------------------------------------------------------------
  ## return
  return @$p{qw(xp_so xp_base)};
}

##==============================================================================
## Methods: Simple OO interface

## $p = $p->splice_so(%opts)
##  + %opts:
##     base => $filename_or_fh_or_scalar_ref,
##     so   => $filename_or_fh_or_scalar_ref,
##     out  => $filename_or_fh_or_scalar_ref, ##-- optional
##     basename => $basename,
sub splice_so {
  my ($p,%opts) = @_;

  ##-- sanity check(s)
  Log::Log4perl::MDC->put("xmlbase", $opts{basename}) if (defined($opts{basename}) && !Log::Log4perl::MDC->get('xmlbase'));
  $p->logconfess("splice_so(): no 'base' key defined!") if (!defined($opts{base}));
  $p->logconfess("splice_so(): no 'so' key defined!") if (!defined($opts{so}));

  ##-- get parsers
  my ($xp_so,$xp_base) = $p->xmlParsers();

  ##-- setup $p->{outfh}
  if (ref($opts{out}) && UNIVERSAL::isa($opts{out},'SCALAR')) {
    $p->{outfh} = IO::Handle->new();
    CORE::open($p->{outfh},">",$opts{out})
	or $p->logconfess("could not open buffer as string: $!");
  } elsif (ref($opts{out})) {
    $p->{outfh} = $opts{out};
  } else {
    $p->{outfh} = IO::File->new(">$opts{out}")
      or $p->logconfess("could not open output file '$opts{out}': $!");
  }

  ##-- parse standoff
  if (!ref($opts{so})) {
    if (!$opts{so} || $opts{so} eq '-') {
      $p->vlog($p->{traceLevel}, "splice_so(): parse standoff pipe - (stdin)");
      $xp_so->parse(\*STDIN);
    } else {
      $p->vlog($p->{traceLevel}, "splice_so(): parse standoff file $opts{so}");
      $xp_so->parsefile($opts{so});
    }
  } elsif (UNIVERSAL::isa($opts{so},'SCALAR')) {
    $p->vlog($p->{traceLevel}, "splice_so(): parse standoff buffer");
    $xp_so->parse(${$opts{so}});
  } else {
    $p->vlog($p->{traceLevel}, "splice_so(): parse standoff filehandle");
    $xp_so->parse($opts{so});
  }

  ##-- parse source
  if (!ref($opts{base})) {
    if (!$opts{base} || $opts{base} eq '-') {
      $p->vlog($p->{traceLevel}, "splice_so(): parse base pipe - (stdin)");
      $xp_base->parse(\*STDIN);
    } else {
      $p->vlog($p->{traceLevel}, "splice_so(): parse base file $opts{base}");
      $xp_base->parsefile($opts{base});
    }
  } elsif (UNIVERSAL::isa($opts{base},'SCALAR')) {
    $p->vlog($p->{traceLevel}, "splice_so(): parse base buffer");
    $xp_base->parse(${$opts{base}});
  } else {
    $p->vlog($p->{traceLevel}, "splice_so(): parse base filehandle");
    $xp_base->parse($opts{base});
  }

  ##-- close up
  delete($p->{outfh});
  $p->vlog($p->{spliceInfo}, $_) foreach ($p->summary((!ref($opts{base}) ? $opts{base} : undef),
						      (!ref($opts{so})   ? $opts{so}   : undef)));
  return $p;
}


## @msgs = $p->summary()
## @msgs = $p->summary($baselabel)
## @msgs = $p->summary($baselabel,$solabel)
##  + info messages
sub summary {
  my ($p,$baselab,$solab) = @_;
  return (
	  ("merged " . pctstr($p->{nMergedAttrs}, scalar(keys %{$p->{so_attrs}}), 'attribute-lists')
	   .' and '  . pctstr($p->{nMergedContent}, scalar(keys %{$p->{so_content}}), 'content-strings')
	   .($solab ? " from $solab" : '')
	   .($baselab ? " into $baselab" : '')
	  ),
	 );
}

##==============================================================================
## Methods: Document Processing
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->idsplice($doc)
## + $doc is a DTA::TokWrap::Document object
## + %$doc keys:
##    cwstbasebufr => \$data,	##-- (input) preferred: base data-ref (default=\$doc->{cwsdata})
##    cwstbasefile => $file,	##-- (input) fallback : base file (default=$doc->{cwsfile})
##    cwstsobufr   => \$data,	##-- (input) preferred: standoff data-ref (default=\$doc->{xtokdata})
##    cwstsofile   => $file,	##-- (input) fallback : standoff file (default=$doc->{xtokfile})
##    cwstbufr	   => \$data,   ##-- (output) preferred: output buffer
##    cwstfile	   => $filee,   ##-- (output) fallback: output filename
##    idsplice_stamp0 => $f,    ##-- (output) timestamp of operation begin
##    idsplice_stamp  => $f,    ##-- (output) timestamp of operation end
sub idsplice {
  my ($p,$doc) = @_;
  $doc->setLogContext();

  ##-- log, stamp
  $p->vlog($p->{traceLevel},"idsplice()");
  $doc->{idsplice_stamp0} = timestamp();

  ##-- sanity check(s)
  $p = $p->new() if (!ref($p));
  $doc->{cwstbasebufr} = \$doc->{cwsdata}  if (!exists($doc->{cwstbasebufr}) && defined($doc->{cwsdata}));
  $doc->{cwstsobufr}   = \$doc->{xtokdata} if (!exists($doc->{cwstsobufr}) && defined($doc->{xtokdata}));

  ##-- splice: underlying call
  $p->splice_so(base=>($doc->{cwstbasebufr}||$doc->{cwstbasefile}),
		so  =>($doc->{cwstsobufr}||$doc->{cwstsofile}),
		out =>($doc->{cwstbufr}||$doc->{cwstfile}),
	       );

  ##-- finalize
  $doc->{idsplice_stamp} = timestamp(); ##-- stamp
  return $doc;
}

1; ##-- be happy
__END__
