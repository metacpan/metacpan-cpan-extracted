package Tickit::Widget::Table::Paged;
# ABSTRACT: a table widget for larger datasets
use strict;
use warnings;
use parent qw(Tickit::Widget);

our $VERSION = '0.004';

=head1 NAME

Tickit::Widget::Table::Paged - table widget with support for scrolling/paging

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Table::Paged;

 my $tbl = Tickit::Widget::Table::Paged->new;
 $tbl->{row_offset} = 0;
 $tbl->add_column(
 	label => 'Left',
 	align => 'left',
 	width => 8,
 );
 $tbl->add_column(
 	label => 'Second column',
 	align => 'centre'
 );
 $tbl->add_row('left', 'middle') for 1..100;
 Tickit->new(root => $tbl)->run;

=head1 DESCRIPTION

B<WARNING>: This is a preview release. API is subject to change in future,
please get in contact if you're using this, or wait for version 1.000.

This widget provides a scrollable table implementation.

=begin HTML

<p><img src="http://tickit.perlsite.co.uk/cpan-screenshot/tickit-widget-table-paged1.gif" alt="Paged table widget in action" width="430" height="306"></p>

=end HTML

=cut

use Tickit::RenderBuffer qw(LINE_SINGLE LINE_DOUBLE CAP_BOTH);
use Tickit::Utils qw(distribute substrwidth align textwidth);
use Tickit::Style;
use Scalar::Util qw(looks_like_number);
use POSIX qw(floor);

use constant CLEAR_BEFORE_RENDER => 0;
use constant KEYPRESSES_FROM_STYLE => 1;
use constant CAN_FOCUS => 1;

BEGIN {
	style_definition 'base' =>
		cell_padding         => 1,
		fg                   => 'white',
		highlight_b          => 1,
		highlight_fg         => 'yellow',
		highlight_bg         => 'blue',
		selected_b           => 1,
		selected_fg          => 'white',
		selected_bg          => 'red',
		header_b             => 1,
		header_fg            => 'blue',
		scrollbar_fg         => 'white',
		scrollbar_bg         => 'black',
		scrollbar_line_style => 'none',
		scroll_b             => 1,
		scroll_fg            => 'white',
		scroll_bg            => 'black',
#		scroll_line_style    => 'block';
#
#	style_definition ':focus' =>
		'<Up>'               => 'previous_row',
		'<Down>'             => 'next_row',
		'<PageUp>'           => 'previous_page',
		'<PageDown>'         => 'next_page',
		'<Home>'             => 'first_row',
		'<End>'              => 'last_row',
		'<Left>'             => 'previous_column',
		'<Right>'            => 'next_column',
		'<Space>'            => 'select_toggle',
		'<Enter>'            => 'activate';
}

my %ALIGNMENT_TYPE = (
	left   => 0,
	right  => 1,
	centre => 0.5,
	center => 0.5,
	middle => 0.5,
);

=head1 METHODS

=cut

=head2 new

Instantiate. Will attempt to take focus.

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $on_activate = delete $args{on_activate};
	my $multi_select = delete $args{multi_select};
	my $self = $class->SUPER::new(@_);
	$self->on_activate($on_activate) if $on_activate;
	$self->multi_select($multi_select);
	$self->take_focus;
	$self
}

=head1 METHODS - Table content

=head2 data

Returns the table's current data content as an arrayref.

Note that it is not recommended to make any changes to this
data structure - you are responsible for triggering any
necessary redrawing or resizing logic if you choose to do so.

=cut

sub data {
	shift->{data}
}

=head2 clear

Clear all data in the table.

=cut

sub clear {
	my $self = shift;
	$self->{data} = [];
	$self->{highlight_row} = 0;
	$self->redraw;
	$self
}

=head2 add_row

Add a row to the table. Data should be provided as a list with one item per
column.

Returns $self.

=cut

sub add_row {
	my $self = shift;
	push @{$self->{data}}, [ @_ ];
	$self
}

=head2 add_column

Add a new column. Takes the following named parameters:

=over 4

=item * width - (optional) number of columns

=item * type - (optional) data type, currently only supports 'text' (the default)

=item * align - (optional) align left, center or right

=back

Returns $self.

=cut

sub add_column {
	my $self = shift;
	my %args = @_;
	# delete $args{width} if $args{width} eq 'auto';
	@args{qw(base expand)} = (0,1) unless exists $args{width};
	$args{fixed} = delete $args{width} if looks_like_number($args{width});
	$args{type} ||= 'text';
	$args{align} = $ALIGNMENT_TYPE{$args{align} || 0};
	push @{$self->{columns}}, \%args;
	$self
}

=head2 selected_rows

Returns the selected row, or multiple rows as a list if multi_select is enabled.
If multi_select is enabled it does not return the row currently highlighted (unless that row is also selected).

=cut

sub selected_rows {
	my $self = shift;

	if($self->multi_select) {
		my @selected = sort { $a <=> $b } grep $self->{selected}{$_}, keys %{$self->{selected}};
		return @{$self->data}[@selected];
	} else {
		my $idx = $self->highlight_row;
		return $self->data->[$idx];
	}
}

=head1 METHODS - Callbacks

=head2 on_activate

Accessor for the activation callback - if called without parameters,
will return the current coderef (if any), otherwise, will set the new
callback.

This callback will be triggered via L</key_activate>:

 $code->($row_index, $row_data_as_arrayref)

If multiselect is enabled, the callback will have the following:

 $code->(
   [$highlight_row_index, @selected_row_indices],
   $highlight_row_data_as_arrayref,
   @selected_rows_as_arrayrefs
 )

(the selected row data + index list could be empty here)

=cut

sub on_activate {
	my $self = shift;
	if(@_) {
		$self->{on_activate} = shift;
		return $self;
	}
	return $self->{on_activate}
}

=head2 multi_select

Accessor for multi_select mode - when set, this allows multiple rows
to be selected.

=cut

sub multi_select {
	my $self = shift;
	if(@_) {
		$self->{multi_select} = shift;
		return $self;
	}
	return $self->{multi_select} ? 1 : 0
}

=head1 METHODS - Other

=head2 lines

Number of lines to request.

=cut

sub lines { 1 }

=head2 cols

Number of columns to request.

=cut

sub cols { 1 }

=head2 vscroll

True if there's a vertical scrollbar.

=cut

sub vscroll { 1 }

=head2 hscroll

True if there's a horizontal scrollbar.

=cut

sub hscroll { 0 }

=head2 row_offset

Current row offset (vertical scroll position).

=cut

sub row_offset { shift->{row_offset} ||= 0 }

=head2 visible_lines

Returns the list of lines currently visible in the display.

=cut

sub visible_lines {
	my $self = shift;
	return @{$self->{data}}[$self->row_offset..$self->row_offset + $self->scroll_dimension];
}

=head2 header_rect

Returns the L<Tickit::Rect> representing the header area.

=cut

sub header_rect {
	my $self = shift;
	$self->{header_rect} ||= Tickit::Rect->new(
		top => 0, lines => 1, left => 0, cols => $self->window->cols
	);
}

=head2 body_rect

Returns the L<Tickit::Rect> representing the body area.

=cut

sub body_rect {
	my $self = shift;
	$self->{body_rect} ||= Tickit::Rect->new(
		top => 1, lines => $self->window->lines - 1, left => 0, cols => $self->window->cols - 1
	);
}

=head2 scrollbar_rect

Returns the L<Tickit::Rect> representing the scroll bar.

=cut

sub scrollbar_rect {
	my $self = shift;
	$self->{scrollbar_rect} ||= Tickit::Rect->new(
		top => 1, lines => $self->window->lines - 1, left => $self->window->cols - 1, cols => 1,
	);
}

=head2 render_header

Render the header area.

=cut

sub render_header {
	my ($self, $rb) = @_;
	$rb->goto(0, 0);
	for (@{$self->{column_layout}}) {
		if(($_->{type} // '') eq 'padding') {
			$rb->text(' ' x $_->{value}, $self->get_style_pen('padding'));
		} else {
			$_->{style} = $self->get_style_pen('header');
			local $_->{text} = $_->{label} // '';
			$self->render_cell($rb, $_);
		}
	}
	$rb->text(' ', $self->get_style_pen('header')) if $self->vscroll;
}

=head2 render_to_rb

Render the table.

=cut

sub render_to_rb {
	my ($self, $rb, $rect) = @_;
	my $win = $self->window;
	$self->{highlight_row} ||= 0;

	$self->render_header($rb, $rect) if $rect->intersects($self->header_rect);
	$self->render_body($rb, $rect) if $rect->intersects($self->body_rect);
	$self->render_scrollbar($rb, $rect) if $rect->intersects($self->scrollbar_rect);
	my $highlight_pos = 1 + $self->highlight_visible_row;
	$win->cursor_at($highlight_pos, 0);
}

=head2 render_body

Render the body area.

=cut

sub render_body {
	my ($self, $rb, $rect) = @_;
	return $self unless my $win = $self->window;
	my $highlight_pos = 1 + $self->highlight_visible_row;
	my @visible = (undef, $self->visible_lines);
	LINE:
	for my $y ($rect->linerange) {
		next LINE unless $y;
		next LINE if $y >= @visible;
		unless($visible[$y]) {
			$rb->goto($y, $rect->left);
			$rb->text(' ' x $rect->cols, $self->get_style_pen('padding'));
			next LINE;
		}
		$rb->goto($y, 0);
		my @col_text = @{$visible[$y]};
		CELL:
		for (@{$self->{column_layout}}) {
			if($_->{type} eq 'widget') {
				$rb->skip($_->{value});
				my $w = $_->{attached_widget}[$y];
				$w->set_style_tag('highlight' => ($y == $highlight_pos) ? 1 : 0);
				(shift @col_text)->($w);
				next CELL;
			}

			if($_->{type} eq 'padding') {
				$rb->text(' ' x $_->{value}, $self->get_style_pen('padding'));
			} else {
				$_->{style} = $self->get_style_pen(
					($y == $highlight_pos)
					? 'highlight'
					: ($self->multi_select && $self->{selected}{$y + $self->row_offset - 1})
					? 'selected'
					: undef
				);
				local $_->{text} = shift @col_text;
				$self->render_cell($rb, $_);
			}
		}
	}
}

=head2 apply_column_widget

Add widgets for the column.

=cut

sub apply_column_widget {
	my $self = shift;
	return $self unless my $win = $self->window;
	for my $y (1..$win->lines-1) {
		CELL:
		for (@{$self->{column_layout}}) {
			next CELL unless $_->{type} eq 'widget';

			my $sub = $win->make_sub($y, $_->{start}, 1, $_->{value});
			$_->{attached_widget}[$y] = $_->{factory}->($sub);
		}
	}
	$self;
}

=head2 render_scrollbar

Render the scrollbar.

=cut

sub render_scrollbar {
	my ($self, $rb) = @_;
	my $win = $self->window;
	my $cols = $win->cols;
	--$cols if $self->vscroll;

	my $h = $win->lines - 1;
	if(my ($min, $max) = map 1 + $_, $self->scroll_rows) {
		# Scrollbar should be shown, since we don't have all rows visible on the screen at once
		$rb->vline_at(1, $min - 1, $cols, LINE_SINGLE, $self->get_style_pen('scrollbar'), CAP_BOTH) if $min > 1;
		$rb->vline_at($min, $max, $cols, LINE_DOUBLE, $self->get_style_pen('scroll'), CAP_BOTH);
		$rb->vline_at($max + 1, $h, $cols, LINE_SINGLE, $self->get_style_pen('scrollbar'), CAP_BOTH) if $max < $h;
	} else {
		# Placeholder scrollbar - just render it as empty
		$rb->vline_at(1, $h, $cols, LINE_SINGLE, $self->get_style_pen('scrollbar'), CAP_BOTH);
	}
}

=head2 render_cell

Render a given cell.

=cut

sub render_cell {
	my $self = shift;
	my $rb = shift;
	my $args = shift;

	# Trim first
	my $txt = textwidth($args->{text}) > $args->{value}
	   ? substrwidth $args->{text}, 0, $args->{value}
	   : $args->{text};

	my ($pre, undef, $post) = align textwidth($txt), $args->{value}, $args->{align};
	$rb->text(' ' x $pre, $args->{style}) if $pre;
	$rb->text($txt, $args->{style});
	$rb->text(' ' x $post, $args->{style}) if $post;
	return $self;
}

=head2 reshape

Handle reshape requests.

=cut

sub reshape {
	my $self = shift;
	delete @{$self}{qw(body_rect header_rect scrollbar_rect)};
	$self->SUPER::reshape(@_);
	$self->distribute_columns;
	$self->apply_column_widget;
}

=head2 distribute_columns

Distribute space between columns.

=cut

sub distribute_columns {
	my $self = shift;
	my $pad = $self->get_style_values('cell_padding');
	my @spacing = @{$self->{columns}};
	(undef, @spacing) = map {;
		+{
			base => $pad,
			expand => 0,
			type => 'padding'
		},
		$_
	} @spacing if $pad;
	my $cols = $self->window->cols;
	--$cols if $self->vscroll;
	distribute $cols, @spacing;
	if($self->{column_layout}) {
		CELL:
		for my $cell (@{$self->{column_layout}}) {
			next CELL unless $cell->{type} eq 'widget';
			$_->set_window(undef) for grep defined, @{$cell->{attached_widget}};
		}
	}
	$self->{column_layout} = \@spacing;
	$self
}

=head2 window_gained

Called when a window has been assigned to the widget.

=cut

sub window_gained {
	my $self = shift;
	$self->SUPER::window_gained(@_);
	my $win = $self->window;
	$win->set_expose_after_scroll(1) if $win->can('set_expose_after_scroll');
# reshape will do this already
#	$self->distribute_columns;
#	$self->apply_column_widget;
}

=head2 expose_rows

Expose the given rows.

=cut

sub expose_rows {
	my $self = shift;
	return $self unless my $win = $self->window;
	my $cols = $win->cols;
	map Tickit::Rect->new(
		top => $_,
		left => 0,
		lines => 2,
		cols => $cols
	), @_;
}

=head2 highlight_row

Returns the index of the currently-highlighted row.

=cut

sub highlight_row {
	my $self = shift;
	return $self->{highlight_row};
}

=head2 highlight_visible_row

Returns the position of the highlighted row taking scrollbar into account.

=cut

sub highlight_visible_row {
	my $self = shift;
	return $self->{highlight_row} - $self->row_offset;
}

=head2 scroll_highlight

Update scroll information after changing highlight position.

=cut

sub scroll_highlight {
	my $self = shift;
	my $up = shift;
	return $self unless my $win = $self->window;

	return $self unless my $scrollbar_rect = $self->active_scrollbar_rect;
	my $old = $self->highlight_visible_row;
	my $redraw_rect = Tickit::RectSet->new;
	$redraw_rect->add($scrollbar_rect);
	if($up) {
		--$self->{highlight_row};
		--$self->{row_offset};
	} else {
		++$self->{highlight_row};
		++$self->{row_offset};
	}

	my $direction = $up ? -1 : 1;
	$redraw_rect->add($scrollbar_rect->translate($direction, 0));
	$redraw_rect->add($_) for $self->expose_rows($old, $self->highlight_visible_row);

	# FIXME We're assuming the header is 1 row in height here (and elsewhere),
	# this seems like an arbitrary restriction.
	$win->scrollrect(1, 0, $win->lines - 1, $win->cols, $direction, 0);
	$win->expose($_) for map $_->translate(-$direction, 0), $redraw_rect->rects;
}

=head2 move_highlight

Change the highlighted row.

=cut

sub move_highlight {
	my $self = shift;
	my $up = shift;
	return $self unless my $win = $self->window;
	my $old = $self->highlight_visible_row;
	if($up) {
		--$self->{highlight_row};
	} else {
		++$self->{highlight_row};
	}
	$win->expose($_) for $self->expose_rows($old, $self->highlight_visible_row);
	$self
}

=head2 key_previous_row

Go to the previous row.

=cut

sub key_previous_row {
	my $self = shift;
	return $self unless my $win = $self->window;
	return $self if $self->{highlight_row} <= 0;

	return $self->move_highlight(1) if $self->highlight_visible_row >= 1;
	return $self->scroll_highlight(1);
}

=head2 key_next_row

Move to the next row.

=cut

sub key_next_row {
	my $self = shift;
	return $self unless my $win = $self->window;
	return $self if $self->{highlight_row} >= $self->row_count - 1;

	return $self->move_highlight(0) if $self->highlight_visible_row < $win->lines - 2;
	return $self->scroll_highlight(0);
}

=head2 key_first_row

Move to the first row.

=cut

sub key_first_row {
	my $self = shift;
	$self->{highlight_row} = 0;
	$self->{row_offset} = 0;
	$self->redraw;
}

=head2 key_last_row

Move to the last row.

=cut

sub key_last_row {
	my $self = shift;
	$self->{highlight_row} = $self->row_count - 1;
	$self->{row_offset} = $self->row_count > $self->scroll_dimension ? -1 + $self->row_count - $self->scroll_dimension : 0;
	$self->redraw;
}

=head2 key_previous_page

Go up a page.

=cut

sub key_previous_page {
	my $self = shift;
	$self->{highlight_row} -= $self->scroll_dimension;
	$self->{row_offset} -= $self->scroll_dimension;
	$self->{highlight_row} = 0 if $self->{highlight_row} < 0;
	$self->{row_offset} = 0 if $self->{row_offset} < 0;
	$self->redraw;
}

=head2 key_next_page

Go down a page.

=cut

sub key_next_page {
	my $self = shift;
	$self->{highlight_row} += $self->scroll_dimension;
	$self->{row_offset} += $self->scroll_dimension;
	$self->{highlight_row} = $self->row_count - 1 if $self->{highlight_row} > $self->row_count - 1;
	my $max = $self->row_count > $self->scroll_dimension ? -1 + $self->row_count - $self->scroll_dimension : 0;
	$self->{row_offset} = $max if $self->{row_offset} > $max;
	$self->redraw;
}

=head2 scroll_position

Current vertical scrollbar position.

=cut

sub scroll_position { shift->{row_offset} }

=head2 row_count

Total number of rows.

=cut

sub row_count { scalar @{shift->{data}} }

=head2 sb_height

Current scrollbar height.

=cut

sub sb_height {
	my $self = shift;
	my $ext = $self->scroll_dimension;
	my $max = $self->row_count - $ext;
	return 1 unless $max;
	return floor(0.5 + ($ext * $ext / $max));
}

=head2 scroll_rows

Positions of the scrollbar indicator.

=cut

sub scroll_rows {
	my $self = shift;
	my $cur = $self->scroll_position;
	my $ext = $self->scroll_dimension;
	my $max = $self->row_count - $ext;
	return unless $max;
	my $y = floor(0.5 + ($cur * ($ext - $self->sb_height) / $max));
	return $y, $y + $self->sb_height;
}

=head2 active_scrollbar_rect

Rectangle representing the area covered by the current scrollbar.

=cut

sub active_scrollbar_rect {
	my $self = shift;
	return unless my ($start, $end) = $self->scroll_rows;
	Tickit::Rect->new(
		top => 1 + $start,
		bottom => 2 + $end,
		left => $self->window->cols - 1,
		cols => 1,
	);
}

=head2 scroll_dimension

Size of the vertical scrollbar.

=cut

sub scroll_dimension {
	my $self = shift;
	return 1 unless my $win = $self->window;
	$win->lines - 2;
}

=head2 key_next_column

Move to the next column.

=cut

sub key_next_column { }

=head2 key_previous_column

Move to the previous column.

=cut

sub key_previous_column { }

=head2 key_first_column

Move to the first column.

=cut

sub key_first_column { }

=head2 key_last_column

Move to the last column.

=cut

sub key_last_column { }

=head2 key_activate

Activate the highlighted item.

=cut

sub key_activate {
	my $self = shift;
	if(my $code = $self->{on_activate}) {
		my $idx = $self->highlight_row;
		if($self->multi_select) {
			my @selected = sort { $a <=> $b } grep $self->{selected}{$_}, keys %{$self->{selected}};
			$code->(
				[ $idx, @selected ],
				$self->{data}[$idx],
				@{$self->{data}}[@selected]
			);
		} else {
			$code->(
				$idx,
				$self->{data}[$idx],
			);
		}
	}
	$self
}

=head2 key_select_toggle

Toggle selected row.

=cut

sub key_select_toggle {
	my $self = shift;
	return $self unless $self->multi_select;
	$self->{selected}{$self->highlight_row} = $self->{selected}{$self->highlight_row} ? 0 : 1;
	$self
}

1;

__END__

=head1 TODO

Current list of pending features:

=over 4

=item * Storage abstraction - the main difference between this widget and
L<Tickit::Widget::Table> is that this is designed to work with a storage
abstraction. The current abstraction implementation needs more work before
it's reliable enough for release, so this version only has basic arrayref
support.

=item * Column and cell highlighting modes

=item * Proper widget-in-cell support

=item * Formatters for converting raw cell data into printable format
(without having to go through a separate widget)

=item * Better header support (more than one row, embedded widgets)

=back

=head1 SEE ALSO

=over 4

=item * L<Tickit::Widget::Table> - older table implementation based on L<Tickit::Widget::HBox> and L<Tickit::Widget::VBox>
widgets. Does not support scrolling and performance isn't as good, so it will eventually be merged with this one.

=item * L<Text::ANSITable> - not part of L<Tickit> but has some impressive styling capabilities.

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2013. Licensed under the same terms as Perl itself.
