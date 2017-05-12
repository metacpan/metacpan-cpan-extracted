package Wx::Perl::EntryList;

=head1 NAME

Wx::Perl::EntryList - dynamic list that can be displayed in various controls

=head1 SYNOPSIS

  my $list = Wx::Perl::EntryList->new;
  $list->add_entries_at( 0, [ 'a', 'b', 'c', 'd', 'e' ] );

  # create a view to display it
  my $view = Wx::Perl::EntryList::ListBoxView->new
                 ( $list, sub { return $_[0] }, $parent );

=head1 DESCRIPTION

A dynamic list that can be observed (using C<Class::Publisher>) for
changes and can be displayed in various controls.

=head1 METHODS

=cut

use strict;
use base qw(Class::Publisher Class::Accessor::Fast);

our $VERSION = '0.01';

__PACKAGE__->mk_accessors( qw(entries) );

=head2 new

  my $list = Wx::Perl::EntryList->new;

Creates a list object.

=cut

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( { entries => [] } );

    return $self;
}

=head2 get_entry_at

  my $entry = $list->get_entry_at( $index );

Returns the nth entry of the list.

=cut

sub get_entry_at { return $_[0]->entries->[ $_[1] ] }

=head2 add_entries_at

  $list->add_entries_at( $index, [ $entry1, $entry2, ... ] );

Add some entries to the list, notifying any listeners.

=cut

sub _add_entries_at {
    my( $self, $index, $entries ) = @_;

    splice @{$self->entries}, $index, 0, @$entries;
}

sub add_entries_at {
    my( $self, $index, $entries ) = @_;

    $self->_add_entries_at( $index, $entries );
    $self->notify_subscribers( 'add_entries',
                               index => $index,
                               count => scalar @$entries,
                               );
}

=head2 delete_entry

  $list->delete_entry( $index );

Deletes a single entry from the list, notifying any listeners.

=cut

sub _delete_entries {
    my( $self, $index, $count ) = @_;

    return splice @{$self->entries}, $index, $count;
}

sub delete_entry {
    my( $self, $index ) = @_;

    $self->_delete_entries( $index, 1 );
    $self->notify_subscribers( 'delete_entries',
                               index => $index,
                               count => 1,
                               );
}

=head2 move_entry

  $list->move_entry( $from_index, $to_index );

Moves an entry of the list, notifying any listeners.

=cut

sub move_entry {
    my( $self, $from, $to ) = @_;
    my( $entry ) = $self->_delete_entries( $from, 1 );
    $self->_add_entries_at( $to, [ $entry ] );
    $self->notify_subscribers( 'move_entries',
                               from  => $from,
                               to    => $to,
                               count => 1,
                               );
}

=head2 count

  my $count = $list->count;

The number of items in the list.

=cut

sub count    { scalar @{$_[0]->entries} }

sub _fixup_iterator {
    my( $self, $it, $event, %args ) = @_;

    if( $event eq 'add_entries' ) {
        if( $it->current >= $args{index} ) {
            $it->current( $it->current + $args{count} );
        }
    } elsif( $event eq 'delete_entries' ) {
        if( $it->current >= $args{index} ) {
            if( $it->current < $args{index} + $args{count} ) {
                $it->current( 0 );
            } else {
                $it->current( $it->current - $args{count} );
            }
        }
    } elsif( $event eq 'move_entries' ) {
        if(    $it->current >= $args{from}
            && $it->current < $args{from} + $args{count} ) {
            $it->current( $it->current - $args{from} + $args{to} );
        } else {
            $self->_fixup_iterator( $it, 'delete_entries',
                                    index => $args{from},
                                    count => $args{count},
                                    );
            $self->_fixup_iterator( $it, 'add_entries',
                                    index => $args{to},
                                    count => $args{count},
                                    );
        }
    }
}

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Wx::Perl::EntryList::ListBoxView>,
L<Wx::Perl::EntryList::VirtualListCtrlView>, L<Wx::Perl::ListView>,
L<Wx::Perl::EntryList::Iterator>

=cut

1;
