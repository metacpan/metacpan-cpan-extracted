use strict;
use warnings;
use Test::More;
use autobox::Lookup;

# Test data structures
my $data = {
    level1 => {
        level2 => {
            level3 => "value at level 3",
        },
        array_key => [
            { sub_key => "value in array 0" },
            { sub_key => "value in array 1" },
        ],
    },
};

# 1 Test: Multi-level key lookup that succeeds
{
    my $result = $data->get("level1.level2.level3");
    is($result, "value at level 3", "1. Multi-level lookup succeeded for key 'level1.level2.level3'");
}

# Test: Multi-level key lookup that doesn't find a value
{
    my $result = $data->get("level1.level2.nonexistent");
    is($result, undef, "2. Multi-level lookup returned undef for nonexistent key 'level1.level2.nonexistent'");
}

# Test: Multi-level lookup including integer keys on a structure containing arrays
{
    my $result = $data->get("level1.array_key.1.sub_key");
    is($result, "value in array 1", "3. Multi-level lookup succeeded for key 'level1.array_key.1.sub_key'");
}

# Test: Invalid array index
{
    my $result = $data->get("level1.array_key.10.sub_key");
    is($result, undef, "4. Multi-level lookup returned undef for invalid array index 'level1.array_key.10.sub_key'");
}

# Test: Attempting to use a non-integer key on an array
{
    my $result = $data->get("level1.array_key.non_integer");
    is($result, undef, "5. Multi-level lookup returned undef for non-integer key on array 'level1.array_key.non_integer'");
}


{
    my $data = { foo => 'bar' };
    my $result = $data->get("foo.bar");
    is($result, undef, "6. Multi-level lookup returned undef for non-integer key on array 'level1.array_key.non_integer'");
}

# Done testing
done_testing();
