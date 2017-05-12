#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket;
use Data::Dumper;
use File::Basename;
use Carp;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use Test::More tests => 5;

use UR::Namespace::Command::Old::DiffRewrite;

my $test_class = "UR::Namespace::Command::Old::DiffRewrite";
my $test_class_parent = 'UR::Namespace::Command::Base';

# The messaging methods print to the filehandle $Command::stderr, which defaults
# to STDERR.  Redefine it so the messages are printed to a filehandle we
# can read from, $stderr_twin, but regular perl diagnostic messages still go
# to the real STDERR
my $stderr_twin;
$UR::ModuleBase::stderr = undef;
socketpair($UR::ModuleBase::stderr,$stderr_twin, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
$UR::ModuleBase::stderr->autoflush(1);
$stderr_twin->blocking(0);

my $filename = __FILE__;

my $croak_ending_string = determine_croak_message_ending_string();

for my $type (qw/fatal error warning status/) {
    subtest "$type message" => sub {
        plan tests => 9;

        my $buffer;
        my $accessor = $type . "_message";

        my $uc_type = uc($type);
        my $msg_prefix = ($type eq "status" ? "" : "$uc_type: ");

        my $msg_source_sub = $accessor . '_source';

        for my $do_queue ([],[0],[1]) {
            for my $do_dump ([],[0],[1]) {
                my $subtest_do_queue = defined $do_queue->[0] ? $do_queue->[0] : '<undef>';
                my $subtest_do_dump = defined $do_dump->[0] ? $do_dump->[0] : '<undef>';
                subtest "queue: $subtest_do_queue, dump: $subtest_do_dump" => sub {

                    my $dump_flag = "dump_" . $type . "_messages";
                    $test_class->$dump_flag(@$do_dump);

                    my $queue_flag = "queue_" . $type . "_messages";
                    $test_class->$queue_flag(@$do_queue);

                    my $test_sending_message = sub {
                        my($messaging_args, $expected_message) = @_;
                        my $ok_message = "$type setting works for args: ".join(', ', @$messaging_args);
                        my $message_line;
                        if ($type eq 'fatal') {
                            my $got_die_message;
                            local $SIG{__DIE__} = sub { $got_die_message = shift };
                            $message_line = __LINE__ + 1;
                            eval { $test_class->$accessor(@$messaging_args) };
                            my $expected_die_message = "FATAL: $expected_message at $filename line $message_line${croak_ending_string}";
                            is($got_die_message, $expected_die_message, $ok_message);
                            is($@, $expected_die_message, "(exception) $ok_message");
                        } else {
                            $message_line = __LINE__ + 1;    # The messaging sub will be called on the next line
                            is($test_class->$accessor(@$messaging_args), $expected_message,       $ok_message);
                            $buffer = $stderr_twin->getline;
                            is($buffer,
                                ($test_class->$dump_flag ? "${msg_prefix}$expected_message\n" : undef),
                                ($test_class->$dump_flag ?  "got message" : "no dump")
                              );
                        }
                        return $message_line;
                    };

                    my $list_accessor = $accessor . "s";

                    is($test_class->$accessor(),         undef ,         "$type starts unset");
                    $buffer = $stderr_twin->getline;
                    is($buffer, undef, "no message");

                    my $cb_register = $type . "_messages_callback";
                    my $cb_msg_count = 0;
                    my @cb_args;
                    my $callback_sub = sub { @cb_args = @_; $cb_msg_count++;};
                    ok($test_class->$cb_register($callback_sub), "can set callback");
                    is($test_class->$cb_register(), $callback_sub, 'can get callback');

                    my $message_line = $test_sending_message->(['error%d', 1], 'error1');

                    my %source_info = $test_class->$msg_source_sub();
                    is_deeply(\%source_info,
                              { $accessor => 'error1',
                                $type.'_package' => 'main',
                                $type.'_file' => __FILE__,
                                $type.'_line' => $message_line,
                                $type.'_subroutine' => undef },   # not called from within a sub
                              "$msg_source_sub returns correct info");

                    is($cb_msg_count, 1, "$type callback fired");
                    is_deeply(
                        \@cb_args,    [$test_class, "error1"],       "$type callback got correct args"
                    );

                    is($test_class->$accessor(),         "error1",       "$type returns");
                    $buffer = $stderr_twin->getline;
                    is($buffer, undef, "no dump");

                    $test_sending_message->(['error2'],'error2');

                    is($cb_msg_count, 2, "$type callback fired");

                    is($test_class->$accessor(),         "error2",       "$type returns");
                    is_deeply(
                        \@cb_args,    [$test_class, "error2"],       "$type callback got correct args"
                    );

                    is_deeply(
                        [$test_class->$list_accessor],
                        ($test_class->$queue_flag ? ["error1","error2"] : []),
                        ($test_class->$queue_flag ? "$type list is correct" : "$type list is correctly empty")
                    );

                    is($test_class->$accessor(undef),    undef ,         "undef message sent to $type");

                    is($cb_msg_count, 3, "$type callback fired");

                    $buffer = $stderr_twin->getline;
                    is($buffer, undef, 'Setting undef message results in no output');

                    is($test_class->$accessor(),         undef ,         "$type still has the previous message");
                    is_deeply(
                        \@cb_args,    [$test_class, undef],       "$type callback got correct args"
                    );

                    is_deeply(
                        [$test_class->$list_accessor],
                        ($test_class->$queue_flag ? ["error1","error2"] : []),
                        ($test_class->$queue_flag ? "$type list is correct" : "$type list is correctly empty")
                    );

                    my $listref_accessor = $list_accessor . "_arrayref";
                    my $listref = $test_class->$listref_accessor();
                    is_deeply(
                        $listref,
                        ($test_class->$queue_flag ? ['error1','error2'] : []),
                        "$type listref is correct"
                    );

                    $test_class->$cb_register(sub { $_[1] .= "foo"});
                    $test_sending_message->(['altered'], 'alteredfoo');
                    is_deeply(
                        [$test_class->$list_accessor],
                        ($test_class->$queue_flag ? ["error1","error2","alteredfoo"] : []),
                        ($test_class->$queue_flag ? "$type list is correct" : "$type list is correctly empty")
                    );

                    $test_class->$cb_register(undef);  # Unset the callback

                    is($test_class->$accessor(undef),    undef ,         "undef message sent to $type message");
                    is($cb_msg_count, 3, "$type callback correctly didn't get fired");
                    $buffer = $stderr_twin->getline();
                    is($buffer, undef, 'Setting undef message results in no output');
                    is_deeply(
                        [$test_class->$list_accessor],
                        ($test_class->$queue_flag ? ["error1","error2","alteredfoo"] : []),
                        ($test_class->$queue_flag ? "$type list is correct" : "$type list is correctly empty")
                    );

                    if ($test_class->$queue_flag) {
                        $listref->[2] = "something else";
                        is_deeply(
                            [$test_class->$list_accessor],
                            ["error1","error2","something else"],
                            "$type list is correct after changing via the listref"
                        );


                        @$listref = ();
                        is_deeply(
                            [$test_class->$list_accessor],   [],    "$type list cleared out as expected"
                        );
                    }
                    done_testing();
                };
            }

        }
    };
}

subtest 'set message on instance, but retrieve via its class' => sub {
    plan tests => 6;

    $_->dump_error_messages(0) foreach ($test_class, $test_class_parent);
    $_->queue_error_messages(1) foreach ($test_class, $test_class_parent);

    my $o1 = $test_class->create(namespace_name => 'URT');
    my $o2 = $test_class->create(namespace_name => 'URT');

    my $message_to_obj1 = 'message to object 1';
    ok($o1->error_message($message_to_obj1), 'send message to first object instance');

    my $message_to_obj2 = 'message to object 2';
    ok($o2->error_message($message_to_obj2), 'send message to second object instance');

    my $message_to_class = 'message to class';
    ok($test_class->error_message($message_to_class), 'send message to class');

    my $message_to_parent_class = 'message to parent class';
    ok($test_class_parent->error_message($message_to_parent_class), 'send message to parent class');

    my @messages = $test_class->error_messages();
    is_deeply(\@messages,
            [ $message_to_class, $message_to_obj1, $message_to_obj2 ],
            'Got messages back from the class, including instances');

    @messages = $test_class_parent->error_messages();
    is_deeply(\@messages,
            [ $message_to_parent_class, $message_to_class, $message_to_obj1, $message_to_obj2 ],
            'Got messages back from the parent class, including instances');

    $_->dump_error_messages(1) foreach ($test_class, $test_class_parent);
    $_->queue_error_messages(0) foreach ($test_class, $test_class_parent);
};

# Later versions of Carp::croak put a period at the end of the exception
# message.  Earlier versions have no period
sub determine_croak_message_ending_string {
    eval { Carp::croak "test" };
    my($maybe_period) = $@ =~ m/test at \S+ line \d+(\.?)/;
    return "$maybe_period\n";
}

1;
