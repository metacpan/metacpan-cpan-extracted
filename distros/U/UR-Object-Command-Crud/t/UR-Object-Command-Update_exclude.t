#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Path::Class;
use lib file(__FILE__)->dir->stringify;
use TestCrudClasses;

use Test::More tests => 1;

subtest 'exclude properties' => sub{
    plan tests => 7;

    use_ok('UR::Object::Command::Update') or die;
    use_ok('UR::Object::Command::Crud') or die;

    my %sub_command_configs = map { $_ => { skip => 1 } } grep { $_ ne 'update' } UR::Object::Command::Crud->buildable_sub_command_names;
    $sub_command_configs{update}->{exclude} = [qw/ name friends /];
    UR::Object::Command::Crud->create_command_subclasses(
        target_class => 'Test::Muppet',
        sub_command_configs => \%sub_command_configs,
    );

    ok(UR::Object::Type->get('Test::Muppet::Command::Update::Job'), 'update job command exists');

    ok(!UR::Object::Type->get('Test::Muppet::Command::Update::Name'), 'update name command does not exist');

    ok(!UR::Object::Type->get('Test::Muppet::Command::Update::Friends'), 'update friends tree does not exist');
    ok(!UR::Object::Type->get('Test::Muppet::Command::Update::Friends::Add'), 'update add friends command does not exist');
    ok(!UR::Object::Type->get('Test::Muppet::Command::Update::Friends::Remove'), 'update remove friends command does not exist');

};

done_testing();
