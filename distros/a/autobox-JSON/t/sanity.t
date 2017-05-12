use strict;
use warnings;
use Test::More;
require_ok 'autobox::JSON';
use autobox::JSON;

# Hash randomization!

my $json = { name => 'Jim', age => 46 }->to_json;

ok
    $json eq '{"name":"Jim","age":46}'
    ||
    $json eq '{"age":46,"name":"Jim"}'
    ,
    "hash to json";

my $hash = { name => 'Jim', age => 46};

is [1,2,3,4]->to_json, '[1,2,3,4]', "array to json";

my $array = [1,2,3,4];

is $array->to_json, '[1,2,3,4]', "array to json";

is_deeply q|{"name":"Jim","age":46}|->from_json,
    {name => 'Jim', age => 46}, "q string to json";

is_deeply '{"name":"Jim","age":46}'->from_json,
    {name => 'Jim', age => 46}, "string to json";

my $str = '{"name":"Jim","age":46}';

is_deeply $str->from_json, {name => 'Jim', age => 46}, "string to json";

done_testing();
