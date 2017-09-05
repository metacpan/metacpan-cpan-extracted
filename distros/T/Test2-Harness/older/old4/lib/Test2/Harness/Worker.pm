package Test2::Harness::Worker;
use strict;
use warnings;

use Carp qw/confess croak/;
use POSIX qw/:sys_wait_h/;
use IPC::Cmd qw/can_run/;
use IPC::Open3 qw/open3/;
use Scalar::Util qw/blessed openhandle/;
use Time::HiRes qw/sleep time/;

use File::Spec;

use Test2::Harness::Util qw/write_file_atomic open_file/;

use Test2::Harness;
use Test2::Harness::Job;

use Test2::Harness::HashBase qw{
    -harness -run_id -run_dir
    -pid
    -_preload_list
    -jobs
    -_active
};

sub init {
    my $self = shift;

    croak "'run_id' and 'run_dir' attributes must both be specified, or both be ommited"
        if ($self->{+RUN_ID} xor $self->{+RUN_DIR});

    if ($self->{+HARNESS}) {
        @{$self}{(+RUN_ID, +RUN_DIR)} = $self->{+HARNESS}->make_run unless $self->{+RUN_ID};
    }
    elsif (my $run_dir = $self->{+RUN_DIR}) {
        $self->{+HARNESS} = Test2::Harness->load(File::Spec->catfile($run_dir, 'config'));
    }

    croak "You must provide either a 'harness' or an initialized 'run_dir'"
        unless $self->{+HARNESS};

    $self->{+JOBS} ||= [];
}

sub active {
    my $self = shift;

    return 1 if $self->{+_ACTIVE};

    my $pid = $self->{+PID} or return 0;

    my $ret = waitpid($pid, WNOHANG);
    my $exit = $?;

    # Still active
    return 1 if $ret == 0;

    # Something else reaped it?
    if ($ret == -1) {
        warn "Worker process ($pid) is missing, is something else reaping children?" if $ret == -1;
        delete $self->{+PID};
        return 1;
    }

    confess "Internal Error, pid mismatch after wait" if $ret != $pid;

    delete $self->{+PID};
    $exit >>= 8;
    die "Worker process failure (Exit Code: $exit)" if $exit;

    # If we only just exited we want to return true once more so that final
    # polling can happen, next call to active will return false.
    return 1;
}

sub spawn {
    my $self = shift;

    my $runner;
    if ($0 =~ m{yath$}) {
        $runner = File::Spec->rel2abs($0 . '-runner');
    }

    if (!$runner || !-f $runner) {
        $runner = can_run('yath-runner') or die "Could not find 'yath-runner' in execution path";
    }

    # Find out where Test2::Harness::Worker came from, make sure that is in our workers @INC
    my $inc = $INC{"Test2/Harness/Worker.pm"};
    $inc =~ s{/Test2/Harness/Worker\.pm$}{}g;
    $inc = File::Spec->rel2abs($inc);

    $self->{+PID} = open3(
        undef, ">&" . fileno(STDOUT), ">&" . fileno(STDERR),
        $^X,
        "-I$inc",
        $runner,
        blessed($self),
        run_id => $self->{+RUN_ID},
        run_dir => $self->{+RUN_DIR},
    );
}

sub poll {
    my $self = shift;

    my $jobs = $self->{+JOBS};
    my $run_dir = $self->{+RUN_DIR};

    opendir(my $run_handle, $run_dir) or die "Could not open run dir '$run_dir': $!";

    my $harness = $self->{+HARNESS};
    for my $id (readdir($run_handle)) {
        next unless $id =~ m/^\d+$/;
        next if $jobs->[$id];

        $jobs->[$id] = Test2::Harness::Job->new(
            job_id  => $id,
            job_dir => File::Spec->catdir($run_dir, $id),
            harness => $self->{+HARNESS},
        );
    }

    closedir($run_handle);
    return map { $_ ? $_->poll : () } @$jobs;
}

sub run {
    my $self = shift;
    confess "Worker is already active" if $self->{+_ACTIVE};
    local $self->{+_ACTIVE} = 1;
    my %params = @_;
    my $harness = $self->{+HARNESS};
    my $curdir = File::Spec->curdir();
    chdir($harness->rootdir) or die "Could not chdir to '" . $harness->rootdir . "': $!";

    my $file;
    my $ok = eval { $file = $self->_run(%params); 1 };
    my $err = $@;

    # Go back to the original directory, unless we have a file to run.
    unless($file) {
        chdir($curdir) or die "Could not chdir to '$curdir': $!";
    }

    die $err unless $ok;
    return $file;
}

sub _run {
    my $self = shift;
    my %params = @_;

    my $run_dir = $self->{+RUN_DIR};
    my $harness = $self->{+HARNESS};
    my $preload = $harness->load_preloads;
    $self->preload_list if $preload;

    my $id = 1;
    my @active;
    for my $test ($harness->find_tests) {
        while (@active >= $harness->jobs) {
            $params{poll}->($self->poll) if $params{poll};
            next if $self->_reap(\@active);
            sleep 0.02;
        }

        my $job_id = $id++;

        my $job_dir = File::Spec->catdir($run_dir, $job_id);
        mkdir($job_dir) or die "Could not create directory '$job_dir': $!";
        my $job_file = File::Spec->catfile($job_dir, 'job');
        write_file_atomic($job_file, $test->filename . "\n");

        if ($preload && !$test->no_preload) {
            my $pid = fork;
            confess "Failed to fork" unless defined $pid;

            # Child
            return $self->run_preloaded($job_id, $test) unless $pid;

            # Parent
            push @active => [time, $job_id, $pid];
        }
        else {
            push @active => [time, $job_id, $self->run_open3($job_id, $test)];
        }
    }

    while (@active) {
        $params{poll}->($self->poll) if $params{poll};
        next if $self->_reap(\@active);
        sleep 0.02;
    }

    $params{poll}->($self->poll) if $params{poll};

    return undef;
}

sub make_handles {
    my $self = shift;
    my ($job_path) = @_;

    my $out_file = File::Spec->catfile($job_path, 'stdout');
    my $out_fh = open_file($out_file, '>');

    my $err_fh;
    if ($self->{+HARNESS}->merge) {
        open($err_fh, '>&', $out_fh) or die "Could not open new STDERR: $!";
    }
    else {
        my $err_file = File::Spec->catfile($job_path, 'stderr');
        $err_fh = open_file($err_file, '>');
    }

    return ($out_fh, $err_fh);
}

sub run_open3 {
    my $self = shift;
    my ($job_id, $test) = @_;

    my $harness = $self->{+HARNESS};
    my $job_path = File::Spec->catdir($self->{+RUN_DIR}, $job_id);
    my $file = $test->filename;

    my ($out_write, $err_write) = $self->make_handles($job_path);

    local $ENV{T2_FORMATTER}         = 'Stream';
    local $ENV{T2_STREAM_SERIALIZER} = 'JSON';
    local $ENV{T2_STREAM_FILE}       = File::Spec->catfile($job_path, 'events');
    local $ENV{T2_STREAM_ID}         = $job_id;

    my $muxing = $harness->output_muxing;
    my $events = $harness->output_events;
    my $mux_file = File::Spec->catfile($job_path, 'muxed');

    my @mods;
    if ($muxing && $events) {
        push @mods => "-MTest2::Plugin::IOSync=$mux_file";
    }
    elsif ($muxing) {
        push @mods => "-MTest2::Plugin::IOMuxer=$mux_file";
    }
    elsif ($events) {
        push @mods => "-MTest2::Plugin::IOEvents";
    }

    my $cmd = $harness->perl_command;

    my $pid;
    $cmd->(
        sub {
            $pid = open3(
                undef, ">&" . fileno($out_write), ">&" . fileno($err_write),
                @_,
                @mods,
                $file,
            );
        }
    );

    return $pid;
}

sub run_preloaded {
    my $self = shift;
    my ($job_id, $test) = @_;

    my $harness = $self->{+HARNESS};
    my $job_path = File::Spec->catdir($self->{+RUN_DIR}, $job_id);
    my $file = $test->filename;

    $ENV{T2_FORMATTER}         = 'Stream';
    $ENV{T2_STREAM_SERIALIZER} = 'JSON';
    $ENV{T2_STREAM_FILE}       = File::Spec->catfile($job_path, 'events');
    $ENV{T2_STREAM_ID}         = $job_id;

    $0 = $file;
    $self->_reset_DATA($file);
    @ARGV = ();

    # if FindBin is preloaded, reset it with the new $0
    FindBin::init() if defined &FindBin::init;

    # restore defaults
    Getopt::Long::ConfigDefaults() if defined &Getopt::Long::ConfigDefaults;

    # reset the state of empty pattern matches, so that they have the same
    # behavior as running in a clean process.
    # see "The empty pattern //" in perlop.
    # note that this has to be dynamically scoped and can't go to other subs
    "" =~ /^/;

    open(my $stderr, '>&', *STDERR) or die "Could not clone STDERR: $!";
    my ($out_write, $err_write) = $self->make_handles($job_path);
    my $die = sub { print $stderr @_; exit 255 };

    close(STDOUT) or $die->("Could not close STDOUT: $!");
    open(STDOUT, '>&', fileno($out_write)) or $die->("Could not open new STDOUT: $!");

    close(STDERR) or $die->("Could not close STDERR: $!");
    open(STDERR, '>&', fileno($err_write)) or $die->("Could not open new STDERR: $!");

    # avoid child processes sharing the same seed value as the parent
    srand();

    my $muxing = $harness->output_muxing;
    my $events = $harness->output_events;
    my $mux_file = File::Spec->catfile($job_path, 'muxed');

    my @mods;
    if ($muxing && $events) {
        require Test2::Plugin::IOSync;
        Test2::Plugin::IOSync->import($mux_file);
    }
    elsif ($muxing) {
        require Test2::Plugin::IOMuxer;
        Test2::Plugin::IOMuxer->import($mux_file);
    }
    elsif ($events) {
        require Test2::Plugin::IOEvents;
        Test2::Plugin::IOEvents->import;
    }

    Test2::API::test2_reset_io() if $INC{'Test2/API.pm'};

    # Test::Builder is loaded? Reset the $Test object to make it unaware
    # that it's a forked off process so that subtests won't run
    if ($INC{'Test/Builder.pm'}) {
        if (defined $Test::Builder::Test) {
            $Test::Builder::Test->reset;
        }
        else {
            Test::Builder->new;
        }
    }

    return $file;
}

# Heavily modified from forkprove
sub _reset_DATA {
    my $self = shift;
    my ($file) = @_;

    # open DATA from test script
    if (openhandle(\*main::DATA)) {
        close ::DATA;
        if (open my $fh, $file) {
            my $code = do { local $/; <$fh> };
            if(my($data) = $code =~ /^__(?:END|DATA)__$(.*)/ms){
                open ::DATA, '<', \$data
                  or die "Can't open string as DATA. $!";
            }
        }
    }

    for my $set ($self->preload_list) {
        my ($mod, $file, $pos) = @$set;

        my $fh = do {
            no strict 'refs';
            *{ $mod . '::DATA' }
        };

        # note that we need to ensure that each forked copy is using a
        # different file handle, or else concurrent processes will interfere
        # with each other

        close $fh if openhandle($fh);

        if (open $fh, '<', $file) {
            seek($fh, $pos, 0);
        }
        else {
            warn "Couldn't reopen DATA for $mod ($file): $!";
        }
    }
}

# Heavily modified from forkprove
sub preload_list {
    my $self = shift;

    return @{$self->{+_PRELOAD_LIST}} if $self->{+_PRELOAD_LIST};

    my $list = $self->{+_PRELOAD_LIST} = [];

    for my $loaded (keys %INC) {
        next unless $loaded =~ /\.pm$/;

        my $mod = $loaded;
        $mod =~ s{/}{::}g;
        $mod =~ s{\.pm$}{};

        my $fh = do {
            no strict 'refs';
            no warnings 'once';
            *{ $mod . '::DATA' }
        };

        next unless openhandle($fh);
        push @$list => [ $mod, $INC{$loaded}, tell($fh) ];
    }

    return @$list;
}

sub _reap {
    my $self = shift;
    my ($list) = @_;

    my $reaped = 0;
    my @keep;

    for my $set (@$list) {
        my ($time, $id, $pid, @io) = @$set;

        my $ret = waitpid($pid, WNOHANG);
        my $exit = $?;

        if($ret == 0) {
            push @keep => $set;
            next;
        }

        die "Process $pid was already reaped!" if $ret == -1;

        $reaped++;
        $exit >>= 8;

        for my $fh (@io) {
            close($fh) or die "Could not close handle: $!";
        }

        my $exit_file = File::Spec->catfile($self->{+RUN_DIR}, $id, 'exit');
        write_file_atomic($exit_file, "$exit\n");
    }

    @$list = @keep;

    return $reaped;
}


1;
