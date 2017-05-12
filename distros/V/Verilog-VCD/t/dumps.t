
use warnings;
use strict;
use Test::More tests => 7;

# Check if module loads ok
BEGIN { use_ok('Verilog::VCD', qw(:all)) }


my $vcd;
my $expected;

# Before a VCD file is parsed, dumps hash is empty
my %dumps = get_dumps();
is_deeply(\%dumps, {}, 'no dumps yet');

$vcd = parse_vcd('t/vcd/nc.vcd');

%dumps = get_dumps();
$expected = {(
    dumpvars => [qw(115)],
    dumpall  => [qw(335 601)],
    dumpon   => [qw(597)],
    dumpoff  => [qw(448 611)],
)};
is_deeply(\%dumps, $expected, 'several dumps');

is(get_timescale(), '1 us', 'timescale = 1us');
is(get_endtime(), '1041', 'end time');

my @comms = get_decl_comments();
$expected = [(
    'manually added one line',
    "manually added 3 lines\n2nd line\n3rd line",
    'manually added another one line'
)];
is_deeply(\@comms, $expected, 'declaration comments');

@comms = get_sim_comments();
$expected = [(
    {time => 597, comment => 'manually added one sim line'},
    {time => 611, comment => "manually added two lines\nand here is the 2nd"},
)];
is_deeply(\@comms, $expected, 'simulation comments');

