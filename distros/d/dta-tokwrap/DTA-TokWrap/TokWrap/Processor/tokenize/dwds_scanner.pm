## -*- Mode: CPerl -*-

## File: DTA::TokWrap::Processor::tokenize::dwds_scanner.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA tokenizer wrappers: tokenizer: dwds_scanner via command-line

package DTA::TokWrap::Processor::tokenize::dwds_scanner;

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
	  tokenize=>undef,
	  inplace=>1,
	 );
}

## $tz = $tz->init()
sub init {
  my $tz = shift;

  ##-- search for tokenizer program
  if (!defined($tz->{tokenize})) {
    $tz->{tokenize} = path_prog('dwds_scanner',
				prepend=>($tz->{inplace} ? ['.','../src'] : undef),
				warnsub=>sub {$tz->logconfess(@_)},
			       );
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
  $tz->logconfess("tokenize(): no dwds_scanner program found")
    if (!$tz->{tokenize});
  $tz->logconfess("tokenize(): no .txt file defined")
    if (!defined($doc->{txtfile}));
  $tz->logconfess("tokenize(): .txt file '$doc->{txtfile}' not readable")
    if (!-r $doc->{txtfile});

  ##-- run program
  $doc->{tokdata0} = '';
  my $cmd = ("'$tz->{tokenize}'"
	     ." '$doc->{txtfile}'"
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
package DTA::TokWrap::Processor::tokenize::scanner;
our @ISA = qw(DTA::TokWrap::Processor::tokenize::dwds_scanner);

1; ##-- be happy

__END__
