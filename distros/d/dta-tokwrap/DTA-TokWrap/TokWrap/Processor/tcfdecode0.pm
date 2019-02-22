## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Processor::tcfdecode0.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: TCF[?tei,?text,tokens,sentences]->?TEI,?text,tokdata decoding

package DTA::TokWrap::Processor::tcfdecode0;

use DTA::TokWrap::Version;  ##-- imports $VERSION, $RCDIR
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:slurp :time :libxml);
use DTA::TokWrap::Processor;

use Carp;
use strict;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::TokWrap::Processor);

##==============================================================================
## Constructors etc.
##==============================================================================

## $dec = CLASS_OR_OBJ->new(%args)
##  + %args: (none)

## %defaults = CLASS_OR_OBJ->defaults()
##  + called by constructor
##  + inherited dummy method
sub defaults {
  return (
	  decode_tcfx => 1,
	  decode_tcft => 1,
	  decode_tcfw => 1,
	  decode_tcfa => 1,
	 );
}

## $dec = $dec->init()
##  + inherited dummy method
#sub init { $_[0] }

##==============================================================================
## Methods
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->tcfdecode0($doc, %opts)
## + %opts: overrides %$dec
##     decode_tcfx => $bool,  ##-- whether to decode $tcfxdata (default=1)
##     decode_tcft => $bool,  ##-- whether to decode $tcftdata (default=1)
##     decode_tcfw => $bool,  ##-- whether to decode $tcfwdata (default=1)
##     decode_tcfa => $bool,  ##-- whether to decode $tcfadata (default=1)
## + $doc is a DTA::TokWrap::Document object
## + %$doc keys:
##    tcfdoc   => $tcfdoc,   ##-- (input) TCF input document
##    ##
##    tcfxdata => $tcfxdata, ##-- (output) TEI-XML decode0d from TCF
##    tcftdata => $tcftdata, ##-- (output) text data decode0d from TCF
##    tcfwdata => $tcfwdata, ##-- (output) tokenized data decode0d from TCF, without byte-offsets, with "SID/WID" attributes
##    tcfadata => $tcfadata, ##-- (output) annotation data decode0d from TCF
##    ##
##    tcfdecode0_stamp0 => $f, ##-- (output) timestamp of operation begin
##    tcfdecode0_stamp  => $f, ##-- (output) timestamp of operation end
##    tcfxdata_stamp   => $f, ##-- (output) timestamp of operation end
##    tcftdata_stamp   => $f, ##-- (output) timestamp of operation end
##    tcfwdata_stamp   => $f, ##-- (output) timestamp of operation end
##    tcfadata_stamp   => $f, ##-- (output) timestamp of operation end
## + code lifted in part from DTA::CAB::Format::TCF::parseDocument()
sub tcfdecode0 {
  my ($dec,$doc,%opts) = @_;
  $dec = $dec->new if (!ref($dec));
  @$dec{keys %opts} = values %opts;
  $doc->setLogContext();

  ##-- log, stamp
  $dec->vlog($dec->{traceLevel},"tcfdecode0()");
  $doc->{tcfdecode0_stamp0} = timestamp(); ##-- stamp

  ##-- sanity check(s)
  $dec->logconfess("tcfdecode0(): no {tcfdoc} defined") if (!$doc->{tcfdoc});

  ##-- decode0: corpus: /D-Spin/TextCorpus
  my $xdoc    = $doc->{tcfdoc};
  my $xroot   = $xdoc->documentElement;
  $dec->logconfess("tcfdecode0(): no document element found in TCF document") if (!$xroot);
  my $xcorpus = [$xroot->getChildrenByLocalName('TextCorpus')]->[0]
    or $dec->logconfess("tcfdecode0(): no /*/TextCorpus node found in TCF document");

  ##-- decode0: tcfxdata: /D-Spin/TextCorpus/textSource[@type="(application|text)/tei+xml"]
  if ($dec->{decode_tcfx}) {
    $dec->vlog($dec->{traceLevel},"tcfdecode0(): textSource");
    my ($xtei) = $xcorpus->getChildrenByLocalName('textSource');
    my $xtype  = $xtei ? ($xtei->getAttribute('type')//'') : '';
    undef ($xtei) if ($xtype !~ m{^(?:text|application)/tei\+xml\b}); # || $xtype =~ m{\btokenized=(?![0n])});
    $doc->{tcfxdata} = $xtei ? $xtei->textContent : '';
    utf8::encode($doc->{tcfxdata}) if (utf8::is_utf8($doc->{tcfxdata}));
  }

  ##-- decode0: tcftdata: /D-Spin/TextCorpus/text
  ## + annoying hack: we grep for elements here b/c libxml getChildrenByLocalName('text') also returns text-nodes!
  if ($dec->{decode_tcft}) {
    $dec->vlog($dec->{traceLevel},"tcfdecode0(): text");
    my ($xtext) = grep {UNIVERSAL::isa($_,'XML::LibXML::Element')} $xcorpus->getChildrenByLocalName('text');
    $doc->{tcftdata} = $xtext ? $xtext->textContent : '';
    utf8::encode($doc->{tcftdata}) if (utf8::is_utf8($doc->{tcftdata}));
  }

  ##-- decode0: tcfwdata: xtokens, xsents
  my ($xtokens) = $xcorpus->getChildrenByLocalName('tokens');
  my ($xsents) = $xcorpus->getChildrenByLocalName('sentences');

  ##-- decode0: tcfwdata
  if ($dec->{decode_tcfw}) {
    ##-- parse: /D-Spin/TextCorpus/tokens
    $dec->vlog($dec->{traceLevel},"tcfdecode0(): tokens");
    my (@wids,%id2w,$wid);
    if (defined($xtokens)) {
      foreach ($xtokens->getChildrenByLocalName('token')) {
	if (!defined($wid=$_->getAttribute('ID'))) {
	  $wid = sprintf("w%x", $#wids);
	  $_->setAttribute('ID'=>$wid);
	}
	$id2w{$wid} = $_->textContent;
	push(@wids,$wid);
      }
    } else {
      ##-- pathological case: no 'tokens' layer: just warn (in case someone is performing an expensive no-op)
      $dec->logwarn("tcfdecode0(): no TextCorpus/tokens node found in TCF document");
    }

    ##-- parse: /D-Spin/TextCorpus/sentences
    $dec->vlog($dec->{traceLevel},"tcfdecode0(): sentences");
    my @sents = qw();
    if (defined($xsents)) {
      my ($s,$sid,$swids);
      foreach ($xsents->getChildrenByLocalName('sentence')) {
	if (!defined($sid=$_->getAttribute('ID'))) {
	  $sid = sprintf("s%x", $#sents);
	  $_->setAttribute(ID=>$sid);
	}
	if (!defined($swids=$_->getAttribute('tokenIDs'))) {
	  $dec->logwarn("tcfdecode0(): no tokenIDs attribute for sentence #$sid, skipping");
	  next;
	}
	push(@sents, [map {$id2w{$_}."\t$sid/$_\n"} split(' ',$swids)]);
      }
    } else {
      @sents = map {$id2w{$_}."\ts0/$_\n"} @wids;
    }

    ##-- decode0: tcfwdata: final
    $dec->vlog($dec->{traceLevel},"tcfdecode0(): tcfwdata");
    $doc->{tcfwdata} = join('', map {join('',@$_)."\n"} @sents);
    utf8::encode($doc->{tcfwdata}) if (utf8::is_utf8($doc->{tcfwdata}));
  }

  ##-- decode: tcf annotations
  if ($dec->{decode_tcfa}) {
    ##-- parse: /D-Spin/TextCorpus/(POStags|lemmas|orthography)
    $dec->vlog($dec->{traceLevel},"tcfdecode0(): tcfadata");

    my $adoc  = XML::LibXML::Document->new("1.0","UTF-8");
    my $aroot = XML::LibXML::Element->new("annotations");
    $adoc->setDocumentElement($aroot);
    $aroot->setAttribute('type','att.linguistic');
    $aroot->setAttribute('source','tcf');

    my %id2w = qw();
    my ($id,$w);
    my $getw = sub {
      $id = shift // '';
      if (!defined($w=$id2w{$id})) {
	$w = $id2w{$id} = $aroot->addNewChild(undef,'w');
	$w->setAttribute('id',$id);
      }
      return wantarray ? ($id,$w) : $w;
    };

    my ($xlemma) = $xcorpus->getChildrenByLocalName('lemmas');
    if (defined($xlemma)) {
      foreach ($xlemma->getChildrenByLocalName('lemma')) {
	$getw->( $_->getAttribute('tokenIDs') )->setAttribute('lemma'=>$_->textContent);
      }
    }

    my ($xpos) = $xcorpus->getChildrenByLocalName('POStags');
    if (defined($xpos)) {
      foreach ($xpos->getChildrenByLocalName('tag')) {
	$getw->( $_->getAttribute('tokenIDs') )->setAttribute('pos'=>$_->textContent);
      }
    }

    my ($xorth) = $xcorpus->getChildrenByLocalName('orthography');
    if (defined($xorth)) {
      foreach ($xorth->getChildrenByLocalName('correction')) {
	next if (($_->getAttribute('operation')//'') ne 'replace');
	$getw->( $_->getAttribute('tokenIDs') )->setAttribute('norm'=>$_->textContent);
      }
    }

    $doc->{tcfadata} = $adoc->toString(1);
  }

  ##-- finalize
  #$dec->vlog($dec->{traceLevel},"tcfdecode0(): finalize");
  $doc->{tcfdecode0_stamp} = $doc->{tcfxdata_stamp} = $doc->{tcftdata_stamp} = $doc->{tcfwdata_stamp} = $doc->{tcfadata_stamp} = timestamp(); ##-- stamp
  return $doc;
}

##==============================================================================
## Utilities
##==============================================================================

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Processor::tcfdecode0 - DTA tokenizer wrappers: TCF[tei,text,tokens,sentences]-E<gt>TEI,text extraction

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::tcfdecode0;
 
 $dec = DTA::TokWrap::Processor::tcfdecode0->new(%opts);
 $doc_or_undef = $dec->tcfdecode0($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::Processor::tcfdecode0 provides an object-oriented
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor> wrapper
for extracting the C<tei>,C<text>,C<tokens>, and C<sentences> layers
from a tokenized TCF ("Text Corpus Format", cf. http://weblicht.sfs.uni-tuebingen.de/weblichtwiki/index.php/The_TCF_Format) document
as originally encoded by
a L<DTA::TokWrap::Processor::tcfencode|DTA::TokWrap::Processor::tcfencode> ("tcfencoder") object.
The encoded TCF document should have the following layers:

=over 4

=item textSource[@type="application/tei+xml"]

Source TEI-XML encoded as an XML text node; should be identical to the source XML
{xmlfile} or {xmldata} passed to the tcfencoder.  Also accepts type "text/tei+xml".

=item text

Serialized text encoded as an XML text node; should be identical to the serialized
text {txtfile} or {txtdata} passed to the tcfencoder.

=item tokens

Tokens returned by the tokenizer for the C<text> layer.
Document order of tokens should correspond B<exactly> to the serial order of the associated text in the C<text> layer.

=item sentences

Sentences returned by the tokenizer for the tokens in the C<tokens> layer.
Document order of sentences must correspond B<exactly> to the serial order of the associated text in the C<text> layer.

=back

The following additional layers will be decoded if the C<decode_tcfa> option is set to a true value:

=over 4

=item lemmas

TCF lemmata identified by C<tokenIDs> in 1:1 correspondence with the tokens in the C<tokens> layer.

=item POStags

TCF part-of-speech tags identified by C<tokenIDs> in 1:1 correspondence with the tokens in the C<tokens> layer.

=item orthography

TCF orthographic normalizations (C<replace> operations only) identified by C<tokenIDs> in 1:1 correspondence with the tokens in the C<tokens> layer.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tcfdecode0: Constants
=pod

=head2 Constants

=over 4

=item @ISA

DTA::TokWrap::Processor::tcfdecode0
inherits from
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tcfdecode0: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = $CLASS_OR_OBJECT->new(%args);

Constructor. Default %args:

 decode_tcfx => $bool,  ##-- whether to decode $tcfxdata (default=1)
 decode_tcft => $bool,  ##-- whether to decode $tcftdata (default=1)
 decode_tcfw => $bool,  ##-- whether to decode $tcfwdata (default=1)
 decode_tcfa => $bool,  ##-- whether to decode $tcfadata (default=1)

=item defaults

 %defaults = $CLASS->defaults();

Static class-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tcfdecode0: Methods
=pod

=head2 Methods

=over 4

=item tcfdecode0

 $doc_or_undef = $CLASS_OR_OBJECT->tcfdecode0($doc);

Decode0s the {tcfdoc} key of the
L<DTA::TokWrap::Document|DTA::TokWrap::Document> object
to TCF, storing the result in
C<$doc-E<gt>{tcfxdata}>, C<$doc-E<gt>{tcftdata}>, and C<$doc-E<gt>{tcfwdata}>.

Relevant %$doc keys:

 tcfdoc   => $tcfdoc,   ##-- (input) TCF input document
 ##
 tcfxdata => $tcfxdata, ##-- (output) TEI-XML decode0d from TCF
 tcftdata => $tcftdata, ##-- (output) text data decode0d from TCF
 tcfwdata => $tcfwdata, ##-- (output) tokenized data decode0d from TCF, without byte-offsets, with "SID/WID" attributes
 tcfadata => $tcfadata, ##-- (output) annotation data decode0d from TCF
 ##
 tcfdecode0_stamp0 => $f, ##-- (output) timestamp of operation begin
 tcfdecode0_stamp  => $f, ##-- (output) timestamp of operation end
 tcfxdata_stamp   => $f, ##-- (output) timestamp of operation end
 tcftdata_stamp   => $f, ##-- (output) timestamp of operation end
 tcfwdata_stamp   => $f, ##-- (output) timestamp of operation end
 tcfadata_stamp   => $f, ##-- (output) timestamp of operation end

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

Copyright (C) 2014-2018 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut


