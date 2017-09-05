package Test2::Harness::Run;
use strict;
use warnings;

use File::Spec;
use Carp qw/croak confess/;
use IPC::Open3 qw/open3/;

use Test2::Harness::Run::Job;

use Test2::Harness::HashBase qw/-pid -run_dir -run_id -config -jobs/;

sub spawn {
    my $class  = shift;
    my %params = @_;

    my $dir    = $params{dir}    or croak "'dir' is required";
    my $config = $params{config} or croak "'config' is required";
    my $run_id = $params{run_id} or croak "'run_id' is required";

    my $run_dir = File::Spec->rel2abs("$dir/$run_id");

    my $env = $params{env};

    my $old_env;
    if ($env) {
        $old_env = {%ENV};
        $ENV{$_} = $env->{$_} for keys %$env;
    }

    local $ENV{T2_FORMATTER}  = 'Stream';
    local $ENV{T2_STREAM_SERIALIZER} = 'JSON';

    my ($pid, $fh);
    my $ok = eval {
        confess "'$run_dir' already exists" if -e $run_dir;
        mkdir($run_dir);

        $config->write($run_dir);

        require Test2::Harness::Runner;
        $pid = open3(
            undef, '>&1', '>&2',
            $^X,
            (map { "-I$_" } @INC), # Make sure the same @INC is in place
            $config->cli_switches,
            "-MTest2::Harness::Runner=$run_id," . File::Spec->rel2abs($run_dir),
            '-e' => Test2::Harness::Runner::runtime_code(),
        ) or die "Could not spawn a runner: $!";

        1;
    };
    my $err = $@;

    if ($env) {
        for my $key (keys %$old_env, keys %ENV) {
            if (defined $old_env->{$_}) {
                $ENV{$_} = $old_env->{$_};
            }
            else {
                delete $ENV{$_};
            }
        }
    }

    die $err unless $ok;

    return $class->new(
        pid     => $pid,
        run_id  => $run_id,
        config  => $config,
        run_dir => $run_dir,
    );
}

sub init {
    my $self = shift;

    croak "'run_dir' is a required attribute" unless $self->{+RUN_DIR};
    $self->{+CONFIG} ||= Test2::Harness::Config->read($self->{+RUN_DIR});
    $self->{+JOBS} = {};
}

sub poll {
    my $self = shift;

    my $jobs = $self->{+JOBS};
    my $run_dir = $self->{+RUN_DIR};
    opendir(my $run_handle, $run_dir) or die "Could not open run dir '$run_dir': $!";

    # TODO, instead of reading the entire directory and looping, look for the next dir using a counter
    for my $file (sort { $a <=> $b } grep { m/^\d+$/ && !$jobs->{$_} } readdir($run_handle)) {
        $jobs->{$file} ||= Test2::Harness::Run::Job->new(id => $file, job_dir => "$run_dir/$file");
    }

    closedir($run_handle);
    return map { $_->poll } values %$jobs;
}

1;
