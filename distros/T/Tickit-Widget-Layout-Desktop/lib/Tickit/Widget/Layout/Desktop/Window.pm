package Tickit::Widget::Layout::Desktop::Window;
$Tickit::Widget::Layout::Desktop::Window::VERSION = '0.010';
use strict;
use warnings;

use parent qw(Tickit::WidgetRole::Movable Tickit::SingleChildWidget);

=head1 NAME

Tickit::Widget::Layout::Desktop - provides a holder for "desktop-like" widget behaviour

=head1 VERSION

version 0.010

=cut

use curry::weak;
use Tickit::RenderBuffer qw(LINE_THICK LINE_SINGLE LINE_DOUBLE);
use Tickit::Utils qw(textwidth);
use Tickit::Style;

use constant WIDGET_PEN_FROM_STYLE => 1;

BEGIN {
	style_definition base =>
		fg          => 'grey',   # Generic frame lines
		linetype    => 'round',  # How to draw frames, 'round' means single with rounded corners
		maximise_fg => 'green',  # Maximise button
		close_fg    => 'red',    # Close button
		control_fg  => 'white',  # Control
		title_fg    => 'white';

	style_definition ':active' =>
		fg          => 'white',
		maximise_fg => 'hi-green',
		close_fg    => 'hi-red',
		title_fg    => 'hi-green';

	style_definition ':focus-child' =>
		fg          => 'hi-green';
	style_definition ':focus' =>
		fg          => 'hi-red';
}

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new;
	Scalar::Util::weaken(
		$self->{container} = $args{container} or die "No container provided?"
	);
	$self;
}

=head2 position_is_maximise

Returns true if this location is the maximise button.

=cut

sub position_is_maximise {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;
	# what hardcoded madness is this
	return 1 if $line == 0 && $col == $win->cols - 4;
	return 0;
}

=head2 position_is_close

Returns true if this location is the close button.

=cut

sub position_is_close {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;
	# again I say with the numbers
	return 1 if $line == 0 && $col == $win->cols - 2;
	return 0;
}

sub position_is_control {
	my ($self, $line, $col) = @_;
	my $win = $self->window or return;
	# more numbers!
	return 1 if $line == 0 && $col >= 1 && $col <= 3;
	return 0;
}

sub action_close {
	my ($self) = @_;
	# Close button... probably need some way to indicate when
	# this happens, Tickit::Window doesn't appear to have set_on_closed ?
	$self->close;
}

sub close {
	my ($self) = @_;
	$self->{container}->close_panel($self);
	$self
}

sub action_restore {
	my ($self) = @_;
	my $win = $self->window or return 1;
	return 1 unless $self->{maximised};
	$win->change_geometry(
		$self->{maximised}->top,
		$self->{maximised}->left,
		$self->{maximised}->lines,
		$self->{maximised}->cols,
	);
	delete $self->{maximised};
}

sub parent { shift->{container} }

sub action_maximise {
	my ($self) = @_;
	my $win = $self->window or return 1;
	return 1 if $self->{maximised};
	$self->{maximised} = $win->rect;
	$win->change_geometry(
		0,
		0,
		$win->parent->lines,
		$win->parent->cols,
	);
}

sub action_control {
	my ($self) = @_;
	$self->{container}->show_control(
		$self,
		$self->{maximised}
		? ('Restore' => $self->curry::weak::action_restore)
		: ('Maximise' => $self->curry::weak::action_maximise),
		'Minimise' => $self->curry::weak::action_minimise,
		'Weld'     => $self->curry::weak::action_weld,
		'Unweld'   => $self->curry::weak::action_unweld,
		'On top'   => sub {  },
		'Close'    => $self->curry::weak::action_close,
	);
}

sub action_weld { }
sub action_unweld { }

=head2 mouse_press

Override mouse click events to mark this window as active
before continuing with the usual move/resize detection logic.

Provides click-to-raise and click-to-focus behaviour.

=cut

sub mouse_press {
	my $self = shift;
	my ($line, $col) = @_;
	$self->{container}->make_active($self);
	if($self->position_is_close($line, $col)) {
		$self->action_close;
		return 1;
	} elsif($self->position_is_maximise($line, $col)) {
		$self->action_maximise;
		return 1;
	} elsif($self->position_is_control($line, $col)) {
		$self->action_control;
		return 1;
	} else {
		$self->SUPER::mouse_press(@_)
	}
}

=head2 with_rb

Runs the given coderef with a L<Tickit::RenderBuffer>, saving
and restoring the context around the call.

Returns $self.

=cut

sub with_rb {
	my ($self, $rb, $code) = @_;
	$rb->save;
	$code->($rb);
	$rb->restore;
	$self;
}

=head2 content_rect

Represents the inner area of this window, i.e. the
content without the frame.

=cut

sub content_rect {
	my ($self) = @_;
	my $win = $self->window;
	$self->child->window->rect->translate(
		$win->top,
		$win->left
	)
}

sub container { shift->{container} }

my %override = (
	southeast => 0x256D,
	northeast => 0x2570,
	southwest => 0x256E,
	northwest => 0x256f,
);

=head2 render_to_rb

Returns $self.

=cut

sub render_to_rb {
	my ($self, $rb, $rect) = @_;
	my $win = $self->window or return;
	return unless $self->child->window;

	# If the exposed area does not overlap the frame, bail out now
	return if $self->content_rect->contains($rect);

	# Use a default pen for drawing all the line-related pieces
	$rb->setpen($self->get_style_pen);

	# First, work out any line intersections for our border.
	$self->with_rb($rb => sub {
		my $rb = shift;
		my ($top, $left) = ($win->top, $win->left);

		# We'll be rendering relative to the container
		$rb->translate(-$top, -$left);

		# Ask our container to ask all other floating
		# windows to render their frames on our context,
		# so we join line segments where expected
		$self->{container}->overlay($rb, $rect, $self);

		# Restore our origin
		# TODO would've thought ->restore should handle this?
		$rb->translate($top, $left);
	});

	my ($w, $h) = map $win->$_ - 1, qw(cols lines);
	my $text_pen = $self->get_style_pen('title');

	# This is a nasty hack - we want to know whether it's safe to draw
	# rounded corners, so we start by checking whether we have any line
	# cells already in place in the corners...

	# ... then we render our actual border, possibly using a different style for
	# active window...
	my $line = {
		round  => LINE_SINGLE,
		single => LINE_SINGLE,
		thick  => LINE_THICK,
		double => LINE_DOUBLE,
	}->{$self->get_style_values('linetype')};

	# So we first render the frame. This will pick up any adjoining lines from
	# our overlay, all being well.
	$rb->linebox_at(0, $h, 0, $w, $line);

	if($self->get_style_values('linetype') eq 'round') {
		my $limit = [
			$win->root->bottom,
			$win->root->right
		];

		my @corner_char;
		CORNER:
		foreach my $corner ([0,0], [0,$w], [$h,0], [$h,$w]) {
			my ($y, $x) = @$corner;
			next CORNER if $y >= $limit->[0] or $x >= $limit->[1] or $x < 0 or $y < 0;

			# Apply our window offset... note that ->get_cell will segfault if
			# we're outside the render area, so the widget width had better be
			# correct here.
			my $cell = eval { $rb->get_cell($y, $x); };

			# If we have a line segment here, ->linemask should be an object...
			next CORNER unless $cell and my $linemask = $cell->linemask;

			# ... which we map to a "corner" type
			my $corners = join "", grep { $linemask->$_ == LINE_SINGLE } qw( north south east west );

			push @corner_char, [
				$y, $x, $override{$corners}, $cell->pen
			] if exists $override{$corners};
		}
		# ... and finally we overdraw the corners.
		$rb->char_at(@$_) for @corner_char;
	}

	# Then the title
	my $txt = $self->format_label;
	$rb->text_at(0, (1 + $w - textwidth($txt)) >> 1, $txt, $text_pen);

	# and the icons for min/max/close.
	$rb->text_at(0, $w - 3, " ", $self->get_style_pen('maximise'));
	$rb->text_at(0, $w - 1, " ", $self->get_style_pen('maximise'));
	$rb->text_at(0, $w - 4, "\N{U+25CE}", $self->get_style_pen('maximise'));
	$rb->text_at(0, $w - 2, "\N{U+2612}", $self->get_style_pen('close'));

	$rb->text_at(0, 1, "[\N{U+25AA}]", $self->get_style_pen('control'));

	# Minimise isn't particularly useful, so let's not bother with that one.
	# $rb->text_at(0, $w - 5, "\N{U+238A}", Tickit::Pen->new(fg => 'hi-yellow'));
}

sub format_label {
	my $self = shift;
	' ' . $self->label . ' ';
}

sub render_frame {
	my ($self, $rb, $target) = @_;
	my $win = $self->window or return;

	my $line_type = LINE_SINGLE; #LINE_DOUBLE; #$self->is_active ? LINE_DOUBLE : LINE_SINGLE;

	$self->with_rb($rb, sub {
		my $rb = shift;
		# so we restrict our frame rendering to the area covered by the target...
		$rb->clip($target);

		# then render all 4 edges, taking into account potential split where the
		# target area goes. We want to render up to the target but not actually
		# overlapping it, otherwise we'll end up with T junctions rather than
		# corners. This all seems mildly inefficient and overcomplicated but
		# calculating as Tickit::Rect overlap/subtract combinations was beyond
		# me at the time of writing. Patches welcome.
		if($win->left < $target->left) {
			$rb->hline_at($win->top, $win->left, $target->left, $line_type);
			$rb->hline_at($win->bottom - 1, $win->left, $target->left, $line_type);
		}
		if($win->right > $target->right) {
			$rb->hline_at($win->top, $target->right - 1, $win->right - 1, $line_type);
			$rb->hline_at($win->bottom - 1, $target->right - 1, $win->right - 1, $line_type);
		}
		if($win->top < $target->top) {
			$rb->vline_at($win->top, $target->top, $win->left, $line_type);
			$rb->vline_at($win->top, $target->top, $win->right - 1, $line_type);
		}
		if($win->bottom > $target->bottom) {
			$rb->vline_at($target->bottom - 1, $win->bottom - 1, $win->left, $line_type);
			$rb->vline_at($target->bottom - 1, $win->bottom - 1, $win->right - 1, $line_type);
		}
	});
}

sub is_active { shift->{active} ? 1 : 0 }

sub label {
	my $self = shift;
	return $self->{label} // '' unless @_;
	$self->{label} = shift;
	return $self;
}

sub lines {
	my $self = shift;
	my $child = $self->child;
	return 2 + ($child ? $child->lines : 0);
}

sub cols {
	my $self = shift;
	my $child = $self->child;
	return 2 + ($child ? $child->cols : 0);
}

sub children_changed { shift->set_child_window }

sub window_gained {
	my $self = shift;
	my ($win) = @_;
	delete $self->{frame_rects};
	$self->{window_lines} = $win->lines;
	$self->{window_cols} = $win->cols;
	return $self->SUPER::window_gained(@_);
}

sub reshape {
	my $self = shift;
	my $win = $self->window;

	# Keep our frame info if we're just moving the window around?
	delete $self->{frame_rects};# unless $self->{window_lines} == $win->lines && $self->{window_cols} == $win->cols;
	$self->{window_lines} = $win->lines;
	$self->{window_cols} = $win->cols;
	$self->set_child_window
}

sub set_child_window {
	my $self = shift;

#	warn "set child window for $self\n";
	my $window = $self->window or return;
	my $child  = $self->child  or return;

	my $lines = $window->lines;
	my $cols  = $window->cols;

#	warn "* $lines x $cols\n";
	if( $lines > 2 and $cols > 2 ) {
		if( my $childwin = $child->window ) {
#	warn "* geom change\n";
			$childwin->change_geometry( 1, 1, $lines - 2, $cols - 2 );
		} else {
#	warn "* new sub\n";
			my $childwin = $window->make_sub( 1, 1, $lines - 2, $cols - 2 );
			$child->set_window( $childwin );
		}
	} else {
#		warn "* too small, clear\n";
		if( $child->window ) {
			$child->set_window( undef );
		}
	}
}

sub mark_active {
	my $self = shift;
	$self->{active} = 1;
	$self->set_style_tag(active => 1);
	$self->expose_frame;
	$self
}

sub mark_inactive {
	my $self = shift;
	$self->{active} = 0;
	$self->set_style_tag(active => 0);
	$self->expose_frame;
	$self
}

# 'hmmm.'
sub expose_frame {
	my $self = shift;
	my $win = $self->window or return $self;

	my @rect = $self->frame_rects;
	$win->expose($_) for @rect;
	$self;
}

sub frame_rects {
	my $self = shift;
	@{ $self->{frame_rects} ||= [
		# Tickit::Rect really is quite neat
		$self->window->rect->subtract($self->content_rect)
	] };
}

sub adjust_left {
	my ($self, $delta) = @_;
	my $rect = $self->window->rect;
	my $cols = $rect->cols - $delta;
	return if $cols < $self->MIN_WIDTH;
	$self->window->change_geometry(
		$rect->top,
		$rect->left + $delta,
		$rect->lines,
		$cols,
	)
}
sub adjust_right {
	my ($self, $delta) = @_;
	my $rect = $self->window->rect;
	my $cols = $rect->cols + $delta;
	return if $cols < $self->MIN_WIDTH;
	$self->window->change_geometry(
		$rect->top,
		$rect->left,
		$rect->lines,
		$cols,
	)
}
sub adjust_top {
	my ($self, $delta) = @_;
	my $rect = $self->window->rect;
	my $lines = $rect->lines - $delta;
	return if $lines < $self->MIN_HEIGHT;
	$self->window->change_geometry(
		$rect->top + $delta,
		$rect->left,
		$lines,
		$rect->cols,
	)
}
sub adjust_bottom {
	my ($self, $delta) = @_;
	my $rect = $self->window->rect;
	my $lines = $rect->lines + $delta;
	return if $lines < $self->MIN_HEIGHT;
	$self->window->change_geometry(
		$rect->top,
		$rect->left,
		$lines,
		$rect->cols,
	)
}

sub linked_widgets {
	shift->{linked_widgets} ||= {}
}

=head2 change_geometry

Override geometry changes to allow welding and constraints.

We have a set of rules for each widget, of the following form:

 {
  left => [
   left => $w1,
   right => $w2,
  ],
  top => [
   top => $w2
  ]
 }

If the left edge changes, the left edge of $w1 and the right edge of $w2 would move by the same amount.

If the top changes, the top of $w2 would move by the same amount

That's about it. The idea is that edges can be "joined", meaning that resizing applies to multiple widgets at once.

=cut

sub change_geometry {
	my ($self, $top, $left, $lines, $cols) = @_;

	delete $self->{maximised};

	my $deskwin = $self->container->window;

	$left = 0 if $left < 0;
	$top = 0 if $top < 0;

	$lines = $deskwin->lines if $top < $self->window->top && $self->window->bottom == $deskwin->bottom;
	$cols = $deskwin->cols if $left < $self->window->left && $self->window->right == $deskwin->right;

	$lines = $deskwin->lines - $top if $top + $lines > $deskwin->lines;
	$cols = $deskwin->cols - $left if $left + $cols > $deskwin->cols;

	my $rect = Tickit::Rect->new(
		top => $top,
		left => $left,
		lines => $lines,
		cols => $cols,
	);

	my $linked = $self->linked_widgets;
	EDGE:
	for my $edge (keys %$linked) {	
		my $delta = $rect->$edge - $self->window->$edge or next EDGE;
		my @target = @{$linked->{$edge} ||= []};
		while(my ($k, $v) = splice @target, 0, 2) {
			my $method = 'adjust_' . $k;
			$v->$method(
				$delta
			);
		}
	}
	$self->SUPER::change_geometry(
		$top, $left, $lines, $cols
	);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2012-2015. Licensed under the same terms as Perl itself.
