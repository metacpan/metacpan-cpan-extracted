package Wx::Perl::ListView;

=head1 NAME

Wx::Perl::ListView - virtual list control interface

=head1 METHODS

=cut

use Wx;

use strict;
use base qw(Wx::ListCtrl);

our $VERSION = '0.01';

use Wx qw(:listctrl);

=head2 new

  my $listview = Wx::Perl::ListView->new( $model, $parent, $id,
                                          $position, $size, $style );

Constructs a C<Wx::Perl::ListView> using the given model.

=cut

sub new {
    my( $class, $model, $parent, $id, $pos, $size, $style ) = @_;
    my $self = $class->SUPER::new( $parent, $id || -1,
                                   $pos || [-1, -1], $size || [-1,-1],
                                   ( $style || 0 ) |wxLC_VIRTUAL|wxLC_REPORT );

    $self->{_model} = $model;
    $self->{_cache} = { row => -1, column => -1 };
    $self->{_attr} = Wx::ListItemAttr->new;

    return $self;
}

sub _get_item {
    my( $self, $row, $column ) = @_;
    return $self->{_cache}{item}
      if    $self->{_cache}{row} == $row
         && $self->{_cache}{column} == $column;

    my $item = $self->{_model}->get_item( $row, $column );
    die "Could not get item for ($row, $column)" unless $item;
    if( $item->{font} || $item->{foreground} || $item->{background} ) {
        $item->{attr} = Wx::ListItemAttr->new;
        $item->{attr}->SetTextColour( $item->{foreground} )
          if $item->{foreground};
        $item->{attr}->SetBackgroundColour( $item->{background} )
          if $item->{background};
        $item->{attr}->SetFont( $item->{font} )
          if $item->{font};
    }

    $self->{_cache} = { row => $row, column => $column, item => $item };

    return $item;
}

sub OnGetItemText {
    my( $self, $row, $column ) = @_;
    my $item = $self->_get_item( $row, $column );

    return defined $item->{string} ? $item->{string} : '';
}

sub OnGetItemImage {
    my( $self, $row ) = @_;
    my $item = $self->_get_item( $row, 0 );

    return defined $item->{image} ? $item->{image} : -1;
}

sub OnGetItemColumnImage {
    my( $self, $row, $column ) = @_;
    my $item = $self->_get_item( $row, $column );

    return defined $item->{image} ? $item->{image} : -1;
}

sub OnGetItemAttr {
    my( $self, $row ) = @_;
    my $item = $self->_get_item( $row, 0 );

    return $item->{attr} || $self->{_attr};
}

=head2 refresh

  $listview->refresh;
  $listview->refresh( $item );
  $listview->refresh( $from, $to );

Refreshes the displayed data from the model.  Might also change
the number of items in the control.

=cut

sub refresh {
    my( $self, $from, $to ) = @_;

    $self->{_cache} = { row => -1, column => -1 };
    $self->SetItemCount( $self->{_model}->get_item_count );
    $self->RefreshItems( $from, $to ), return if @_ == 3;
    $self->RefreshItem( $from ), return if @_ == 2;
    $self->Refresh, return;
}

=head2 model

  my $model = $listview->model;

=cut

sub model    { $_[0]->{_model} }

1;

__END__

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

Copyright (c) 2007 Mattia Barbon <mbarbon@cpan.org>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself
