#!perl
use strictures 2;

use Ref::Util               qw( is_plain_arrayref is_plain_hashref );
use Test2::V1               qw( is isnt ok subtest done_testing );
use Test2::Tools::Exception ();

use WebService::OPNsense::Object ();

use constant {
    TEST_DATA_INT   => 42,
    TEST_DATA_FLOAT => 3.14,
    TEST_DATA_SMALL => 7,
    THREE           => 3,
};

subtest 'simple object' => sub {
    my $item = WebService::OPNsense::Object->new(
        uuid        => 'abc-123',
        description => 'Test',
        enabled     => 1,
    );
    is( $item->get('uuid'),        'abc-123', 'get uuid' );
    is( $item->get('description'), 'Test',    'get desc' );
    is( $item->get('enabled'),     1,         'get enabled' );
};

subtest 'nested hashref' => sub {
    my $item = WebService::OPNsense::Object->new(
        name   => 'parent',
        nested => {
            child => 'value',
        },
    );
    is( $item->get('name'), 'parent', 'parent name' );
    my $child = $item->get('nested');
    ok( $child->isa('WebService::OPNsense::Object'), 'nested is Object' );
    is( $child->get('child'), 'value', 'nested child' );
};

subtest 'deeply nested hashrefs' => sub {
    my $item = WebService::OPNsense::Object->new(
        level1 => {
            level2 => {
                level3 => 'deep',
            },
        },
    );
    my $l1 = $item->get('level1');
    ok( $l1->isa('WebService::OPNsense::Object'), 'level1 is Object' );
    my $l2 = $l1->get('level2');
    ok( $l2->isa('WebService::OPNsense::Object'), 'level2 is Object' );
    is( $l2->get('level3'), 'deep', 'level3 value' );
};

subtest 'arrayref values preserved as-is' => sub {
    my $item = WebService::OPNsense::Object->new(
        items  => [ 1, 2, THREE ],
        nested => {
            tags => [ 'a', 'b' ],
        },
    );
    my $items = $item->get('items');
    ok( is_plain_arrayref($items), 'arrayref preserved as ARRAY' );
    is( $items->[0], 1,     'array element 0' );
    is( $items->[2], THREE, 'array element 2' );

    my $nested = $item->get('nested');
    my $tags   = $nested->get('tags');
    ok( is_plain_arrayref($tags), 'nested arrayref preserved as ARRAY' );
    is( $tags->[1], 'b', 'nested array element 1' );
};

subtest 'null and undef values' => sub {
    my $item = WebService::OPNsense::Object->new(
        present => 'here',
        missing => undef,
    );
    is( $item->get('present'), 'here', 'present value' );
    is( $item->get('missing'), undef,  'undef value is preserved' );
};

subtest 'numeric and boolean values' => sub {
    my $item = WebService::OPNsense::Object->new(
        count => 42,
        ratio => 3.14,
        flag  => 0,
    );
    is( $item->get('count'), TEST_DATA_INT,   'integer value' );
    is( $item->get('ratio'), TEST_DATA_FLOAT, 'float value' );
    is( $item->get('flag'),  0,               'zero value' );
};

subtest 'empty hashref becomes Object' => sub {
    my $item = WebService::OPNsense::Object->new(
        empty => {},
    );
    my $empty = $item->get('empty');
    ok( $empty->isa('WebService::OPNsense::Object'), 'empty hashref becomes Object' );
};

subtest 'multiple nested keys at same level' => sub {
    my $item = WebService::OPNsense::Object->new(
        first  => { key => 'a' },
        second => { key => 'b' },
    );
    is( $item->get('first')->get('key'),  'a', 'first nested key' );
    is( $item->get('second')->get('key'), 'b', 'second nested key' );
};

subtest 'TO_JSON' => sub {
    subtest 'basic' => sub {
        my $item = WebService::OPNsense::Object->new(
            uuid  => 'xyz',
            count => TEST_DATA_INT,
        );
        my $json = $item->TO_JSON;
        is( $json->{uuid},  'xyz',         'TO_JSON uuid' );
        is( $json->{count}, TEST_DATA_INT, 'TO_JSON count' );
    };

    subtest 'masks client key' => sub {
        my $client_mock = { fake => 'client' };
        my $item        = WebService::OPNsense::Object->new( uuid => 'abc' );
        $item->{client} = $client_mock;
        my $json = $item->TO_JSON;
        is( $json->{uuid},   'abc',      'TO_JSON uuid present' );
        is( $json->{client}, '[MASKED]', 'TO_JSON client masked' );
        isnt( $json->{client}, $client_mock, 'TO_JSON client not original ref' );
    };

    subtest 'client key not present' => sub {
        my $item = WebService::OPNsense::Object->new(
            uuid  => 'def',
            count => TEST_DATA_SMALL,
        );
        my $json = $item->TO_JSON;
        is( $json->{uuid},  'def',           'TO_JSON uuid' );
        is( $json->{count}, TEST_DATA_SMALL, 'TO_JSON count' );
    };

    subtest 'nested object stays as Object (no recursion)' => sub {
        my $item = WebService::OPNsense::Object->new(
            top => {
                middle => {
                    leaf => 'end',
                },
            },
        );
        my $json = $item->TO_JSON;
        ok( is_plain_hashref($json),                           'TO_JSON top-level is HASH' );
        ok( $json->{top}->isa('WebService::OPNsense::Object'), 'TO_JSON nested stays as Object' );
        is( $json->{top}->get('middle')->get('leaf'), 'end', 'TO_JSON nested value via get' );
    };
};

subtest 'get returns undef for nonexistent key' => sub {
    my $item = WebService::OPNsense::Object->new( key => 'val' );
    is( $item->get('nonexistent'), undef, 'get nonexistent key returns undef' );
};

done_testing;
