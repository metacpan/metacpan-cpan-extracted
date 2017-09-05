package Test2::Harness::Schema::WorkDir;
use strict;
use warnings;

use File::Spec();
use Test2::Harness::Util::File::JSONL();
use Test2::Harness::Data::Run();

use Carp qw/croak confess/;
use Scalar::Util qw/weaken/;
use Test2::Util qw/pkg_to_file/;

BEGIN { require Test2::Harness::Schema; our @ISA = 'Test2::Harness::Schema' }
use Test2::Harness::Util::HashBase qw/-root -polls /;

sub init {
    my $self = shift;

    croak "The 'root' attribute is required"
        unless $self->{+ROOT};

    $self->{+ROOT} = File::Spec->rel2abs($self->{+ROOT});

    $self->{+POLLS} ||= {};
    $self->{+INDEX} ||= {};
    $self->{+CACHE} ||= {};
}

sub reload {
    my $self = shift;

    %{$self->{+POLLS}} = ();
    %{$self->{+INDEX}} = ();
    %{$self->{+CACHE}} = ();
}

sub clear_cache { %{shift->{+CACHE}} = () }


sub run_insert {
    my $self = shift;
    my ($run) = @_;
}

sub run_fetch {
    my $self = shift;
    my ($run_id) = @_;
}

sub run_list {
    my $self = shift;
}

sub run_poll {
    my $self = shift;
    my ($max) = @_;
}

sub job_insert {
    my $self = shift;
    my ($run_id, $job) = @_;
}

sub job_fetch {
    my $self = shift;
    my ($run_id, $job_id) = @_;
}

sub job_list {
    my $self = shift;
    my ($run_id) = @_;
}

sub job_poll {
    my $self = shift;
    my ($run_id, $max) = @_;
}

sub event_insert {
    my $self = shift;
}

sub event_fetch {
    my $self = shift;
    my ($run_id, $job_id, $event_id) = @_;
}

sub event_poll {
    my $self = shift;
    my ($run_id, $job_id, $max) = @_;
}

sub event_list {
    my $self = shift;
    my ($run_id, $job_id) = @_;
}

1;

