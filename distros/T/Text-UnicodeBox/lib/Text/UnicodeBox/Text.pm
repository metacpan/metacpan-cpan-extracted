package Text::UnicodeBox::Text;

=head1 NAME

Text::UnicodeBox::Text - Objects to describe text rendering

=head1 DESCRIPTION

This module is part of the low level interface to L<Text::UnicodeBox>; you probably don't need to use it directly.

=cut

use Moose;
use Text::UnicodeBox::Utility;
use Text::CharWidth qw(mbwidth mbswidth);
use Term::ANSIColor qw(colorstrip);
use Exporter 'import';
use List::Util qw(max);
use utf8;

=head1 METHODS

=head2 new (%params)

=over 4

=item value

The string representation of the text.

=item length

How many characters wide the text represents when rendered on the screen.

=back

=cut

has 'value'    => ( is => 'rw' );
has 'length'   => ( is => 'rw' );
has 'line_count' => ( is => 'rw', default => 1 );
has 'longest_word_length' => ( is => 'ro', lazy => 1, builder => '_build_longest_word_length' );
has '_lines'   => ( is => 'rw' );
has '_longest_line_length' => ( is => 'rw' );

our @EXPORT_OK = qw(BOX_STRING);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

=head1 EXPORTED METHODS

The following methods are exportable by name or by the tag ':all'

=head2 BOX_STRING ($value)

Given the passed text, figures out the a smart value for the C<length> field and returns a new instance.

=cut

sub BOX_STRING {
	my $string = shift;

	# Strip out any colors
	my $stripped_string = colorstrip($string);

	# Determine the width on a terminal of the string given; may be composed of unicode characters that take up two columns, or by ones taking up 0 columns
	my $length = mbswidth($stripped_string);

	return __PACKAGE__->new(value => $string, length => $length);
}

=head2 align_and_pad

  my $text = BOX_STRING('Test');
  $text->align_and_pad(8);
  # is the same as
  # $text->align_and_pad( width => 8, pad => 1, pad_char => ' ', align => 'left' );
  $text->value eq ' Test     ';

Modify the value of this object to pad and align the text according to the specification.  Pass any of the following parameters:

=over 4

=item width

Defaults to the object's C<length>.  Specifies how wide of a space the string is to be fit in.  Doesn't make sense for this value to smaller then the width of the string.  If you pass only one parameter to C<align_and_pad>, this is the parameter it's assigned to.

=item align

If the string looks like a number, the align default to 'right'; otherwise, 'left'.

=item pad (default: 1)

How much padding on the right and left

=item pad_char (default: ' ')

What character to use for padding

=back

=cut

sub align_and_pad {
	my $self = shift;
	my %opt;
	if (int @_ == 1) {
		$opt{width} = shift;
	}
	else {
		%opt = @_;
	}

	my $string = $self->value();
	my $length = $self->length();

	$opt{width} ||= $length;
	$opt{pad}   = 1 if ! defined $opt{pad};
	$opt{pad_char} ||= ' ';
	if (! $opt{align}) {
		# Align numbers to the right and text to the left
		my $is_a_number = $string =~ m{^([0-9]+|[0-9]*\.[0-9]+)$};
		$opt{align} = $is_a_number ? 'right' : 'left';
	}

	# Align
	while ($length < $opt{width}) {
		$string = $opt{align} eq 'right' ? $opt{pad_char} . $string : $string . $opt{pad_char};
		$length++;
	}
	
	# Pad
	$string = ($opt{pad_char} x $opt{pad}) . $string . ($opt{pad_char} x $opt{pad});
	$length += $opt{pad} * 2;

	$self->value($string);
	$self->length($length);

	return $self;
}

=head2 to_string

Returns the value of this object.

=cut

sub to_string {
	my $self = shift;
	return $self->value;
}

## _build_longest_word_length
#
#  In order to find ideal widths of a wrapped column without breaking words, it's necessary to know the longest word length in the string.

sub _build_longest_word_length {
	my $self = shift;

	my $longest_word = 0;
	foreach my $word (split / /, $self->value) {
		my $obj = BOX_STRING($word);
		$longest_word = max($obj->length, $longest_word);
	}
	
	return $longest_word;
}

=head2 lines

Return array of objects of this string split into new strings on the newline character

=cut

sub lines {
	my $self = shift;
	$self->_split_up_on_newline();
	if ($self->_lines) {
		return @{ $self->_lines };
	}
	else {
		return $self;
	}
}

=head2 line_count

Provides the count of C<lines()>

=head2 longest_line_length

Return the length of the longest line in C<lines()>

=cut

sub longest_line_length {
	my $self = shift;
	$self->_split_up_on_newline();
	return $self->_longest_line_length;
}

## _split_up_on_newline
#
#  Populate _lines, line_count and _longest_line_length

sub _split_up_on_newline {
	my $self = shift;

	# Don't repeat work
	return if defined $self->_longest_line_length;

	my (@lines, $longest_line);
	foreach my $line (split /\n/, $self->value) {
		my $obj = BOX_STRING($line);
		push @lines, $obj;
		$longest_line = max($obj->length, $longest_line || 0);
	}
	
	$self->_longest_line_length($longest_line || 0);
	$self->_lines(\@lines);
	$self->line_count(int @lines);
}

=head2 split (%args)

  my @segments = $obj->split( max_width => 100, break_words => 1 );

Return array of objects of this string split at the max width given.  If break_words => 1, break anywhere, otherwise only break on the space character.

=cut

sub split {
	my ($self, %args) = @_;
	my $class = ref $self;

	my @segments;
	my $value = $self->value;

	my $width = 0;
	my $buffer = '';
	my $color_state_tracker = _color_state_tracker();
	my $save_buffer = sub {
		my $esc = chr(27);
		$buffer .= $esc . '[0m' if $color_state_tracker->{is_colored}->();

		# If the string is split at a boundary between different color codes, you may get
		# a series of redundant reset statements
		$buffer =~ s/$esc\[\d+m $esc\[0m/$esc\[0m/gx;
		$buffer =~ s/^$esc\[0m//;

		push @segments, $class->new(value => $buffer, length => $width);
		$buffer = '';
		$width = 0;
		$buffer .= $color_state_tracker->{stringify_states}->();
	};

	my $add_char = sub {
		my ($char, $value_ref) = @_;
		my $ord = ord($char);

		# Check for a color escape sequence
		if ($ord == 27 && $$value_ref =~ m{^\[(\d+)m}) {
			my $color_state = $1 * 1;
			$$value_ref =~ s{^\[\d+m}{};
			$buffer .= $char . "[${color_state}m";

			$color_state_tracker->{add_state}->($color_state);
			return;
		}
		
		my $char_width = mbwidth($char);
		$save_buffer->() if $char_width + $width > $args{max_width};

		$buffer .= $char;
		$width += $char_width;
		$save_buffer->() if $width == $args{max_width};
	};

	my $character_by_character = $args{break_words} ? 1 : 0;

	while (length $value) {
		if ($character_by_character) {
			my $char = substr $value, 0, 1, '';
			$add_char->($char, \$value);
		}
		else {
			# Extract the next word, up to a space
			my $word;
			my $next_space_index = index $value, ' ';
			while ($next_space_index == 0) {
				# Value currently starts with a space; write each space out
				$add_char->( substr($value, 0, 1, ''), \$value );
				$next_space_index = index $value, ' ';
			}
			if ($next_space_index > 0) {
				$word = substr $value, 0, $next_space_index, '';
			}
			if (! $word) {
				$word = $value;
				$value = '';
			}
			# Wrap to the next line if the current line can't hold this word
			my $word_width = mbswidth($word);
			$save_buffer->() if $word_width + $width > $args{max_width};

			# Write out the word, character by character
			while (length $word) {
				my $char = substr $word, 0, 1, '';
				$add_char->($char, \$word);
			}
		}
	}
	$save_buffer->();

	return @segments;
}

## _color_state_tracker
#
#  Pass in a numerical ANSI color escape and it'll track what the cumulative state is over time

sub _color_state_tracker {
	my %color_state;
	my %set_order;
	my $set_count = 0;

	return {
		is_colored => sub {
			return keys %color_state ? 1 : 0;
		},
		add_state => sub {
			my $color_state = shift;
			my $type;
			# 0 is the reset code
			if ($color_state == 0) {
				%color_state = ();
				return;
			}
			elsif ($color_state == 1 || $color_state == 22) {
				$type = 'bold';
			}
			elsif ($color_state == 3 || $color_state == 23) {
				$type = 'italics';
			}
			elsif ($color_state == 4 || $color_state == 24) {
				$type = 'underline';
			}
			elsif ($color_state == 7 || $color_state == 27) {
				$type = 'inverse';
			}
			elsif ($color_state == 9 || $color_state == 29) {
				$type = 'strikethrough';
			}
			elsif ($color_state >= 30 || $color_state <= 39) {
				$type = 'foreground';
			}
			elsif ($color_state >= 40 || $color_state <= 49) {
				$type = 'background';
			}
			return unless $type;

			if ($color_state >= 20 && $color_state <= 29) {
				delete $color_state{$type};
				delete $set_order{$type};
			}
			else {
				$color_state{$type} = $color_state;
				$set_order{$type} = ++$set_count;
			}
		},
		stringify_states => sub {
			return join '', map { chr(27) . "[$color_state{$_}m" }
				sort { $set_order{$a} <=> $set_order{$b} }
				keys %color_state;
		},
	};
}

=head1 COPYRIGHT

Copyright (c) 2012 Eric Waters and Shutterstock Images (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
