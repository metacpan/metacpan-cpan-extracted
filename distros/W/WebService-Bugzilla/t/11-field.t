#!perl
use strict;
use warnings;
use Test::More import => [ qw( done_testing is isa_ok subtest ) ];
use lib 'lib', 't/lib';

use Test::Bugzilla;
use WebService::Bugzilla::Field;
use WebService::Bugzilla::Field::Value;

my $bz = Test::Bugzilla->new(
    base_url => 'http://bugzilla.example.com/rest',
    api_key  => 'abc',
);

subtest 'Get all fields' => sub {
    my $fields = $bz->field->get;
    isa_ok($fields, 'ARRAY', 'get all fields returns arrayref');
    isa_ok($fields->[0], 'WebService::Bugzilla::Field', 'first element is Field object');
    is($fields->[0]->name, 'priority', 'field name is priority');
    isa_ok($fields->[0]->values, 'ARRAY', 'field values is arrayref');
    isa_ok($fields->[0]->values->[0], 'WebService::Bugzilla::Field::Value', 'value element is Field::Value object');
    is($fields->[0]->values->[0]->name, 'P1', 'first value name is P1');
};

subtest 'Get specific field' => sub {
    my $field = $bz->field->get_field('priority');
    isa_ok($field, 'WebService::Bugzilla::Field', 'get_field returns Field object');
    is($field->name, 'priority', 'field name is priority');
};

subtest 'Get legal field values' => sub {
    my $legal = $bz->field->legal_values('priority');
    isa_ok($legal, 'ARRAY', 'legal_values returns arrayref');
    is($legal->[0], 'P1', 'first legal value is P1');
};

subtest 'Get legal field values for product' => sub {
    my $legal_product = $bz->field->legal_values('priority', 1);
    isa_ok($legal_product, 'ARRAY', 'legal_values for product returns arrayref');
};

done_testing();
