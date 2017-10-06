#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Path::Class;
use lib file(__FILE__)->dir->stringify;
use TestCrudClasses;

use Test::More tests => 1;

subtest 'tests' => sub{
    plan tests => 4;

    use_ok('UR::Object::Command::UpdateTree') or die;
    use_ok('UR::Object::Command::Crud') or die;

    my %sub_command_configs = map { $_ => { skip => 1 } } grep { $_ ne 'update' } UR::Object::Command::Crud->buildable_sub_command_names;
    UR::Object::Command::Crud->create_command_subclasses(
        target_class => 'Test::Muppet',
        sub_command_configs => \%sub_command_configs,
    );

    my $pkg = 'Test::Muppet::Command::Update';
    ok(UR::Object::Type->get($pkg), 'muppet update tree command exists'),
    isa_ok($pkg, 'UR::Object::Command::UpdateTree');

};

done_testing();
