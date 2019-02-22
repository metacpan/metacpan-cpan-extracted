## -*- Mode: CPerl -*-

## File: DTA::TokWrap.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: top level

package DTA::TokWrap;
use Time::HiRes ('tv_interval','gettimeofday');
use Carp;
use strict;

##-- sub-modules
use DTA::TokWrap::Version qw();
use DTA::TokWrap::Logger;
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:si);
use DTA::TokWrap::Document qw(:tok);
use DTA::TokWrap::Document::Maker;

##-- optional sub-packages
use DTA::TokWrap::CxData qw();

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::TokWrap::Base);
our $VERSION = $DTA::TokWrap::Version::VERSION;

##==============================================================================
## Constructors etc.
##==============================================================================

## $tw = $CLASS_OR_OBJ->new(%args)
##  + %args, %$tw:
##    (
##     ##-- Sub-Processor options
##     inplacePrograms => $bool,      ##-- use in-place programs if available? (default=1)
##     procOpts        => \%opts,     ##-- common options for DTA::TokWrap::Processor sub-classes
##     ##
##     ##-- Document options
##     outdir => $outdir,     ##-- passed to $doc->{outdir}; default='.'
##     tmpdir => $tmpdir,     ##-- passed to $doc->{tmpdir}; default=($ENV{DTATW_TMP}||$ENV{TMP}||$outdir)
##     keeptmp => $bool,      ##-- passed to $doc->{keeptmp}; default=0
##     force   => \@keys,     ##-- passed to $doc->{force}; default=none
##     ##
##     ##-- Processing objects
##     mkindex  => $mkindex,   ##-- DTA::TokWrap::Processor::mkindex object, or option-hash
##     mkbx0    => $mkbx0,     ##-- DTA::TokWrap::Processor::mkbx0 object, or option-hash
##     mkbx     => $mkbx,      ##-- DTA::TokWrap::Processor::mkbx object, or option-hash
##     tokenize => $tok,       ##-- DTA::TokWrap::Processor::tokenize object, subclass object, or option-hash
##     tokenizeClass => $cls,  ##-- ${DTA::TokWrap::Document::TOKENIZE_CLASS} proxy
##     tokenize1 => $tok1,     ##-- DTA::TokWrap::Processor::tokenize1 object or option-hash
##     tok2xml  => $tok2xml,   ##-- DTA::TokWrap::Processor::tok2xml object, or option-hash
##     #standoff => $standoff,  ##-- DTA::TokWrap::Processor::standoff object, or option-hash [OBSOLETE]
##     txmlanno  => $txmlanno, ##-- DTA::TokWrap::Processor::txmlanno object, or option-hash
##     addws => $addws,	       ##-- DTA::TokWrap::Processor::addws object, or option-hash
##     idsplice => $idsplice,  ##-- DTA::TokWrap::Processor::idsplice object, or option-hash
##     ##
##     ##-- Profiling information (set on $doc->close())
##     ##   + pseudo-processor '' represents all processor for TokWrap object
##     profile => {
##       ${proc} => {
##         ndocs => $ndocs,          ##-- total number of documents processed by ${proc} (if known)
##         ntoks => $ntoks,          ##-- total number of tokens processed by ${proc} (if known)
##         nxbytes => $nxbytes,      ##-- total number of source XML bytes processed by ${proc} (if known)
##         elapsed => $secs,         ##-- total number of seconds spent in processor ${proc}
##         laststamp => $stamp,      ##-- last end stamp for ${proc}
##       },
##     },
##    )

## %defaults = $CLASS->defaults()
sub defaults {
  return (
	  ##-- General options
	  inplacePrograms => 1,
	  #procOpts => {},
	  ##
	  ##-- Document options
	  outdir => '.',
	  tmpdir => ($ENV{DTATW_TMP}||$ENV{TMP}),
	  keeptmp => 0,
	  #force  => undef,
	  ##
	  ##-- Processing objects
	  mkindex => undef,
	  mkbx0 => undef,
	  mkbx => undef,
	  tokenize => undef,
	  tokenizeClass => $DTA::TokWrap::Document::TOKENIZE_CLASS,
	  tokenize1 => undef,
	  tok2xml => undef,
	  txmlanno => undef,
	  addws => undef,
	  idsplice => undef,
	  #standoff => undef,
	  ##
	  ##-- TCF-codec objects
	  tcfencode=>undef,
	  tcftokenize=>undef,
	  tcfdecode=>undef,
	  tcfalign=>undef,
	 );
}

## $tw = $tw->init()
sub init {
  my $tw = shift;

  ##-- Defaults: Document options
  $tw->{outdir} = '.' if (!$tw->{outdir});
  $tw->{tmpdir} = $tw->{outdir} if (!$tw->{tmpdir});

  ##-- Defaults: Processing objects
  my %key2opts = (
		  mkindex => {inplace=>$tw->{inplacePrograms}},
		  mkbx0 => {inplace=>$tw->{inplacePrograms}},
		  tokenize => {inplace=>$tw->{inplacePrograms}},
		  ALL => ($tw->{procOpts}||{}),
		 );
  my ($class,%newopts);
  foreach (qw(mkindex mkbx0 mkbx tokenize tokenize1 tok2xml txmlanno addws idsplice tcfencode tcftokenize tcfdecode0 tcfalign tcfdecode)) { #standoff
    next if (UNIVERSAL::isa($tw->{$_},"DTA::TokWrap::Processor::$_"));
    $class   = $_ eq 'tokenize' ? "DTA::TokWrap::Processor::tokenize::".($tw->{tokenizeClass}//${DTA::TokWrap::Document::TOKENIZE_CLASS}) : "DTA::TokWrap::Processor::$_";
    %newopts = (%{$key2opts{ALL}}, ($key2opts{$_} ? %{$key2opts{$_}} : qw()));
    if (UNIVERSAL::isa($tw->{$_},'ARRAY')) {
      $tw->{$_} = $class->new(%newopts, @{$tw->{$_}});
    } elsif (UNIVERSAL::isa($tw->{$_},'HASH')) {
      $tw->{$_} = $class->new(%newopts, %{$tw->{$_}});
    } else {
      $tw->{$_} = $class->new(%newopts);
    }
  }

  ##-- return
  return $tw;
}

##==============================================================================
## Methods: Document pseudo-I/O
##==============================================================================

## $doc = $CLASS_OR_OBJECT->open($xmlfile,%docNewOptions)
##  + wrapper for DTA::TokWrap::Document->open($xmlfile,tw=>$tw,%docNewOptions)
sub open {
  my $tw = shift;
  $tw = $tw->new() if (!ref($tw));
  return DTA::TokWrap::Document->open($_[0], tw=>$tw, @_[1..$#_]);
}

## $bool = $tw->close($doc)
##  + Really just a wrapper for $doc->close()
sub close {
  $_[1]{tw} = $_[0];
  $_[1]->close();
}

##==============================================================================
## Methods: Document Processing
##  + nothing here (yet); see DTA::TokWrap::Document e.g. $doc->makeKey()
##==============================================================================

##==============================================================================
## Methods: Profiling
##==============================================================================

## undef = $tw->logProfile($logLevel)
sub logProfile {
  my ($tw,$level) = @_;
  return if (!$level);
  my $logstr = "Summary:";
  my $profh = $tw->{profile};
  #my @procs = (qw(mkindex mkbx0 mkbx tokenize tokenize1 tok2xml txmlanno sowxml soaxml sosxml),'');
  my @procs = (
	       sort {
		 ($a eq $b ? 0
		  : ($a eq '' ? 1
		     : ($b eq '' ? -1
			: ( (($profh->{$a}{laststamp}||0) <=> ($profh->{$b}{laststamp}||0))
			    ||
			     ($a cmp $b)
			  ))))
	       } keys(%{$tw->{profile}})
	      );
  my $format = "\n%14s: %4d doc, %7stok, %7sbyte in %7ssec: %7stok/sec ~ %7sbyte/sec";
  my ($proc,$prof,$elapsed,$toksPerSec,$xbytesPerSec);
  foreach $proc (@procs) {
    $prof         = $profh->{$proc};
    $elapsed      = ($prof->{elapsed}||0);
    $toksPerSec   = $elapsed > 0 ? sistr((($prof->{ntoks}||0)/$elapsed),'f','.1') : 'inf  ';
    $xbytesPerSec = $elapsed > 0 ? sistr((($prof->{nxbytes}||0)/$elapsed),'f','.1') : 'inf  ';
    $logstr .= sprintf($format,
		       ($proc eq '' ? 'TOTAL' : $proc),
		       ($prof->{ndocs}||0),
		       sistr(($prof->{ntoks}||0),'f','.1'),
		       sistr(($prof->{nxbytes}||0),'f','.1'),
		       sistr($elapsed, 'f', '.1'),
		       $toksPerSec,
		       $xbytesPerSec);
  }
  $tw->vlog($level,$logstr);
}

1; ##-- be happy

__END__

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap - DTA tokenizer wrappers: top level

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap;
 
 ##========================================================================
 ## Constructors etc.
 
 $tw = DTA::TokWrap->new(%options);       ##-- constructor
 %defaults = DTA::TokWrap->defaults();    ##-- static default options
 $tw = $tw->init();                       ##-- dynamic default options
 
 ##========================================================================
 ## Methods: Document pseudo-I/O
 
 $doc = $CLASS_OR_OBJECT->open($xmlfile,%docNewOptions);
 $bool = $tw->close($doc);
 
 ##========================================================================
 ## Methods: Profiling
 
 $tw->logProfile($logLevel);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

This manpage describes the DTA::TokWrap B<module>.
For an introduction to the DTA::TokWrap B<distribution>, see
L<DTA::TokWrap::Intro>.

The DTA::TokWrap package provides top-level object-oriented wrappers
for (batch) tokenization of DTA "base-format" XML documents.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap: Constants
=pod

=head2 Constants

=over 4

=item Variable: @ISA

The DTA::TokWrap class inherits from L<DTA::TokWrap::Base|DTA::TokWrap::Base>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item defaults

 %defaults = CLASS->defaults();

Static default options; see L<DTA::TokWrap::Base>.

=item init

 $tw = $tw->init();

Set dynamic default object structure; see L<DTA::TokWrap::Base>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap: Methods: Document pseudo-I/O
=pod

=head2 Methods: Document pseudo-I/O

=over 4

=item open

 $doc = $CLASS_OR_OBJECT->open($xmlfile,%docNewOptions);

Wrapper for L<DTA::TokWrap::Document-E<gt>open($xmlfile,tw=E<gt>$tw,%docNewOptions)|DTA::TokWrap::Document/open>

=item close

 $bool = $tw->close($doc);

Wrapper for L<$doc-E<gt>close()|DTA::TokWrap::Document/close>

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap: Methods: Profiling
=pod

=head2 Methods: Profiling

=over 4

=item logProfile

 undef = $tw->logProfile($logLevel);

Logs profiling information (throughput) at $logLevel
using the Log::Log4perl mechanism via DTA::TokWrap::Logger.
See L<DTA::TokWrap::Logger>.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl
=pod

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





