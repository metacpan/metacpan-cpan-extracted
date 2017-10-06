#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Path::Class;
use lib file(__FILE__)->dir->stringify;
use TestCrudClasses;

use Test::Exception;
use Test::More tests => 4;

my %test;
subtest 'setup' => sub{
    plan tests => 8;

    use_ok('UR::Object::Command::Create') or die;
    use_ok('UR::Object::Command::Crud') or die;

    my %sub_command_configs = map { $_ => { skip => 1 } } grep { $_ ne 'create' } UR::Object::Command::Crud->buildable_sub_command_names;
    UR::Object::Command::Crud->create_command_subclasses(
        target_class => 'Test::Muppet',
        sub_command_configs => \%sub_command_configs,
    );

    $test{cmd_class} = 'Test::Muppet::Command';
    ok(UR::Object::Type->get($test{cmd_class}), 'muppet command exists'),
    $test{cmd} = $test{cmd_class}.'::Create';
    ok(UR::Object::Type->get($test{cmd}), 'muppet create command exists'),
    is_deeply([$test{cmd_class}->sub_command_classes], [$test{cmd}], 'only generated create command');

    $test{burt} = Test::Muppet->create(name => 'burt');
    ok($test{burt}, 'create burt');

    $test{rubber_ducky} = Test::Muppet->create(name => 'rubber ducky');
    ok($test{rubber_ducky}, 'create rubber ducky');

    $test{job} = Test::Job->create(name => 'troublemaker');
    ok($test{job}, 'create job');

};

subtest 'command properties' => sub{
    plan tests => 2;

    my $cmd = $test{cmd}->create;
    is($cmd->namespace, 'Test::Muppet::Command', 'namepace');
    is($cmd->target_class, 'Test::Muppet', 'target_class');
    $cmd->delete;

};

subtest 'fails' => sub{
    plan tests => 1;

    my $cmd = $test{cmd}->create;
    ok(!$cmd->execute, 'fails w/o params');
    $cmd->delete;

};

subtest 'create' => sub{
    plan tests => 7;

    my %params = (
        name => 'ernie',
        title => 'mr',
        friends => [$test{rubber_ducky} ],
        best_friend => $test{burt},
        job => $test{job},
    );
    lives_ok(sub{ $test{cmd}->execute(%params); }, 'create');

    my $new_muppet = Test::Muppet->get(name => 'ernie');
    ok($new_muppet, 'created new muppet');
    is($new_muppet->title, 'mr', 'title');
    is($new_muppet->job, $test{job}, 'job');
    is($new_muppet->best_friend, $test{burt}, 'burt is best_friend');
    is_deeply([$new_muppet->friends], [$test{rubber_ducky}], 'friends');

    ok(UR::Context->commit, 'commit');

};

done_testing();
