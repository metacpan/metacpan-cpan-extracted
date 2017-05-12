use strict;
my @scripts;

use Test::More tests => 4;

my $logfile = $0;
$logfile =~ s/t$/log/;

ok ( -e "./$logfile", "Verifying existance of $logfile")
   or diag("No log file found for '$0'");

use Test::Parser::PgOptions;

my $parser = new Test::Parser::PgOptions;
$parser->parse($logfile);

my $h = $parser->data();
my @a = @{$h->{database}->{parameters}->{parameter}};

my $realized;
my $expected;

$realized = scalar @a;
$expected = 167;
ok ($realized == $expected,
    "Data count: expected $expected, realized $realized");

$realized = $h->{database}->{name};
$expected = 'PostgreSQL';
ok ($realized eq $expected,
    "Database name: expected $expected, realized $realized");

$realized = $h->{database}->{version};
$expected = '';
for my $i (@a) {
  $expected = $i->{setting} if ($i->{name} eq 'server_version');
}
ok ($realized eq $expected,
    "Database version: expected $expected, realized $realized");

print $parser->to_xml();
print "\n";
