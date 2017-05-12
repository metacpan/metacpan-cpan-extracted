
use warnings;
use strict;
use Test::More tests => 10;

# Check if module loads ok
BEGIN { use_ok('Verilog::VCD', qw(list_sigs get_timescale)) }

my $expected;
my @sigs;

# Before a VCD file is parsed, the timescale is undefined
is(get_timescale(), undef, 'undefined timescale');

# Sorting is needed to guard against indeterminate hash ordering
$expected = ([sort qw(
    tb.data[7:0]
    tb.abc[foo
    tb.i
    tb.inv1.out
    tb.ev1
    tb.named_block.j
    chip.cpu.alu.toggle.sss
    tb.bar
    tb.inv0.in
    tb.invtemp
    tb.inv0.out
    tb.inv1.in
    tb.bufd
    tb.fp
    tb.mxout
    tb.foo
)]);
@sigs = list_sigs('t/vcd/vcs.vcd');
@sigs = sort @sigs;
is_deeply(\@sigs, $expected, 'vcs.vcd');

is(get_timescale(), '1ns', 'timescale = 1ns');

# Check VCD file with just 1 signal in it
$expected = ([qw(
    chip.cpu.alu.toggle.sss
)]);
@sigs = list_sigs('t/vcd/one-sig.vcd');
is_deeply(\@sigs, $expected, 'one signal');

is(get_timescale(), '10ps', 'timescale = 10ps');

# Passed argument is ignored
is(get_timescale('1ms'), '10ps', 'getter, not setter');


# Check error messages

$@ = '';
eval { my @sigs = list_sigs() };
like($@, qr/list_sigs requires a filename/, 'die if no filename');

$@ = '';
eval { my @sigs = list_sigs(undef) };
like($@, qr/list_sigs requires a filename/, 'die if undef');

$@ = '';
eval { my @sigs = list_sigs('file-does-not-exist.vcd') };
like($@, qr/Can not open VCD file/, 'die if file does not exist');

