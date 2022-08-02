package UI::Various::PoorTerm::base;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::base - abstract helper class for PoorTerm's UI elements

=head1 SYNOPSIS

    # This module should only be used by the UI::Various::PoorTerm UI
    # element classes!

=head1 ABSTRACT

This module provides some helper functions for the UI elements of the
minimal fallback UI.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

All functions of the module will be included as second "base
class" (in C<@ISA>).  Note that this is not a diamond pattern as this "base
class" does not import anything besides C<Exporter>.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Text::Wrap;
$Text::Wrap::huge = 'overflow';
$Text::Wrap::unexpand = 0;

our $VERSION = '0.30';

use UI::Various::core;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

The module provides the following common (internal) methods for all
UI::Various::PoorTerm UI element classes:

=cut

#########################################################################

=head2 B<_cut> - cut string according to width of UI element

    $wrapped_string = $ui_element->_cut($string, ...);

=head3 example:

    print $self->_cut($prefix, ' ', $self->text), "\n";

=head3 parameters:

    $string             the string(s) to be shortened

=head3 description:

This method joins all strings passed to it.  It then checks if they fit
within the L<maximum line length|UI::Various::Main/max_width ro> and that
the length of the strings do not exceed the defined width for the UI element
itself.  Any excess content is cut away.

Note that method is unfit for multi-line strings.  Also note that the
specific width of the UI element is transitive meaning that it could be
defined in one of the parents of the UI element itself.

=head3 returns:

the (maybe) shortened string

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _cut($@)
{
    my $self = shift;
    my $string = join('', @_);

    my $len = length($string);
    my $width = $self->width || 0;
    my $max_width = $self->top->max_width;

    $width <= $max_width  or  $width = $max_width;
    if ($len <= $width  or  $width < 1)
    {
	return $string;
    }
    return substr($string, 0, $width);
}

#########################################################################

=head2 B<_wrap> - wrap string according to width of UI element

    $wrapped_string = $ui_element->_wrap($prefix, $string);

=head3 example:

    print $self->_wrap($prefix, $self->text), "\n";

=head3 parameters:

    $prefix             text in front of first line
    $string             the string to be wrapped

=head3 description:

This method checks if the given prefix text and string fit within the
L<maximum line length|UI::Various::Main/max_width ro>, and that the length
of the string does not exceed the defined width for the UI element itself.

If string plus prefix is longer than the maximum line length, or if the
string (without prefix!) is longer than the specific width for the UI
element, the string gets automatically wrapped at the last word boundary
before that length.  Wrapped lines are prefixed with as much blanks as the
prefix of the first line has characters.

Note that the specific width of the UI element is transitive meaning that it
could be defined in one of the parents of the UI element itself.

Also note that if the method can't find a place to properly break up the
string, it gives up and returns a longer one.

=head3 returns:

the (hopefully correctly) wrapped string

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _wrap($$$)
{
    my ($self, $prefix, $string) = @_;

    my $len_p = length($prefix);
    my $len_s = length($string);
    my $width = $self->width || 0;
    my $max_width = $self->top->max_width;

    $width <= $max_width - $len_p  or  $width = $max_width - $len_p;
    if ($len_s <= $width  or  $width < 1)
    {
	return $prefix.$string;
    }
    local $_ = ' ' x $len_p;
    $Text::Wrap::columns = $width + $len_p + 1;
    $_ = wrap($prefix, $_, $string);
    return $_;
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

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
