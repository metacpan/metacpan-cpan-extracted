package Wx::Perl::EntryList::VirtualListCtrlView;

=head1 NAME

Wx::Perl::EntryList::VirtualListCtrlView - display an entry list

=head1 DESCRIPTION

Uses a C<Wx::Perl::ListView> to display an entry list and
automatically refreshes the appropriate part of the display when the
underlying entry list changes.

=head1 METHODS

=cut

use strict;
# FIXME hack!
use base qw(Wx::Perl::ListView Wx::Perl::ListCtrl Class::Accessor::Fast);

use Wx qw(:listctrl);
use Wx::Event qw(EVT_LIST_BEGIN_DRAG EVT_LEFT_UP);

__PACKAGE__->mk_accessors( qw(list) );

=head2 new

  my $view = Wx::Perl::EntryList::VirtualListCtrlView->new
                 ( $entrylist, $model, $parent, $style );

Creates a new view for the given entry list.  C<$model> must be an
implementation of C<Wx::Perl::ListView::Model>, C<$parent> a parent
window for the control and C<$style> any style appropriate for
C<Wx::Perl::ListView>.

=cut

sub new {
    my( $class, $entrylist, $model, $parent, $style ) = @_;
    my $self = $class->SUPER::new( $model, $parent, -1, [-1, -1], [-1, -1],
                                   $style );
    $self->list( $entrylist );
    $entrylist->add_subscriber( '*', $self, '_list_changed' )
      if $entrylist;

    return $self;
}

sub DESTROY {
    my( $self ) = @_;

    $self->list->delete_subscriber( '*', $self ) if $self->list;
}

=head2 support_dnd

  $view->support_dnd;

Enables items of the list to be moved by using drag and drop.

=cut

sub support_dnd {
    my( $self ) = @_;

    EVT_LIST_BEGIN_DRAG( $self, $self, \&_begin_drag );
}

sub _begin_drag {
    my( $self, $event ) = @_;
    $self->{_entrylist_dragging} = 1;
    $self->{_entrylist_drag_index} = $event->GetIndex;
    EVT_LEFT_UP( $self, \&_end_drag );
}

sub _end_drag {
    my( $self, $event ) = @_;
    EVT_LEFT_UP( $self, undef );

    return unless $self->{_entrylist_dragging};
    $self->{_entrylist_dragging} = 0;
    my $to = $self->_entry( $event->GetX, $event->GetY );
    return if $to < 0;

    $self->list->move_entry( $self->{_entrylist_drag_index}, $to );
}

sub _entry {
    my( $self, $x, $y ) = @_;
    my( $item, $flags ) = $self->HitTest( [$x, $y] );

    if( $item < 0 || $flags & wxLIST_HITTEST_NOWHERE ) {
        return $self->GetItemCount;
    } elsif( $flags & wxLIST_HITTEST_ONITEM ) {
        return $item;
    } else {
        return -1;
    }
}

sub _list_changed {
    my( $self, $list, $event, %args ) = @_;

    my( $from, $to );
    if( $event eq 'delete_entries' ) {
        $self->refresh;
        return;
    } elsif( $event eq 'add_entries' ) {
        ( $from, $to ) = ( $args{index}, $self->GetItemCount );
    } elsif( $event eq 'move_entries' ) {
        ( $from, $to ) = ( $args{from}, $args{to} );
    }
    my $items = $self->GetItemCount ? $self->GetItemCount - 1 : 0;
    ( $from, $to ) = sort { $a <=> $b }
                     map  $_ < 0 ? 0 :
                          $_ > $items ? $items :
                          $_, ( $from, $to );
    $self->refresh( $from, $to );
}

1;
