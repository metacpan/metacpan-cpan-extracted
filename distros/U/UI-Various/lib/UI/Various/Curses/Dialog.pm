package UI::Various::Curses::Dialog;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Curses::Dialog - concrete implementation of L<UI::Various::Dialog>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Dialog;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Dialog> using
L<Curses::UI>.

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

our $VERSION = '1.00';

use UI::Various::core;
use UI::Various::Dialog;
use UI::Various::Curses::base;

require Exporter;
our @ISA = qw(UI::Various::Dialog UI::Various::Curses::base);
our @EXPORT_OK = qw();

use Curses::UI;

#########################################################################
#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<_prepare> - prepare UI element

    $ui_element->_prepare;

=head3 description:

Prepare the UI element for L<Curses::UI>.  I<The method should only be
called from
C<L<UI::Various::Curses::Main::mainloop|UI::Various::Curses::Main/mainloop>>!>

=head3 returns:

number of errors encountered

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _prepare($@)
{
    debug(3, __PACKAGE__, '::_prepare');
    my ($self) = @_;
    local $_ =  $self->parent;

    # height/width must be defined!
    my ($h, $w) = ($self->height, $self->width);
    defined $h  or  $h = $self->max_height;
    defined $w  or  $w = $self->max_width;
    my @attributes = $self->_common_attributes();
    $self->_cui($_->_cui
		->add($self->_cid,
		      'Window', -border => 1, -title => $self->title,
		      -height => $h, -width => $w, -centered => 1,
		      @attributes
		     ));

    my ($errors, $row) = (0, 0);
    while ($_ = $self->child)
    {
	$errors += $_->_prepare($row, 0);
	# The 1 is a fallback for FreeBSD missing the height (missing max.?):
	# uncoverable condition false
	# uncoverable condition right
	$row += $_->_cui->height || 1;
    }

    return $errors;
}

#########################################################################

=head2 B<destroy> - remove window from application

C<Curses>'s concrete implementation of
L<UI::Various::Dialog::destroy|UI::Various::Dialog/destroy - remove window
from application> directly destroy the window and removes its children.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub destroy($)
{
    debug(2, __PACKAGE__, '::destroy');
    my ($self) = @_;
    $self->_cui  and  $self->_cui->loose_focus();
    local $_ =  $self->parent;
    $self->_cleanup;
    $self = undef;
    $_->children == 0  and  $_->_cui->mainloopExit;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Dialog>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
