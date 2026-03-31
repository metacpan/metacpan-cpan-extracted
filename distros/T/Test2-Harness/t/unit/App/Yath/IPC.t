use Test2::V0 -target => 'App::Yath::IPC';
use File::Spec;
use File::Temp qw/tempdir/;

subtest 'dir() does not warn when ENV USER is unset' => sub {
    my $tmp = tempdir(CLEANUP => 1);

    # Build minimal mock settings for the dir() method
    my $ipc_group = mock {} => (
        add => [dir => sub { undef }],
    );
    my $yath_group = mock {} => (
        add => [
            base_dir => sub { $tmp },
            orig_tmp => sub { $tmp },
        ],
    );
    my $settings = mock {} => (
        add => [
            ipc  => sub { $ipc_group },
            yath => sub { $yath_group },
        ],
    );

    my $ipc = $CLASS->new(settings => $settings);

    # Delete USER and LOGNAME to simulate CI environment
    local $ENV{USER};
    delete $ENV{USER};
    local $ENV{LOGNAME};
    delete $ENV{LOGNAME};

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $dir = $ipc->dir;

    is(\@warnings, [], 'no warnings when $ENV{USER} is not set');
    ok(defined $dir, 'dir() returns a defined value');
    like($dir, qr/yath-ipc-unknown-/, 'dir falls back to "unknown" username');
};

subtest 'dir() username fallback chain' => sub {
    my $tmp = tempdir(CLEANUP => 1);

    my $ipc_group = mock {} => (
        add => [dir => sub { undef }],
    );
    my $yath_group = mock {} => (
        add => [
            base_dir => sub { $tmp },
            orig_tmp => sub { $tmp },
        ],
    );
    my $settings = mock {} => (
        add => [
            ipc  => sub { $ipc_group },
            yath => sub { $yath_group },
        ],
    );

    # LOGNAME fallback when USER is unset
    {
        local $ENV{USER};
        delete $ENV{USER};
        local $ENV{LOGNAME} = 'cirunner';

        my $ipc = $CLASS->new(settings => $settings);
        my $dir = $ipc->dir;
        like($dir, qr/yath-ipc-cirunner-/, 'falls back to LOGNAME when USER is unset');
    }

    # USER takes priority over LOGNAME
    {
        local $ENV{USER} = 'testuser';
        local $ENV{LOGNAME} = 'other';

        my $ipc = $CLASS->new(settings => $settings);
        my $dir = $ipc->dir;
        like($dir, qr/yath-ipc-testuser-/, 'USER takes priority over LOGNAME');
    }
};

done_testing;
