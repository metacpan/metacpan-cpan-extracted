package UI::Various::RichTerm::base;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::RichTerm::base - abstract helper class for RichTerm's UI elements

=head1 SYNOPSIS

    # This module should only be used by the UI::Various::RichTerm UI
    # element classes!

=head1 ABSTRACT

This module provides some helper functions for the UI elements of the rich
console.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

All functions of the module will be included as second "base
class" (in C<@ISA>).  Note that this is not a diamond pattern as this "base
class" does not import anything besides C<Exporter>.

=head2 Global Definitions

=over

=cut

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Text::Wrap;
$Text::Wrap::huge = 'overflow';
$Text::Wrap::unexpand = 0;

our $VERSION = '0.06';

use UI::Various::core;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%D);

#########################################################################

=item B<%D>

a hash of decoration characters for window borders (C<W1> to C<W9> without
C<W5>), box borders (C<B1> to C<B9> without C<B5>), check boxes (C<CL> and
C<CR>), radio buttons (C<RL> and C<RR>) and normal buttons (C<BL> and C<BR>)

=cut

use constant DECO_ASCII => (W7 => '#', W8 => '=', W9 => '#',
			    W4 => '"',		  W6 => '"',
			    W1 => '#', W2 => '=', W3 => '#',
			    B7 => '+', B8 => '-', B9 => '+',
			    B4 => '|',		  B6 => '|',
			    B1 => '+', B2 => '-', B3 => '+',
			    BL => '[', BR => ']',
			    CL => '[', CR => ']',
			    RL => '(', RR => ')');

# not yet supported:
use constant DECO_UTF8 => (W7 => "\x{2554}", W8 => "\x{2550}", W9 => "\x{2557}",
			   W4 => "\x{2551}",		       W6 => "\x{2551}",
			   W1 => "\x{255a}", W2 => "\x{2550}", W3 => "\x{255d}",
			   B7 => "\x{250c}", B8 => "\x{2500}", B9 => "\x{2510}",
			   B4 => "\x{2502}",		       B6 => "\x{2502}",
			   B1 => "\x{2514}", B2 => "\x{2500}", B3 => "\x{2518}",
			   BL => "\x{2503}", BR => "\x{2503}",
			   CL => '[', CR => ']',
			   RL => '(', RR => ')');

our %D = DECO_ASCII;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


#########################################################################
#########################################################################

=back

=head1 METHODS

The module provides the following common (internal) methods for all
UI::Various::RichTerm UI element classes:

=cut

#########################################################################

=head2 B<_size> - determine size of UI element

    ($width, $height) = $ui_element->_size($string, $content_width);

=head3 example:

    my ($w, $h) = $self->_size($self->text, $content_width);

=head3 parameters:

    $string             the string to be analysed
    $content_width      preferred width of content

=head3 description:

This method determines the width and height of a UI element.

If the UI element has it's own defined (not inherited) widht and/or height,
no other calculation is made (no matter if the string will fit or not).

If no own width is defined, the text will be wrapped into lines no longer
than the given preferred maximum width and the length of the longest of line
is returned.  If a sub-string has no word boundary to break it into chunks
smaller than C<$content_width>, C<$content_width> is returned even though
the string will not really fit when it will be displayed later.)

If no own height is defined, the number of lines of the wrapped string is
returned.

=head3 returns:

width and height of the string when it will be displayed later

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _size($$$)
{
    my ($self, $string, $content_width) = @_;

    my ($w, $h) = ($self->{width}, $self->{height});
    $w  and  $h  and  return ($w, $h);

    $Text::Wrap::columns = ($w ? $w : $content_width) + 1;
    $string = wrap('', '', $string);
    my @lines = split "\n", $string;

    unless ($w)
    {
	$w = 0;
	local $_;
	foreach (map { length($_) } @lines)
	{   $w >= $_  or  $w = $_;   }
	$w <= $content_width  or  $w = $content_width;
    }

    $h  or  $h = @lines;
    return ($w, $h);
}

#########################################################################

=head2 B<_format> - format text according to given options

    $string = $ui_element->_format($prefix, $decoration_before, $text,
                                   $decoration_after, $width, $height);
        or

    $string = $ui_element->_format($prefix, $decoration_before, \@text,
                                   $decoration_after, $width, $height);

=head3 example:

    my ($w, $h) = $self->_size($self->text, $content_width);
    $string = $self->_format('(1) ', '[ ', $self->text, ' ]', $w, $h);

=head3 parameters:

    $prefix             text in front of first line
    $decoration_before  decoration before content of each line
    $text               string to be wrapped or reference to wrapped text lines
    $decoration_after   decoration after content of each line
    $width              the width returned by _size above
    $height             the height returned by _size above

=head3 description:

This method formats the given text into a text box of the previously
(C<L<_size|/_size - determine size of UI element>>) determined width and
height, decorates it with some additional strings (e.g. to symbolise a
button) and a prefix set by its parent.  Note that the (latter) prefix is
only added to the first line with text, all additional lines gets a blank
prefix of the same length.

Also note that the given text can either be a string which is wrapped or a
reference to an array of already wrapped strings that only need the final
formatting.

The decorations and prefix will cause the resulting text box to be wider
than the given width, which only describes the width of the text itself.

And as already described under C<L<_size|/_size - determine size of UI
element>> above, the layout will be broken if it can't fit.  The display of
everything is preferred over cutting of possible important parts.

=head3 returns:

the rectangular text box for the given string

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _format($$$$$$$)
{
    my ($self, $prefix, $deco_before, $text, $deco_after, $w, $h) = @_;
    my $alignment = 7; # TODO L8R: $self->alignment;

    my $len_p = length($prefix);
    my ($len_d_bef, $len_d_aft) = (length($deco_before), length($deco_after));
    my $prefix2 = ' ' x $len_p;
    local $_;

    # TODO L8R: handle colour (add to front of DECO-1, reset after DECO-2)

    # format text-box:
    # wrap text, if applicable:
    my @text;
    if (ref($text) eq 'ARRAY')
    {   @text = @{$text};   }
    else
    {
	$Text::Wrap::columns = $w + 1;
	@text = split "\n", wrap('', '', $text);
    }
    foreach (0..$#text)
    {
	my $l = length($text[$_]);
	if ($l < $w)
	{
	    # TODO: this is only the code for the alignments 1/4/7:
	    {   $text[$_] .= ' ' x ($w - $l);   }
	}
	$text[$_] = ($_ == 0 ? $prefix : $prefix2)
	    . $deco_before . $text[$_] . $deco_after;
    }
    if ($h > @text)
    {
	$_ = ' ' x ($w + $len_p + $len_d_bef + $len_d_aft);
	# TODO: this is only the code for the alignments 7/8/9:
	{   push @text, ($_) x ($h - @text);   }
    }

    return join("\n", @text);
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
