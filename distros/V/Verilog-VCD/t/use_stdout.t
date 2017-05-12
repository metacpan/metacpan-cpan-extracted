
use warnings;
use strict;
use Test::More;

if ($] < 5.008) {
    plan skip_all => 'Test will not run on perl before version 5.8';
    # Redirecting STDOUT to a scalar variable was introduced in 5.8.
}
else {
    plan tests => 11;
}

use Verilog::VCD qw(:all);

my $vcd;
my $expected;
my $fh;
my $out;
my $old_stdout;

open $fh, '>', \$out;
$old_stdout = select $fh;
$vcd = parse_vcd('t/vcd/one-sig.vcd', {use_stdout => 1});
select $old_stdout;
close $fh;

$expected = '0 1
12 0
24 1
36 0
48 1
60 0
72 1
84 0
';

is($out, $expected, 'stdout');
is(get_timescale(), '10ps', 'timescale = 10ps');
is(get_endtime(), '84', 'endtime');


# Make sure only signal definitions are included in
# the returned data structure, not t-v pairs.
my ($code) = keys %{ $vcd };
is($code, '+', 'code');
my @keys = keys %{ $vcd->{$code} };
is_deeply(\@keys, [('nets')], 'no tv pairs');


open $fh, '>', \$out;
$old_stdout = select $fh;
$vcd = parse_vcd('t/vcd/one-sig.vcd', {use_stdout => 1, timescale => 'ps'});
select $old_stdout;
close $fh;

$expected = '0 1
120 0
240 1
360 0
480 1
600 0
720 1
840 0
';

is($out, $expected, 'stdout timescale');


open $fh, '>', \$out;
$old_stdout = select $fh;
$vcd = parse_vcd('t/vcd/vcs.vcd', {
                    use_stdout => 0,    # still works with a goofy value
                    siglist    => [('tb.foo')]
});
select $old_stdout;
close $fh;

$expected = '0 x
2 0
8 z
9 1
';

is($out, $expected, 'stdout siglist');
is(get_endtime(), '86', 'endtime');


# Check error messages

$@ = '';
eval { my $vcd = parse_vcd('t/vcd/one-sig.vcd', {
                    siglist    => [('foo')],
                    use_stdout => 1
}) };
like($@, qr/No matching signals were found/, 'die if wrong signal');

$@ = '';
eval { my $vcd = parse_vcd('t/vcd/vcs.vcd', {use_stdout => 1}) };
like($@, qr/too many signals/, 'die if no siglist');

$@ = '';
eval { my $vcd = parse_vcd('t/vcd/vcs.vcd', {
            use_stdout => 1,
            siglist    => [qw(tb.foo tb.bar)]
}) };
like($@, qr/too many signals/, 'die if too many sigs');

