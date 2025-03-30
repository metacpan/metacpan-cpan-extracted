use strict;
use warnings;
use Test::More;
use autobox::Lookup;

# Sample data structure
my $data = {
    b => { key => 'value_b' },
    a => { key => 'value_a' },
    c => { key => 'value_c' },
};

# Expected results
my $expected_flat = [ { "key" => "value_a" }, { "key" => "value_b" }, { "key" => "value_c" } ];
my $expected_recursive = [ 'value_a', 'value_b', 'value_c' ];

# Test cases


is_deeply(
    $data->get('[].key'),
    $expected_recursive,
    'Recursive lookup on hash with [] and .key'
);

is_deeply(
    $data->get('[]'),
    $expected_flat,
    'Flat lookup on hash with []'
);

done_testing();
