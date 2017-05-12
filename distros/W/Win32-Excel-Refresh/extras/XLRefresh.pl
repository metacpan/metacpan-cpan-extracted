# --------------------------------------------------------
# XLRefresh.pl
#
#  Perl program to automatically refresh Excel workbooks through a command-line interface
#
#  Usage: XLRefresh -[aqpv] -m macro(s) filename
#
#  options:
#    -a, --all          Refresh All PivotTables and Queries
#    -q, --query-tables Refreshes All QueryTables  
#    -p, --pivot-tables Refresh All PivotTables
#    -m, --macros       Runs specified macros
#    -v, --visible      Shows application while running
#
# Compiled with PerlApp from ActiveState
# PerlApp --clean -exe XLRefresh.exe --icon ..\images\xlr.ico XLRefresh.pl
#
# Copyright 2005. Christopher Brown.  CTBROWN@CPAN.ORG
# --------------------------------------------------------


# --------------------------------------------------------
# USE NECESSARY MODULES
# --------------------------------------------------------
use Win32::Excel::Refresh;
use strict;

our ( $opt_a, $opt_p, $opt_q, $opt_m, $opt_v ) ;

use Getopt::Mixed;
Getopt::Mixed::init("a p q v m=s all>a pivot-tables>p query-tables>q macros>m visible>v");
Getopt::Mixed::getOptions();

use File::Spec::Functions ':ALL';


# --------------------------------------------------------
# TRAP ERRORS: Usage
# --------------------------------------------------------
# my $filename = join( ' ', @ARGV );
if ( ! @ARGV ) {
	print <<'EOT';

XLRefresh
  Perl program to automatically refresh Excel workbooks through a command-line interface

  Usage: XLRefresh -[aqpv] -[m macro(s)] filename(s)

  options:
    -a, --all          Refresh All PivotTables and Queries
    -q, --query-tables Refreshes All QueryTables  
    -p, --pivot-tables Refresh All PivotTables
    -m, --macros       Runs specified macros
    -v, --visible      Shows application while running

EOT

	exit;
}


# --------------------------------------------------------
# LOOP THROUGH FILES
# --------------------------------------------------------
foreach my $filename ( @ARGV ) {

	# --------------------------------------------------------
	# TRAP ERRORS: Invalid file(s)
	# --------------------------------------------------------
	# print $filename;
	$filename = rel2abs($filename);
	die("$filename does not exist.\n") if ( !-e $filename);

	## CREATE $options
	my @macros = split(';', $opt_m);

	my $opts = {
		'all'          => $opt_a ,
		'query-tables' => $opt_q ,
		'pivot-tables' => $opt_p ,
		'macros'       => \@macros,
		'visible'	     => $opt_v
	};

	&XLRefresh($filename, $opts);

}
