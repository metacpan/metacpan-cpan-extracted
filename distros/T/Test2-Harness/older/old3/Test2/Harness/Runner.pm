package Test2::Harness::Runner;
use strict;
use warnings;

use POSIX qw/:sys_wait_h/;
use Time::HiRes qw/sleep time/;
use IPC::Open3 qw/open3/;
use Scalar::Util 'openhandle';
use Carp qw/confess/;

use Test2::Util qw/try_sig_mask do_rename/;

use IO::Handle;
use Test2::Harness::Config;

use Test2::Harness::HashBase qw/-run_id -config -run_dir -_preload_list/;

sub import {
    my $class = shift;
    return unless @_;
    my ($run_id, $run_dir) = @_;

    $0 = "Test2::Harness::Runner($run_id, $run_dir)";

    my $config = Test2::Harness::Config->read($run_dir);
    my $preload = $config->load_preloads;

    my $self = bless(
        {
            run_id  => $run_id,
            run_dir => $run_dir,
            config  => $config,
        },
        $class
    );

    # Prep the preload list
    $self->preload_list if $preload;

    my $id = 1;
    my @active;
    for my $test ($config->find_tests) {
        while (@active >= $config->jobs) {
            next if $self->_reap(\@active);
            sleep 0.02;
        }

        my $job_id = $id++;

        chdir($test->chdir) or die "Could not chdir to '" . $test->chdir . "': $!";

        my $job_dir = "${run_dir}/${job_id}";
        mkdir($job_dir) or die "Could not create directory '$job_dir': $!";

        my ($ok, $err) = try_sig_mask {
            my $base_file = "${job_dir}/job";
            open(my $jf, '>', "$base_file.pend") or die "Could not open job file: $!";
            print $jf $test->filename . "\n";
            close($jf) or die "Could not close job file: $!";
            my ($ren_ok, $ren_err) = do_rename("$base_file.pend", $base_file);
            die $ren_err unless $ren_ok;
        };
        die $err unless $ok;

        if ($preload && !$test->no_preload) {
            my $pid = $self->run_preloaded($job_id, $test);
            return unless $pid; # In child

            push @active => [time, $job_id, $pid];
            next;
        }

        push @active => [time, $job_id, $self->run_open3($job_id, $test)];
    }

    while (@active) {
        next if $self->_reap(\@active);
        sleep 0.02;
    }

    exit 0;
}

sub runtime_code { <<"EOT" }
package Test2::Harness::Runner;
#line ${\(__LINE__ + 1)} "${\__FILE__}"
my \$test_file = Test2::Harness::Runner::test_file();
\$@ = '';
package main;
do \$test_file;
die \$@ if \$@;
exit 0;
EOT

sub _make_handles {
    my $self = shift;
    my ($job_path, $file) = @_;

    my ($out_write, $err_write);

    open($out_write, '>', "$job_path/stdout") or die "Could not open new STDOUT: $!";

    if ($self->{+CONFIG}->merge) {
        open($err_write, '>&', $out_write) or die "Could not open new STDERR: $!";
    }
    else {
        open($err_write, '>', "$job_path/stderr") or die "Could not open new STDERR: $!";
    }

    return ($out_write, $err_write);
}

sub run_open3 {
    my $self = shift;
    my ($job_id, $test) = @_;

    my $config = $self->{+CONFIG};
    my $job_path = join '/' => ($self->{+RUN_DIR}, $job_id);
    my $file = $test->filename;

    my ($out_write, $err_write) = $self->_make_handles($job_path, $file);

    my $job_dir = "${job_path}/${job_id}";
    local $ENV{T2_STREAM_FILE} = "$job_dir/events";
    local $ENV{T2_STREAM_ID} = $job_id;

    my $pid = open3(
        undef, ">&" . fileno($out_write), ">&" . fileno($err_write),
        $^X,
        $config->event_stream ? '-MTest2::Harness::EventStream' : (),
        $config->cli_switches($test->shbang->{switches} or ()),
        $file,
    );

    return ($pid, $out_write, $err_write);
}

sub run_preloaded {
    my $self = shift;
    my ($job_id, $test) = @_;

    my $pid = fork();
    confess "Could not fork" unless defined $pid;
    return $pid if $pid;

    my $config = $self->{+CONFIG};
    my $file = $test->filename;
    my $job_path = join '/' => ($self->{+RUN_DIR}, $job_id);

    local $ENV{T2_STREAM_FILE} = "$job_path/events";
    $ENV{T2_STREAM_ID} = $job_id;

    $0 = $file;
    $self->_reset_DATA($file);
    @ARGV = ();

    # Stuff copied shamelessly from forkprove
    ####################
    # if FindBin is preloaded, reset it with the new $0
    FindBin::init() if defined &FindBin::init;

    # restore defaults
    Getopt::Long::ConfigDefaults() if defined &Getopt::Long::ConfigDefaults;

    # reset the state of empty pattern matches, so that they have the same
    # behavior as running in a clean process.
    # see "The empty pattern //" in perlop.
    # note that this has to be dynamically scoped and can't go to other subs
    "" =~ /^/;

    # Test::Builder is loaded? Reset the $Test object to make it unaware
    # that it's a forked off proecess so that subtests won't run
    if ($INC{'Test/Builder.pm'}) {
        if (defined $Test::Builder::Test) {
            $Test::Builder::Test->reset;
        }
        else {
            Test::Builder->new;
        }
    }

    # avoid child processes sharing the same seed value as the parent
    srand();
    ####################
    # End stuff copied from forkprove

    open(my $stderr, '>&', *STDERR) or die "Could not clone STDERR: $!";
    open(my $stdout, '>&', *STDERR) or die "Could not clone STDOUT: $!";
    my ($out_write, $err_write) = $self->_make_handles($job_path, $file);
    my $die = sub { print $stderr @_; exit 255 };

    no strict 'refs';
    *{"Test2::Harness::Runner::test_file"} = sub { $test->filename };

    close(STDOUT) or $die->("Could not close STDOUT: $!");
    open(STDOUT, '>&', fileno($out_write)) or $die->("Could not open new STDOUT: $!");

    close(STDERR) or $die->("Could not close STDERR: $!");
    open(STDERR, '>&', fileno($err_write)) or $die->("Could not open new STDERR: $!");

    if ($config->event_stream) {
        require Test2::Harness::EventStream;
        Test2::Harness::EventStream->import;
    }

    # Let the -e take over.
    return;
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

        my ($ok, $err) = try_sig_mask {
            my $base_file = $self->run_dir . '/' . $id . "/exit";
            open(my $exit_fh, '>', "$base_file.pend") or die "Could not open exit file: $!";
            print $exit_fh "$exit\n";
            close($exit_fh);
            my ($ren_ok, $ren_err) = do_rename("$base_file.pend", $base_file);
            die $ren_err unless $ren_ok;
        };
        die $err unless $ok;
    }

    @$list = @keep;

    return $reaped;
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

1;
