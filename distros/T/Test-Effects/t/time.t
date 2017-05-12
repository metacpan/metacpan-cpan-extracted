use Test::Effects;

# How long we're going to test timing for...
my $sleepy_time = 0.25;

# Use a +/- 10% margin of error...
my ($min, $max) = ($sleepy_time * 0.9, $sleepy_time * 1.1);

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
sub select_random_context { return @{ $contexts[rand @contexts] } }

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
plan tests => 2 * keys %timing_spec;

# Run them all...
for my $test (keys %timing_spec) {
    # Test quietly...
    effects_ok { nap $sleepy_time }
               TIME {
                    select_random_context(),
               }
               => "Didn't oversleep: $test";

    # Test verbosely...
    effects_ok { nap $sleepy_time }
               VERBOSE {
                    TIME => 1,
                    select_random_context(),
               }
               => "Didn't oversleep: $test";
}

done_testing();

