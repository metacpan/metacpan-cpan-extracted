package Tickit::WidgetRole::Movable;
# ABSTRACT: resizable/movable panel mixin for Tickit widgets
use strict;
use warnings;
use parent qw(Tickit::WidgetRole);

our $VERSION = '0.002';

=head1 NAME

Tickit::WidgetRole::Movable - support for resizable/movable "panels"

=head1 VERSION

Version 0.002

=head1 SYNOPSIS

 package Tickit::Widget::MovingThing;
 use parent qw(Tickit::WidgetRole::Movable Tickit::Widget);

 sub lines { 2 }
 sub cols { 2 }
 sub render_to_rb { ... }

=head1 DESCRIPTION

B< WARNING >: This is an early preview release. Things may change.

Apply this as a parent class to a widget to provide for resize/move semantics, similar to
behaviour provided by common window managers.

Expects the widget to be contained by a parent object which provides a suitable area in
which to resize/move the widget.

State information is stored in the C< _movable_role > hashref in C< $self >, so this requires
instances to be blessed hashrefs.

=cut

use constant {
	# Resizing horizontally and/or vertically
	NORTH => 1,
	EAST  => 2,
	SOUTH => 3,
	WEST  => 4,

	# Resizing by corner
	NORTHWEST => 5,
	NORTHEAST => 6,
	SOUTHWEST => 7,
	SOUTHEAST => 8,
};

=head2 MIN_HEIGHT

Minimum height to apply to this widget. Default is 2.

=cut

use constant MIN_HEIGHT => 2;

=head2 MIN_WIDTH

Minimum width to apply to this widget. Default is 2.

=cut

use constant MIN_WIDTH => 2;

=head1 METHODS

=cut

=head2 export_subs_for

Empty implementation for L<Tickit::WidgetRole> C<export_subs_for>.

=cut

# TODO The model used by L<Tickit::WidgetRole> doesn't seem to be a good fit here. We
# want something closer to classical inheritance; the target widget needs to have the
# ability to override/wrap our methods, so we don't want to inject those as subs directly.
sub export_subs_for { +{ } }

=head2 on_mouse

Handle mouse events.

We can be in one of three states here: a mouse press, a drag event, or a release.

We delegate each of these to separate methods - see:

=over 4

=item * L</mouse_press> - first click, this is either a one-off or the start of a drag event

=item * L</mouse_release> - mouse has been released, either after a click or after dragging

=item * L</mouse_drag> - one or more mouse buttons are pressed and the mouse has moved

=back

=cut

sub on_mouse {
	my ($self, $ev) = @_;
	return $self->mouse_release($ev->line, $ev->col) if $ev->type eq 'release';
	return unless $ev->button & 1;

	return $self->mouse_press($ev->line, $ev->col) if $ev->type eq 'press';
	return $self->mouse_drag($ev->line, $ev->col) if $ev->type eq 'drag';
}

=head2 mouse_press

Handle a mouse press event.

We're either in:

=over 4

=item * a corner - start resizing in both directions

=item * an edge - start resizing in one dimension

=item * the title bar - start moving the window

=back

=cut

sub mouse_press {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;

	if(my $corner = $self->position_is_corner($line, $col)) {
		$self->start_resize_from_corner($corner);
	} elsif($self->position_is_title($line, $col)) {
		$self->start_moving($line, $col);
	} elsif(my $edge = $self->position_is_edge($line, $col)) {
		$self->start_resize_from_edge($edge);
	}
	return 1;
}

=head2 position_is_corner

If this location is a corner of the window, return the
appropriate constant (NORTHEAST, NORTHWEST, SOUTHEAST,
SOUTHWEST), otherwise returns false.

=cut

sub position_is_corner {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;
	if($line == 0) {
		return NORTHWEST if $col == 0;
		return NORTHEAST if $col == $win->cols - 1;
		return 0;
	}
	return 0 unless $line == $win->lines - 1;
	return SOUTHWEST if $col == 0;
	return SOUTHEAST if $col == $win->cols - 1;
	return 0;
}

=head2 position_is_corner

If this location is an edge for this window, return the
appropriate constant (NORTH, EAST, SOUTH, WEST), otherwise
returns false.

=cut

sub position_is_edge {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;
	return NORTH if $line == 0;
	return WEST if $col == 0;
	return SOUTH if $line == $win->lines - 1;
	return EAST if $col == $win->cols - 1;
	return 0;
}

=head2 position_is_title

If this location is somewhere in the title (currently defined
as "top row, apart from corners and close button), returns true.

=cut

sub position_is_title {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;
	return 1 if $line == 0 && $col > 0 && $col < ($win->cols - 2);
	return 0;
}

=head2 start_resize_from_corner

Start resizing from a corner.

=cut

sub start_resize_from_corner {
	my $self = shift;
	my $corner = shift;
	my $win = $self->window or return;
	$self->{_movable_role}{mouse_action} = 'resize_from_corner';
	$self->{_movable_role}{corner} = $corner;
	$self->{_movable_role}{origin} = {
		map { $_ => $win->$_ } qw(top left bottom right)
	};
	$win->{steal_input} = 1;
}

=head2 start_resize_from_edge

Start resizing from an edge.

=cut

sub start_resize_from_edge {
	my $self = shift;
	my $edge = shift;
	my $win = $self->window or return;
	$self->{_movable_role}{mouse_action} = 'resize_from_edge';
	$self->{_movable_role}{edge} = $edge;
	$self->{_movable_role}{origin} = {
		map { $_ => $win->$_ } qw(top left bottom right)
	};
	$win->{steal_input} = 1;
}

=head2 start_moving

Start moving the window.

=cut

sub start_moving {
	my $self = shift;
	my ($line, $col) = @_;
	my $win = $self->window or return;
	$self->{_movable_role}{mouse_action} = 'move';
	$self->{_movable_role}{origin} = {
		line => $line,
		col => $col,
	};
	$win->{steal_input} = 1;
}

=head2 mouse_drag

Deal with our drag events by changing window geometry
accordingly.

=cut

sub mouse_drag {
	my ($self, $line, $col) = @_;
	if(my $action = $self->{_movable_role}{mouse_action}) {
		$self->$action($line, $col);
	} else {
		# Dragging one window over another is probably
		# going to raise this warning...
		# die "Unknown action";
	}
}

=head2 move

Handle ongoing move events.

=cut

sub move {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;
	my $top = $win->top + ($line - $self->{_movable_role}{origin}{line});
	my $left = $win->left + ($col - $self->{_movable_role}{origin}{col});
	$self->change_geometry(
		$top,
		$left,
		$win->lines,
		$win->cols,
	);
}

=head2 resize_from_corner

Resize action, from a corner.

=cut

sub resize_from_corner {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;
	if($self->{_movable_role}{corner} == SOUTHEAST) {
		my $lines = $line + 1;
		my $cols = $col + 1;
		return unless $lines >= $self->MIN_HEIGHT && $cols >= $self->MIN_WIDTH;
		$self->change_geometry(
			$win->top,
			$win->left,
			$lines,
			$cols,
		);
	} elsif($self->{_movable_role}{corner} == NORTHEAST) {
		my $lines = $win->bottom - ($win->top + $line);
		my $cols = $col + 1;
		return unless $lines >= $self->MIN_HEIGHT && $cols >= $self->MIN_WIDTH;
		$self->change_geometry(
			$win->top + $line,
			$win->left,
			$lines,
			$cols,
		);
	} elsif($self->{_movable_role}{corner} == NORTHWEST) {
		my $lines = $win->bottom - ($win->top + $line);
		my $cols = $win->right - ($win->left + $col);
		return unless $lines >= $self->MIN_HEIGHT && $cols >= $self->MIN_WIDTH;
		$self->change_geometry(
			$win->top + $line,
			$win->left + $col,
			$lines,
			$cols,
		);
	} elsif($self->{_movable_role}{corner} == SOUTHWEST) {
		my $lines = $line + 1;
		my $cols = $win->right - ($win->left + $col);
		return unless $lines >= $self->MIN_HEIGHT && $cols >= $self->MIN_WIDTH;
		$self->change_geometry(
			$win->top,
			$win->left + $col,
			$lines,
			$cols,
		);
	}
}

=head2 resize_from_edge

Resize action - starting from an edge.

=cut

sub resize_from_edge {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;
	if($self->{_movable_role}{edge} == NORTH) {
		my $lines = $win->bottom - ($win->top + $line);
		return unless $lines >= $self->MIN_HEIGHT;
		$self->change_geometry(
			$win->top + $line,
			$win->left,
			$lines,
			$win->cols,
		);
	} elsif($self->{_movable_role}{edge} == EAST) {
		my $cols = $col + 1;
		return unless $cols >= $self->MIN_WIDTH;
		$self->change_geometry(
			$win->top,
			$win->left,
			$win->lines,
			$cols,
		);
	} elsif($self->{_movable_role}{edge} == SOUTH) {
		my $lines = $line + 1;
		return unless $lines >= $self->MIN_HEIGHT;
		$self->change_geometry(
			$win->top,
			$win->left,
			$line + 1,
			$win->cols,
		);
	} elsif($self->{_movable_role}{edge} == WEST) {
		my $cols = $win->right - ($win->left + $col),;
		return unless $cols >= $self->MIN_WIDTH;
		$self->change_geometry(
			$win->top,
			$win->left + $col,
			$win->lines,
			$cols,
		);
	}
}

=head2 mouse_release

On release make sure we hand back input to the previous handler.

=cut

sub mouse_release {
	my ($self, $v) = @_;
	my $win = $self->window or die "no window?";
	$win->{steal_input} = 0;
	$self->{_movable_role}{mouse_action} = '';
}

=head2 change_geometry

Default action when attempting to change geometry is to proxy this
to the L<Tickit::Window> directly. Override this in subclasses to
implement constraints (e.g. clamp co-ordinates and pass to C< ->SUPER::change_geometry >,
or return early without applying the action) or linked window actions
(move/resize another window after applying the geometry change to
this one).

=cut

sub change_geometry {
	shift->window->change_geometry(@_);
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Tickit::Window>

=item * L<Tickit::WidgetRole::Borderable>

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
