#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Path::Class;
use lib file(__FILE__)->dir->stringify;
use TestCrudClasses;

use Test::Exception;
use Test::More tests => 3;

my %test;
subtest 'setup' => sub{
    plan tests => 6;

    use_ok('UR::Object::Command::List') or die;
    use_ok('UR::Object::Command::Crud') or die;

    my %sub_command_configs = map { $_ => { skip => 1 } } grep { $_ ne 'list' } UR::Object::Command::Crud->buildable_sub_command_names;
    $test{sub_command_configs} = \%sub_command_configs;
    UR::Object::Command::Crud->create_command_subclasses(
        target_class => 'Test::Muppet',
        sub_command_configs => $test{sub_command_configs},
    );

    $test{cmd_class} = 'Test::Muppet::Command';
    ok(UR::Object::Type->get($test{cmd_class}), 'muppet command exists'),
    $test{cmd} = $test{cmd_class}.'::List';
    ok(UR::Object::Type->get($test{cmd}), 'muppet list command exists'),
    is_deeply([$test{cmd_class}->sub_command_classes], [$test{cmd}], 'only generated list command');

    $test{elmo} = Test::Muppet->create(name => 'elmo');
    ok($test{elmo}, 'create elmo');

};

subtest 'command config' => sub{
    plan tests => 3;

    my $sub_command_configs = $test{sub_command_configs};
    $sub_command_configs->{list}->{show} = [];
    throws_ok(
        sub{ UR::Object::Command::Crud->create_command_subclasses(target_class => 'Dummy', sub_command_configs => $sub_command_configs) ;},
        qr/Invalid config for LIST `show`/,
        'fails with invlaid show config',
    );
    delete $sub_command_configs->{list}->{show};

    $sub_command_configs->{list}->{order_by} = [];
    throws_ok(
        sub{ UR::Object::Command::Crud->create_command_subclasses(target_class => 'Dummy1', sub_command_configs => $sub_command_configs,) ;},
        qr/Invalid config for LIST `order_by`/,
        'fails with invlaid order_by config',
    );
    delete $sub_command_configs->{list}->{order_by};

    $sub_command_configs->{list}->{blah} = [];
    throws_ok(
        sub{ UR::Object::Command::Crud->create_command_subclasses(target_class => 'Dummy2', sub_command_configs => $sub_command_configs,) ;},
        qr/Unknown config for LIST/,
        'fails with invlaid config key',
    );
    delete $sub_command_configs->{list}->{blah};

};

subtest 'list' => sub{
    plan tests => 2;

    my $output;
    open local(*STDOUT), '>', \$output or die $!;
    lives_ok(sub{ $test{cmd}->execute(filter => 'name=elmo'); }, 'list');
    like($output, qr/elmo/, 'listed muppets');

};

done_testing();
