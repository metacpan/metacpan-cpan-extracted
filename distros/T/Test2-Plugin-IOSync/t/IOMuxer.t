use Test2::Bundle::Extended -target => 'Test2::Plugin::IOMuxer';
use File::Temp qw/tempfile/;
use IPC::Open3 qw/open3/;
use List::Util qw/first/;

{
    no warnings 'redefine';
    *Test2::Plugin::IOMuxer::Layer::time = sub() { 12345 };
}

ok($INC{'Test2/Plugin/OpenFixPerlIO.pm'}, "Loaded OpenFixPerlIO");

subtest mux_handle => sub {
    Test2::Plugin::IOMuxer->import(qw/mux_handle/);
    imported_ok('mux_handle');
    my ($fh, $name)  = tempfile("$$-XXXXXXXX");
    my ($mh, $muxed) = tempfile("$$-XXXXXXXX");
    close($mh) or die "$!";

    mux_handle($fh, $muxed);

    print $fh "This is a test\n";
    print $fh "This is a\nmulti-line test\n";
    print $fh "This is a no line-end test 1";
    print $fh "This is a no line-end test 2";
    print $fh "\n";
    print $fh "This is the final test\n";
    close($fh) or die "$!";

    open($fh, '<', $name) or die "$!";

    is(
        [<$fh>],
        [
            "This is a test\n",
            "This is a\n",
            "multi-line test\n",
            "This is a no line-end test 1This is a no line-end test 2\n",
            "This is the final test\n",
        ],
        "Got all lines as expected in main handle"
    );

    close($Test2::Plugin::IOMuxer::Layer::MUX_FILES{$muxed}) or die "$!";
    $Test2::Plugin::IOMuxer::Layer::MUX_FILES{$muxed} = undef;

    open($mh, '<', $muxed) or die "$!";
    like(
        [<$mh>],
        [
            qr{^START-TEST2-SYNC-\d+: 12345\n$},
            qr{^This is a test\n$},
            qr{^\+STOP-TEST2-SYNC-\d+: 12345\n$},
            qr{^START-TEST2-SYNC-\d+: 12345\n$},
            qr{^This is a\n$},
            qr{^multi-line test\n$},
            qr{^\+STOP-TEST2-SYNC-\d+: 12345\n$},
            qr{^START-TEST2-SYNC-\d+: 12345\n$},
            qr{^This is a no line-end test 1\n$},
            qr{^-STOP-TEST2-SYNC-\d+: 12345\n$},
            qr{^START-TEST2-SYNC-\d+: 12345\n$},
            qr{^This is a no line-end test 2\n$},
            qr{^-STOP-TEST2-SYNC-\d+: 12345\n$},
            qr{^START-TEST2-SYNC-\d+: 12345\n$},
            qr{^\n$},
            qr{^\+STOP-TEST2-SYNC-\d+: 12345\n$},
            qr{^START-TEST2-SYNC-\d+: 12345\n$},
            qr{^This is the final test\n$},
            qr{^\+STOP-TEST2-SYNC-\d+: 12345\n$},
        ],
        "Got all lines as expected, with markers in mux file"
    );

    unlink($name);
    unlink($muxed);
};

subtest mux_test_io => sub {
    my ($out_fh, $out_file) = tempfile("$$-XXXXXXXX");
    my ($err_fh, $err_file) = tempfile("$$-XXXXXXXX");
    my ($mux_fh, $mux_file) = tempfile("$$-XXXXXXXX");
    close($mux_fh);

    {
        local $ENV{T2_FORMATTER}       = 'TAP';
        local $ENV{T2_HARNESS_VERBOSE} = 0;
        local $ENV{T2_HARNESS_ACTIVE}  = 0;
        local $ENV{HARNESS_VERBOSE}    = 0;
        local $ENV{HARNESS_ACTIVE}     = 0;
        local $ENV{PERL5LIB}           = join ':' => @INC;

        my $file = first { -e $_ } './t/iotest.pl', './iotest.pl';
        my $pid = open3(undef, '>&' . fileno($out_fh), '>&' . fileno($err_fh), $^X, '-Ilib', "-M$CLASS=$mux_file", $file);

        waitpid($pid, 0);
        is($?, 0, "subprocess exited fine");
    }

    close($out_fh);
    close($err_fh);

    open($out_fh, '<', $out_file) or die "$!";
    open($err_fh, '<', $err_file) or die "$!";
    open($mux_fh, '<', $mux_file) or die "$!";

    like(
        [<$out_fh>],
        array {
            item "STDOUT BEFORE TESTING\n";
            item qr/^# Seeded/;
            item "ok 1 - pass 1\n";
            item "STDOUT IN TESTING\n";
            item "ok 2 - pass 2\n";
            item "1..2\n";
            item "STDOUT AFTER TESTING\n";
            end;
        },
        "Got standard output"
    );

    is(
        [<$err_fh>],
        array {
            item "STDERR BEFORE TESTING\n";
            item "# a diag message 1\n";
            item "STDERR IN TESTING\n";
            item "# a diag message 2\n";
            item "STDERR AFTER TESTING\n";
            end;
        },
        "Got standard error"
    );

    like(
        [<$mux_fh>],
        array {
            item qr/^START-TEST2-SYNC-(\d+): [0-9\.]+/;
            item qr/^STDOUT BEFORE TESTING/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^STDERR BEFORE TESTING/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^# Seeded srand with seed/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^ok 1 - pass 1/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^STDOUT IN TESTING/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^ok 2 - pass 2/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^# a diag message 1/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^STDERR IN TESTING/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^# a diag message 2/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^1\.\.2/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^STDOUT AFTER TESTING/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            item qr/^START-TEST2-SYNC-\d+: [0-9\.]+/;
            item qr/^STDERR AFTER TESTING/;
            item qr/^\+STOP-TEST2-SYNC-\d+: [0-9\.]+/;

            end;
        },
        "Got muxed output"
    );

    unlink($out_file);
    unlink($err_file);
    unlink($mux_file);
};

done_testing;
