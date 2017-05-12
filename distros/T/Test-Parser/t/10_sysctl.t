use strict;
my @scripts;

use Test::More tests => 2;

my $logfile = $0;
$logfile =~ s/t$/log/;

ok ( -e "./$logfile", "Verifying existance of $logfile")
   or diag("No log file found for '$0'");

use Test::Parser::Sysctl;

my $parser = new Test::Parser::Sysctl;
$parser->parse($logfile);

my $h = $parser->data();
my @a = @{$h->{parameters}->{parameter}};

my $realized;
my $expected;

$realized = scalar @a;
$expected = 454;
ok ($realized == $expected,
    "Data count: expected $expected, realized $realized");

#print $parser->to_xml();
#print "\n";
