use strict;
my @scripts;

use Test::More tests => 5;

my $logfile = $0;
$logfile =~ s/t$/log/;

ok ( -e "./$logfile", "Verifying existance of $logfile")
   or diag("No log file found for '$0'");

use Test::Parser::lhcs_regression;

my $parser = new Test::Parser::lhcs_regression;
$parser->parse($logfile);

ok ($parser->num_executed() == 6, "Executed count");
ok ($parser->num_passed()   == 1,  "Passed count");
ok ($parser->num_failed()   == 5,  "Failed count");
ok ($parser->num_skipped()  == 0,  "Skipped count");




