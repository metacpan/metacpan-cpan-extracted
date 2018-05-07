
use warnings;
use strict;
use Test::More tests => 47;

# Check if module loads ok
BEGIN { use_ok('Verilog::VCD', qw(:all)) }

# Check module version number
BEGIN { use_ok('Verilog::VCD', '0.08') }


my $vcd;
my $expected;

# Before a VCD file is parsed, the endtime, date and version are undefined
is(get_endtime(), undef, 'undefined endtime');
is(get_date(   ), undef, 'undefined date');
is(get_version(), undef, 'undefined version');

# Before a VCD file is parsed, comments array is empty
my @comms = get_decl_comments();
is_deeply(\@comms, [], 'no declaration comments yet');
@comms = get_sim_comments();
is_deeply(\@comms, [], 'no simulation comments yet');

# Before a VCD file is parsed, dumps hash is empty
my %dumps = get_dumps();
is_deeply(\%dumps, {}, 'no dumps yet');

$vcd = parse_vcd('t/vcd/one-sig.vcd');
is(keys %{ $vcd }, 1, 'one code');
my ($code) = keys %{ $vcd };
is($code, '+', 'code');
is(scalar @{ $vcd->{$code}{nets} }, '1', 'number of nets');
is($vcd->{$code}{nets}[0]{name}, 'sss', 'name');
is($vcd->{$code}{nets}[0]{hier}, 'chip.cpu.alu.toggle', 'hier');
is($vcd->{$code}{nets}[0]{type}, 'reg', 'type');
is($vcd->{$code}{nets}[0]{size}, '1'  , 'size');
my $tv = $vcd->{$code}{tv};
my @ts = map { $_->[0] } @{ $tv };
my @vs = map { $_->[1] } @{ $tv };
my @times_exp = (
    '0',
    '12',
    '24',
    '36',
    '48',
    '60',
    '72',
    '84'
);
$expected = \@times_exp;
is_deeply(\@ts, $expected, 'times');
$expected = [(
    '1',
    '0',
    '1',
    '0',
    '1',
    '0',
    '1',
    '0'
)];
is_deeply(\@vs, $expected, 'values');

my $i = 0;
for (@{ $vcd->{$code}{tv} }) {
    is(scalar @{ $_ }, '2', "number of elements in tv array $i");
    $i++;
}

is(get_endtime(), '84', 'end time');

# Passed argument is ignored
is(get_endtime('1234'), '84', 'getter, not setter');

is(get_timescale(), '10ps', 'timescale = 10ps');

@comms = get_decl_comments();
is_deeply(\@comms, [('Csum: 1 20708e55cba79ffd')], 'declaration comments');

%dumps = get_dumps();
is_deeply(\%dumps, {dumpvars => [0]}, 'dumpvars at time 0');


# Check all valid timescales: s ms us ns ps fs

$vcd = parse_vcd('t/vcd/one-sig.vcd', {timescale => 'fs'});
$tv = $vcd->{$code}{tv};
@ts = map { $_->[0] } @{ $tv };
$expected = [ map {$_ * 10e3} @times_exp ];
is_deeply(\@ts, $expected, 'times fs');

$vcd = parse_vcd('t/vcd/one-sig.vcd', {timescale => 'ps'});
$tv = $vcd->{$code}{tv};
@ts = map { $_->[0] } @{ $tv };
$expected = [ map {$_ * 10} @times_exp ];
is_deeply(\@ts, $expected, 'times ps');

$vcd = parse_vcd('t/vcd/one-sig.vcd', {timescale => 'ns'});
$tv = $vcd->{$code}{tv};
@ts = map { $_->[0] } @{ $tv };
$expected = [ map {$_ * 10e-3} @times_exp ];
is_deeply(\@ts, $expected, 'times ns');

$vcd = parse_vcd('t/vcd/one-sig.vcd', {timescale => 'us'});
$tv = $vcd->{$code}{tv};
@ts = map { $_->[0] } @{ $tv };
$expected = [ map {$_ * 10e-6} @times_exp ];
is_deeply(\@ts, $expected, 'times us');

$vcd = parse_vcd('t/vcd/one-sig.vcd', {timescale => 'ms'});
$tv = $vcd->{$code}{tv};
@ts = map { $_->[0] } @{ $tv };
$expected = [ map {$_ * 10e-9} @times_exp ];
is_deeply(\@ts, $expected, 'times ms');

# Also check that extra foo option is ignored
$vcd = parse_vcd('t/vcd/one-sig.vcd', {timescale => 's', foo => 1});
$tv = $vcd->{$code}{tv};
@ts = map { $_->[0] } @{ $tv };
$expected = [ map {$_ * 10e-12} @times_exp ];
is_deeply(\@ts, $expected, 'times s');


# Check error messages

$@ = '';
eval { my $vcd = parse_vcd('t/vcd/one-sig.vcd', {timescale => 'sec'}) };
like($@, qr/Illegal user-supplied timescale/, 'die if illegal user timescale');

$@ = '';
eval { my @sigs = parse_vcd() };
like($@, qr/parse_vcd requires a filename/, 'die if no filename');

$@ = '';
eval { my @sigs = parse_vcd(undef) };
like($@, qr/parse_vcd requires a filename/, 'die if undef');

$@ = '';
eval { my @sigs = parse_vcd('file-does-not-exist.vcd') };
like($@, qr/Can not open VCD file/, 'die if file does not exist');

$@ = '';
eval { my $vcd = parse_vcd({timescale => 'ns'}, 't/vcd/one-sig.vcd') };
like($@, qr/passed as a hash reference/, 'die if illegal option order');

$@ = '';
eval { my $vcd = parse_vcd('t/vcd/one-sig.vcd', timescale => 'ns') };
like($@, qr/passed as a hash reference/, 'die if option hash');

$@ = '';
eval { my $vcd = parse_vcd('t/vcd/one-sig.vcd', 777) };
like($@, qr/passed as a hash reference/, 'die if option hash');

$@ = '';
eval { my @sigs = parse_vcd('t/vcd/vcs.vcd', {siglist => []}) };
like($@, qr/siglist was empty/, 'die if siglist was empty');

$@ = '';
eval { my @sigs = parse_vcd('t/vcd/bad-timescale1.vcd', {timescale => 'fs'}) };
like($@, qr/Unsupported timescale found/, 'die if unit missing in timescale');

$@ = '';
eval { my @sigs = parse_vcd('t/vcd/bad-timescale2.vcd', {timescale => 'ns'}) };
like($@, qr/Unsupported timescale units/, 'die if wrong unit in timescale');

$@ = '';
eval { my @sigs = parse_vcd('t/vcd/plain.txt') };
like($@, qr/No signals were found/, 'die if no signals in file');
