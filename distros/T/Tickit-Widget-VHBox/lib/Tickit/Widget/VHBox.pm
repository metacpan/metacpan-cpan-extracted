package Tickit::Widget::VHBox;
# ABSTRACT: Horizontal layout with vertical fallback
use strict;
use warnings;

use parent qw(Tickit::Widget::LinearBox);

our $VERSION = '0.001';

=head1 NAME

Tickit::Widget::VHBox - distribute child widgets vertically or horizontally

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::VBox;
 use Tickit::Widget::Static;

 my $vbox = Tickit::Widget::VBox->new;

 foreach my $position (qw( top middle bottom )) {
    $vbox->add(
       Tickit::Widget::Static->new(
          text   => $position,
          align  => "centre",
          valign => $position,
       ),
       expand => 1
    );
 }

 Tickit->new( root => $vbox )->run;

=head1 DESCRIPTION

This subclass of L<Tickit::Widget::LinearBox> distributes its children
horizontally if there is room, falling back to a vertical layout if
necessary.

=head1 STYLE

The default style pen is used as the widget pen.

Note that while the widget pen is mutable and changes to it will result in
immediate redrawing, any changes made will be lost if the widget style is
changed.

The following style keys are used:

=over 4

=item spacing => INT

The spacing (lines or columns) between children

=back

=cut

use Tickit::Style;
use List::Util qw( sum max );

BEGIN {
	style_definition base =>
	   spacing => 0;

	style_reshape_keys qw( spacing );
}

use constant WIDGET_PEN_FROM_STYLE => 1;

sub orientation { shift->{orientation} ||= 'horizontal' }

sub is_horizontal { shift->{orientation} eq 'horizontal' }

sub lines {
	my $self = shift;
	if($self->is_horizontal) {
		return max( 1, map { $_->requested_lines } $self->children );
	} else {
		my $spacing = $self->get_style_values( "spacing" );
		return ( sum( map { $_->requested_lines } $self->children ) || 1 ) +
			$spacing * ( $self->children - 1 );
	}
}

sub cols {
	my $self = shift;
	if($self->is_horizontal) {
		my $spacing = $self->get_style_values( "spacing" );
		return ( sum( map { $_->requested_cols } $self->children ) || 1 ) +
			$spacing * ( $self->children - 1 );
	} else {
		return max( 1, map { $_->requested_cols } $self->children );
	}
}

sub get_total_quota {
   my $self = shift;
   my ( $window ) = @_;
   return $self->is_horizontal ? $window->cols : $window->lines;
}

sub get_child_base {
   my $self = shift;
   my ( $child ) = @_;
   return $self->is_horizontal ? $child->requested_cols : $child->requested_lines;
}

sub set_child_window {
	my $self = shift;
	if($self->is_horizontal) {
		my ( $child, $left, $cols, $window ) = @_;

		if( $window and $cols ) {
			if( my $childwin = $child->window ) {
				$childwin->change_geometry( 0, $left, $window->lines, $cols );
			} else {
				my $childwin = $window->make_sub( 0, $left, $window->lines, $cols );
				$child->set_window( $childwin );
			}
		} else {
			if( $child->window ) {
				$child->set_window( undef );
			}
		}
	} else {
		my ( $child, $top, $lines, $window ) = @_;

		if( $window and $lines ) {
			if( my $childwin = $child->window ) {
				$childwin->change_geometry( $top, 0, $lines, $window->cols );
			} else {
				my $childwin = $window->make_sub( $top, 0, $lines, $window->cols );
				$child->set_window( $childwin );
			}
		} else {
			if( $child->window ) {
				$child->set_window( undef );
			}
		}
	}
}

1;

__END__

=head1 LICENSE

Almost entirely based on L<Tickit::Widget::VBox> and L<Tickit::Widget::HBox>,
see those for more details.

Licensed under the same terms as Perl itself.
