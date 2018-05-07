
use warnings;
use strict;
use Test::More tests => 34;

use Verilog::VCD qw(:all);

my $vcd;
my $expected;

# Before a VCD file is parsed, the endtime, date and version are undefined
is(get_endtime(),   undef, 'undefined endtime');
is(get_closetime(), undef, 'undefined closetime');
is(get_date(),      undef, 'undefined date');
is(get_version(),   undef, 'undefined version');

# Before a VCD file is parsed, comments array is empty
my @comms = get_decl_comments();
is_deeply(\@comms, [], 'no declaration comments yet');
@comms = get_sim_comments();
is_deeply(\@comms, [], 'no simulation comments yet');

# Before a VCD file is parsed, dumps hash is empty
my %dumps = get_dumps();
is_deeply(\%dumps, {}, 'no dumps yet');

# Sorting is needed to guard against indeterminate hash ordering
$expected = ([sort qw(
    tb.dut.in
    tb.dut.in2[7:0]
    tb.dut.out2[7:0]
    tb.dut.outa[3:0]
    tb.dut.io[1:0]
    tb.dut.out
)]);
my @sigs = list_sigs('t/vcd/vcs.evcd');
@sigs = sort @sigs;
is_deeply(\@sigs, $expected, 'sigs evcd');

$vcd = parse_vcd('t/vcd/vcs.evcd', {siglist => [('tb.dut.io[1:0]')]});

is(get_timescale(), '1ns', 'timescale = 1ns');
is(keys %{ $vcd }, 1, 'one code');
my ($code) = keys %{ $vcd };
is($code, '<4', 'code');
is(scalar @{ $vcd->{$code}{nets} }, '1', 'number of nets');
is($vcd->{$code}{nets}[0]{name}, 'io[1:0]', 'name');
is($vcd->{$code}{nets}[0]{hier}, 'tb.dut' , 'hier');
is($vcd->{$code}{nets}[0]{type}, 'port'   , 'type');
is($vcd->{$code}{nets}[0]{size}, '[1:0]'  , 'size');

my $i = 0;
for (@{ $vcd->{$code}{tv} }) {
    is(scalar @{ $_ }, '4', "number of elements in tv array $i");
    $i++;
}

my $tv = $vcd->{$code}{tv};
my @actuals = map { $_->[0] } @{ $tv };
my @expects = (qw(
    0
    9
    18
    18
    22
    27
    36
));
is_deeply(\@actuals, \@expects, 'times');

@actuals = map { $_->[1] } @{ $tv };
@expects = (qw(
    LH
    LL
    LH
    XX
    LH
    LL
    LH
));
is_deeply(\@actuals, \@expects, 'values');

@actuals = map { $_->[2] } @{ $tv };
@expects = (qw(
    60
    66
    60
    66
    60
    66
    60
));
is_deeply(\@actuals, \@expects, 'strength0');

@actuals = map { $_->[3] } @{ $tv };
@expects = (qw(
    06
    00
    06
    66
    06
    00
    06
));
is_deeply(\@actuals, \@expects, 'strength1');

is(get_endtime(),   '36', 'end time');
is(get_closetime(), '42', 'close time');

is(get_timescale(), '1ns', 'timescale = 1ns');

@comms = get_decl_comments();
is_deeply(\@comms, [('Csum: 1 4db1f6174ef0adc6')], 'declaration comments');

%dumps = get_dumps();
$expected = {(
    dumpports       => [qw(0)],
    dumpportsoff    => [qw(18)],
    dumpportson     => [qw(22)],
)};
is_deeply(\%dumps, $expected, 'several dumps');

$vcd = parse_vcd('t/vcd/vcs.evcd', {timescale => 'ps'});
is(get_closetime(), '42000', 'close time mult');
is(get_timescale(), '1ps', 'timescale = 1ps');

