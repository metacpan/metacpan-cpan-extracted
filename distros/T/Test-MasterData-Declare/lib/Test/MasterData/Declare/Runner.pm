package Test::MasterData::Declare::Runner;
use 5.010001;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw/bucket/],
    ro  => [qw/code/],
);

use Carp qw/croak/;

sub run {
    my $self = shift;

    $self->code->();
}

sub add_reader_to_bucket {
    my ($self, $reader) = @_;

    $self->bucket({}) unless $self->bucket;

    # TODO: merge reader
    $self->bucket->{$reader->table_name} = $reader;
}

sub rows {
    my ($self, $table_name) = @_;

    if (!defined $self->bucket || !exists $self->bucket->{$table_name}) {
        croak "$table_name is not exists.";
    }
    my $reader = $self->bucket->{$table_name};
    my $rows = $reader->rows;
    return $rows;
}

1;
