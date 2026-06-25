#!perl
use v5.24;
use strictures 2;

use Test2::V1               qw( is isnt ok done_testing );
use Test2::Tools::Exception qw( dies lives );

use WebService::OPNsense::Object;

# Simple object
{
    my $obj = WebService::OPNsense::Object->new(
        uuid        => 'abc-123',
        description => 'Test',
        enabled     => 1,
    );
    is( $obj->get('uuid'),        'abc-123', 'get uuid' );
    is( $obj->get('description'), 'Test',    'get desc' );
    is( $obj->get('enabled'),     1,         'get enabled' );
}

# Nested hashref
{
    my $obj = WebService::OPNsense::Object->new(
        name   => 'parent',
        nested => {
            child => 'value',
        },
    );
    is( $obj->get('name'), 'parent', 'parent name' );
    my $child = $obj->get('nested');
    ok( $child->isa('WebService::OPNsense::Object'), 'nested is Object' );
    is( $child->get('child'), 'value', 'nested child' );
}

# Deeply nested hashrefs
{
    my $obj = WebService::OPNsense::Object->new(
        level1 => {
            level2 => {
                level3 => 'deep',
            },
        },
    );
    my $l1 = $obj->get('level1');
    ok( $l1->isa('WebService::OPNsense::Object'), 'level1 is Object' );
    my $l2 = $l1->get('level2');
    ok( $l2->isa('WebService::OPNsense::Object'), 'level2 is Object' );
    is( $l2->get('level3'), 'deep', 'level3 value' );
}

# Arrayref values are preserved as-is (not converted)
{
    my $obj = WebService::OPNsense::Object->new(
        items  => [ 1, 2, 3 ],
        nested => {
            tags => [ 'a', 'b' ],
        },
    );
    my $items = $obj->get('items');
    is( ref $items,  'ARRAY', 'arrayref preserved as ARRAY' );
    is( $items->[0], 1,       'array element 0' );
    is( $items->[2], 3,       'array element 2' );

    my $nested = $obj->get('nested');
    my $tags   = $nested->get('tags');
    is( ref $tags,  'ARRAY', 'nested arrayref preserved as ARRAY' );
    is( $tags->[1], 'b',     'nested array element 1' );
}

# Null / undef values
{
    my $obj = WebService::OPNsense::Object->new(
        present => 'here',
        missing => undef,
    );
    is( $obj->get('present'), 'here', 'present value' );
    is( $obj->get('missing'), undef,  'undef value is preserved' );
}

# Numeric and boolean values
{
    my $obj = WebService::OPNsense::Object->new(
        count => 42,
        ratio => 3.14,
        flag  => 0,
    );
    is( $obj->get('count'), 42,   'integer value' );
    is( $obj->get('ratio'), 3.14, 'float value' );
    is( $obj->get('flag'),  0,    'zero value' );
}

# Empty hashref becomes Object
{
    my $obj = WebService::OPNsense::Object->new(
        empty => {},
    );
    my $empty = $obj->get('empty');
    ok( $empty->isa('WebService::OPNsense::Object'), 'empty hashref becomes Object' );
}

# Multiple nested keys at same level
{
    my $obj = WebService::OPNsense::Object->new(
        first  => { key => 'a' },
        second => { key => 'b' },
    );
    is( $obj->get('first')->get('key'),  'a', 'first nested key' );
    is( $obj->get('second')->get('key'), 'b', 'second nested key' );
}

# TO_JSON — basic
{
    my $obj = WebService::OPNsense::Object->new(
        uuid  => 'xyz',
        count => 42,
    );
    my $json = $obj->TO_JSON;
    is( $json->{uuid},  'xyz', 'TO_JSON uuid' );
    is( $json->{count}, 42,    'TO_JSON count' );
}

# TO_JSON — masks client key (skip BUILD which filters 'client')
{
    my $client_mock = { fake => 'client' };
    my $obj         = WebService::OPNsense::Object->new( uuid => 'abc' );
    $obj->{client} = $client_mock;
    my $json = $obj->TO_JSON;
    is( $json->{uuid},   'abc',      'TO_JSON uuid present' );
    is( $json->{client}, '[MASKED]', 'TO_JSON client masked' );
    isnt( $json->{client}, $client_mock, 'TO_JSON client not original ref' );
}

# TO_JSON — client key not present
{
    my $obj = WebService::OPNsense::Object->new(
        uuid  => 'def',
        count => 7,
    );
    my $json = $obj->TO_JSON;
    is( $json->{uuid},  'def', 'TO_JSON uuid' );
    is( $json->{count}, 7,     'TO_JSON count' );
}

# TO_JSON — nested object stays as Object (TO_JSON does not recurse)
{
    my $obj = WebService::OPNsense::Object->new(
        top => {
            middle => {
                leaf => 'end',
            },
        },
    );
    my $json = $obj->TO_JSON;
    is( ref $json, 'HASH', 'TO_JSON top-level is HASH' );
    ok( $json->{top}->isa('WebService::OPNsense::Object'), 'TO_JSON nested stays as Object' );
    is( $json->{top}->get('middle')->get('leaf'), 'end', 'TO_JSON nested value via get' );
}

# get returns undef for nonexistent key
{
    my $obj = WebService::OPNsense::Object->new( key => 'val' );
    is( $obj->get('nonexistent'), undef, 'get nonexistent key returns undef' );
}

done_testing;
