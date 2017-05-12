use strict;
use warnings;

use Test::More tests => 5;
use Sub::Install qw(install_sub);

use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__)."/../..";
use UR;

subtest 'setup test' => sub {
    plan tests => 3;

    UR::Object::Type->define(
        class_name => 'SomeModule',
    );
    ok(SomeModule->__meta__, 'defined SomeModule');

    install_sub({
        into => 'SomeModule',
        as => 'do_something',
        code => sub {
            my $self = shift;
            $self->debug_message('do_something');
        },
    });

    for my $base_class ('Command::V1', 'Command::V2') {
        my $class_name = 'Some' . $base_class;

        UR::Object::Type->define(
            class_name => $class_name,
            is => $base_class,
        );
        ok($class_name->__meta__, "defined $class_name");

        install_sub({
            into => $class_name,
            as => '_execute_body',
            code => sub {
                my $self = shift;
                $self->debug_message('execute');
                my $sm = SomeModule->create();
                $sm->do_something();
            },
        });

        install_sub({
            into => $class_name,
            as => 'debug',
            code => sub {
                my $self = shift;
                my $debug = $self->super_can('debug');
                if ($self->$debug) {
                    return IO::File->new('/dev/null', 'w');
                } else {
                    return 0;
                }
            },
        });
    }
};

my $command_test_count = 6;
my $command_test = sub {
    my $class = shift;
    my $debug = shift;

    my ($dump_debug_messages, $debug_message) = setup_subtest($class);

    is($dump_debug_messages->{'SomeModule'}, 0,
        'dump_debug_messages disabled on SomeModule');
    is($dump_debug_messages->{$class}, 0,
        "dump_debug_messages disabled on $class");

    $class->_execute_delegate_class_with_params($class, {debug => $debug});

    is($debug_message->{'SomeModule'}, 1, 'debug_message fired on SomeModule');
    is($debug_message->{$class}, 1, "debug_message fired on $class");

    my $status = $debug ? 'enabled' : 'disabled';
    ok(!!$dump_debug_messages->{'SomeModule'} == !!$debug,
        "dump_debug_messages $status on SomeModule");
    ok(!!$dump_debug_messages->{$class} == !!$debug,
        "dump_debug_messages $status on $class");
};

subtest 'Command::V1 with --debug' => sub {
    plan tests => $command_test_count;
    $command_test->('SomeCommand::V1', 1);
};
subtest 'Command::V1 without --debug' => sub {
    plan tests => $command_test_count;
    $command_test->('SomeCommand::V1', 0);
};
subtest 'Command::V2 with --debug' => sub {
    plan tests => $command_test_count;
    $command_test->('SomeCommand::V2', 1);
};
subtest 'Command::V2 without --debug' => sub {
    plan tests => $command_test_count;
    $command_test->('SomeCommand::V2', 0);
};

sub setup_subtest {
    my $cmd_class = shift;

    UR::ModuleBase->dump_debug_messages(0);
    $cmd_class->dump_debug_messages(0);

    my %dump_debug_messages = (
        'SomeModule' => SomeModule->dump_debug_messages,
        $cmd_class => $cmd_class->dump_debug_messages,
    );
    my %debug_message = (
        'SomeModule' => 0,
        $cmd_class => 0,
    );
    my $callback = sub {
        my ($self, $type, $message) = @_;
        my $class = $self->class;
        $dump_debug_messages{$class} = $self->dump_debug_messages;
        $debug_message{$class} = 1;
    };

    SomeModule->add_observer(
        aspect => 'debug_message',
        callback => $callback,
    );

    $cmd_class->add_observer(
        aspect => 'debug_message',
        callback => $callback,
    );

    return (\%dump_debug_messages, \%debug_message);
}
