
use warnings;
use strict;
use Test::More;

if ($] < 5.008) {
    plan skip_all => 'Test will not run on perl before version 5.8';
    # Redirecting STDOUT to a scalar variable was introduced in 5.8.
}
else {
    plan tests => 3;
}

use Verilog::VCD qw(:all);

my $vcd;
my $expected;
my $fh;
my $out;
my $old_stdout;

open $fh, '>', \$out;
$old_stdout = select $fh;
$vcd = parse_vcd('t/vcd/vcs.evcd', {
    use_stdout  => 1,
    siglist     => [('tb.dut.outa[3:0]')]
});
select $old_stdout;
close $fh;

$expected = '0 LLLL 6666 0000
9 LLLH 6660 0006
18 LLHL 6606 0060
18 XXXX 6666 6666
22 LLHL 6606 0060
27 LLHH 6600 0066
36 LHLL 6066 0600
';

is($out, $expected, 'stdout');


# Make sure only signal definitions are included in
# the returned data structure, not t-v pairs.
my ($code) = keys %{ $vcd };
is($code, '<3', 'code');
my @keys = keys %{ $vcd->{$code} };
is_deeply(\@keys, [('nets')], 'no tv pairs');

