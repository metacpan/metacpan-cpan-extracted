use Test2::Bundle::Extended -target => 'Test2::Plugin::IOEvents';

my $line;
my $events = intercept {
    open(my $stdout, '>&', \*STDOUT) or die "$!";
    open(my $stderr, '>&', \*STDERR) or die "$!";
    local (*STDOUT, *STDERR) = (*$stdout, *$stderr);
    $CLASS->import;
    $line = __LINE__ + 1;
    print STDOUT "Foo STDOUT\n";
    print STDERR "Foo STDERR\n";
    warn "A warning\n";
};

is(
    $events,
    array {
        item event Output => sub {
            call diagnostics => F();
            call message => "Foo STDOUT\n";
            call stream_name => 'STDOUT';

            # Verify the context/trace
            prop file => __FILE__;
            prop line => $line;
        };
        item event Output => sub {
            call diagnostics => T();
            call message => "Foo STDERR\n";
            call stream_name => 'STDERR';

            # Verify the context/trace
            prop file => __FILE__;
            prop line => $line + 1;
        };
        item event Output => sub {
            call diagnostics => T();
            call message => "A warning\n";
            call stream_name => 'STDERR';

            # Verify the context/trace
            prop file => __FILE__;
            prop line => $line + 2;
        };
        end;
    },
    "Got the output events"
);

done_testing;
