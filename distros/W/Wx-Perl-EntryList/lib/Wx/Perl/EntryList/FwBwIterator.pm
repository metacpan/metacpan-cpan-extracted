package Wx::Perl::EntryList::FwBwIterator;

=head1 NAME

Wx::Perl::EntryList::FwBwIterator - iterate over Wx::Perl::EntryList sequentially

=head1 SYNOPSIS

See L<Wx::Perl::EntryList::Iterator>.

=head1 DESCRIPTION

A C<Wx::Perl::EntryList::Iterator> subclass that allows sequential
iteration over an entry list.

=head1 METHODS

=cut

use strict;
use base qw(Wx::Perl::EntryList::Iterator);

=head2 next_entry

  $it->next_entry;

Moves the iterator to the next entry of the list.  Does nothing if the
iterator points at the end of the list.

=cut

sub next_entry {
    my( $self ) = @_;
    return if $self->at_end;

    $self->current( $self->current + 1 );
}

=head2 previous_entry

  $it->previous_entry;

Moves the iterator to the previous entry of the list.  Does nothing if
the iterator points at the beginning of the list.

=cut

sub previous_entry {
    my( $self ) = @_;
    return if $self->at_start;

    $self->current( $self->current - 1 );
}

1;
