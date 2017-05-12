use strict;
my @scripts;

use Test::More tests => 17;

my $logfile = $0;
$logfile =~ s/t$/log/;

ok (-e "./$logfile", "Verifying existance of $logfile")
   or diag("No log file found for '$0'");

use Test::Parser::Sar;

my $parser = new Test::Parser::Sar;
$parser->parse($logfile);

my $h = $parser->data();
my @a;

my $realized;
my $expected;

@a = @{$h->{sar}->{proc_s}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (proc/s): expected $expected, realized $realized");

@a = @{$h->{sar}->{cswch_s}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (cswch/s): expected $expected, realized $realized");

@a = @{$h->{sar}->{cpu}->{data}};
$realized = scalar @a;
$expected = 505;
ok ($realized == $expected,
    "Data count (cpu): expected $expected, realized $realized");

@a = @{$h->{sar}->{inode}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (inode): expected $expected, realized $realized");

@a = @{$h->{sar}->{intr}->{data}};
$realized = scalar @a;
$expected = 404;
ok ($realized == $expected,
    "Data count (intr): expected $expected, realized $realized");

@a = @{$h->{sar}->{intr_s}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (intr_s): expected $expected, realized $realized");

@a = @{$h->{sar}->{io}->{tr}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (tr): expected $expected, realized $realized");

@a = @{$h->{sar}->{io}->{bd}->{data}};
$realized = scalar @a;
$expected = 12625;
ok ($realized == $expected,
    "Data count (bd): expected $expected, realized $realized");

@a = @{$h->{sar}->{memory}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (memory): expected $expected, realized $realized");

@a = @{$h->{sar}->{memory_usage}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (memory_usage): expected $expected, realized $realized");

@a = @{$h->{sar}->{paging}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (paging): expected $expected, realized $realized");

@a = @{$h->{sar}->{network}->{ok}->{data}};
$realized = scalar @a;
$expected = 404;
ok ($realized == $expected,
    "Data count (net_ok): expected $expected, realized $realized");

@a = @{$h->{sar}->{network}->{err}->{data}};
$realized = scalar @a;
$expected = 404;
ok ($realized == $expected,
    "Data count (net_err): expected $expected, realized $realized");

@a = @{$h->{sar}->{network}->{sock}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (net_sock): expected $expected, realized $realized");

@a = @{$h->{sar}->{queue}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (queue): expected $expected, realized $realized");

@a = @{$h->{sar}->{swapping}->{data}};
$realized = scalar @a;
$expected = 101;
ok ($realized == $expected,
    "Data count (swapping): expected $expected, realized $realized");

#print $parser->to_xml();
#print "\n";
#$parser->plot();
