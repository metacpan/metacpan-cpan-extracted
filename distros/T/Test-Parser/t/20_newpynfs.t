use strict;
my @scripts;

use Test::More tests => 5;

my $logfile = $0;
$logfile =~ s/t$/log/;

ok ( -e "./$logfile", "Verifying existance of $logfile")
   or diag("No log file found for '$0'");

use Test::Parser::newpynfs;

my $parser = new Test::Parser::newpynfs;
$parser->parse($logfile);

ok ($parser->num_executed() == 578, "Executed count");
ok ($parser->num_passed()   == 491,  "Passed count");
ok ($parser->num_failed()   ==  57,  "Failed count");
ok ($parser->num_skipped()  ==  13,  "Skipped count");




