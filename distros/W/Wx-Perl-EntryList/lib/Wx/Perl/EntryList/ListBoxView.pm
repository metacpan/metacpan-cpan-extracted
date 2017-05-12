package Wx::Perl::EntryList::ListBoxView;

use Wx;

=head1 NAME

Wx::Perl::EntryList::ListBoxView - display an entry list

=head1 DESCRIPTION

Uses a C<Wx::ListBox> to display an entry list.

=head1 METHODS

=cut

use strict;
use base qw(Wx::ListBox Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(list model) );

sub new {
    my( $class, $entrylist, $model, $parent, $style ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1, -1], [-1, -1],
                                   [], $style );
    $self->model( $model );
    $self->set_list( $entrylist );

    return $self;
}

sub set_list {
    my( $self, $entrylist ) = @_;

    $self->list->delete_subscriber( '*', $self ) if $self->list;
    if( $entrylist ) {
        $entrylist->add_subscriber( '*', $self, '_list_changed' );
        $self->list( $entrylist );
        $self->_fill_list;
    }
}

sub DESTROY {
    my( $self ) = @_;

    $self->set_list( undef );
}

sub _fill_list {
    my( $self ) = @_;

    $self->Clear;

    for( my $i = 0; $i < $self->list->count; ++$i ) {
        $self->Append( $self->model->( $self->list->get_entry_at( $i ) ) );
    }
}

sub _list_changed {
    my( $self, $list, $event, %args ) = @_;

    if( $event eq 'delete_entries' ) {
        $self->Delete( $args{index} );
    } elsif( $event eq 'add_entries' ) {
        my $entry = $list->get_entry_at( $args{index} );
        my( $label, $data ) = $self->model->( $entry );
        $self->InsertItems( [ $label ], $args{index} );
        $self->SetClientData( $args{index}, $data );
    } elsif( $event eq 'move_entries' ) {
        my $label = $self->GetString( $args{from} );
        my $data = $self->GetClientData( $args{from} );
        $self->Delete( $args{from} );
        $args{to}-- if $args{from} < $args{to};
        $self->InsertItems( [ $label ], $args{to} );
        $self->SetClientData( $args{to}, $data );
    }
}

1;
