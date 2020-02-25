use Test2::V0;
require IO::Handle;

BEGIN {
    if (eval { require Capture::Tiny; 1 }) {
        Capture::Tiny->import('capture');

        *CAPTURE_TINY = sub { 1 };
    }
    else {
        *CAPTURE_TINY = sub { 0 };
    }
}

my $events = intercept {
    require Test2::Plugin::IOEvents;
    Test2::Plugin::IOEvents->import;

    print "Hello\n";
    print STDOUT "Hello STDOUT\n";
    print STDERR "Hello STDERR\n";
    warn "Hello WARN\n";

    subtest foo => sub {
        ok(1, "assert");
        print "Hello\n";
        print STDOUT "Hello STDOUT\n";
        print STDERR "Hello STDERR\n";
        warn "Hello WARN\n";
    };
};

like(
    $events,
    [
        {info => [{tag => 'STDOUT', details => "Hello\n"}]},
        {info => [{tag => 'STDOUT', details => "Hello STDOUT\n"}]},
        {info => [{tag => 'STDERR', details => "Hello STDERR\n"}]},
        {info => [{tag => 'STDERR', details => "Hello WARN\n"}]},
        {
            subevents => [
                {}, # The assert
                {info => [{tag => 'STDOUT', details => "Hello\n"}]},
                {info => [{tag => 'STDOUT', details => "Hello STDOUT\n"}]},
                {info => [{tag => 'STDERR', details => "Hello STDERR\n"}]},
                {info => [{tag => 'STDERR', details => "Hello WARN\n"}]},
            ],
        }
    ],
    "Got the output in the right places, output from subtests is in subtests"
);

my $fh = \*STDOUT;
if (IO::Handle->can('autoflush')) {
    $fh->autoflush(1);
    is($fh->autoflush, 1, "set autoflush");
}

is(syswrite(STDOUT, ""), 0, "syswrite works");

if (CAPTURE_TINY()) {
    my ($stdout, $stderr, $exit) = capture {
        print STDOUT "Hello STDOUT\n";
        print STDERR "Hello STDERR\n";
    };

    is($stdout, "Hello STDOUT\n", "captured stdout");
    is($stderr, "Hello STDERR\n", "captured stderr");
}

ok(open(my $fh1, '>&', STDOUT), "Can clone STDOUT", $!);

open(STDOUT, '>&', *STDERR) or die "Could not change STDOUT: $!";
is(fileno(STDOUT), 1, "kept filehandle");

open(STDOUT, '>&', $fh1) or die "Could not change STDOUT: $!";
is(fileno(STDOUT), 1, "kept filehandle");
close($fh1);

untie(*STDERR);

ok(open(my $fh2, '>&', STDERR), "Can clone STDERR after untie", $!);
close($fh2);

done_testing;
