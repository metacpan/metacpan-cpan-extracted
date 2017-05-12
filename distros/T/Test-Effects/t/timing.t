use Test::Effects;

# How long we're going to test timing for...
my $sleepy_time = 0.1;

# Use a +/- 34% margin of error...
my ($min, $max) = ($sleepy_time * 0.6, $sleepy_time * 1.4);

# Short sleep...
sub nap {
    my $time = shift;
    select undef, undef, undef, $time;
    return $time;
}

# Select a random testing context...
my @contexts = (
    [ void_return   => undef          ],
    [ scalar_return => $sleepy_time   ],
    [ list_return   => [$sleepy_time] ],
);

# The various possible test specifications...
my %timing_spec = (
    'empty hash'   => {},
    'empty array'  => [],
    'number'       => $max,
    'array'        => [$min, $max],
    'hash min'     => { min => $min },
    'hash max'     => { max => $max },
    'hash min/max' => { min => $min, max => $max },
);

# How many tests in total???
plan 
    -e '.developer' ? (tests =>  2 * keys(%timing_spec) * @contexts )
                    : (skip_all => 'Developer test only' );

# Run them all...
for my $context (@contexts) {
    for my $test (keys %timing_spec) {
        # Test quietly...
        effects_ok { nap $sleepy_time }
                {
                        timing => $timing_spec{$test},
                        @$context,
                }
                => "Didn't oversleep: $test under $context->[0] ";

        # Test verbosely...
        effects_ok { nap $sleepy_time }
                VERBOSE {
                        timing => $timing_spec{$test},
                        @$context,
                }
                => "Didn't oversleep: $test under $context->[0]";
    }
}

done_testing();
