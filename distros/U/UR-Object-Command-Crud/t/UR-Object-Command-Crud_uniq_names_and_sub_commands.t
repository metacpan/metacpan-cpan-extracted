#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Path::Class;
use lib file(__FILE__)->dir->stringify;
use TestCrudClasses;

use Test::More tests => 1;

subtest 'unique names and classes' => sub{
    plan tests => 6;

    use_ok('UR::Object::Command::Crud') or die;

    my $pkg = 'Test::Muppet::Command::Update';
    my $meta = UR::Object::Type->define(
        class_name => $pkg,
        is => 'Command::Tree',
    );
    ok($meta, 'defined update tree'),
    isa_ok($pkg, 'Command::Tree');

    UR::Object::Command::Crud->create_command_subclasses(
        target_class => 'Test::Muppet',
    );

    $pkg = 'Test::Muppet::Command';
    ok(UR::Object::Type->get($pkg), 'muppet tree command exists'),
    is_deeply(
        [ $pkg->sub_command_names ],
        [ UR::Object::Command::Crud->buildable_sub_command_names ],
        'subcommand names'
    );

    is_deeply(
        [ $pkg->sub_command_classes ],
        [ map { join('::', 'Test::Muppet::Command', UR::Value::Text->get($_)->to_camel) }  UR::Object::Command::Crud->buildable_sub_command_names ],
        'subcommands'
    );

};

done_testing();
