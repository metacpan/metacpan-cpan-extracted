
package XCAP::Client::Element;

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

sub fetch { $_[0]->connection->fetch; }

sub delete { $_[0]->connection->delete; }

sub create { 
    my $self = shift;
    $self->connection->fetch($self->content); 
}

sub replace { 
    my $self = shift;
    $self->connection->fetch($self->content); 
}


1;

