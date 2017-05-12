package Text::UnicodeBox;

=encoding utf-8

=head1 NAME

Text::UnicodeBox - Text box drawing using the Unicode box symbols

=head1 SYNOPSIS

  use Text::UnicodeBox;
  use Text::UnicodeBox::Control qw(:all);
  
  my $box = Text::UnicodeBox->new();
  $box->add_line(
    BOX_START( style => 'double', top => 'double', bottom => 'double' ), '   ', BOX_END(),
    '    ',
    BOX_START( style => 'heavy', top => 'heavy', bottom => 'heavy' ), '   ', BOX_END()
  );
  print $box->render();

  # Renders:
  # ╔═══╗    ┏━━━┓
  # ║   ║    ┃   ┃
  # ╚═══╝    ┗━━━┛

=head1 DESCRIPTION

Text::UnicodeBox is a low level box drawing interface.  You'll most likely want to use one of the higher level modules such as L<Text::UnicodeBox::Table>.

The unicode box symbol table (L<http://en.wikipedia.org/wiki/Box-drawing_character>) is a fairly robust set of symbols that allow you to draw lines and boxes with monospaced fonts.  This module allows you to focus on the content of the boxes you need to draw and mostly ignore how to draw a good looking box with proper connections between all the lines.

The low level approach is line-based.  A box object is created, C<add_line> is called for each line of content you'd like to render, and C<render> is called to complete the box.

Output is built up over time, which allows you to stream the output rather then buffering it and printing it in one go.

=cut

use Moose;

use Text::UnicodeBox::Control qw(:all);
use Text::UnicodeBox::Text qw(:all);
use Text::UnicodeBox::Utility qw(normalize_box_character_parameters);
use Scalar::Util qw(blessed);

has 'buffer_ref' => ( is => 'rw', default => sub { my $buffer = '';  return \$buffer } );
has 'last_line'  => ( is => 'rw' );
has 'whitespace_character' => ( is => 'ro', default => ' ' );
has 'fetch_box_character' => ( is => 'rw' );

our $VERSION = 0.03;

=head1 METHODS

=head2 new (%params)

Create a new instance.  Provide arguments as a list.  Valid arguments are:

=over 4

=item whitespace_character (default: ' ')

When the box renderer needs to pad the output of the interstitial lines of output, this character will be used.  Defaults to a simple space.

=item fetch_box_character

Provide a subroutine which will be used instead of the L<Text::UnicodeBox::Utility/fetch_box_character>.  This allows the user granular control over what symbols will be used for box drawing.  The subroutine will be called with a hash with any or all of the following keys: 'left', 'right', up', 'down', 'vertical' or 'horizontal'.  The value of each will be either '1' (default style), 'light', 'heavy', 'single' or 'double'.

Return a single width character or return undefined and a '?' will be used for rendering.

=back

=head2 buffer

Return the current buffer of rendered text.

=cut

sub buffer {
	my $self = shift;
	return ${ $self->buffer_ref };
}

=head2 add_line (@parts)

Pass a list of parts for a rendered line of output.  You may pass either a string, a L<Text::UnicodeBox::Control> or a L<Text::UnicodeBox::Text> object.  Strings will be transformed into the latter.  The line will be rendered to the buffer.

=cut

sub add_line {
	my $self = shift;
	my @parts;

	# Read off each arg, validate, then push onto @parts as objects
	foreach my $part (@_) {
		if (ref $part && blessed $part && ($part->isa('Text::UnicodeBox::Control') || $part->isa('Text::UnicodeBox::Text'))) {
			push @parts, $part;
		}
		elsif (ref $part) {
			die "add_line() takes only strings or Text::UnicodeBox:: objects as arguments";
		}
		else {
			push @parts, BOX_STRING($part);
		}
	}

	my %current_line = (
		parts => \@parts,
		parts_at_position => {},
	);

	# Generate this line as text
	my $line = '';
	{
		my $position = 0;
		my %context;
		foreach my $part (@parts) {
			$current_line{parts_at_position}{$position} = $part;
			$line .= $part->to_string(\%context, $self);
			$position += $part->can('length') ? $part->length : 1;
		}
		$line .= "\n";
		$current_line{final_position} = $position;
	}

	## Generate the top of the box if needed

	my $box_border_line;
	if (grep { $_->can('top') && $_->top } @parts) {
		$box_border_line = $self->_generate_box_border_line(\%current_line);
	}
	elsif ($self->last_line && grep { $_->can('bottom') && $_->bottom } @{ $self->last_line->{parts} }) {
		$box_border_line = $self->_generate_box_border_line(\%current_line);
	}

	# Store this for later reference
	$self->last_line(\%current_line);

	# Add lines to the buffer ref
	my $buffer_ref = $self->buffer_ref;
	$$buffer_ref .= $box_border_line if defined $box_border_line;
	$$buffer_ref .= $line;
}

=head2 render

Complete the rendering of the box, drawing any final lines needed to close up the drawing.

Returns the buffer

=cut

sub render {
	my $self = shift;

	my @box_bottoms = grep { $_->can('bottom') && $_->bottom } @{ $self->last_line->{parts} };
	if (@box_bottoms) {
		my $box_border_line = $self->_generate_box_border_line();
		my $buffer_ref = $self->buffer_ref;
		$$buffer_ref .= $box_border_line;
	}

	return $self->buffer();
}

sub _find_part_at_position {
	my ($line_details, $position) = @_;
	return if $position >= $line_details->{final_position};
	while ($position >= 0) {
		if (my $return = $line_details->{parts_at_position}{$position}) {
			return $return;
		}
		$position--;
	}
	return;
}

sub _generate_box_border_line {
	my ($self, $current_line) = @_;
	my ($below_box_style, $above_box_style);

	# Find the largest final_position value
	my $final_position = $current_line ? $current_line->{final_position} : 0;
	$final_position = $self->last_line->{final_position}
		if $self->last_line && $self->last_line->{final_position} > $final_position;

	my $line = '';
	foreach my $position (0..$final_position - 1) {
		my ($above_part, $below_part);
		$above_part = _find_part_at_position($self->last_line, $position) if $self->last_line;
		$below_part = _find_part_at_position($current_line, $position) if $current_line;

		my %symbol;
		# First, let the above part specify styling
		if ($above_part && $above_part->isa('Text::UnicodeBox::Control')) {
			$symbol{up} = $above_part->style || 'light';
			if ($above_part->position eq 'start' && $above_part->bottom) {
				$above_box_style = $above_part->bottom;
				$symbol{right} = $above_box_style;
			}
			elsif ($above_part->position eq 'end') {
				$symbol{left} = $above_box_style;
				$above_box_style = undef;
			}
			elsif ($above_part->position eq 'rule') {
				$symbol{left} = $symbol{right} = $above_box_style;
			}
		}
		elsif ($above_part && $above_part->isa('Text::UnicodeBox::Text') && $above_box_style) {
			$symbol{left} = $symbol{right} = $above_box_style;
		}

		# Next, let the below part override
		if ($below_part && $below_part->isa('Text::UnicodeBox::Control')) {
			$symbol{down} = $below_part->style || 'light';
			if ($below_part->position eq 'start' && $below_part->top) {
				$below_box_style = $below_part->top;
				$symbol{right} = $below_box_style if $below_box_style;
			}
			elsif ($below_part->position eq 'end') {
				$symbol{left} = $below_box_style if $below_box_style;
				$below_box_style = undef;
			}
			elsif ($below_part->position eq 'rule') {
				$symbol{left} = $symbol{right} = $below_box_style if $below_box_style;
			}
		}
		elsif ($below_part && $below_part->isa('Text::UnicodeBox::Text') && $below_box_style) {
			$symbol{left} = $symbol{right} = $below_box_style;
		}
		if (! keys %symbol) {
			$symbol{horizontal} = $below_box_style ? $below_box_style : $above_box_style ? $above_box_style : undef;
			delete $symbol{horizontal} unless defined $symbol{horizontal};
		}

		# Find the character and add it to the line
		my $char;
		if (! keys %symbol) {
			$char = $self->whitespace_character();
		}
		else {
			$char = $self->_fetch_box_character(%symbol);
		}
		$char = '?' unless defined $char;
		$line .= $char;
	}

	$line .= "\n";

	return $line;
}

sub _fetch_box_character {
	my ($self, %symbol) = @_;
	my $cache_key = join ';', map { "$_=$symbol{$_}" } sort keys %symbol;
	if (exists $self->{_fetch_box_character_cache}{$cache_key}) {
		return $self->{_fetch_box_character_cache}{$cache_key};
	}
	my $char;
	if ($self->fetch_box_character) {
		$char = $self->fetch_box_character->(
			normalize_box_character_parameters(%symbol)
		);
	}
	else {
		$char = Text::UnicodeBox::Utility::fetch_box_character(%symbol);
	}
	$self->{_fetch_box_character_cache}{$cache_key} = $char;
	return $char;
}

=head1 DEVELOPMENT

This module is being developed via a git repository publicly avaiable at http://github.com/ewaters/Text-UnicodeBox.  I encourage anyone who is interested to fork my code and contribute bug fixes or new features, or just have fun and be creative.

=head1 COPYRIGHT

Copyright (c) 2012 Eric Waters and Shutterstock Images (http://shutterstock.com).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
