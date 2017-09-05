package Test2::Harness::Job;
use strict;
use warnings;

use Test2::Harness::HashBase qw{
    -job_id -job_dir -harness
    -parser
    -pipeline
    -failures
};

sub passing { !$_[0]->{+FAILURES} }

sub init {
    my $self = shift;

    $self->{+FAILURES} = 0;

    my @args = (
        job_id  => $self->{+JOB_ID},
        job_dir => $self->{+JOB_DIR},
        harness => $self->{+HARNESS},
    );

    $self->{+PARSER}   ||= $self->{+HARNESS}->parser->new(@args);
    $self->{+PIPELINE} ||= [map { $_->new(@args) } @{$self->{+HARNESS}->pipeline}];
}

sub poll {
    my $self = shift;

    my @events = $self->{+PARSER}->poll or return;

    for my $p (@{$self->{+PIPELINE}}) {
        @events = $p->process(@events);
    }

    for my $e (@events) {
        next unless $e->causes_fail;
        $self->{+FAILURES}++;
    }

    return @events;
}


1;
