use strict;
use warnings;
use Test::More;
use autobox::Lookup;
use Data::Dumper;

sub dumper { Data::Dumper->new([@_])->Indent(0)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump }



$\ = "\n"; $, = "\t";

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


is_deeply( [ sort $data->get("level1")->keys->@* ], ["array_key","level2"], 'keys on hash' );
is_deeply( [ sort $data->get("level1.array_key")->keys->@* ], [0,1], 'keys on array' );
is_deeply( [ sort $data->get("level1.array_key")->values->@* ], [{"sub_key" => "value in array 0"},{"sub_key" => "value in array 1"}], 'some test' );

done_testing();

