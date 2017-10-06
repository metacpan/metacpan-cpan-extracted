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
    plan tests => 5;

    use_ok('UR::Object::Command::UpdateIsMany') or die;
    use_ok('UR::Object::Command::Crud') or die;

    my %sub_command_configs = map { $_ => { skip => 1 } } grep { $_ ne 'update' } UR::Object::Command::Crud->buildable_sub_command_names;
    UR::Object::Command::Crud->create_command_subclasses(
        target_class => 'Test::Muppet',
        sub_command_configs => \%sub_command_configs,
    );

    $test{ernie} = Test::Muppet->create(name => 'ernie');
    ok($test{ernie}, 'create ernie');

    $test{burt} = Test::Muppet->create(name => 'burt');
    ok($test{burt}, 'create burt');

    $test{gonzo} = Test::Muppet->create(name => 'gonzo');
    ok($test{gonzo}, 'create gonzo');

};

subtest 'add friend' => sub{
    plan tests => 19;

    my $pkg = 'Test::Muppet::Command::Update::Friends::Add';
    ok(UR::Object::Type->get($pkg), 'muppet add friends command exists'),

    my $cmd = $pkg->create;
    $cmd->dump_error_messages(0);
    $cmd->queue_error_messages(1);
    $cmd->dump_status_messages(0);
    $cmd->queue_status_messages(1);
    my $error_messages = $cmd->error_messages_arrayref();

    is($cmd->namespace, 'Test::Muppet::Command', 'namespace');
    is($cmd->property_function, 'add_friend', 'property_function');

    ok(!$cmd->execute, 'fails w/o params');
    is(scalar(@$error_messages), 3, 'Got 3 error messages');
    foreach my $expected (  qr{Property 'test_muppets': No value specified for required property},
                            qr{Property 'values': No value specified for required property},
                            qr{Please see 'test muppet update friends add --help' for more information\.},
    ) {
        like(shift(@$error_messages),
            $expected,
            'Check error message content');
    }

    $cmd->is_executed(undef);
    @$error_messages = ();

    $cmd->test_muppets([$test{ernie}]);
    ok(!$cmd->execute, 'fails w/o value');
    is(scalar(@$error_messages), 2, 'Got 2 error messages');
    foreach my $expected (  qr{Property 'values': No value specified for required property},
                            qr{Please see 'test muppet update friends add --help' for more information\.},
    ) {
        like(shift(@$error_messages),
            $expected,
            'Check error message content');
    }

    $cmd->is_executed(undef);
    @$error_messages = ();

    $test{ernie}->add_friend($test{burt});
    is_deeply([$test{ernie}->friends], [$test{burt}], 'ernie is friends with burt');
    $cmd->values([$test{gonzo}]);
    ok($cmd->execute, 'add friend');
    is(scalar(@$error_messages), 0, 'Got 0 error messages');
    my @status_messages = $cmd->status_messages();
    is(scalar(@status_messages), 1, 'Got 1 status message');
    like($status_messages[0], qr{ADD_FRIEND\s+\w+\s+\w+}, 'added friend message');
    is_deeply([sort {$a->name cmp $b->name} $test{ernie}->friends], [sort {$a->name cmp $b->name} ($test{burt}, $test{gonzo})], 'ernie is friends with burt and gonzo');
    ok(UR::Context->commit, 'commit');
};

subtest 'remove friend' => sub{
    plan tests => 20;

    my $pkg = 'Test::Muppet::Command::Update::Friends::Remove';
    ok(UR::Object::Type->get($pkg), 'muppet remove friends command exists'),

    my $cmd = $pkg->create;
    $cmd->dump_error_messages(0);
    $cmd->queue_error_messages(1);
    $cmd->dump_status_messages(0);
    $cmd->queue_status_messages(1);
    my $error_messages = $cmd->error_messages_arrayref();

    is($cmd->namespace, 'Test::Muppet::Command', 'namespace');
    is($cmd->property_function, 'remove_friend', 'property_function');

    ok(!$cmd->execute, 'fails w/o params');
    is(scalar(@$error_messages), 3, 'Got 3 error messages');
    foreach my $expected (  qr{Property 'test_muppets': No value specified for required property},
                            qr{Property 'values': No value specified for required property},
                            qr{Please see 'test muppet update friends remove --help' for more information\.},
    ) {
        like(shift(@$error_messages), $expected, 'Check error message content');
    }
    is(scalar($cmd->status_messages), 0, 'Got 0 status messages');

    $cmd->is_executed(undef);
    @$error_messages = ();

    $cmd->test_muppets([$test{ernie}]);
    ok(!$cmd->execute, 'fails w/o value');
    is(scalar(@$error_messages), 2, 'Got 2 error messages');
    foreach my $expected (  qr{Property 'values': No value specified for required property},
                            qr{Please see 'test muppet update friends remove --help' for more information\.},
    ) {
        like(shift(@$error_messages), $expected, 'Check error message content');
    }

    $cmd->is_executed(undef);
    @$error_messages = ();

    is_deeply([sort {$a->name cmp $b->name} $test{ernie}->friends], [sort {$a->name cmp $b->name} ($test{burt}, $test{gonzo})], 'ernie is friends with burt and gonzo');
    $cmd->values([$test{gonzo}]);
    ok($cmd->execute, 'remove friend');
    is(scalar(@$error_messages), 0, 'Got 0 error messages');
    my @status_messages = $cmd->status_messages;
    is(scalar(@status_messages), 1, 'Got 1 status message');
    like($status_messages[0], qr{REMOVE_FRIEND\s+\w+\s\w+}, 'REMOVE_FRIEND status message');

    is_deeply([$test{ernie}->friends], [$test{burt}], 'ernie is friends with burt');
    ok(UR::Context->commit, 'commit');
};

done_testing();
