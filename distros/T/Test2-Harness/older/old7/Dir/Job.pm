package Test2::Harness::Schema::Dir::Job;
use strict;
use warnings;

use Carp qw/confess croak/;

use File::Spec();
use Test2::Harness::Data::Job();
use Test2::Harness::Data::Event();
use Test2::Harness::Schema::Dir::Job::Muxer();

use Scalar::Util qw/weaken/;

BEGIN { require Test2::Harness::Schema::Dir; our @ISA = 'Test2::Harness::Schema::Dir' }
use Test2::Harness::Util::HashBase qw/-run_id -job_id/;

sub init {
    my $self = shift;

    croak "'run_id' is a required attribute"
        unless $self->{+RUN_ID};

    croak "'job_id' is a required attribute"
        unless $self->{+JOB_ID};

    $self->SUPER::init();
}

sub supports {
    my $self = shift;
    my ($type) = @_;
    return $type eq 'event';
}

sub can_insert { 0 }

sub can_fetch {
    my $self = shift;
    my ($type) = @_;
    return $type eq 'event';
}

sub event_insert {
    my $self = shift;
    my $class = ref($self) || $self;

    chomp(my $error = <<"    EOT");
'event_insert()' is not a possible using the JobDir schema.
Events must be written by an external process using this schema.
Attempted to insert an event
    EOT

    confess($error);
}

sub _event_poller {
    my $self = shift;

    my $run_id = $self->{+RUN_ID};
    my $job_id = $self->{+JOB_ID};

    return $self->{+POLLS}->{events}->{$run_id}->{$job_id} ||= Test2::Harness::Schema::Dir::Job::Muxer->new(
        run_id   => $run_id,
        job_id   => $job_id,
        job_root => $self->path($run_id, $job_id),
    );
}

sub event_fetch {
    my $self = shift;
    my ($event_id) = @_;

    my $run_id = $self->{+RUN_ID};
    my $job_id = $self->{+JOB_ID};

    my $cache = $self->{+CACHE}->{events}->{$run_id}->{$job_id} ||= {};
    return $cache->{$event_id} if $cache->{$event_id};

    my $event_data = $self->_event_poller($run_id, $job_id)->fetch($event_id)
        or return undef;

    my $event = Test2::Harness::Data::Event->new(%$event_data);

    $cache->{$event_id} = $event;
    weaken($cache->{$event_id});
    return $event;
}

sub event_poll {
    my $self = shift;
    my ($max) = @_;

    # Use the main muxer
    my $muxer = $self->_event_poller();

    return $self->_event_poll($muxer, $max);
}

sub event_list {
    my $self = shift;

    my $run_id = $self->{+RUN_ID};
    my $job_id = $self->{+JOB_ID};

    # Need a new muxer to do this
    my $muxer = Test2::Harness::Schema::Dir::Job::Muxer->new(
        run_id   => $run_id,
        job_id   => $job_id,
        job_root => $self->path($run_id, $job_id),
    );

    return $self->_event_poll($muxer);
}

sub _event_poll {
    my $self = shift;
    my ($muxer, $max) = @_;

    my $run_id = $self->{+RUN_ID};
    my $job_id = $self->{+JOB_ID};

    my $cache = $self->{+CACHE}->{events}->{$run_id}->{$job_id} ||= {};

    my @out;
    for my $event_data ($muxer->poll($max)) {
        my $event_id = $event_data->{event_id};

        if (my $event = $cache->{$event_id}) {
            push @out => $event;
            next;
        }

        my $event = Test2::Harness::Data::Event->new(%$event_data);
        $cache->{$event_id} = $event;
        weaken($cache->{$event_id});
        push @out => $event;
    }

    return @out;
}

1;
