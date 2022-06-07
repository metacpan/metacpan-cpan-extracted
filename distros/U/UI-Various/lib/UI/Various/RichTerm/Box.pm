package UI::Various::RichTerm::Box;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::RichTerm::Box - concrete implementation of L<UI::Various::Box>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Box;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Box> using
the rich terminal UI.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.24';

use UI::Various::core;
use UI::Various::Box;
use UI::Various::RichTerm::container;
use UI::Various::RichTerm::base qw(%D);

require Exporter;
our @ISA = qw(UI::Various::Box UI::Various::RichTerm::container);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<_prepare> - prepare UI element

    ($width, $height) = $ui_element->_prepare($content_width, $prefix_length);

=head3 example:

    my ($w, $h) = $_->_prepare($content_width, $pre_len);
    $width < $w  and  $width = $w;
    $height += $h;

=head3 parameters:

    $content_width      preferred width of content
    $prefix_length      the length of a prefix for active UI elements

=head3 description:

Prepare output of the UI element by determining and returning the space it
wants or needs.  I<The method should only be called from other
C<UI::Various::RichTerm> container elements!>

Note that C<$content_width> initially already includes one prefix length as
that's the standard needed by all other UI elements.

=head3 returns:

width and height the UI element will require or need when printed

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _prepare($$$)
{
    my ($self, $content_width, $prefix_length) = @_;
    my ($rows, $columns) = ($self->rows, $self->columns);
    local $_;

    # 1. reduce width if we have an explicit one;
    #    also include border, if applicable:
    $content_width = $self->{width} - $prefix_length
	if  defined  $self->{width}
	and  $content_width > $self->{width} - $prefix_length;
    $content_width -= 2  if  $self->border;

    # 2. determine active and/or marked (checkbox or radio button) columns
    #    (which need prefixes somewhere):
    my @active_column = (0) x $columns;
    my @marked_column = (0) x $columns;
    my $active_columns = 0;
    my $marked_width = 0;
    foreach my $column (0..($columns - 1))
    {
	foreach (0..($rows - 1))
	{
	    $_ = $self->field($_, $column);
	    if (defined $_)
	    {
		$active_column[$column] = 1  if  $_->can('_process');
		my $type = ref($_);
		my $mw = ($type =~ m/::(?:Check|Radio)$/ ? 4 :
			  0);
		$marked_column[$column] > $mw
		    or  $marked_column[$column] = $mw;
	    }
	}
	$active_columns++  if  $active_column[$column];
	$marked_width += $marked_column[$column];
    }
    $self->{_active} = \@active_column;	# keep list of active columns for _show
    $self->{_marked} = \@marked_column;	# keep list of marked columns for _show

    # 3. determine needed width of each column for even distribution of widths:
    my $text_width =
	$content_width
	- $prefix_length * ($active_columns - 1)
	- $marked_width
	- $columns + 1;		# borders between columns (visible or not)
    $text_width > $columns  or  $text_width = $columns;
    my $even_width = int($text_width / $columns);
    my @widths = ($even_width) x $columns;
    my $free_space = $text_width - $even_width * $columns;
    my $need_max = 0;
    foreach my $column (0..($columns - 1))
    {
	my ($width, $max_width) = ($even_width, 0);
	foreach my $row (0..($rows - 1))
	{
	    $_ = $self->field($row, $column);
	    defined $_  or  next;
	    my ($w, $h) = $_->_prepare($width, $prefix_length);
	    $max_width = $w  if  $max_width < $w;
	}
	if ($max_width < $even_width)
	{
	    $widths[$column] = $max_width;
	    $free_space += $even_width - $max_width;
	}
	else
	{   $need_max++;   }
    }

    # 4. if applicable additional free space gets added to those currently
    #    needing maximum width:
    if ($need_max < $columns)
    {
	# 4. (a) if no column uses even maximum grant widest one the space:
	if (0 == $need_max)
	{
	    my ($biggest, $big_width) = (0, 0);
	    foreach (reverse(0..($columns - 1)))
	    {
		if ($big_width < $widths[$_])
		{   $biggest = $_;   $big_width = $widths[$_];   }
	    }
	    $free_space -= ($even_width - $widths[$biggest]);
	    $widths[$biggest] = $even_width;
	    $need_max = 1;
	}
	# 4. (b) grant free space to one or more widest columns:
	$free_space = int($free_space / $need_max);
	foreach my $column (0..($columns - 1))
	{
	    next  unless  $widths[$column] == $even_width;
	    my ($width, $max_width) = ($even_width + $free_space, 0);
	    foreach my $row (0..($rows - 1))
	    {
		$_ = $self->field($row, $column);
		defined $_  or  next;
		my ($w, $h) = $_->_prepare($width, $prefix_length);
		$max_width = $w  if  $max_width < $w;
	    }
	    $widths[$column] = $max_width;
	}
    }
    $self->{_widths} = \@widths;	# keep computed widths for _show

    # 5. now the height of each row can be computed:
    my @heights = ();
    foreach my $row (0..($rows - 1))
    {
	my $max_height = 0;
	foreach my $column (0..($columns - 1))
	{
	    $_ = $self->field($row, $column);
	    defined $_  or  next;
	    my ($w, $h) = $_->_prepare($widths[$column], $prefix_length);
	    $max_height = $h  if  $max_height < $h;
	}
	push @heights, $max_height;
    }
    $self->{_heights} = \@heights;	# keep computed heights for _show

    # 6. compute the sum of each widths and heights (including prefixes and
    # borders):
    my ($w, $h) = (0, 0);
    --$columns;
    $w += $widths[$_] foreach (0..$columns);
    $w += $prefix_length * $active_columns;	# here we need the real count!
    $w += $marked_width;
    $w += $columns;
    $w += 2  if  $self->border;
    $h += $heights[$_] foreach (0..($rows - 1));
    $h += 2 + $rows - 1  if  $self->border;
    return ($w, $h);
}

#########################################################################

=head2 B<_show> - return formatted UI element

    $string = $ui_element->_show($prefix, $width, $height, $pre_active);

=head3 example:

    my ($w, $h) = $_->_prepare($content_width, $pre_len);
    ...
    $_->_show('    ', $w, $h, $pre_active);

=head3 parameters:

    $prefix             text in front of first line
    $width              the width returned by _prepare above
    $height             the height returned by _prepare above
    $pre_active         format string for prefixes

=head3 description:

Return the formatted (rectangular) text box of the UI element.  Its height
will be exactly as specified, unless there hasn't been enough space.  The
weight is similarly as specified (as the widths of all possible prefixes
already have been returned by C<L<_prepare|/_prepare - prepare UI
element>>).  I<The method should only be called from other
UI::Various::RichTerm container elements!>

=head3 returns:

the rectangular text box for UI element

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _show($$$$$)
{
    my ($self, $outer_prefix, $width, $height, $pre_active) = @_;
    my $blank = $pre_active eq '' ? '' : ' ' x length(sprintf($pre_active, 0));
    local $_;

    # 1. top border:
    my $text = '';
    if ($self->border)
    {
	$text .= $D{B7};
	foreach my $column (0..($self->columns - 1))
	{
	    $text .= $D{b8}  if  $column > 0;
	    $text .= $D{B8} x $self->{_widths}[$column];
	    $text .= $D{B8} x $self->{_marked}[$column];
	    $text .= $D{B8} x length($blank) if $self->{_active}[$column];
	}
	$text .= $D{B9} . "\n";
    }

    foreach my $row (0..($self->rows - 1))
    {
	# 2. intermediate border:
	if ($self->border  and  $row > 0)
	{
	    $text .= $D{b4};
	    foreach my $column (0..($self->columns - 1))
	    {
		$text .= $D{b5}  if  $column > 0;
		$text .= $D{c5} x $self->{_widths}[$column];
		$text .= $D{c5} x $self->{_marked}[$column];
		$text .= $D{c5} x length($blank) if $self->{_active}[$column];
	    }
	    $text .= $D{b6} . "\n";
	}

	# now for the content of the fields, which are returned in correct
	# size by _show (and _format):
	my $h = $self->{_heights}[$row];
	# 3. concatenate fields of columns line by line in temporary array:
	my @output = ();
	my $border = $self->border ? $D{B5} : ' ';
	foreach my $column (0..($self->columns - 1))
	{
	    my $w = $self->{_widths}[$column];
	    $_ = $self->field($row, $column);
	    my $prefix = '';
	    if ($self->{_active}[$column])
	    {
		if (defined $_  and  $_->can('_process'))
		{
		    my $tl = $self->_toplevel;
		    if ($tl  and  defined $tl->{_active_index}{$_})
		    {
			my $i = $tl->{_active_index}{$_};
			$prefix = sprintf($pre_active, $i);
		    }
		}
		else
		{   $prefix = $blank;   }
	    }
	    my @field =
		split(m/\n/,
		      defined $_
		      ?  $_->_show($prefix, $w, $h, $pre_active)
		      : $self->_format($prefix, '', '', ' ', '', '', $w, $h));
	    if ($column > 0)
	    {   $output[$_] .= $border . $field[$_]  foreach  (0..$#field);   }
	    else
	    {   $output[$_] = $field[$_]  foreach  (0..$#field);   }
	}

	# 4. build complete row:
	my $bl = $self->border ? $D{B4} : '';
	my $br = $self->border ? $D{B6} : '';
	$text .= $self->_format('', $bl, '', \@output, '', $br, 0, 0);
	$text .= "\n";
    }

    # 5. bottom border:
    if ($self->border)
    {
	$text .= $D{B1};
	foreach my $column (0..($self->columns - 1))
	{
	    $text .= $D{b2}  if  $column > 0;
	    $text .= $D{B2} x $self->{_widths}[$column];
	    $text .= $D{B2} x $self->{_marked}[$column];
	    $text .= $D{B2} x length($blank) if $self->{_active}[$column];
	}
	$text .= $D{B3} . "\n";
    }

    # 6. final reformatting of whole block:
    $outer_prefix = ' ' x length($outer_prefix);
    my @text = split m/\n/, $text;
    return
	$self->_format($outer_prefix, '', '', \@text, '', '', $width, $height);
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Box>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
