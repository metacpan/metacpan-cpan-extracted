#!/usr/bin/env perl

use strict;
use warnings 'FATAL';

use Path::Class;
use lib file(__FILE__)->dir->stringify;
use TestCrudClasses;

use Test::Exception;
use Test::More tests => 7;

my %test;
subtest 'setup' => sub{
    plan tests => 9;

    use_ok('UR::Object::Command::Update') or die;
    use_ok('UR::Object::Command::Crud') or die;

    my %sub_command_configs = map { $_ => { skip => 1 } } grep { $_ ne 'update' } UR::Object::Command::Crud->buildable_sub_command_names;
    $sub_command_configs{update}->{only_if_null} = [qw/ best_friend name /];
    UR::Object::Command::Crud->create_command_subclasses(
        target_class => 'Test::Muppet',
        sub_command_configs => \%sub_command_configs,
    );

    $test{cmd_class} = 'Test::Muppet::Command';
    ok(UR::Object::Type->get($test{cmd_class}), 'muppet command exists'),
    $test{cmd} = $test{cmd_class}.'::Update';
    ok(UR::Object::Type->get($test{cmd}), 'muppet update command exists'),
    is_deeply([$test{cmd_class}->sub_command_classes], [$test{cmd}], 'only generated update command');

    $test{ernie} = Test::Muppet->create(name => 'ernie');
    ok($test{ernie}, 'create ernie');

    $test{burt} = Test::Muppet->create(name => 'burt');
    ok($test{burt}, 'create burt');

    $test{gonzo} = Test::Muppet->create(name => 'gonzo');
    ok($test{gonzo}, 'create gonzo');

    $test{job} = Test::Job->create(name => 'troublemaker');
    ok($test{job}, 'create job');

};

subtest 'command properties' => sub{
    plan tests => 3;

    my $cmd = Test::Muppet::Command::Update::Name->create;
    is($cmd->namespace, 'Test::Muppet::Command', 'namespace');
    is($cmd->target_name_pl, 'test muppets', 'target_name_pl');
    is($cmd->target_name_ub_pl, 'test_muppets', 'target_name_ub_pl');
    $cmd->delete;

};

subtest 'update name' => sub{
    plan tests => 19;

    my $pkg = 'Test::Muppet::Command::Update::Name';
    ok(UR::Object::Type->get($pkg), 'muppet update name command exists'),

    my $cmd = $pkg->create;

    $cmd->dump_error_messages(0);
    $cmd->queue_error_messages(1);
    $cmd->dump_status_messages(0);
    $cmd->queue_status_messages(1);
    my $error_messages = $cmd->error_messages_arrayref();

    ok(!$cmd->execute, 'fails w/o params');
    is(scalar(@$error_messages), 3, 'Got 3 error messages');
    like($error_messages->[0],
        qr{Property 'test_muppets': No value specified for required property},
        'complains about missing "test_muppets"');
    like($error_messages->[1],
        qr{Property 'value': No value specified for required property},
        'complains about missing "value"');
    like($error_messages->[2],
        qr{Please see 'test muppet update name --help' for more information\.},
        'Prompts user to see help text');
    is(scalar($cmd->status_messages), 0, 'No status messages');

    @$error_messages = ();
    $cmd->is_executed(undef);
    $cmd->test_muppets([$test{ernie}]);
    ok(!$cmd->execute, 'fails w/o value');

    is(scalar(@$error_messages), 2, 'Got 2 error messages');
    like($error_messages->[0],
        qr{Property 'value': No value specified for required property},
        'complains about missing "value"');
    like($error_messages->[1],
        qr{Please see 'test muppet update name --help' for more information\.},
        'Prompts user to see help text');
    is(scalar($cmd->status_messages), 0, 'No status messages');

    @$error_messages = ();
    $cmd->value('blah');
    ok($cmd->execute, 'udpate fails b/c name is not null');

    is(scalar(@$error_messages), 0, 'no error messages');
    my @status_messages = $cmd->status_messages;
    is(scalar(@status_messages), 2, 'Got 2 status messages');
    is($status_messages[0], 'Update test muppets name...', 'First message, updating name');
    like($status_messages[1], qr{^FAILED_NOT_NULL\s+Test::Muppet\s+\w+}, 'Second message about not null');

    is($test{ernie}->name, 'ernie', 'did not set title b/c it was not null');
    ok(UR::Context->commit, 'commit');

};

subtest 'update title' => sub{
    plan tests => 20;

    my $pkg = 'Test::Muppet::Command::Update::Title';
    ok(UR::Object::Type->get($pkg), 'muppet update title command exists'),

    my $cmd = $pkg->create;
    $cmd->dump_error_messages(0);
    $cmd->queue_error_messages(1);
    $cmd->dump_status_messages(0);
    $cmd->queue_status_messages(1);
    my $error_messages = $cmd->error_messages_arrayref();

    ok(!$cmd->execute, 'fails w/o params');
    is(scalar(@$error_messages), 3, 'Got 3 error messages'); # Assumming same 3 as when updating name above
    is(scalar($cmd->status_messages), 0, 'Got 0 status messages');
    $cmd->is_executed(undef);
    @$error_messages = ();

    $cmd->test_muppets([$test{ernie}]);
    ok(!$cmd->execute, 'fails w/o value');
    is(scalar(@$error_messages), 2, 'Got 2 error messages');
    is(scalar($cmd->status_messages), 0, 'Got 0 status messages');
    $cmd->is_executed(undef);
    @$error_messages = ();

    $cmd->value('blah');
    ok(!$cmd->execute, 'udpate fails w/ invalid value');
    is(scalar(@$error_messages), 2, 'Got 2 error messages');
    like($error_messages->[0],
        qr{Property 'value': The value blah is not in the list of valid values for value\.  Valid values are:},
        'Saw errror about property "value" value not valid');
    like($error_messages->[1],
        qr{Please see 'test muppet update title --help' for more information},
        'Prompts user to see help text');
    is(scalar($cmd->status_messages), 0, 'Got 0 status messages');
    ok(!$test{ernie}->title, 'did not set title');
    $cmd->is_executed(undef);
    @$error_messages = ();

    $cmd->value('mr');
    ok($cmd->execute, 'udpate title');
    is(scalar(@$error_messages), 0, 'Got 0 error messages');
    my @status_messages = $cmd->status_messages();
    is(scalar(@status_messages), 2, 'Got 2 status messages');
    is($status_messages[0], 'Update test muppets title...', 'message about update');
    like($status_messages[1], qr{^UPDATE\s+Test::Muppet\s+\w+\s+NULL\s+mr}, 'Message describing the update');
    is($test{ernie}->title, 'mr', 'set title');
    ok(UR::Context->commit, 'commit');
};

subtest 'update best friend' => sub{
    plan tests => 9;

    my $pkg = 'Test::Muppet::Command::Update::BestFriend';
    ok(UR::Object::Type->get($pkg), 'muppet update best friend command exists'),

    my $cmd = $pkg->create;
    $cmd->dump_error_messages(0);
    $cmd->dump_status_messages(0);

    ok(!$cmd->execute, 'fails w/o params');
    $cmd->is_executed(undef);

    $cmd->test_muppets([$test{ernie}]);
    ok(!$cmd->execute, 'fails w/o value');
    $cmd->is_executed(undef);

    $cmd->value($test{burt});
    ok($cmd->execute, 'udpate best_friend');
    is($test{ernie}->best_friend, $test{burt}, 'set best_friend');
    ok(UR::Context->commit, 'commit');

    $cmd = $pkg->create(test_muppets => [$test{ernie}], value => $test{ernie});
    $cmd->dump_status_messages(0);
    ok($cmd->execute, 'udpate');
    is($test{ernie}->best_friend, $test{burt}, 'did not set best_friend b/c it was not null');
    ok(UR::Context->commit, 'commit');

};

subtest 'update job' => sub{
    plan tests => 7;

    my $pkg = 'Test::Muppet::Command::Update::Job';
    ok(UR::Object::Type->get($pkg), 'muppet update job command exists'),

    my $cmd = $pkg->create;
    $cmd->dump_error_messages(0);
    $cmd->dump_status_messages(0);

    ok(!$cmd->execute, 'fails w/o muppets');
    $cmd->is_executed(undef);

    $cmd->test_muppets([$test{ernie}]);
    ok(!$cmd->execute, 'fails w/o value');
    $cmd->is_executed(undef);

    ok(!$test{ernie}->job, 'ernie does not have a job');
    $cmd->value($test{job});
    ok($cmd->execute, 'udpate job');
    is($test{ernie}->job, $test{job}, 'set job');
    ok(UR::Context->commit, 'commit');

};

subtest 'fails' => sub{
   plan tests => 9;

    my $cmd = Test::Muppet::Command::Update::Name->create;
    $cmd->dump_error_messages(0);
    $cmd->queue_error_messages(1);
    my $error_messages = $cmd->error_messages_arrayref();

    ok(!$cmd->execute, 'fails w/o muppets');
    is(scalar(@$error_messages), 3, 'Got 3 error messages');
    foreach my $expected (  qr{Property 'test_muppets': No value specified for required property},
                            qr{Property 'value': No value specified for required property},
                            qr{Please see 'test muppet update name --help' for more information\.},
    ) {
        like(shift(@$error_messages),
            $expected,
            'Check error message contents');
    }

    $cmd->is_executed(undef);
    @$error_messages = ();

    $cmd->test_muppets([$test{ernie}]);
    ok(!$cmd->execute, 'fails w/o value');
    is(scalar(@$error_messages), 2, 'Got 2 error messages');
    foreach my $expected (  qr{Property 'value': No value specified for required property},
                            qr{Please see 'test muppet update name --help' for more information\.},
    ) {
        like(shift(@$error_messages),
            $expected,
            'Check error message contents');
    }

    $cmd->delete;

};

done_testing();
