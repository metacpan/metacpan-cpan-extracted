use strict;
use warnings;
use Test::More;
require_ok 'autobox::JSON';
use autobox::JSON;

my $hash = { name => 'Jim', age => 46};
my $str = $hash->encode_json;
ok $str eq '{"name":"Jim","age":46}' || $str eq '{"age":46,"name":"Jim"}',
    'hash to json';

my $pretty = $hash->encode_json_pretty;
ok
    $pretty eq
'{
   "name" : "Jim",
   "age" : 46
}
'
    ||
    $pretty eq
'{
   "age" : 46,
   "name" : "Jim"
}
'
, "hash to pretty json";

is [1,2,3,4]->encode_json, '[1,2,3,4]', "array to json";

my $array = [1,2,3,4];

is $array->encode_json, '[1,2,3,4]', "array to json";

is_deeply q|{"name":"Jim","age":46}|->decode_json,
    {name => 'Jim', age => 46}, "q string to json";

is_deeply '{"name":"Jim","age":46}'->decode_json,
    {name => 'Jim', age => 46}, "string to json";

is_deeply $str->decode_json, {name => 'Jim', age => 46}, "string to json";

done_testing();
