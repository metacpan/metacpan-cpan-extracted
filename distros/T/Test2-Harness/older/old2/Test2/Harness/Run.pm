package Test2::Harness::Run;
use strict;
use warnings;

use Test2::Harness::HashBase qw/-_files -uuid -id -pid -machine -start_time -end_time -result -step_delay -config/;

use Carp qw/croak/;
use Time::HiRes qw/sleep/;
use File::Temp qw/tempfile/;

use Test2::Harness::Util qw/gen_uuid get_machine/;

use Test2::Harness::TestFile;
use Test2::Harness::Run::Job;
use Test2::Harness::Run::Result;

my $ID = 1;
sub init {
    my $self = shift;

    $self->{+UUID}    ||= gen_uuid();
    $self->{+MACHINE} ||= get_machine();

    $self->{+STEP_DELAY} ||= '0.05';

    $self->{+ID} = $ID++;
    $self->{+PID} = $$;

    $self->{+LISTEN_SOCKET} = eval {
        require IO::Socket::UNIX;

        my ($fh, $file) = tempfile('T2HARNESS-XXXXXX', SUFFIX => '.sock');

        close($file);
        my $listen = IO::Socket::UNIX->new(
            Type => IO::Socket::UNIX::SOCK_STREAM(),
            Listen => $self->{+CONFIG}->jobs + 1,
            Local => $file,
        );

        # Do not block on accept
        $listen->blocking(0);

        {
            listen => $listen,
            file   => $file,
        }
    };
}

sub run {
    my $self = shift;

    croak "This run is already started!"
        if $self->{+START_TIME};

    croak "This run is already complete!"
        if $self->{+END_TIME} || $self->{+RESULT};

    $self->{+START_TIME} = time;

    $config->load_preloads if $config->preload;

    local $@;
    my ($test_file, $set_env);
    my $ok = eval { ($file, $set_env) = $self->_run(); 1 };
    my $error = $@;

    return ($test_file, $set_env) if $file;

    $self->{+END_TIME} = time;

    unless($ok) {
        $self->{+RESULT} ||= Test2::Harness::Run::Result->new();
        $self->{+RESULT}->add_exception($error);
        die $error;
    }

    return;
}

sub _run {
    my $self = shift;

    my $config = $self->config;
    my $max = $config->jobs;

    my @queue = $self->files;

    my (@running, @complete);

    my ($listen, $socket_file);
    if (my $info = $self->{+LISTEN_SOCKET}) {
        $listen = $info->{listen};
        $socket_file = $info->{file};
    }

    my $job_id = 1;
    while (@queue || @running) {
        # Make sure there is always work to do
        while (@running < $max && @queue) {
            my $file = shift @queue;
            my $job = Test2::Harness::Run::Job->new(id => $job_id++, file => $file, config => $self->{+CONFIG});
            my ($test_file, $set_env) = $job->start($socket_file);
            return ($test_file, $set_env) if $test_file;
            push @running => $job;
        }

        if ($listen) {
            while (my $socket = $listen->accept()) {

            }
        }

        push @complete => $self->step(\@running);
    }

    return $self->{+RESULT} = Test2::Harness::Run::Result->new(jobs => \@complete);
}

sub step {
    my $self = shift;
    my ($jobs) = @_;

    my $work = 0;
    my (@complete, @todo);

    while (my $job = shift @$jobs) {
        $work += $job->step();
        if   ($job->is_complete) { push @todo     => $job }
        else                     { push @complete => $job }
    }

    sleep($self->step_delay) unless $work;

    @$jobs = @todo;
    return @complete;
}

sub files {
    my $self = shift;

    return @{$self->{+_FILES}} if $self->{+_FILES};
    return if $self->{+RESULT};

    $self->{+_FILES} = [map { Test2::Harness::TestFile->new(filename => $_) } $self->_find_files];

    return @{$self->{+_FILES}};
}

sub _find_files {
    my $self = shift;
    my (@files, @dirs);

    for my $path (@{$self->{+CONFIG}->search}) {
        if (-f $path) {
            push @files => $path;
        }
        elsif (-d $path) {
            push @dirs => $path;
        }
        else {
            die "Invalid test '$path' not a regular file or directory";
        }
    }

    return @files unless @dirs;

    require File::Find;
    File::Find::find(
        sub {
            no warnings 'once';
            push @files => $File::Find::name if -f $_ && m/\.t2?$/;
        },
        @dirs
    );

    return @files;
}


1;
