package WebService::OpenSky::Utils::Iterator;

# ABSTRACT: Internal iterator class for WebService::OpenSky

use WebService::OpenSky::Moose;
use WebService::OpenSky::Types qw(
  ArrayRef
  Defined
  InstanceOf
  PositiveOrZeroInt
);

our $VERSION = '0.4';

param rows => (
    isa    => ArrayRef [Defined],
    reader => '_rows',
);

field '_index' => (
    writer  => '_set_index',
    isa     => PositiveOrZeroInt,
    default => 0,
);

method first() {
    return $self->_rows->[0];
}

method next() {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my $i    = $self->_index;
    my $next = $self->_rows->[$i] or return;
    $self->_set_index( $i + 1 );
    return $next;
}

method reset() {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    $self->_set_index(0);
    return 1;
}

method all() {
    return @{ $self->_rows };
}

method count() {
    my @all = $self->all;
    return scalar @all;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::OpenSky::Utils::Iterator - Internal iterator class for WebService::OpenSky

=head1 VERSION

version 0.4

=head1 SYNOPSIS

    use WebService::OpenSky::Utils::Iterator;

    my $results = WebService::OpenSky::Utils::Iterator->new( rows => [ 1, 2, 3 ] );

    while ( my $result = $results->next ) {
        ...
    }

=head1 DESCRIPTION

A simple iterator class. To keep it dead simple, it only allows defined values
to be passed in.

=head1 METHODS

=head2 C<next>

    while ( my $result = $results->next ) {
        ...
    }

Returns the next member in the iterator. Returns C<undef> if the iterator is
exhausted.

=head2 C<count>

    if ( $results->count ) {
        ...
    }

Returns the number of members in the iterator.

=head2 C<first>

    my $object = $results->first;

Returns the first object in the results.

=head2 C<reset>

    $results->reset;

Resets the iterator to point to the first member.

=head2 C<all>

    my @objects = $results->all;

Returns a list of all members in the iterator.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
