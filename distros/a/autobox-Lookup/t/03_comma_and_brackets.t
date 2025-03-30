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
    another_key => "value in another_key",
};

{
    my $result = $data->get("level1.level2.level3");
    is($result, "value at level 3", "3. Multi-level lookup succeeded for key 'level1.level2.level3'");
}

# 1. Test: Handling the "[]" case (array mapping for all items)
{
    my $result = $data->get("level1.array_key.[].sub_key");
    is_deeply($result, ["value in array 0", "value in array 1"], 
        "1. '[]' case handled correctly, array values returned");
}

{
    my $result = $data->get("level1.array_key.[]");
    is_deeply($result, [ { "sub_key" => "value in array 0" }, { "sub_key" => "value in array 1" } ], 
        "1. '[]' case handled correctly, array values returned");
}

# exit;
# 2. Test: Comma-separated keys lookup (multiple results)
{
    my $result = $data->get("level1.level2.level3,another_key");
    is_deeply($result, ["value at level 3", "value in another_key"], 
        "2. Comma case handled correctly, multiple values returned");
}

# 3. Test: Multi-level key lookup that succeeds (standard case)

done_testing();
