package Test2::Harness::Schema::WorkDir;
use strict;
use warnings;

use File::Spec();
use Test2::Harness::Util::File::JSONL();
use Test2::Harness::Data::Run();

use Carp qw/croak confess/;
use Scalar::Util qw/weaken/;
use Test2::Util qw/pkg_to_file/;

BEGIN { require Test2::Harness::Schema::WorkDir::Base; our @ISA = 'Test2::Harness::Schema::WorkDir::Base' }
use Test2::Harness::Util::HashBase;

sub reload {
    my $self = shift;

    %{$self->{+POLLS}} = ();
    %{$self->{+INDEX}} = ();
    %{$self->{+CACHE}} = ();
}

sub clear_cache { %{shift->{+CACHE}} = () }

sub _run_poller {
    my $self = shift;

    return $self->{+POLLS}->{runs} ||= Test2::Harness::Util::File::JSONL->new(
        name => $self->path('runs.jsonl'),
    );
}

sub run_insert {
    my $self = shift;
    my ($run) = @_;

    my $run_id = $run->run_id;
    my $path   = $self->path($run_id);

    croak "Run '$run_id' already exists at $path" if -e $path;
    mkdir($path) or croak "Could not create run directory ($path): $!";
    $self->_run_poller->write($run->TO_JSON);

    $self->{+CACHE}->{runs}->{$run_id} = $run;
    weaken($self->{+CACHE}->{runs}->{$run_id});

    return $run;
}

sub run_fetch {
    my $self = shift;
    my ($run_id) = @_;

    my $cache = $self->{+CACHE}->{runs} ||= {};
    return $cache->{$run_id} if $cache->{$run_id};

    my $index = $self->{+INDEX}->{runs} ||= {};

    my $run;

    if (my $pos = $index->{$run_id}) {
        my $poller = $self->_run_poller;
        my $data = $poller->read_line(from => $pos);
        $run = Test2::Harness::Data::Run->new(%$data);
    }
    else {
        for my $item ($self->_run_poll(peek => 1)) {
            next unless $item->{run_id} eq $run_id;
            $run = $item;
        }
    }

    return undef unless $run;

    $cache->{$run_id} = $run;
    weaken($cache->{$run_id});
    return $run;
}

sub run_list {
    my $self = shift;
    return $self->_run_poll(from => 0);
}

sub run_poll {
    my $self = shift;
    my ($max) = @_;

    $self->_run_poll(max => $max);
}

sub _run_poll {
    my $self   = shift;
    my %params = @_;

    my $poller = $self->_run_poller;
    my $index  = $self->{+INDEX}->{runs} ||= {};
    my $cache  = $self->{+CACHE}->{runs} ||= {};

    my @out;
    for my $item ($poller->poll_with_index(%params)) {
        my ($spos, $epos, $data) = @$item;

        my $run_id = $data->{run_id};

        $index->{$run_id} = $spos;

        my $run = $cache->{$run_id} ||= Test2::Harness::Data::Run->new(%$data);
        weaken($cache->{$run_id});

        push @out => $run;
    }

    return @out;
}

sub job_insert {
    my $self = shift;
    my ($run_id, $job) = @_;


    return $job;
}

sub job_fetch {
    my $self = shift;
    my ($run_id, $job_id) = @_;

    return undef unless $job;
    return $job;
}

sub job_list {
    my $self = shift;
    my ($run_id) = @_;
    return $self->_job_poll($run_id, from => 0);
}

sub job_poll {
    my $self = shift;
    my ($run_id, $max) = @_;

    $self->_run_poll($run_id, max => $max);
}

sub event_insert {
    my $self = shift;
    my $class = ref($self) || $self;

    chomp(my $error = <<"    EOT");
'event_insert()' is not a possible using the $class schema.
Events must be written by an external process using this schema.
Attempted to insert an event
    EOT

    confess($error);
}

sub event_fetch {
    my $self = shift;
    my ($run_id, $job_id, $event_id) = @_;
    return $event;
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

