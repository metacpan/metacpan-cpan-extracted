package Wx::Perl::EntryList::Iterator;

=head1 NAME

Wx::Perl::EntryList::Iterator - iterate over Wx::Perl::EntryList

=head1 SYNOPSIS

  my $list = Wx::Perl::EntryList->new;
  $list->add_entries_at( 0, [ 'a', 'b', 'c', 'd', 'e' ] );
  my $it = Wx::Perl::EntryList::FwBwIterator->new;
  $it->attach( $list );

  # $it will iterate taking into accounts
  # insertions/deletions/moves on the list

=head1 DESCRIPTION

Subclasses of C<Wx::Perl::EntryList::Iterator> allow the iteration
over an entry list to proceed in accord to operations on the list.
For example, if the current element if moved, the iteration will
continue from the element's new position.

=head1 METHODS

=cut

use strict;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(current list) );

=head2 attach

  $it->attach( $entrylist );

Associates the iterator with the given C<Wx::Perl::EntryList>.

=cut

sub attach {
    my( $self, $entrylist ) = @_;

    $self->list( $entrylist );
    $entrylist->add_subscriber( '*', $self, '_list_changed' );
}

=head2 detach

  $it->detach;

Detaches the iterator for its associated C<Wx::Perl::EntryList>.

=cut

sub detach {
    my( $self ) = @_;

    $self->list->delete_subscriber( '*', $self );
    $self->list( undef );
}

sub _list_changed {
    my( $self, $list, $event, %args ) = @_;

    $list->_fixup_iterator( $self, $event, %args );
}

=head2 at_start, at_end

C<at_start> returns true when the iterator points to the first element
of the list.  C<at_end> returns true when the iterator points to the
last element of the list.

=cut

sub at_start { $_[0]->current == 0 }
sub at_end   { $_[0]->current >= $_[0]->list->count - 1 }

1;
