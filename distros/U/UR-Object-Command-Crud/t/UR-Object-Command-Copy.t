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
    plan tests => 7;

    use_ok('UR::Object::Command::Copy') or die;
    use_ok('UR::Object::Command::Crud') or die;

    my %sub_command_configs = map { $_ => { skip => 1 } } grep { $_ ne 'copy' } UR::Object::Command::Crud->buildable_sub_command_names;
    UR::Object::Command::Crud->create_command_subclasses(
        target_class => 'Test::Muppet',
        sub_command_configs => \%sub_command_configs,
    );

    $test{cmd_class} = 'Test::Muppet::Command';
    ok(UR::Object::Type->get($test{cmd_class}), 'muppet command exists'),
    $test{cmd} = $test{cmd_class}.'::Copy';
    ok(UR::Object::Type->get($test{cmd}), 'muppet copy command exists'),
    is_deeply([$test{cmd_class}->sub_command_classes], [$test{cmd}], 'only generated copy command');

    $test{ernie} = Test::Muppet->create(
        name => 'ernie',
        title => 'mr',
        job => Test::Job->create(name => 'troublemaker'),
    );
    ok($test{ernie}, 'create ernie');
    ok(UR::Context->commit, 'commit');

};

subtest 'fails' => sub{
    plan tests => 5;

    my $object_count = scalar( () = Test::Muppet->get() );
    throws_ok(sub{ $test{cmd}->execute(source => $test{ernie}, changes => [ "= Invalid Change" ]); }, qr/Invalid change/, 'fails w/ invalid change');
    throws_ok(sub{ $test{cmd}->execute(source => $test{ernie}, changes => [ "names.= Burt" ]); }, qr/Invalid property/, 'fails w/ invalid property');
    throws_ok(sub{ $test{cmd}->execute(source => $test{ernie}, changes => [ "name.= jr", "title=invalid" ]); }, qr/Failed to commit/, 'fails w/ invalid title');
    ok(!Test::Muppet->get(name => 'ernie jr'), 'did not create muppet w/ invalid title;');

    is(scalar( () = Test::Muppet->get() ),
        $object_count,
        'no new objects were created foring failure testing')
};

subtest 'copy' => sub{
    plan tests => 5;

    lives_ok(sub{ $test{cmd}->execute(source => $test{ernie}, changes => [ "name.= sr", "title=dr", "job=",]); }, 'copy');

    my $new = Test::Muppet->get(name => 'ernie sr');
    ok($new, 'created new muppet');
    is($new->title, 'dr', 'title is dr');
    is($new->job, undef, 'no job - he is retired!');

    ok(UR::Context->commit, 'commit');

};

done_testing();
