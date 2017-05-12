
package XCAP::Client::Document;

use Moose;

has connection => (
    is => 'rw',
    isa => 'Object',
    required => 1,
);

has content => (
    is => 'rw',
    isa => 'Str',
);

sub fetch { $_[0]->connection->get; }

sub delete { $_[0]->connection->delete; }

sub create { 
    my $self = shift;
    $self->connection->content($self->content);
    $self->connection->put; 
}

sub replace { 
    my $self = shift;
    $self->connection->content($self->content);
    $self->connection->delete;
    $self->connection->put;
}


1;

