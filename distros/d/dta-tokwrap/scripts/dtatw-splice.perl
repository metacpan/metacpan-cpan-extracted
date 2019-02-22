#!/usr/bin/perl -w

use lib qw(.);
use DTA::TokWrap;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;

use strict;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = File::Basename::basename($0);
our ($help);

##-- debugging
our $DEBUG = 0;
$DTA::TokWrap::Logger::DEFAULT_LOGLEVEL = 'INFO';

##-- vars: I/O
our $basefile = "-";   ##-- default: stdin
our $sofile   = undef; ##-- required
our $outfile  = "-";   ##-- default: stdout

our %popts = (
	      soIgnoreAttrs=>'',
	      soIgnoreElts=>'',
	      soKeepText=>1,
	      soKeepBlanks=>0,
	      wrapOldContent=>undef,
	     );

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'verbose|v=s' => sub { $DTA::TokWrap::Logger::DEFAULT_LOGLEVEL=uc($_[1]); },
	   'quiet|q' => sub { $DTA::TokWrap::Logger::DEFAULT_LOGLEVEL='ERROR'; },

	   ##-- I/O
	   'keep-whitespace|whitespace|space|keep-blanks|blanks|ws!' => \$popts{soKeepBlanks},
	   'keep-text|text|t!' => \$popts{soKeepText},
	   'ignore-attrs|ia=s' => \$popts{soIgnoreAttrs},
	   'ignore-elements|ignore-elts|ie=s' => \$popts{soIgnoreElts},
	   'wrap-old-content|woc|wrap-content|wc|w=s' => \$popts{wrapOldContent},
	   'output|out|o=s' => \$outfile,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-message=>"Not enough arguments given!",-exitval=>0,-verbose=>0}) if (@ARGV < 2);

##-- log init
##-- init
DTA::TokWrap::Logger->ensureLog();

##-- command-line: arguments
($basefile, $sofile) = @ARGV;

##======================================================================
## MAIN

##-- initialize processor object
my $p = DTA::TokWrap::Processor::idsplice->new(%popts)
  or die("$prog: ERROR: could not create DTA::TokWrap::Processor::idsplice object");

##-- guts
$p->splice_so(base=>$basefile,so=>$sofile,out=>$outfile,basename=>File::Basename::basename($basefile))
  or die("$prog: ERROR: splice_so() failed");

__END__

=pod

=head1 NAME

dtatw-splice.perl - splice generic standoff data into base XML files

=head1 SYNOPSIS

 dtatw-splice.perl [OPTIONS] BASE_XML_FILE STANDOFF_XML_FILE

 General Options:
  -help                  # this help message
  -verbose LEVEL         # set verbosity level (FATAL,ERROR,WARN,INFO,DEBUG,TRACE); default=INFO
  -quiet                 # be silent

 I/O Options:
  -blanks , -noblanks    # don't/do keep 'ignorable' whitespace in standoff file (default=ignored)
  -text   , -notext      # do/don't splice in standoff text data (default=do)
  -ignore-attrs LIST     # comma-separated list of standoff attributes to ignore (default=none)
  -ignore-elts LIST      # comma-separated list of standoff content elements to ignore (default=none)
  -wrap-content ELT	 # element in which to wrap original base file content for spliced items (default=empty:none)
  -output FILE           # specify output file (default='-' (STDOUT))

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

Not yet written.

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

Splice generic standoff data into base XML files.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dtatw-add-c.perl(1)|dtatw-add-c.perl>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
L<dtatw-add-ws.perl(1)|dtatw-add-ws.perl>,
L<dtatw-rm-c.perl(1)|dtatw-rm-c.perl>,
...

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut
