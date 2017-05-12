package Text::UnicodeBox::Table;

=encoding utf-8

=head1 NAME

Text::UnicodeBox::Table - High level interface providing easy table drawing

=head1 SYNOPSIS

  my $table = Text::UnicodeBox::Table->new();

  $table->add_header('id', 'name');
  $table->add_row('1', 'George Washington');
  $table->add_row('2', 'Thomas Jefferson');
  print $table->render();

  # Prints:
  # ┌────┬───────────────────┐
  # │ id │ name              │
  # ├────┼───────────────────┤
  # │  1 │ George Washington │
  # │  2 │ Thomas Jefferson  │
  # └────┴───────────────────┘

=head1 DESCRIPTION

This module provides an easy high level interface over L<Text::UnicodeBox>.

=cut

use Moose;
use Text::UnicodeBox::Text qw(:all);
use Text::UnicodeBox::Control qw(:all);
use List::Util qw(sum max);
extends 'Text::UnicodeBox';

has 'lines'             => ( is => 'rw', default => sub { [] } );
has 'max_column_widths' => ( is => 'rw', default => sub { [] } );
has 'style'             => ( is => 'rw', default => 'light' );
has 'is_rendered'       => ( is => 'rw' );
has 'split_lines'       => ( is => 'rw' );
has 'max_width'         => ( is => 'rw' );
has 'column_widths'     => ( is => 'rw' );
has 'break_words'       => ( is => 'rw' );

=head1 METHODS

=head2 new

Pass any arguments you would to L<Text::UnicodeBox/new> but with the following additions.

=over 4

=item split_lines

If set, line breaks in cell data will result in new rows rather then breaks in the rendering.

=item max_width

If set, the width of the table will ever exceed the given width.  Data will be attempted to fit with wrapping at word boundaries.

=item break_words

If set, wrapping may break words

=item column_widths

  column_widths => [ undef, 40, 60 ],
  # First column may be any width but the second and third have specified widths

Specify the exact width of each column, sans padding and box formatting.

=item style

  my $table = Text::UnicodeBox::Table->new( style => 'horizontal_double ');

You may specify a certain style for the table to be drawn.  This may be overridden on a per row basis.

=over 4

=item light

All lines are light.

=item heavy

All lines are heavy.

=item double

All lines are double.

=item horizontal_double

All horizontal lines are double, where vertical lines are single.

=item heavy_header

The lines drawing the header are heavy, all others are light.

=back

=back

=head2 add_header ( [\%opt,] @parts )

  $table->add_header({ bottom => 'heavy' }, 'Name', 'Age', 'Address');

Same as C<add_row> but sets the option ('header' => 1)

Draws one line of output with a border on the top and bottom.

=head2 add_row ( [\%opt,] @parts )

If the first argument to this method is a hashref, it is interpreted as an options hash.   This hash takes the following parameters:

=over 4

=item style (default: 'light')

What style will be used for all box characters involved in this line of output.  Options are: 'light', 'double', 'heavy'

=item alignment

  alignment => [ 'right', 'left', 'right' ]
 
Pass a list of 'right' and 'left', corresponding with the number of columns of output.  This will control the alignment of this row, and if passed to C<add_header>, all following rows as well.  By default, values looking like a number are aligned to the right, with all other values aligned to the left.

=item header_alignment

The header will always be aligned to the left unless you pass this array ref to specify custom alignment.

=item top

=item bottom

If set, draw a line above or below the current line.

=item header

Same as passing C<top> and C<bottom> to the given style (or the default style C<style>)

=back

=cut

sub add_header {
	my $self = shift;
	my %opt = ref $_[0] ? %{ shift @_ } : ();
	$opt{header} = 1;

	# Support special table-wide styles
	if ($self->style) {
		if ($self->style eq 'horizontal_double') {
			$opt{bottom} = $opt{top} = 'double';
		}
		elsif ($self->style eq 'heavy_header') {
			$opt{bottom} = $opt{top} = $opt{style} = 'heavy';
		}
		else {
			$opt{style} ||= $self->style;
		}
	}

	$self->_push_line(\%opt, @_);
}

sub add_row {
	my $self = shift;
	my %opt = ref $_[0] ? %{ shift @_ } : ();

	# Support special table-wide styles
	if ($self->style && $self->style =~ m{^(heavy|double|light)$}) {
		$opt{style} = $self->style;
	}

	$self->_push_line(\%opt, @_);
}

around 'render' => sub {
	my $orig = shift;
	my $self = shift;

	if ($self->is_rendered) {
		return $self->buffer;
	}

	my @alignment;

	my $lines             = $self->lines;
	my $max_column_widths = $self->max_column_widths;

	if ($self->_is_width_constrained || $self->split_lines) {
		if ($self->max_width && ! $self->column_widths) {
			$self->_determine_column_widths();
		}
		($lines, $max_column_widths) = $self->_fit_lines_to_widths($lines);
	}

	my $last_line_index = $#{ $lines };
	foreach my $i (0..$last_line_index) {
		my ($opts, $columns) = @{ $lines->[$i] };
		my %start = (
			style => $opts->{style} || 'light',
		);
		if ($opts->{header} || $i == 0 || $opts->{top}) {
			$start{top} = $opts->{top} || $start{style};
		}
		if ($opts->{header} || $i == $last_line_index || $opts->{bottom}) {
			$start{bottom} = $opts->{bottom} || $start{style};
		}

		# Support special table-wide styles
		if ($self->style) {
			if ($self->style eq 'horizontal_double' && $i == $last_line_index) {
				$start{bottom} = 'double';
			}
		}

		if ($opts->{alignment}) {
			@alignment = @{ $opts->{alignment} };
		}

		my @parts = ( BOX_START(%start) );
		foreach my $j (0..$#{$columns}) {
			my $align = $opts->{header_alignment} ? $opts->{header_alignment}[$j]
					  : $opts->{header}           ? 'left'
					  : $alignment[$j] || undef;

			push @parts, $columns->[$j]->align_and_pad(
				width => $max_column_widths->[$j],
				align => $align,
			);

			if ($j != $#{$columns}) {
				push @parts, BOX_RULE;
			}
			elsif ($j == $#{$columns}) {
				push @parts, BOX_END;
			}
		}
		$self->add_line(@parts);
	}

	$self->is_rendered(1);
	$self->$orig();
};

sub _push_line {
	my ($self, $opt, @columns) = @_;

	# Allow undef to be passed in columns; map it to ''
	$columns[$_] = '' foreach grep { ! defined $columns[$_] } 0..$#columns;

	my $do_split_lines = defined $opt->{split_lines} ? $opt->{split_lines} : $self->split_lines;

	# Convert each column into a ::Text object so that I can figure out the length as
	# well as record max column widths
	my @strings;
	foreach my $i (0..$#columns) {
		my $string = BOX_STRING($columns[$i]);
		my $string_length = $string->length;
		push @strings, $string;

		if ($do_split_lines && $columns[$i] =~ m/\n/) {
			# Asking for the longest_line_length will automatically split the string on newlines
			$string_length = $string->longest_line_length;
		}

		# Update record of max column widths
		$self->max_column_widths->[$i] = max($string_length, $self->max_column_widths->[$i] || 0);
	}

	push @{ $self->lines }, [ $opt, \@strings ];
}

sub _is_width_constrained {
	my $self = shift;
	return $self->max_width || $self->column_widths;
}

## _determine_column_widths
#
# Pass no args, return nothing.  Figure out what the column widths should be where the caller has specified a custom max_width value that they'd like the whole table to be constrained to.

sub _determine_column_widths {
	my $self = shift;
	return if $self->column_widths;
	return if ! $self->max_width;

	# Max width represents the max width of the rendered table, with padding and box characters
	# Let's figure out how many characters will be used for rendering and padding
	my $column_count = int @{ $self->max_column_widths };
	my $padding_width = 1;
	my $rendering_characters_width =
		($column_count * ($padding_width * 2)) # space on left and right of each cell text
		+ $column_count + 1;                   # bars on right of each column + one on left in beginning

	# Prepare a checker for determining success
	my $widths_over = sub {
		my @column_widths = @_;
		return (sum (@column_widths) + $rendering_characters_width) - $self->max_width;
	};
	my $widths_fit = sub {
		my @column_widths = @_;
		if ($widths_over->(@column_widths) <= 0) {
			$self->column_widths( \@column_widths );
			return 1;
		}
		return 0;
	};

	# Escape early if the max column widths already fit the constraint
	return if $widths_fit->(@{ $self->max_column_widths });

	# FIXME
	if ($self->break_words) {
		warn "Passing max_width and break_words without column_widths is not yet implemented\n";
	}

	# Figure out longest word lengths
	my @longest_word_lengths;
	foreach my $line (@{ $self->lines }) {
		foreach my $column_index (0..$#{ $line->[1] }) {
			my $length = $line->[1][$column_index]->longest_word_length;
			$longest_word_lengths[$column_index] = max($length, $longest_word_lengths[$column_index] || 0);
		}
	}

	# Sanity check about if it's even possible to proceed
	if ($widths_over->(@longest_word_lengths) > 0) {
		die "It's not possible to fit the table in width ".$self->max_width." without break_words => 1\n";
	}

	# Reduce the amout of wrapping as much as possible.  Try and fit in the max_width with breaking the
	# fewest possible columns.

	my @column_widths = @{ $self->max_column_widths };
	my @column_index_by_width = sort { $column_widths[$b] <=> $column_widths[$a] } 0..$#column_widths;

	while (! $widths_fit->(@column_widths)) {
		# Select the next widest column and try shortening it
		my $column_index = shift @column_index_by_width;
		if (! defined $column_index) {
			die "Shortened all the columns and found no way to fit";
		}

		my $overage = $widths_over->(@column_widths);
		my $new_width = $column_widths[$column_index] - $overage;
		if ($new_width < $longest_word_lengths[$column_index]) {
			$new_width = $longest_word_lengths[$column_index];
		}
		$column_widths[$column_index] = $new_width;
	}

	return;
}

## _fit_lines_to_widths (\@lines, \@column_widths)
#
#  Pass an array ref of lines (most likely from $self->lines).  Return an array ref of lines wrapped to the $self->column_widths values, and an array ref of the new max column widths.

sub _fit_lines_to_widths {
	my ($self, $lines, @column_widths) = @_;

	@column_widths = @{ $self->column_widths } if ! @column_widths && $self->column_widths;
	@column_widths = @{ $self->max_column_widths } if ! @column_widths;
	if (! @column_widths) {
		die "Can't call _fit_lines_to_widths() without column_widths set or passed";
	}
	my @max_column_widths;

	my @new_lines;
	foreach my $line (@$lines) {
		my ($opts, $strings) = @$line;
		my @new_line;
		foreach my $column_index (0..$#column_widths) {
			my $string = $strings->[$column_index];
			my $width  = $column_widths[$column_index];

			# As long as this string doesn't span multiple lines, and
			# if no width constraint or if this string already fits, store and move on
			if ($string->line_count == 1 && (! $width || $string->length <= $width)) {
				$new_line[0][$column_index] = $string;
				next;
			}

			my ($store_buffer, $add_string_to_buffer);
			{
				my $row_index = 0;
				my $length = 0;
				my $buffer = '';
				$store_buffer = sub {
					return unless $length;
					$new_line[$row_index++][$column_index] = BOX_STRING($buffer);
					$length = 0;
					$buffer = '';
				};
				$add_string_to_buffer = sub {
					my ($word_value, $word_length) = @_;
					if ($width && $length + $word_length > $width) {
						$store_buffer->();
					}
					$buffer .= $word_value;
					$length += $word_length;
				};
			}

			foreach my $line ($string->lines) {

				# If no width constraint or if this string already fits, store and move on
				if (! $width || $line->length <= $width) {
					$add_string_to_buffer->($line->value, $line->length);
					$store_buffer->();
					next;
				}

				foreach my $segment ($line->split( break_words => $self->break_words, max_width => $width )) {
					$add_string_to_buffer->($segment->value, $segment->length);
					$store_buffer->();
				}
				next;
			}
		}
		foreach my $row_index (0..$#new_line) {
			# Every cell needs to have a string object
			foreach my $column_index (0..$#column_widths) {
				$new_line[$row_index][$column_index] ||= BOX_STRING('');

				# Update max_column_widths
				my $width = $new_line[$row_index][$column_index]->length;
				$max_column_widths[$column_index] = $width
					if ! $max_column_widths[$column_index] || $max_column_widths[$column_index] < $width;
			}
			push @new_lines, [ $opts, $new_line[$row_index] ];
		}
	}

	return (\@new_lines, \@max_column_widths);
}

=head2 output_width

Returns the width of the table if it were rendered right now without additional rows added.

=cut

sub output_width {
	my $self = shift;

	my $width = 1; # first pipe char
	
	foreach my $column_width (@{ $self->max_column_widths }) {
		$width += $column_width + 3; # 2: padding, 1: trailing pipe char
	}

	if ($self->max_width && $width > $self->max_width) {
		return $self->max_width; # FIXME: is this realistic?  What about for very small values of max_width and large count of columns?
	}

	return $width;
}

=head1 COPYRIGHT

Copyright (c) 2012 Eric Waters and Shutterstock Images (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
