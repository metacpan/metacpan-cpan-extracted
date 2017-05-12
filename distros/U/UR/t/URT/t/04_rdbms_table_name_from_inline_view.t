#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use URT; # dummy namespace

UR::Object::Type->define(
    class_name => 'URT::NormalTable',
    id_by => 'id',
    table_name => 'foo',
    data_source => 'URT::DataSource::SomeSQLite',
);

UR::Object::Type->define(
    class_name => 'URT::InlineView',
    id_by => 'id',
    table_name => '(select foo_id from foo where foo_id is not null) inline_foo',
    data_source => 'URT::DataSource::SomeSQLite',
);

UR::Object::Type->define(
    class_name => 'URT::InlineViewAs',
    id_by => 'id',
    table_name => '(select foo_id from foo where foo_id is not null) as inline_foo',
    data_source => 'URT::DataSource::SomeSQLite',
);

my @tests = (
    'URT::NormalTable' => [undef, undef],
    'URT::InlineView' => ['(select foo_id from foo where foo_id is not null)', 'inline_foo'],
    'URT::InlineViewAs' => ['(select foo_id from foo where foo_id is not null)', 'inline_foo'],
);

for (my $i = 0; $i < @tests; $i += 2) {
    my($class_name, $expected_data) = @tests[$i, $i+1];
    my $class_meta = $class_name->__meta__;
    my($view, $alias) = URT::DataSource::SomeSQLite->parse_view_and_alias_from_inline_view($class_meta->table_name);
    is($view, $expected_data->[0], "$class_name view");
    is($alias, $expected_data->[1], "$class_name alias");
}

    
