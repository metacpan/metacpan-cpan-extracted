use strict;
use warnings;
use Test::JSON::More;
use Test::More;

my $json = '{"foo":123,"bar":"baz"}';
ok_json($json, 'ok_json');
cmp_json($json, '{"bar":"baz","foo":123}', 'cmp_json');

my $schema = {
    type       => "object",
    properties => {
        foo => { type => "integer" },
        bar => { type => "string" }
    },
    required => [ "foo" ]
};
ok_json_schema($json, $schema, 'ok_json_schema');

is parsed_json->{foo}, 123;

ok_json_schema(
    $json,
    '{"required":["foo"],"type":"object","properties":{"bar":{"type":"string"},"foo":{"type":"integer"}}}',
    'ok_json_schema json'
);

done_testing;
