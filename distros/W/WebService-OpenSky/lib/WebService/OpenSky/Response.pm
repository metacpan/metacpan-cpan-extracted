package WebService::OpenSky::Response;

# ABSTRACT: A class representing a response from the OpenSky Network API

use WebService::OpenSky::Moose;
use WebService::OpenSky::Utils::Iterator;
use WebService::OpenSky::Types qw(
  ArrayRef
  Bool
  HashRef
  InstanceOf
  Route
);

our $VERSION = '0.5';

param raw_response => (
    isa     => ArrayRef | HashRef,
    default => method() { $self->_empty_response },
);

param route => (
    isa => Route,
);

param query => (
    isa => HashRef,
);

field _iterator => (
    is       => 'rw',
    isa      => InstanceOf ['WebService::OpenSky::Utils::Iterator'],
    writer   => '_set_iterator',
    init_arg => undef,
);

field _inflated => (
    is       => 'rw',
    isa      => Bool,
    default  => 0,
    init_arg => undef,
);

method BUILD(@args) {
    if ( !$self->raw_response ) {
        $self->raw_response( $self->_empty_response );
    }
}

method _inflate() {
    return if $self->_inflated;
    my $iterator = WebService::OpenSky::Utils::Iterator->new( rows => $self->_create_response_objects );
    $self->_set_iterator($iterator);
    $self->_inflated(1);
}

method _create_response_iterator() {
    croak 'This method must be implemented by a subclass';
}

method _empty_response() {
    croak 'This method must be implemented by a subclass';
}

method iterator() {
    $self->_inflate;
    return $self->_iterator;
}

method next() {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    $self->_inflate;
    return $self->iterator->next;
}

method first() {
    $self->_inflate;
    return $self->iterator->first;
}

method reset() {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    $self->_inflate;
    return $self->iterator->reset;
}

method all() {
    $self->_inflate;
    return $self->iterator->all;
}

method count() {
    $self->_inflate;
    return $self->iterator->count;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OpenSky::Response - A class representing a response from the OpenSky Network API

=head1 VERSION

version 0.5

=head1 DESCRIPTION

This class represents iterator from the OpenSky Network API. By default, it does
not instantiate individual response objects until you first ask for them. This is for performance reasons.

=head1 METHODS

=head2 raw_response

The raw response from the OpenSky Network API.

=head2 route

The route used to retrieve this response.

=head2 query

The query used to retrieve this response.

=head2 iterator

Returns an iterator of results. See L<WebService::OpenSky> to understand the
actual response class returned for a given method and which underlying module
represents the results. (Typically this would be
L<WebService::OpenSky::Core::Flight> or
L<WebService::OpenSky::Core::StateVector>.)

As a convenience, the following methods are delegated to the iterator:

=over 4

=item * first

=item * next

=item * reset

=item * all

=item * count

=back

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
