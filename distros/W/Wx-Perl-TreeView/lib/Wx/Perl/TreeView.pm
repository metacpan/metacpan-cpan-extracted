package Wx::Perl::TreeView;

=head1 NAME

Wx::Perl::TreeView - virtual tree control interface

=head1 DESCRIPTION

C<Wx::Perl::TreeView> provides a "virtual" tree control, similar to
a virtual C<Wx::ListCtrl>.  All the data access methods are contained
inside C<Wx::Perl::TreeView::Model>.  C<Wx::Perl::TreeView> forwards
all unknown method calls to the contained C<Wx::TreeCtrl>.

=cut

use Wx;

use strict;
use base qw(Wx::EvtHandler);

our $VERSION = '0.02';

use Wx::Event qw(EVT_TREE_ITEM_EXPANDING);

=head2 new

  my $treeview = Wx::Perl::TreeView->new( $tree_control, $model );

Constructs a new C<Wx::Perl::TreeView> instance using the previously
constructed tree control and model.

=cut

sub new {
    my( $class, $tree, $model ) = @_;
    my $self = $class->SUPER::new;

    $self->{treectrl} = $tree;
    $self->{model}    = $model;

    $tree->PushEventHandler( $self );

    # FIXME work around wxWidgets bug :-(
    my $target = Wx::wxMSW || Wx::wxVERSION >= 2.009 ?
                     $self : $tree;
    EVT_TREE_ITEM_EXPANDING( $target, $tree,
                             sub { $self->_on_item_expanding( $_[1]->GetItem );
                                   $_[1]->Skip;
                                   } );

    $self->reload;

    return $self;
}

sub _on_item_expanding {
    my( $self, $item ) = @_;
    my $tree = $self->treectrl;
    my $model = $self->model;
    my $cookie = $tree->GetPlData( $item )->{cookie};

    $tree->DeleteChildren( $item );

    my $count = $model->get_child_count( $cookie );
    if( $count == 0 ) {
        $tree->SetItemHasChildren( $item, 0 );
        return;
    }

    for( my $i = 0; $i < $count; ++$i ) {
        my( $ccookie, $cstring, $cimage, $ccdata ) =
            $model->get_child( $cookie, $i );

        my $child = $tree->AppendItem
          ( $item, $cstring, ( defined $cimage ? $cimage : -1 ), -1,
            Wx::TreeItemData->new( { cookie => $ccookie, data => $ccdata } ) );
        $tree->SetItemHasChildren( $child, $model->has_children( $ccookie ) );
    }
}

=head2 reload

  $treeview->reload;

Deletes all tree items and readds root node(s) from the model.

=cut

sub reload {
    my( $self ) = @_;
    my( $model, $tree ) = ( $self->model, $self->treectrl );
    $self->DeleteAllItems;

    my( $cookie, $string, $image, $data ) = $model->get_root;
    my $root = $tree->AddRoot
      ( $string, ( defined $image ? $image : -1 ), -1,
        Wx::TreeItemData->new( { cookie => $cookie, data => $data } ) );
    $tree->SetItemHasChildren( $root, $model->has_children( $cookie ) );

    if( $tree->GetWindowStyleFlag & Wx::wxTR_HIDE_ROOT() ) {
        $self->_on_item_expanding( $root );
    }
}

=head2 refresh

  my $refreshed = $treeview->refresh;
  my $refreshed = $treeview->refresh( [ $treeitemid1, $treeitemid2, ... ] );

Walks the tree and refreshes data from the expanded tree
branches. Returns C<true> on success.

If one of the expanded nodes has a different child count in the model
and in the tree, calls C<reload> and returns C<false>.

If a list of C<Wx::TreeItemId> is passed as argument, te child count
of these nodes is not checked against the model, and after refreshing
these nodes are expanded.

=cut

sub refresh {
    my( $self, $is_expanding ) = @_;
    $is_expanding ||= [];

    my( $model, $tree ) = ( $self->model, $self->treectrl );

    my( $cookie, $string, $image ) = $model->get_root;
    my( $can_refresh, $data ) = $self->_check( $tree->GetRootItem, $cookie,
                                               $string, $image,
                                               $is_expanding );
    if( $can_refresh ) {
        $self->_refresh( $tree->GetRootItem, $data );
    } else {
        $self->reload;
    }
    $self->_on_item_expanding( $_ ) foreach @$is_expanding;

    return $can_refresh;
}

sub _check {
    my( $self, $pitem, $pcookie, $pstring, $pimage, $pcdata,
        $is_expanding ) = @_;
    my( $model, $tree ) = ( $self->model, $self->treectrl );
    my $data = { text   => $pstring,
                 image  => $pimage,
                 cookie => $pcookie,
                 data   => $pcdata,
                 childs => [],
                 };
    return ( 1, $data ) if grep $_ == $pitem, @$is_expanding;
    return ( 1, $data ) unless $tree->IsExpanded( $pitem );
    my $cchilds = $tree->GetChildrenCount( $pitem, 0 );
    my $mchilds = $model->get_child_count( $pcookie );

    return ( 0, undef ) if $cchilds != $mchilds;

    my( $child, $cookie ) = $tree->GetFirstChild( $pitem );
    my $index = 0;
    while( $child->IsOk ) {
        my( $ccookie, $cstring, $cimage, $ccdata ) =
            $model->get_child( $pcookie, $index );
        my( $can_refresh, $cdata ) = $self->_check
            ( $child, $ccookie, $cstring, $cimage, $ccdata, $is_expanding );
        return ( 0, undef ) unless $can_refresh;
        push @{$data->{childs}}, $cdata;
        ( $child, $cookie ) = $tree->GetNextChild( $pitem, $cookie );
        ++$index;
    }

    return ( 1, $data );
}

sub _refresh {
    my( $self, $item, $data ) = @_;
    my $tree = $self->treectrl;

    $tree->SetItemText( $item, $data->{text} );
    $tree->SetItemImage( $item, defined $data->{image} ? $data->{image} : -1 );
    $tree->SetPlData( $item, { cookie => $data->{cookie},
                               data   => $data->{data},
                               } );

    return unless $tree->IsExpanded( $item );

    my( $child, $cookie ) = $tree->GetFirstChild( $item );
    my $index = 0;
    while( $child->IsOk ) {
        $self->_refresh( $child, $data->{childs}[$index] );
        ( $child, $cookie ) = $tree->GetNextChild( $item, $cookie );
        ++$index;
    }
}

=head2 get_cookie

  my $cookie = $treeview->get_cookie( $treeitemid );

Returns the cookie associated with the given C<Wx::TreeItemId>.

=cut

sub get_cookie {
    my( $self, $item ) = @_;

    return $self->treectrl->GetPlData( $item )->{cookie};
}

=head2 treectrl

  my $treectrl = $treeview->treectrl;

=head2 model

  my $model = $treeview->model;

=cut

sub treectrl { $_[0]->{treectrl} }
sub model    { $_[0]->{model} }

sub GetPlData {
    my( $self, $item ) = @_;

    return $self->treectrl->GetPlData( $item )->{data};
}

sub SetPlData {
    my( $self, $item, $data ) = @_;

    $self->treectrl->GetPlData( $item )->{data} = $data;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my( $self ) = shift;
    ( my $name = $AUTOLOAD ) =~ s/.*:://;
    return unless $self->{treectrl}; # global destruction
    $self->{treectrl}->$name( @_ );
}

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2007 Mattia Barbon <mbarbon@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself
