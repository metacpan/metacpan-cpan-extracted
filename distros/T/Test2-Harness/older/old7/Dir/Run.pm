package Test2::Harness::Schema::Dir::Run;
use strict;
use warnings;

use Carp qw/croak/;

use File::Spec();

use Scalar::Util qw/weaken/;

BEGIN { require Test2::Harness::Schema::Dir; our @ISA = 'Test2::Harness::Schema::Dir' }
use Test2::Harness::Util::HashBase qw/-run_id/;

sub supports {
    my $self = shift;
    my ($type) = @_;
    return $type eq 'job';
}

sub can_insert {
    my $self = shift;
    my ($type) = @_;
    return $type eq 'job';
}

sub can_fetch {
    my $self = shift;
    my ($type) = @_;
    return $type eq 'job';
}

sub init {
    my $self = shift;

    croak "'run_id' is a required attribute"
        unless $self->{+RUN_ID};

    $self->SUPER::init();
}

sub _job_poller {
    my $self = shift;

    my $run_id = $self->{+RUN_ID};

    return $self->{+POLLS}->{jobs}->{$run_id} ||= Test2::Harness::Util::File::JSONL->new(
        name => $self->path('jobs.jsonl'),
    );
}

sub job_insert {
    my $self = shift;
    my ($job) = @_;

    my $run_id = $self->{+RUN_ID};

    my $job_id = $job->job_id;
    my $path   = $self->path($job_id);

    croak "Job '$job_id' already exists at $path" if -e $path;
    mkdir($path) or croak "Could not create run directory ($path): $!";
    $self->_job_poller($run_id)->write($job->TO_JSON);

    $self->{+CACHE}->{jobs}->{$run_id}->{$job_id} = $job;
    weaken($self->{+CACHE}->{jobs}->{$run_id}->{$job_id});

    return $job;
}

sub job_fetch {
    my $self = shift;
    my ($job_id) = @_;

    my $run_id = $self->{+RUN_ID};

    my $cache = $self->{+CACHE}->{jobs}->{$run_id} ||= {};
    return $cache->{$job_id} if $cache->{$job_id};

    my $index = $self->{+INDEX}->{jobs}->{$run_id} ||= {};

    my $job;

    if (my $pos = $index->{$job_id}) {
        my $poller = $self->_job_poller($run_id);
        my $data = $poller->read_line(from => $pos);
        $job = Test2::Harness::Data::Job->new(%$data);
    }
    else {
        for my $item ($self->_job_poll($run_id, peek => 1)) {
            next unless $item->{job_id} eq $job_id;
            $job = $item;
        }
    }

    return undef unless $job;

    $cache->{$job_id} = $job;
    weaken($cache->{$job_id});
    return $job;
}

sub job_list {
    my $self = shift;
    return $self->_job_poll(from => 0);
}

sub job_poll {
    my $self = shift;
    my ($max) = @_;
    $self->_run_poll(max => $max);
}

sub _job_poll {
    my $self   = shift;
    my (%params) = @_;

    my $run_id = $self->{+RUN_ID};

    my $poller = $self->_job_poller($run_id);
    my $index  = $self->{+INDEX}->{jobs}->{$run_id} ||= {};
    my $cache  = $self->{+CACHE}->{jobs}->{$run_id} ||= {};

    my @out;
    for my $item ($poller->poll_with_index(%params)) {
        my ($spos, $epos, $data) = @$item;

        my $job_id = $data->{job_id};

        $index->{$job_id} = $spos;

        my $job = $cache->{$job_id} ||= Test2::Harness::Data::Job->new(%$data);
        weaken($cache->{$job_id});

        push @out => $job;
    }

    return @out;
}

1;
