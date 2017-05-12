# This test makes sure that the code from the SYNOPSIS works as
# advertised.

use Test::More tests => 4;

use Text::TypingEffort qw/effort/;
ok(1, 'use Text::TypingEffort');

my $effort = effort("The quick brown fox jumps over the lazy dog");
isa_ok( $effort, 'HASH', 'result is a hashref' );

# floating point compare can be wierd
my $energy = sprintf("%.4f", delete $effort->{energy});
my $should = "2.2194";
is( $energy, $should, 'energy correct' );

ok(
    eq_hash(
        $effort,
        {
            characters => 43,
            presses    => 44,
            distance   => 950,
        }
    ),
    'characters, presses and distance correct'
);

