## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Processor::tcfdecode.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: TCF->TEI+ws decoding via proxy document

package DTA::TokWrap::Processor::tcfdecode;

use DTA::TokWrap::Version;  ##-- imports $VERSION, $RCDIR
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:slurp :time :libxml);
use DTA::TokWrap::Processor;
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

## $dec = CLASS_OR_OBJ->new(%args)
##  + %args:
##    (
##     'att.linguistic' => $bool,  ##-- if true, use TEI att.linguistic features (default)
##    )

## %defaults = CLASS_OR_OBJ->defaults()
##  + called by constructor
##  + inherited dummy method
sub defaults {
  return (
	  'att.linguistic' => 1,
	  );
}

## $dec = $dec->init()
##  + inherited dummy method
#sub init { $_[0] }

##==============================================================================
## Methods
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->tcfdecode($doc)
## + $doc is a DTA::TokWrap::Document object
## + %$doc keys:
##    tcfxfile => $tcfxfile,     ##-- (input) TEI-XML decoded from TCF
##    tcftfile => $tcftfile,     ##-- (input) text data decoded from TCF
##    tcfwfile => $tcfwfile,     ##-- (input) tokenized data decoded from TCF, without byte-offsets, with "SID/WID" attributes
##    ##
##    tcfcwsfile => $tcfcwsfile, ##-- (output) tcf-decoded+aligned+ws-spliced output file
##    tcfdecode_stamp0 => $f,    ##-- (output) timestamp of operation begin
##    tcfdecode_stamp  => $f,    ##-- (output) timestamp of operation end
##    #...

sub tcfdecode {
  my ($dec,$doc) = @_;
  $dec = $dec->new if (!ref($dec));
  $doc->setLogContext();

  ##-- log, stamp
  $dec->vlog($dec->{traceLevel},"tcfdecode()");
  $doc->{tcfdecode_stamp0} = timestamp(); ##-- stamp

  ##-- sanity check(s)
  $dec->logconfess("tcfdecode(): no {tcfxfile} defined") if (!$doc->{tcfxfile});
  $dec->logconfess("tcfdecode(): no {tcftfile} defined") if (!$doc->{tcftfile});
  $dec->logconfess("tcfdecode(): no {tcfwfile} defined") if (!$doc->{tcfwfile});

  my $att_ling = $dec->{'att.linguistic'};

  ##-- create a proxy tokwrap-document for processing decoded tcf
  my $ddoc = ref($doc)->new(
			    (map {($_=>$doc->{$_})} grep {!m/(?:_stamp0?|data[01]?|bufr?|doc)$/ || m/^tcf.*(?:file|doc)$/} keys %$doc),
			    tcfdoc   => $doc->{tcfdoc},
			    xmlfile  => $doc->{tcfxfile},
			    tokfile1 => $doc->{tcfwfile},
			    axtokfile => $doc->{tcfafile},
			    cwsfile  => $doc->{tcfcwsfile},
			   );
  ##-- create proxy tokwrap object
  $ddoc->{tw} = ref($ddoc->{tw})->new(
				      (map {($_=>(!ref($ddoc->{tw}{$_}) ? $ddoc->{tw}{$_} : undef))} keys %{$ddoc->{tw}}),
				      procOpts=>{
						 %{$ddoc->{tw}{procOpts}//{}},
						 wbStr=>"\n",
						 sbStr=>"\n\n",
						 txmlsort=>0,
						 txmlsort_bysentence=>0,
						 axtokdatakey => 'tcfadata',
						 decode_tcfa => $att_ling,
						 annojoin=>$att_ling,
						 wIdAttr=>'xml:id',
						 sIdAttr=>'xml:id',
						 wExtAttrs=>($att_ling ? '^(?:lemma|pos|norm|join)=' : ''),
						 sExtAttrs=>'',
						},
				     )
    if ($ddoc->{tw});

  ##-- run tcf-decoding processors on proxy document
  $ddoc->genKey('tcfsplit')
    or $dec->logconfess("failed to generate target 'tcfsplit' for proxy document");
  if ($ddoc->{tcfxdata} && ($ddoc->{tcfwdata}//'') eq '') {
    ##-- proxy decode: pathological case: no tokens or sentences in TCF document -- just un-escape textSource (expensive no-op)
    $ddoc->{notmpkeys} .= ' cwsfile';
    $ddoc->saveFileData('cws', '', $ddoc->{cwsfile}, \$ddoc->{tcfxdata})
      or $dec->logconfess("failed to save decoded TEI data (no-op) for proxy document");
  }
  else {
    ##-- proxy decode: usual case: splice selected TCF layers into TEI source
    ##  + optionally splices TEI att.linguistic features in via txmlanno (implicitly called by tok2xml)
    foreach (qw(tei2txt saveBxFile tcfalign tok2xml addws)) {
      $ddoc->genKey($_)
	or $dec->logconfess("failed to generate target '$_' for proxy document");
    }
  }

  ##-- propagate proxy keys to parent document
  $doc->{tcfcwsfile} = $ddoc->{cwsfile};
  $doc->{"tcf_$_"}   = $ddoc->{$_} foreach (grep {$_ =~ /(?:file|_stamp0?)$/} keys %$ddoc);

  ##-- finalize
  $dec->vlog($dec->{traceLevel},"tcfdecode(): finalize");
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

DTA::TokWrap::Processor::tcfdecode - DTA tokenizer wrappers: TCF-E<gt>TEI+ws decoding via proxy document

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::tcfdecode;
 
 $dec = DTA::TokWrap::Processor::tcfdecode->new(%opts);
 $doc_or_undef = $dec->tcfdecode($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::TokWrap::Processor::tcfdecode provides an object-oriented
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor> wrapper
for decoding the
C<tokens> and C<sentences>
layers as extracted from a TCF document by the L<DTA::TokWrap::Processor::tcfdecode0|DTA::TokWrap::Processor::tcfdecode0> processor
into the decoded TEI C<textSource> layer as C<w> and C<s> elements.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tcfdecode: Constants
=pod

=head2 Constants

=over 4

=item @ISA

DTA::TokWrap::Processor::tcfdecode
inherits from
L<DTA::TokWrap::Processor|DTA::TokWrap::Processor>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tcfdecode: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = $CLASS_OR_OBJECT->new(%args);

Constructor.  Options in %args:

 'att.linguistic' => $bool,  ##-- if true, use TEI att.linguistic features (default=1)

=item defaults

 %defaults = $CLASS->defaults();

Static class-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tcfdecode: Methods
=pod

=head2 Methods

=over 4

=item tcfdecode

 $doc_or_undef = $CLASS_OR_OBJECT->tcfdecode($doc);

Decodes the token- and sentence-structure extracted from a TCF document
and merges the results into the original TEI, assuming that the original encoding
was done by TokWrap.  Uses a proxy L<DTA::TokWrap::Document|DTA::TokWrap::Document>
object to perform the decoding.

Relevant %$doc keys:

 tcfxfile => $tcfxfile,     ##-- (input) TEI-XML decoded from TCF
 tcftfile => $tcftfile,     ##-- (input) text data decoded from TCF
 tcfwfile => $tcfwfile,     ##-- (input) tokenized data decoded from TCF, without byte-offsets, with "SID/WID" attributes
 ##
 tcfcwsfile => $tcfcwsfile, ##-- (output) tcf-decoded+aligned+ws-spliced output file
 tcfdecode_stamp0 => $f,    ##-- (output) timestamp of operation begin
 tcfdecode_stamp  => $f,    ##-- (output) timestamp of operation end

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


