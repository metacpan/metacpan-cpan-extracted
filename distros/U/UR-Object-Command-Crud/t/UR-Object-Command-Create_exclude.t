#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Path::Class;
use lib file(__FILE__)->dir->stringify;
use TestCrudClasses;

use List::MoreUtils 'any';
use Test::More tests => 1;

subtest 'exclude properties' => sub{
    plan tests => 5;

    use_ok('UR::Object::Command::Create') or die;
    use_ok('UR::Object::Command::Crud') or die;

    my %sub_command_configs = map { $_ => { skip => 1 } } grep { $_ ne 'create' } UR::Object::Command::Crud->buildable_sub_command_names;
    $sub_command_configs{create}->{exclude} = [qw/ title /];
    UR::Object::Command::Crud->create_command_subclasses(
        target_class => 'Test::Muppet',
        sub_command_configs => \%sub_command_configs,
    );

    my $create_command_class_name = 'Test::Muppet::Command::Create';
    my $meta = UR::Object::Type->get($create_command_class_name);
    ok($meta, 'muppet create command exists'),

    my $has_name_property = any { $_->property_name eq 'name' } $meta->property_metas;
    ok($has_name_property, 'create command does not have a name property');

    my $has_title_property = any { $_->property_name eq 'title' } $meta->property_metas;
    ok(!$has_title_property, 'create command does not have a title property');

};

done_testing();
