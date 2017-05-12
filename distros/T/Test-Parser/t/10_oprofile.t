use strict;
my @scripts;

use Test::More tests => 2;

my $logfile = $0;
$logfile =~ s/t$/log/;

ok ( -e "./$logfile", "Verifying existance of $logfile")
   or diag("No log file found for '$0'");

use Test::Parser::Oprofile;

my $parser = new Test::Parser::Oprofile;
$parser->parse($logfile);

my $h = $parser->data();
my @a = @{$h->{oprofile}->{symbol}};

my $realized;
my $expected;

$realized = scalar @a;
$expected = 2629;
ok ($realized == $expected,
    "Data count: expected $expected, realized $realized");

#print $parser->to_xml();
#print "\n";
