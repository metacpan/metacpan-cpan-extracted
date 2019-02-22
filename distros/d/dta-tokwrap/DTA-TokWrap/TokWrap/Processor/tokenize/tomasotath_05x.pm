## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Processor::tokenize::tomasotath_05x.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: tokenizer: tomasoblabla (v0.5.x) via command-line

package DTA::TokWrap::Processor::tokenize::tomasotath_05x;

use DTA::TokWrap::Version;  ##-- imports $VERSION, $RCDIR
use DTA::TokWrap::Base;
use DTA::TokWrap::Utils qw(:progs :slurp :time);
use DTA::TokWrap::Processor;

use Encode qw(encode decode);
use Carp;
use strict;

##==============================================================================
## Constants
##==============================================================================
our @ISA = qw(DTA::TokWrap::Processor::tokenize);

##==============================================================================
## Constructors etc.
##==============================================================================

## $tz = CLASS_OR_OBJ->new(%args)
## %defaults = CLASS->defaults()
##  + static class-dependent defaults
##  + %args, %defaults, %$tz:
##    tomata2 => $path_to_dwds_tomasotath, ##-- tokenizer program; default: search
##    abbrevLex => $filename,              ##-- for --to-abbrev=FILE (default: "${RCDIR}/dta_abbrevs.att"; '' for none)
##    tomata2stderr => $bool,              ##-- if false, subprocess stderr will be ignored (default=defined($TRACE_RUNCMD))
##    tomata2opts => \@options,            ##-- additional options (strings) for tokenizer program (default='--to --to-offset --to-analyses')
##    inplace => $bool,                    ##-- prefer in-place programs for search?
sub defaults {
  my $that = shift;
  return (
	  $that->SUPER::defaults(),
	  tomata2   =>undef,
	  tomata2opts=>[ '--to', '--to-offsets', '--to-analyses' ],
	  #abbrevLex => "${RCDIR}/dta_abbrevs_flat.lex",	##-- gets set in init()
	  #stopLex   => "${RCDIR}/dta_stopwords.lex",		##-- gets set in init()
	  #mootHMM   => "${RCDIR}/dta_tokenizer.hmm",		##-- gets set in init()
	  tomata2stderr=>defined($DTA::TokWrap::Utils::TRACE_RUNCMD),
	  inplace=>1,
	 );
}

## $tz = $tz->init()
sub init {
  my $tz = shift;

  ##-- search for tokenizer program
  if (!defined($tz->{tomata2})) {
    $tz->{tomata2} = path_prog('dwds_tomasotath',
			       prepend=>($tz->{inplace} ? ['.','../src'] : undef),
			       warnsub=>sub {$tz->logconfess(@_)},
			      );
  }

  ##-- ensure 'tomata2opts' is an ARRAY
  $tz->{tomata2opts} = [] if (!defined($tz->{tomata2opts}));
  $tz->{tomata2opts} = [ $tz->{tomata2opts} ] if (!ref($tz->{tomata2opts}));

  ##-- abbreviation lexicon
  $tz->{abbrevLex} = "${RCDIR}/dta_abbrevs_flat.lex" if (!defined($tz->{abbrevLex}));
  if ($tz->{abbrevLex} && ! -r $tz->{abbrevLex}) {
    $tz->logconfess("bad abbreviation lexicon '$tz->{abbrevLex}'");
  } elsif ($tz->{abbrevLex}) {
    push(@{$tz->{tomata2opts}}, "--to-abbrevs=$tz->{abbrevLex}");
  }

  ##-- stopword lexicon
  $tz->{stopLex} = "${RCDIR}/dta_stopwords.lex" if (!defined($tz->{stopLex}));
  if ($tz->{stopLex} && ! -r $tz->{stopLex}) {
    $tz->logconfess("bad stopword list '$tz->{stopLex}'");
  } elsif ($tz->{stopLex}) {
    push(@{$tz->{tomata2opts}}, "--to-stopwords=$tz->{stopLex}");
  }

  ##-- tokenizer moot model
  $tz->{mootHMM} = "${RCDIR}/dta_tokenizer.hmm" if (!defined($tz->{mootHMM}));
  if ($tz->{mootHMM} && ! -r $tz->{mootHMM}) {
    $tz->logconfess("bad moot tokenizer model '$tz->{mootHMM}'");
  } elsif ($tz->{mootHMM}) {
    push(@{$tz->{tomata2opts}}, "--to-moot-model=$tz->{mootHMM}");
  }

  return $tz;
}

##==============================================================================
## Methods
##==============================================================================

## $doc_or_undef = $CLASS_OR_OBJECT->tokenize($doc)
## + $doc is a DTA::TokWrap::Document object
## + %$doc keys:
##    txtfile => $txtfile,    ##-- (input) serialized text file
##    tokdata0 => $tokdata,   ##-- (output) tokenizer output data (string)
##    tokenize0_stamp  => $f, ##-- (output) timestamp of operation end
##    tokdata0_stamp => $f,   ##-- (output) timestamp of operation end
## + may implicitly call $doc->mkbx() and/or $doc->saveTxtFile()
sub tokenize {
  my ($tz,$doc) = @_;
  $doc->setLogContext();

  ##-- log, stamp
  $tz = $tz->new if (!ref($tz));
  $tz->vlog($tz->{traceLevel},"tokenize()");
  $doc->{tokenize0_stamp0} = timestamp();

  ##-- sanity check(s)
  $tz->logconfess("tokenize(): no dwds_tomasotath program found")
    if (!$tz->{tomata2});
  $tz->logconfess("tokenize(): no .txt file defined")
    if (!defined($doc->{txtfile}));
  $tz->logconfess("tokenize(): .txt file '$doc->{txtfile}' not readable")
    if (!-r $doc->{txtfile});

  ##-- run program
  $tz->vlog($tz->{traceLevel},"tokenize(): tomata2stderr=$tz->{tomata2stderr}");
  $doc->{tokdata0} = '';
  my $cmd = ("'$tz->{tomata2}'"
	     .' '.join(' ',map {"'$_'"} @{$tz->{tomata2opts}})
	     ." '$doc->{txtfile}'"
	     .($tz->{tomata2stderr} ? '' : ' 2>/dev/null')
	    );
  my $cmdfh = opencmd("$cmd |")
    or $tz->logconfess("tokenize(): open failed for pipe ($cmd |): $!");
  slurp_fh($cmdfh, \$doc->{tokdata0});
  $cmdfh->close();

  ##-- finalize
  $doc->{ntoks} = $tz->nTokens(\$doc->{tokdata0});
  $doc->{tokfile0_stamp} = $doc->{tokenize0_stamp} = $doc->{tokdata0_stamp} = timestamp(); ##-- stamp
  return $doc;
}


##==============================================================================
## Aliases
##==============================================================================
package DTA::TokWrap::Processor::tokenize::tomasotath;
our @ISA = qw(DTA::TokWrap::Processor::tokenize::tomasotath_05x);

package DTA::TokWrap::Processor::tokenize::tomata;
our @ISA = qw(DTA::TokWrap::Processor::tokenize::tomasotath);

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Processor::tokenize::tomasotath_05x - DTA tokenizer wrappers: tokenizer: dwds_tomsatotath v0.5.x via command-line

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::tokenize::tomasotath_05x;
 
 $tz = DTA::TokWrap::Processor::tokenize::tomasotath_05x->new(%args);
 $doc_or_undef = $tz->tokenize($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

This class is currently just a wrapper for the command-line
low-level tokenizer C<dwds_tomasotath> (ToMaSoTaTh), v0.5.x.

Most users should use the high-level
L<DTA::TokWrap|DTA::TokWrap> wrapper class
instead of using this module directly.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tokenize: Constants
=pod

=head2 Constants

=over 4

=item @ISA

DTA::TokWrap::Processor::tokenize::tomasotath
inherits from
L<DTA::TokWrap::Processor::tokenize|DTA::TokWrap::Processor::tokenize>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tokenize: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $tz = $CLASS_OR_OBJ->new(%args);

%args, %$tz: (none yet)

=item defaults

 %defaults = CLASS->defaults();

Static class-dependent defaults.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::TokWrap::Processor::tokenize: Methods
=pod

=head2 Methods

=over 4

=item tokenize

 $doc_or_undef = $CLASS_OR_OBJECT->tokenize($doc);

See L<DTA::TokWrap::Processor::tokenize::tokenize()|DTA::TokWrap::Processor::tokenize/tokenize>.

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


