package Test2::Harness::Worker;
use strict;
use warnings;

use File::Spec();
use File::Find();
use Test2::Harness::Util::Proc();
use Test2::Harness::Worker::TestFile();

use Carp qw/confess croak/;
use POSIX qw/:sys_wait_h/;
use IPC::Cmd qw/can_run/;
use IPC::Open3 qw/open3/;
use Time::HiRes qw/sleep time/;
use Scalar::Util qw/blessed openhandle/;

use Test2::Util qw/pkg_to_file clone_io get_tid/;


use Test2::Harness::Util::HashBase qw{
    -run
    -workdir
    -proc
    -_active
    -_jobs
    -_preload_list
    -pid -tid
};

our $VERSION = 'FIXME';

sub init {
    my $self = shift;

    $self->{+PID} = $$;
    $self->{+TID} = get_tid;

    if (my $work_dir_root = delete $self->{work_dir_root}) {
        require Test2::Harness::Schema::Workdir;
        $self->{+WORKDIR} = Test2::Harness::Schema::Workdir->new(root => $work_dir_root);
    }

    croak "The 'workdir' attribute is required"
        unless $self->{+WORKDIR};

    if (my $run_id = delete $self->{run_id}) {
        $self->{+RUN} = $self->{+WORKDIR}->run_fetch($run_id);
    }

    croak "The 'run' attribute is required"
        unless $self->{+RUN};
}

sub active {
    my $self = shift;

    return 1 if $self->{+_ACTIVE};

    my $proc = $self->{+PROC} or return 0;
    my $exit = $proc->exit;
    return 0 if defined $exit;

    my $ret = $proc->wait(WNOHANG);
    return 1 if $ret == 0;

    # Update the exit value
    $exit = $proc->exit;

    my $pid = $proc->pid;

    # Something else reaped it?
    if ($ret == -1) {
        die "Worker process ($pid) is missing, is something else reaping children?";
        return 1;
    }

    confess "Internal Error, pid mismatch after wait" if $ret != $pid;

    die "Worker process($pid) failure (Exit Code: $exit)" if $exit;

    # If we only just exited we want to return true once more so that final
    # polling can happen, next call to active will return false.
    return 1;
}

sub find_worker_script {
    my $self = shift;

    my $script = $ENV{T2_HARNESS_WORKER_SCRIPT} || 'yath-worker';
    return $script if -f $script;

    if ($0 && $0 =~ m{(.*)\byath(-.*)?$}) {
        return "$1$script" if -f "$1$script";
    }

    # Do we have the full path?
    if(my $out = can_run($script)) {
        return $out;
    }

    die "Could not find '$script' in execution path";
}

sub find_worker_inc {
    my $self = shift;

    # Find out where Test2::Harness::Run::Worker came from, make sure that is in our workers @INC
    my $inc = $INC{"Test2/Harness/Worker.pm"};
    $inc =~ s{/Test2/Harness/Worker\.pm$}{}g;
    return File::Spec->rel2abs($inc);
}

sub spawn {
    my $self = shift;

    my $script = $self->find_worker_script;
    my $inc    = $self->find_worker_inc;

    my $run = $self->{+RUN};
    $run->save_config;

    my $pid = open3(
        undef, ">&" . fileno(STDOUT), ">&" . fileno(STDERR),
        $^X,
        "-I$inc",
        $script,
        blessed($self),
        run_id        => $self->{+RUN}->run_id,
        work_dir_root => $self->{+WORKDIR}->root,
    );

    $self->{+PROC} = Test2::Harness::Util::Proc->new(pid => $pid);
}

sub start {
    my $self = shift;
    my %params = @_;

    confess "Worker is already active" if $self->{+_ACTIVE};
    $self->{+_ACTIVE} = 1;

    my $run = $self->{+RUN};
    my $curdir = File::Spec->rel2abs(File::Spec->curdir());

    if (my $chdir = $run->chdir) {
        chdir($chdir) or die "Could not chdir to '$chdir': $!";
    }

    my $file;
    my $ok = eval { $file = $self->_start(%params); 1 };
    my $err = $@;

    # Go back to the original directory, unless we have a file to run.
    unless ($file && $ok) {
        $self->{+_ACTIVE} = 0;
        chdir($curdir) or die "Could not chdir to '$curdir': $!";
    }

    die $err unless $ok;
    return $file;
}

sub _start {
    my $self = shift;
    my %params = @_;

    my $run     = $self->{+RUN};
    my $workdir = $self->{+WORKDIR};
    my $jobs    = $self->{+_JOBS} ||= [];

    unshift @INC => $run->all_libs;
    $self->preload if $run->preload;

    for my $job ($self->build_jobs) {
        $self->_wait(%params);

        my ($pid, $file) = $self->_start_job($job, %params);
        return $file if $file;

        $workdir->job_insert($run->run_id, $job);
        push @$jobs => [$pid, $job];
    }

    $self->_finish(%params);

    return undef;
}

sub _start_job {
    my $self = shift;
    my ($job, %params) = @_;

    my $run = $self->{+RUN};

    my $pid;
    if ($run->preload && !$job->no_preload) {
        $pid = fork;
        confess "Failed to fork" unless defined $pid;

        # Child
        unless ($pid) {
            my $file = $self->run_preloaded($job);
            return (undef, $file);
        }

        # Parent, nothing to do in here
    }
    else {
        $pid = $self->run_open3($job) or croak "Failed to spawn test";
    }

    return ($pid, undef);
}

sub build_jobs {
    my $self = shift;

    my $run = $self->{+RUN};

    my $id = 1;
    return map {
        Test2::Harness::Data::Job->new(
            job_id     => $id++,
            test_file  => $_->filename,
            headers    => $_->headers,
            shbang     => $_->shbang,
            switches   => $_->switches,
            no_preload => $_->no_preload,
            env_vars   => {
                T2_HARNESS_ACTIVE  => 1,
                T2_HARNESS_VERSION => $VERSION,
                HARNESS_ACTIVE     => 1,
                HARNESS_VERSION    => $VERSION,

                # Copy the env vars from the run
                %{$run->env_vars},
            },
        );
    } $self->find_tests;
}

sub find_tests {
    my $self = shift;

    my $run = $self->{+RUN};

    my $tests = $run->search;

    my (@files, @dirs);

    for my $item (@$tests) {
        push @files => Test2::Harness::Worker::TestFile->new(filename => $item) and next if -f $item;
        push @dirs  => $item and next if -d $item;
        die "'$item' does not appear to be either a file or a directory.\n";
    }

    my $curdir = File::Spec->curdir();
    CORE::chdir($run->chdir) if $run->chdir;

    my $ok = eval {
        File::Find::find(
            sub {
                no warnings 'once';
                return unless -f $_ && m/\.t2?$/;
                push @files => Test2::Harness::Worker::TestFile->new(filename => $File::Find::name);
            },
            @dirs
        );
        1;
    };
    my $error = $@;

    CORE::chdir($curdir);

    die $error unless $ok;

    return sort { $a->filename cmp $b->filename } @files;
}

sub run_open3 {
    my $self = shift;
    my ($job) = @_;

    my $run = $self->{+RUN};
    my $file = $job->test_file;

    my $out_write = $job->stdout_file->open_file('>');
    my $err_write = $run->output_merging ? $out_write : $job->stderr_file->open_file('>');

    my @mods;

    my $env = $job->env_vars;
    if ($run->event_stream) {
        $env->{T2_FORMATTER} = 'Stream';
        push @mods => "-MTest2::Formatter::Stream=" . $job->events_file->name;
    }

    my @cmd = $run->perl_command(switches => [$job->test->switches]);

    my $old;
    for my $key (keys %$env) {
        $old->{$key} = $ENV{$key} if exists $ENV{$key};
        $ENV{$key} = $env->{$key};
    }

    my $pid;

    my $ok = eval {
        $pid = open3(
            undef, ">&" . fileno($out_write), ">&" . fileno($err_write),
            @cmd,
            @mods,
            $file,
        );
        1;
    };
    my $err = $@;

    for my $key (keys %$env) {
        exists $old->{$key} ? $ENV{$key} = $old->{$key} : delete $ENV{$key};
    }

    die $@ unless $ok;

    return $pid;
}

sub run_preloaded {
    my $self = shift;
    my ($job) = @_;

    my $run = $self->{+RUN};
    my $file = $job->test_file;

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

    # Keep a copy of the old STDERR for a while so we can still report errors
    my $stderr = clone_io(\*STDERR);
    my $die = sub { print $stderr @_; exit 255 };

    # Should get fileno 1
    my $out_write = $job->stdout_file->open_file('>');
    close(STDOUT) or die "Could not close STDOUT: $!";
    open(STDOUT, '>&', $out_write) or die "Could not re-open STDOUT";
    die "New STDOUT did not get fileno 1!" unless fileno(STDOUT) == 1;

    # Should get fileno 2
    my $err_write = $run->output_merging ? $out_write : $job->stderr_file->open_file('>');
    close(STDERR) or $die->("Could not close STDERR: $!");
    open(STDERR, '>&', $err_write) or $die->("Could not re-open STDOUT");
    $die->("New STDERR did not get fileno 2!") unless fileno(STDERR) == 2;

    # avoid child processes sharing the same seed value as the parent
    srand();

    if ($run->event_stream) {
        $ENV{T2_FORMATTER} = 'Stream';
        require Test2::Formatter::Stream;
        Test2::Formatter::Stream->import($job->events_file->name);
        Test2::API::test2_formatter('Test2::Formatter::Stream') if $INC{'Test2/API.pm'};
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

sub preload {
    my $self = shift;

    my $run = $self->{+RUN};

    my $preload = $run->preload or return 0;

    require Test2::Formatter::Stream if $run->event_stream;

    for my $mod (@$preload) {
        my $file = pkg_to_file($mod);
        require $file;
    }

    # Build this cache
    $self->preload_list;

    return 1;
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

sub _wait {
    my $self = shift;
    my (%params) = @_;

    my $run = $self->{+RUN};
    my $jobs = $self->{+_JOBS} or return;

    my $count = $params{max_jobs} || $run->job_count || 1;

    while ($params{finish} ? @$jobs : @$jobs >= $count) {
        my @keep;
        my $done = 0;

        for my $job (@$jobs) {
            if ($job->complete) {
                $done++;
            }
            else {
                push @keep => $job;
            }
        }

        @$jobs = @keep;

        sleep 0.02 unless $done;
    }
}

sub _finish {
    my $self = shift;
    $self->_wait(@_, finish => 1)
}

sub DESTROY {
    return if $_[0]->{+PID} != $$;
    return if $_[0]->{+TID} != get_tid;
    $_[0]->_finish
}

1;
