## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Processor::tokenize::waste.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: tokenizer: moot/waste via command-line

package DTA::TokWrap::Processor::tokenize::waste;

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
##    waste => $path_to_waste,		   ##-- tokenizer program; default: search
##    wasteDir => $dirname,                ##-- waste base directory (default: "${RCDIR}/waste")
##    abbrLex => $filename,                ##-- for --abbrevs=FILE (default: "${WASTE_DIR}/abbr.lex"; '' for none)
##    stopLex => $filename,                ##-- for --stopwords=FILE (default: "${WASTE_DIR}/stop.lex"; '' for none)
##    conjLex => $filename,                ##-- for --conjunctions=FILE (default: "${WASTE_DIR}/conj.lex"; '' for none)
##    wasteHmm => $filename,               ##-- for --model=FILE (default: "${WASTE_DIR}/model.hmm")
##    wasteopts => \@options,              ##-- additional options (strings) for tokenizer program (default=['-v2','-Otext,loc'])
##    inplace => $bool,                    ##-- prefer in-place programs for search?
sub defaults {
  my $that = shift;
  return (
	  $that->SUPER::defaults(),
	  waste     => undef,
	  wasteopts => ['-v2', '-Omr,loc'],
	  #abbrLex   => "${RCDIR}/waste/abbr.lex",		##-- gets set in init()
	  #stopLex   => "${RCDIR}/waste/stop.lex",		##-- gets set in init()
	  #conjLex   => "${RCDIR}/waste/conj.lex",		##-- gets set in init()
	  #wasteHmm  => "${RCDIR}/waste/model.hmm",		##-- gets set in init()
	  inplace=>1,
	 );
}

## $tz = $tz->init()
sub init {
  my $tz = shift;

  ##-- search for tokenizer program
  if (!defined($tz->{waste})) {
    $tz->{waste} = path_prog('waste',
			     prepend=>($tz->{inplace} ? ['.','../src'] : undef),
			     warnsub=>sub {$tz->logconfess(@_)},
			    );
  }

  ##-- ensure 'wasteopts' is an ARRAY
  $tz->{wasteopts} = [] if (!defined($tz->{wasteopts}));
  $tz->{wasteopts} = [ $tz->{wasteopts} ] if (!ref($tz->{wasteopts}));

  ##-- waste dir
  $tz->{wasteDir} = "${RCDIR}/waste" if (!defined($tz->{wasteDir}));
  my $wasteDir = $tz->{wasteDir};

  ##-- lexicon: abbrevLex: abbreviations
  $tz->{abbrevLex} = "${wasteDir}/abbr.lex" if (!defined($tz->{abbrevLex}));
  if ($tz->{abbrevLex} && ! -r $tz->{abbrevLex}) {
    $tz->logconfess("bad abbreviation lexicon '$tz->{abbrevLex}'");
  } elsif ($tz->{abbrevLex}) {
    push(@{$tz->{wasteopts}}, "--abbrevs=$tz->{abbrevLex}");
  }

  ##-- lexicon: stopLex: stopwords
  $tz->{stopLex} = "${wasteDir}/stop.lex" if (!defined($tz->{stopLex}));
  if ($tz->{stopLex} && ! -r $tz->{stopLex}) {
    $tz->logconfess("bad stopword lexicon '$tz->{stopLex}'");
  } elsif ($tz->{stopLex}) {
    push(@{$tz->{wasteopts}}, "--stopwords=$tz->{stopLex}");
  }

  ##-- lexicon: conjLex: conjunctions
  $tz->{conjLex} = "${wasteDir}/conj.lex" if (!defined($tz->{conjLex}));
  if ($tz->{conjLex} && ! -r $tz->{conjLex}) {
    $tz->logconfess("bad conjunction lexicon '$tz->{conjLex}'");
  } elsif ($tz->{conjLex}) {
    push(@{$tz->{wasteopts}}, "--conjunctions=$tz->{conjLex}");
  }

  ##-- tokenizer HMM
  $tz->{wasteHmm} = "${wasteDir}/model.hmm" if (!defined($tz->{wasteHmm}));
  if ($tz->{wasteHmm} && ! -r $tz->{wasteHmm}) {
    $tz->logconfess("bad tokenizer model '$tz->{wasteHmm}'");
  } elsif ($tz->{wasteHmm}) {
    push(@{$tz->{wasteopts}}, "--model=$tz->{wasteHmm}");
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
  $tz->logconfess("tokenize(): no 'waste' program found")
    if (!$tz->{waste});
  $tz->logconfess("tokenize(): no .txt file defined")
    if (!defined($doc->{txtfile}));
  $tz->logconfess("tokenize(): .txt file '$doc->{txtfile}' not readable")
    if (!-r $doc->{txtfile});

  ##-- run program
  $tz->vlog($tz->{traceLevel},"tokenize(): calling 'waste' program");
  $doc->{tokdata0} = '';
  my $cmd = ("'$tz->{waste}'"
	     .' '.join(' ',map {"'$_'"} @{$tz->{wasteopts}})
	     ." '$doc->{txtfile}'"
	     #.($tz->{wastestderr} ? '' : ' 2>/dev/null')
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

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::TokWrap::Processor::tokenize::waste - DTA tokenizer wrappers: tokenizer: moot/waste via command-line

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::TokWrap::Processor::tokenize::waste;
 
 $tz = DTA::TokWrap::Processor::tokenize::waste->new(%args);
 $doc_or_undef = $tz->tokenize($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

This class is currently just a wrapper for the command-line
low-level tokenizer C<waste> (moot/waste), v E<gt>= 2.0.10.

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


