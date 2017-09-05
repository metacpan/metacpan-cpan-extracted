package Test2::Harness::Run;
use strict;
use warnings;

use Carp qw/croak/;

use Test2::Harness::Run::Job;
use Test2::Harness::Util::ActiveFile;

use Test2::Harness::Util qw/read_file write_file_atomic/;
use Test2::Harness::Util::JSON qw/decode_json encode_json/;

use Test2::Harness::HashBase qw/-id -dir/;

use Test2::Harness::DirORM DIR();

dorm run => (
    type => 'json',
    is_self => 1,
);

dorm result => (
    type => 'json',
    transform => sub { Test2::Harness::Run::Result->new($_[1]) },
);

dorm jobs => (
    type => 'jsonl',
    transform => sub {
        my $self = shift;
        my ($data) = @_;
        return Test2::Harness::Run::Job->load(
            dir => $self->path($data->{id}),
            id  => $data->{id},
            test_file => $data->{test_file},
        );
    },
);

sub init {
    my $self = shift;

    croak "The 'id' attribute must be set, and must be a true value"
        unless $self->{+ID};

    croak "The 'dir' attribute is required"
        unless $self->{+DIR};

    croak "The '$self->{+DIR}' directory does not exist"
        unless -d $self->{+DIR};
}

1;
