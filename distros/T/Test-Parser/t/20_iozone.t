use strict;
my @scripts;

use Test::More tests => 2;

my $logfile = $0;
$logfile =~ s/t$/log/;

ok ( -e "./$logfile", "Verifying existance of $logfile")
   or diag("No log file found for '$0'");

use Test::Parser::iozone;

my $parser = new Test::Parser::iozone;
$parser->parse($logfile);

my $h = $parser->data();
my %a = %{$h->{data}->{datum}};

my $realized;
my $expected;

$realized = keys( %a );
$expected = 135;
ok ($realized == $expected)
   or diag("Data count: expected $expected, realized $realized");

#print $parser->to_xml();
#print "\n";
#print $parser->plot();
