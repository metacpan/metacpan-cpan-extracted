# HARNESS-NO-PRELOAD

my $WAITPID;
my $WAITPID_ARGS;
my $WAITPID_EXIT;
BEGIN { *CORE::GLOBAL::waitpid = sub { $WAITPID_ARGS = [@_]; $? = ($WAITPID_EXIT << 8); $WAITPID } }
use Test2::Bundle::Extended -target => 'Test2::Harness::Util::Proc';

use ok $CLASS;

subtest construction => sub {
    like(
        dies { $CLASS->new() },
        qr/The 'pid' attribute is required/,
        "Need 'pid'"
    );

    # Use a fake PID so we do not accidentally kill anything real.
    ok(my $one = $CLASS->new(pid => 'abcdefg'), "Created new instance");
};

subtest complete => sub {
    # Make sure it is not real, just in case..
    my $pid = 999999999999999999999999999999999;
    my $one = $CLASS->new(pid => $pid);
    $one->{exit} = 0;
    ok($one->complete, "Complete because exit is defined");
    $one->{exit} = 1;
    ok($one->complete, "Complete because exit is set");

    delete $one->{exit};
    $WAITPID = $pid;
    $WAITPID_EXIT = 11;
    ok($one->complete, "Complete after wait");
    is($one->exit, 11, "set exit");

    delete $one->{exit};
    $WAITPID = $pid;
    $WAITPID_EXIT = 0;
    ok($one->complete, "Complete after wait");
    is($one->exit, 0, "set exit");
};

subtest wait => sub {
    my $pid = 999999999999999999999999999999999;
    my $one = $CLASS->new(pid => $pid);

    $WAITPID_EXIT = 42;
    $WAITPID = $pid;
    my $out = $one->wait(1234);
    is($out, $pid, "Success");
    is($one->exit, 42, "set exit value");
    is(
        $WAITPID_ARGS,
        [$pid, 1234],
        "used expected args",
    );

    $out = $one->wait(1234);
    is($out, -1, "Already reaped");

    delete $one->{exit};

    $WAITPID = 0;
    is($one->wait, 0, "nothing reaped");
    ok(!$one->complete, "not complete");

    $WAITPID = -1;
    like(
        dies { $one->wait },
        qr/^Process \S+ was already reaped/,
        "Exception if a process is being reaped unexpectedly"
    );
};

done_testing;
