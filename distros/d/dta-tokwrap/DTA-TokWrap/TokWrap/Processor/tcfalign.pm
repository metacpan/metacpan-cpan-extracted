## -*- Mode: CPerl; coding: utf-8; -*-

## File: DTA::TokWrap::Processor::tcfalign.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: decoded-TCF tokens<->text alignment

package DTA::TokWrap::Processor::tcfalign;

use DTA::TokWrap::Version;  ##-- imports $VERSION, $RCDIR
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:progs :files :slurp :time :diff);
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

## $aln = CLASS_OR_OBJ->new(%args)
##  + %args:
##    diff => $path_to_diff, ##-- default: search
##    inplace=>$bool,        ##-- prefer in-place programs for search?

## %defaults = CLASS_OR_OBJ->defaults()
sub defaults {
  my $that = shift;
  return (
	  $that->SUPER::defaults(),
	  diff=>undef,
	  inplace=>1,
	 );
}

## $aln = $aln->init()
##  + inherited dummy method
## $aln = $aln->init()
sub init {
  my $aln = shift;

  ##-- search for mkindex program
  if (!defined($aln->{diff})) {
    $aln->{diff} = path_prog('diff',
			    prepend=>($aln->{inplace} ? ['.','../src'] : undef),
			    warnsub=>sub {$aln->logconfess(@_)},
			   );
  }

  return $aln;
}

##==============================================================================
## Methods
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->tcfalign($doc)
## + $doc is a DTA::TokWrap::Document object
## + %$doc keys:
##    txtdata  => $txtdata,  ##-- (input) serialized text data (~ tcfxdata)
##    tcfwdata => $tcfwdata, ##-- (input) tokenized data decoded from TCF, without byte-offsets, with SID/WID attributes
##    tokdata1 => $tokdata1, ##-- (output) aligned token data, with byte-offsets, with SID/WID attributes
##    ##
##    tcfalign_stamp0 => $f, ##-- (output) timestamp of operation begin
##    tcfalign_stamp  => $f, ##-- (output) timestamp of operation end
##    tokdata1_stamp  => $f, ##-- (output) timestamp of operation end
## + code lifted in part from DTA::CAB::Format::TCF::parseDocument()
sub tcfalign {
  my ($aln,$doc) = @_;
  $aln = $aln->new if (!ref($aln));
  $doc->setLogContext();

  ##-- log, stamp
  $aln->vlog($aln->{traceLevel},"tcfalign()");
  $doc->{tcfalign_stamp0} = timestamp(); ##-- stamp

  ##-- sanity check(s)
  $aln->logconfess("tcfalign(): no {txtdata} defined") if (!$doc->{txtdata});
  $aln->logconfess("tcfalign(): no {tcfwdata} defined") if (!$doc->{tcfwdata});

  ##-- check for text-identity
  if (file_try_open($doc->{tcftfile}) && file_try_open($doc->{txtfile})) {
    runcmd_noout($aln->{diff}, '-qwBa', $doc->{tcftfile}, $doc->{txtfile})==0
      or $aln->logwarn("tcfalign(): tcf text layer '$doc->{tcftfile}' differs from serialized text '$doc->{txtfile}'");
  }

  ##-- parse tokens
  my @toks = split(/\n/, $doc->{tcfwdata});

  ##-- construct diff sequences
  $aln->vlog($aln->{traceLevel}, "tcfalign(): constructing diff sequences");
  my $txtc  = join("\n", map {(/\s/ ? ' ' : $_)} split(//,$doc->{txtdata}))."\n";
  my $ttc   = '';
  my $ttc2w = ''; ##-- s.t. $wi==vec($ttc2w, $ttci, 32) iff character at substr($ttc,$ttci,1) belongs to token $toks[$wi]
  my $wi = 0;
  my (@wc,$w);
  foreach (@toks) {
    next if ($_ eq '' || $_ =~ /^%%/);
    ($w=$_) =~ s/\t.*$//;
    @wc = split(//,$w);
    $ttc2w .= pack("N*", map {$wi} @wc);
    $ttc   .= join("\n",@wc,'');
  } continue {
    ++$wi;
  }

  ##-- compute diff
  $aln->vlog($aln->{traceLevel}, "tcfalign(): computing diff");
  my $ttc2txtcr = gdiff2(\$txtc,\$ttc, diffcmd=>$aln->{diff}, DIR=>$doc->{tmpdir});

  ##-- compute token locations
  $aln->vlog($aln->{traceLevel}, "tcfalign(): computing token locations");
  my $w2off = ''; ##-- s.t. $woff=vec($w2off,$wi,32) is text byte-offset for token $toks[$wi]
  my $w2len = ''; ##-- s.t. $wlen=vec($w2len,$wi,32) is text byte-length for token $toks[$wi]
  my ($ttci,$txtci,$wj);
  my $txtci_prev = $wi = undef;
  for ($ttci=0,; $ttci < length($ttc); ++$ttci) {
    next if (!($txtci = vec($$ttc2txtcr, $ttci, 32))); ##-- skip un-aligned token characters
    $txtci--;
    $wj  = vec($ttc2w, $ttci, 32);
    if (!defined($wi) || $wj != $wi) {
      vec($w2len, $wi, 32) = $txtci_prev - vec($w2off, $wi, 32) + 1 if (defined($wi));
      for (++$wi; $wi < $wj; ++$wi) {
	vec($w2off, $wi, 32) = $txtci;
	vec($w2len, $wi, 32) = 0;
      }
      vec($w2off, $wj, 32) = $txtci;
      $wi = $wj;
    }
    $txtci_prev = $txtci;
  }
  ##-- final length
  if (defined($wi)) {
    vec($w2len, $wi, 32) = $txtci_prev - vec($w2off, $wi, 32) + 1;
  }

  ##-- dump token data with locations
  $aln->vlog($aln->{traceLevel}, "tcfalign(): constructing output buffer");
  $wi=0;
  my ($text,$rest,$off,$len);
  foreach (@toks) {
    next if ($_ eq '' || $_ =~ /^%%/);
    ($text,$rest) = split(/\t/,$_,2);
    #$rest =~ s/^[0-9]+ [0-9]+\t?//;

    $off = vec($w2off,$wi,32);
    $len = vec($w2len,$wi,32);
    $_ = join("\t",$text,"$off $len",defined($rest) ? $rest : qw());

    ##-- sanity check(s)
    if ($len==0 && $text ne '') {
      $aln->vlog('warn',"tcfalign(): no text characters for token '$_'");
    }
  } continue {
    ++$wi;
  }
  $doc->{tokdata1} = join("\n",@toks)."\n";

  ##-- finalize
  $doc->{tcfalign_stamp} = $doc->{tokdata1_stamp} = timestamp(); ##-- stamp
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

DTA::TokWrap::Processor::tcfalign - DTA tokenizer wrappers: textE<lt>-E<gt>token alignment for decoded TCF

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::tcfalign;
 
 $aln = DTA::TokWrap::Processor::tcfalign->new(%opts);
 $doc_or_undef = $aln->tcfalign($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::Processor::tcfalign provides an object-oriented
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor> wrapper
for aligning tokens TCF-decoded tokens with TokWrap-serialized text.
It requires GNU diff in your PATH.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tcfalign: Constants
=pod

=head2 Constants

=over 4

=item @ISA

DTA::TokWrap::Processor::tcfalign
inherits from
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tcfalign: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = $CLASS_OR_OBJECT->new(%args);

Constructor.

=item defaults

 %defaults = $CLASS->defaults();

Static class-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tcfalign: Methods
=pod

=head2 Methods

=over 4

=item tcfalign

 $doc_or_undef = $CLASS_OR_OBJECT->tcfalign($doc);

Aligns the text and TCF-decoded tokens from the
L<DTA::TokWrap::Document|DTA::TokWrap::Document> object's
{txtdata} and {tcfwdata} keys, storing the resulting tokenization
with byte offsets in TokWrap-compatible format to
C<$doc-E<gt>{tokdata1}>.

Relevant %$doc keys:

 txtdata  => $txtdata,  ##-- (input) serialized text data (~ tcfxdata)
 tcfwdata => $tcfwdata, ##-- (input) tokenized data decoded from TCF, without byte-offsets, with SID/WID attributes
 ##
 tokdata1 => $tokdata1, ##-- (output) aligned token data, with byte-offsets, with SID/WID attributes
 tcfalign_stamp0 => $f, ##-- (output) timestamp of operation begin
 tcfalign_stamp  => $f, ##-- (output) timestamp of operation end
 tokdata1_stamp  => $f, ##-- (output) timestamp of operation end

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
