## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Processor::mkbx.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: (bx0doc,tx) -> bxdata

package DTA::TokWrap::Processor::mkbx;

use DTA::TokWrap::Version;
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:progs :libxml :libxslt :slurp :time);
use DTA::TokWrap::Processor;
use Encode qw(encode decode encode_utf8 decode_utf8);

use XML::Parser;
use IO::File;
use Carp;
no  bytes;
use strict;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::TokWrap::Processor);

##==============================================================================
## Constructors etc.
##==============================================================================

## $mbx = CLASS_OR_OBJ->new(%args)
## %defaults = CLASS->defaults()
##  + %args, %defaults, %$mbx:
##    (
##     ##-- Block-sorting: hints
##     wbStr => $wbStr,                       ##-- word-break hint text
##     sbStr => $sbStr,                       ##-- sentence-break hint text
##     lbStr => $lbStr,                       ##-- line-break hint text
##     wsStr => $wsStr,                       ##-- whitespace hint text
##     nohints => $bool,                      ##-- if true, set $wbStr=$sbStr=$lbStr=$wsStr="" (i.e. no hints in .txt file)
##     sortkey_attr => $attr,                 ##-- sort-key attribute (default='dta.tw.key'; should jive with mkbx0)
##     ##
##     ##-- Block-sorting: low-level data
##     xp    => $xml_parser,                  ##-- XML::Parser object for parsing $doc->{bx0doc}
##   )
sub defaults {
  my $that = shift;
  return (
	  ##-- inherited
	  $that->SUPER::defaults(),

	  ##-- Block-sorting: hints
	  wbStr => "\n\$WB\$\n",
	  sbStr => "\n\$SB\$\n",
	  lbStr => "\n",
	  wsStr => " ",
	  sortkey_attr => 'dta.tw.key',

	  ##-- Block-sorting: parser
	  xp => undef,
	 );
}

## $mbx = $mbx->init()
sub init {
  my $mbx = shift;

  ##-- ignore hints?
  $mbx->{wbStr}=$mbx->{sbStr}=$mbx->{lbStr}=$mbx->{wsStr}='' if ($mbx->{nohints});

  ##-- create & initialize XML parser
  $mbx->initXmlParser() if (!defined($mbx->{xp}));

  return $mbx;
}

## $xp = $mbx->initXmlParser()
##  + create & initialize $mbx->{xp}, an XML::Parser object
sub initXmlParser {
  my $mbx = shift;

  ##--------------------------------------------
  ## XML::Parser Handlers: closure variables
  my ($blk);         ##-- $blk: global: currently running block
  my ($key);         ##-- $key: global: currently active sort key
  my $blocks = [];   ##-- \@blocks : all parsed blocks
  my $keystack = []; ##-- \@keystack : stack of (inherited) sort keys
  my $key2i = {};    ##-- \%key2i : maps keys to the block-index of their first occurrence, for block-sorting
  #my $id2key = {};   ##-- maps xml:id attributes to their keys (used for serialization of (prev|next)-chains)
  my ($keyAttr);     ##-- $keyAttr : attribute name for sort keys

  ##-- @target_elts : block- and/or hint-like elements
  my @target_elts = qw(c s w lb ws);
  my %target_elts = map {$_=>undef} @target_elts;

  my ($xp,$eltname,%attrs);
  my ($xoff,$toff); ##-- $xoff,$toff: global: current XML-, tx-byte offset
  my ($xlen,$tlen); ##-- $xlen,$tlen: global: current XML-, tx-byte length
  my ($bx0off);     ##-- $bx0off    : global: .bx0 byte-offset of current block

  ##-- save closure data (for debugging)
  @$mbx{qw(blocks keystack key2i)} = ($blocks, $keystack, $key2i);
  @$mbx{qw(blkr keyr)}   = (\$blk, \$key);
  @$mbx{qw(xoffr xlenr)} = (\$xoff,\$xlen);
  @$mbx{qw(toffr tlenr)} = (\$toff,\$tlen);

  ##--------------------------------------------
  ## XML::Parser Handlers: closures

  ##--------------------------------------
  ## undef = cb_init($expat)
  my $cb_init = sub {
    #my ($xp) = shift;

    $keyAttr   = $mbx->{sortkey_attr};
    $blk       = {key=>'__ROOT__',elt=>'__ROOT__',xoff=>0,xlen=>0, toff=>0,tlen=>0,bx0off=>0};
    $key       = $blk->{key};
    $blocks    = [ $blk ];
    $keystack  = [ $key ];
    $key2i     = { $key => 0 };

    ##-- offsets & lengths
    ($xoff,$xlen) = (0,0);
    ($toff,$tlen) = (0,0);
    $bx0off       = 0;

    ##-- save closure data (for debugging)
    @$mbx{qw(blocks keystack key2i)} = ($blocks, $keystack, $key2i);
    @$mbx{qw(blkr keyr)}   = (\$blk, \$key);
    @$mbx{qw(xoffr xlenr)} = (\$xoff,\$xlen);
    @$mbx{qw(toffr tlenr)} = (\$toff,\$tlen);
    $mbx->{bx0offr} = \$bx0off;
  };

  ##--------------------------------------
  ## undef = cb_start($expat, $elt,%attrs)
  my $cb_start = sub {
    ($xp,$eltname,%attrs) = @_;

    ##-- check for sort key
    if (exists($attrs{$keyAttr})) {
      $key = $attrs{$keyAttr};
      $key2i->{$key} = scalar(@$blocks);
    }

    ##-- update key stack
    push(@$keystack,$key);

    ##-- check for target elements
    if (exists($target_elts{$eltname})) {
      ($xlen,$tlen) = (0,0); ##-- hack for hints
      ($xoff,$xlen, $toff,$tlen) = split(/ /,$attrs{n}) if (exists($attrs{n}));
      $bx0off = $xp->current_byte();
      push(@$blocks, $blk={ key=>$key, elt=>$eltname, bx0off=>$bx0off, xoff=>$xoff,xlen=>$xlen, toff=>$toff,tlen=>$tlen });
      if (defined($attrs{text})) {
	##-- literal replacement text (old 'formula' hack)
	#pop(@$blocks); ##-- DEBUG: ignore
	$blk->{text} = $attrs{text};
	@$blk{qw(xoff toff)} = @$blocks ? @{$blocks->[$#$blocks]}{qw(xoff toff)} : (0,0);
	@$blk{qw(xlen tlen)} = (0,0);
      }
    }
  };

  ##--------------------------------------
  ## undef = cb_end($expat, $elt)
  my $cb_end  = sub {
    pop(@$keystack);
    $key = $keystack->[$#$keystack];
  };

  ##--------------------------------------------
  ## XML::Parser object
  $mbx->{xp} = XML::Parser->new(
			       ErrorContext => 1,
			       ProtocolEncoding => 'UTF-8',
			       #ParseParamEnt => '???',
			       Handlers => {
					    Init  => $cb_init,
					    Start => $cb_start,
					    End   => $cb_end,
					    #Char  => $cb_char,
					    #Final => $cb_final,
					   },
			      );

  return $mbx;
}

##==============================================================================
## Methods: mkbx (bx0doc, txfile) => bxdata
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->mkbx($doc)
## + $doc is a DTA::TokWrap::Document object
## + $doc->{bx0doc} should already be populated (else $doc->mkbx0() will be called)
## + %$doc keys:
##    bx0doc  => $bx0doc,  ##-- (input) preliminary block-index data (XML::LibXML::Document)
##    txfile  => $txfile,  ##-- (input) raw text index filename
##    bxdata  => \@blocks, ##-- (output) serialized block index
##    txtdata => $txtbuf,  ##-- (output) raw text buffer
##    mkbx_stamp0 => $f,   ##-- (output) timestamp of operation begin
##    mkbx_stamp  => $f,   ##-- (output) timestamp of operation end
##    bxdata_stamp => $f,  ##-- (output) timestamp of operation end
## + block data: @blocks = ($blk0, ..., $blkN); %$blk =
##   (
##    key    =>$sortkey, ##-- (inherited) sort key
##    elt    =>$eltname, ##-- element name which created this block
##    bx0off =>$bx0off,  ##-- .bx0 byte offset of this block's flag
##    xoff   =>$xoff,    ##-- XML byte offset where this block run begins
##    xlen   =>$xlen,    ##-- XML byte length of this block (0 for hints)
##    toff   =>$toff,    ##-- raw-text byte offset where this block run begins
##    tlen   =>$tlen,    ##-- raw-text byte length of this block (0 for hints)
##    text   =>$text,    ##-- raw-text for this block (overrides toff,tlen,xoff,xlen): e.g. inserted by $mkbx0->{hint_replace_xpaths}
##    otext  =>$otext,   ##-- output text for this block
##    otoff  =>$otoff,   ##-- output text byte offset where this block run begins
##    otlen  =>$otlen,   ##-- output text length (bytes)
##   )
sub mkbx {
  my ($mbx,$doc) = @_;
  $doc->setLogContext(),

  ##-- log, stamp
  $mbx->vlog($mbx->{traceLevel},"mkbx()");
  $doc->{mkbx_stamp0} = timestamp();

  ##-- sanity check(s)
  $mbx = $mbx->new() if (!ref($mbx));
  #$doc->mkbx0() if (!$doc->{bx0doc});
  $mbx->logconfess("mkbx(): no bx0doc key defined")
    if (!$doc->{bx0doc});
  $mbx->logconfess("mkbx(): no .tx file defined")
    if (!$doc->{txfile});
  #$doc->mkindex() if (!-r $doc->{txfile});
  confess(ref($mbx), "::mkbx0(): .tx file '$doc->{txfile}' not readable")
    if (!-r $doc->{txfile});

  ##-- parse bx0doc
  my $bx0str = $doc->{bx0doc}->toString(0);
  $mbx->{xp}->parse($bx0str);

  ##-- prune empty blocks & sort
  my $blocks = $mbx->{blocks};
  $mbx->prune_empty_blocks($blocks);
  $mbx->sort_blocks($blocks);

  ##-- slurp text file
  my $txbuf = '';
  slurp_file($doc->{txfile},\$txbuf);
  $mbx->{txbufr} = \$txbuf; ##-- DEBUG

  ##-- populate block output-text keys
  $mbx->compute_block_text($blocks, \$txbuf);

  ##-- update document: raw bxdata
  $doc->{bxdata} = $blocks;

  ##-- update document: txtdata: tokenizer input text buffer
  $doc->{txtdata} = '';
  my $txtbufr = \$doc->{txtdata};
  $$txtbufr .= $_->{otext} foreach (@$blocks);
  #$$txtbufr .= "\n"; ##-- always terminate text file with a newline (WARNING: can cause dtatw-tok2xml overflow!)

  ##-- hack: txtdata: tokenizer input text buffer
  ##  + workaround for mantis bug #242 (http://odo.dwds.de/mantis/view.php?id=242)
  ##    : '"kontinuierte" quotes @ zeilenanfang --> müll'
  ##  + see also mantis bug #560
  $$txtbufr = decode_utf8($$txtbufr) if (!utf8::is_utf8($$txtbufr));
  my $txtlen= bytes::length($$txtbufr);
  my $quot  = "\x{201c}-\x{201f}\x{275d}-\x{275e}\x{301d}-\x{301f}\x{ab}\x{bb}\"";
  $$txtbufr =~ s/ (\n[^${quot}\n]*[^${quot}\n\s]\ *\n\ *)([${quot}]) / $1."\$QKEEP:$2\$" /ogxe;
  $$txtbufr =~ s/ \n(\ *(?:[${quot}]|\&q(?:uot)?;)) / "\n".(" " x bytes::length($1))     /ogxe;
  $$txtbufr =~ s/ \$QKEEP:([^\$]+)\$	            / $1                                 /ogxe;
  $mbx->logconfess("mkbx(): line-initial quote heuristics changed text length") if (bytes::length($$txtbufr) != $txtlen);
  ##
  ##  + end-of-line quote hack; cf http://kaskade.dwds.de/dtaq/book/view/20001?p=43;hl=niciren
  $$txtbufr =~ s/ ([${quot}]\ *)\n(?!\$)            / "\n".(" " x bytes::length($1)) /ogxe;
  $mbx->logconfess("mkbx(): line-final quote heuristics changed text length") if (bytes::length($$txtbufr) != $txtlen);

  $$txtbufr = encode_utf8($$txtbufr);

  ##-- stamp
  $doc->{mkbx_stamp} = $doc->{bxdata_stamp} = timestamp(); ##-- stamp
  return $doc;
}

## \@blocks = $mbx->prune_empty_blocks(\@blocks)
## \@blocks = $mbx->prune_empty_blocks()
## + removes empty 'c'-type blocks
## + \@blocks defaults to $mbx->{blocks}
sub prune_empty_blocks {
  my ($mbx,$blocks) = @_;
  $blocks  = $mbx->{blocks} if (!$blocks);
  @$blocks = grep { $_->{elt} ne 'c' || defined($_->{text}) || $_->{tlen} > 0 } @$blocks;
  return $blocks;
}

## \@blocks = $mbx->sort_blocks(\@blocks)
##  + sorts \@blocks using $mb->{key2i}
##  + \@blocks defaults to $mbx->{blocks}
sub sort_blocks {
  my ($mbx,$blocks) = @_;
  my $key2i = $mbx->{key2i};
  $blocks = $mbx->{blocks} if (!$blocks);

  @$blocks = (
	      sort {
		($key2i->{$a->{key}} <=> $key2i->{$b->{key}}
		 || $a->{key}  cmp $b->{key}
		 || $a->{bx0off} <=> $b->{bx0off}
		 #|| $a->{xoff} <=> $b->{xoff}
		)
	      } @$blocks
	     );

  return $blocks;
}


## \@blocks = $mbx->compute_block_text(\@blocks, \$txbuf)
## \@blocks = $mbx->compute_block_text(\@blocks)
## \@blocks = $mbx->compute_block_text()
##  + sets $blk->{otoff}, $blk->{otlen}, $blk->{otext} for each block $blk
##  + \$txbuf defaults to $mbx->{txbufr}
##  + \@blocks defaults to $mbx->{blocks}
##  + \@blocks should already have been sorted
sub compute_block_text {
  my ($mbx,$blocks,$txbufr) = @_;
  $blocks = $mbx->{blocks} if (!$blocks);
  $txbufr = $mbx->{txbufr} if (!$txbufr);
  my $otoff = 0;
  my ($SB,$WB,$LB,$WS) = @$mbx{qw(sbStr wbStr lbStr wsStr)};
  my ($blk);
  foreach $blk (@$blocks) {
    ##-- specials
    if    ($blk->{elt} eq 'w')  { $blk->{otext}=$WB; }
    elsif ($blk->{elt} eq 's')  { $blk->{otext}=$SB; }

    elsif ($blk->{elt} eq 'lb') { $blk->{otext}=$LB; }
    elsif ($blk->{elt} eq 'ws') { $blk->{otext}=$WS; }
    elsif (defined($blk->{text})) {
      #$mbx->debug("got literal text '$blk->{text}' (utf8=".(utf8::is_utf8($blk->{text}) ? 1 : 0).")");
      $blk->{otext} = utf8::is_utf8($blk->{text}) ? encode_utf8($blk->{text}) : decode_utf8($blk->{text});
    }
    else {
      $blk->{otext} = substr($$txbufr, $blk->{toff}, $blk->{tlen});
    }
    $blk->{otoff} = $otoff;
    $blk->{otlen} = length($blk->{otext});
    $otoff += $blk->{otlen};
  }
  return $blocks;
}


##==============================================================================
## Methods: I/O
##==============================================================================


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, and edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Processor::mkbx - DTA tokenizer wrappers: (bx0doc,tx) -> bxdata

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::mkbx;
 
 $mbx = DTA::TokWrap::Processor::mkbx->new(%opts);
 $doc_or_undef = $mbx->mkbx($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::Processor::mkbx provides an object-oriented
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor> wrapper
for the creation of in-memory serialized text-block-indices.

Most users should use the high-level
L<DTA::TokWrap|DTA::TokWrap> wrapper class
instead of using this module directly.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::mkbx: Constants
=pod

=head2 Constants

=over 4

=item @ISA

DTA::TokWrap::Processor::mkbx
inherits from
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::mkbx: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = $CLASS_OR_OBJECT->new(%args);

Constructor.

%args, %$obj:

 ##-- Block-sorting: hints
 wbStr => $wbStr,                   ##-- word-break hint text
 sbStr => $sbStr,                   ##-- sentence-break hint text
 sortkey_attr => $attr,             ##-- sort-key attribute (default='dta.tw.key'; should jive with mkbx0)
 
 ##-- Block-sorting: low-level data
 xp    => $xml_parser,              ##-- XML::Parser object for parsing $doc->{bx0doc}

=item defaults

 %defaults = CLASS->defaults();

Static class-dependent defaults.

=item init

 $mbx = $mbx->init();

Dynamic object-dependent defaults.

=item initXmlParser

 $xp = $mbx->initXmlParser();

Create & initialize $mbx-E<gt>{xp}, an XML::Parser object
used to parse $doc-E<gt>{bx0data}.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::mkbx: Methods: mkbx (bx0doc, txfile) => bxdata
=pod

=head2 Methods: mkbx (bx0doc, txfile) => bxdata

=over 4

=item mkbx

 $doc_or_undef = $CLASS_OR_OBJECT->mkbx($doc);

Creates the serialized text-block-index $doc-E<gt>{bxdata}
for the
L<DTA::TokWrap::Document|DTA::TokWrap::Document> object $doc.

Relevant %$doc keys:

 bx0doc  => $bx0doc,  ##-- (input) preliminary block-index data (XML::LibXML::Document)
 txfile  => $txfile,  ##-- (input) raw text index filename
 bxdata  => \@blocks, ##-- (output) serialized block index
 ##
 mkbx_stamp0 => $f,   ##-- (output) timestamp of operation begin
 mkbx_stamp  => $f,   ##-- (output) timestamp of operation end
 bxdata_stamp => $f,  ##-- (output) timestamp of operation end

Block data: @{$doc-E<gt>{bxdata}} = @blocks = ($blk0, ..., $blkN); %$blk =

 key    => $sortkey, ##-- (inherited) sort key
 elt    => $eltname, ##-- element name which created this block
 xoff   => $xoff,    ##-- XML byte offset where this block run begins
 xlen   => $xlen,    ##-- XML byte length of this block (0 for hints)
 toff   => $toff,    ##-- raw-text (.tx) byte offset where this block run begins
 tlen   => $tlen,    ##-- raw-text (.tx) byte length of this block (0 for hints)
 otext  => $otext,   ##-- output text (.txt) for this block
 otoff  => $otoff,   ##-- output text (.txt) byte offset where this block run begins
 otlen  => $otlen,   ##-- output text (.txt) length (bytes)

=item prune_empty_blocks

 \@blocks = $mbx->prune_empty_blocks(\@blocks);
 \@blocks = $mbx->prune_empty_blocks();

Low-level utility.

Removes empty 'c'-type blocks from @blocks
(default=$mbx-E<gt>{blocks}).

=item sort_blocks

 \@blocks = $mbx->sort_blocks(\@blocks);

Low-level utility.

Sorts \@blocks (default=$mbx-E<gt>{blocks})
using $mb-E<gt>{key2i}.

=item compute_block_text

 \@blocks = $mbx->compute_block_text(\@blocks, \$txbuf);
 \@blocks = $mbx->compute_block_text(\@blocks);
 \@blocks = $mbx->compute_block_text();

Low-level utility.

Sets $blk-E<gt>{otoff}, $blk-E<gt>{otlen}, $blk-E<gt>{otext} for each block $blk
in @blocks (default=$mbx-E<gt>{blocks}) by extracting
raw-text (.tx) substrings from \$txbuf (default=$mbx-E<gt>{txbufr}).

\@blocks should already have been sorted before this method is called.

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


