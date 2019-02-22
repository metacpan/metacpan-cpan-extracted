#!/usr/bin/perl -w

use lib qw(.);
use DTA::TokWrap;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;


##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our $prog = File::Basename::basename($0);

##-- debugging
our $DEBUG = 0;
$DTA::TokWrap::Logger::DEFAULT_LOGLEVEL = 'INFO';

##-- vars: I/O
our $outfile = "-";   ##-- default: stdout

##-- vars: default filename infixes
our $srcInfix = '.chr';
our $soInfix  = '.t';

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,
	   'verbose|v=s' => sub { $DTA::TokWrap::Logger::DEFAULT_LOGLEVEL=uc($_[1]); },
	   'quiet|q' => sub { $DTA::TokWrap::Logger::DEFAULT_LOGLEVEL='ERROR'; },

	   ##-- I/O
	   'output|out|o=s' => \$outfile,
	  );

##-- init
DTA::TokWrap::Logger->ensureLog();

##-- command-line: arguments
pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-message=>"Not enough arguments given!",-exitval=>0,-verbose=>0}) if (@ARGV < 1);

our ($srcfile, $sofile) = @ARGV;
if (!defined($sofile)) {
  ($sofile = $srcfile) =~ s/\.xml$/${soInfix}.xml/i;
}

##-- call tokwrap methods
our $doc   = DTA::TokWrap::Document->new(xmlfile=>$srcfile,xtokfile=>$sofile,cwsfile=>$outfile);
our $addws = DTA::TokWrap::Processor::addws->new(traceLevel=>'trace');
$doc->addws($addws);

__END__

=pod

=head1 NAME

dtatw-add-ws.perl - splice standoff //s and //w records from .t.xml into original TEI .chr.xml files

=head1 SYNOPSIS

 dtatw-add-ws.perl [OPTIONS] CHR_XML_FILE T_XML_FILE

 General Options:
  -help                  # this help message
  -verbose LEVEL         # set verbosity level (FATAL,ERROR,WARN,INFO,DEBUG,TRACE); default=INFO
  -quiet                 # be silent

 I/O Options:
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

Splice standoff //s and //w records into original TEI .chr.xml files, producing .cws.xml files.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

L<dtatw-add-c.perl(1)|dtatw-add-c.perl>,
L<dta-tokwrap.perl(1)|dta-tokwrap.perl>,
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
