use strict;
my @scripts;

use Test::More tests => 3;

my $logfile = $0;
$logfile =~ s/t$/log/;

ok ( -e "./$logfile", "Verifying existance of $logfile")
   or diag("No log file found for '$0'");

use Test::Parser::KernelBuild;

my $parser = new Test::Parser::KernelBuild;
$parser->parse($logfile);

ok ($parser->num_errors() == 0, "Error count");
ok ($parser->num_warnings() == 19, "Warnings count");





