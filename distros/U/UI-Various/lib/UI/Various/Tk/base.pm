package UI::Various::Tk::base;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Tk::base - abstract helper class for Tk's UI elements

=head1 SYNOPSIS

    # This module should only be used by the UI::Various::Tk UI
    # element classes!

=head1 ABSTRACT

This module provides some helper functions for the UI elements of the
Perl/Tk GUI.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

All functions of the module will be included as second "base class" (in
C<@ISA>).  Note that this is not a diamond pattern as this "base class" does
not import anything besides C<Exporter>, though it add a common private
attribute to all C<UI::Various::Tk> classes:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.05';

use UI::Various::core;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

#########################################################################

=item B<_tk> [rw, optional]

a reference to the main Perl/Tk element used for the implementation of the
UI element

Note that usually this should only be used within C<UI::Various::Tk>.

=cut

sub _tk($;$)
{   return access('_tk', undef, @_);   }

#########################################################################
#########################################################################

=back

=head1 METHODS

The module also provides the following common (internal) methods for all
UI::Various::Tk UI element classes:

=cut

#########################################################################

=head2 B<_cleanup> - cleanup UI element

    $ui_element->cleanup;

=head3 description:

This method prepares a UI element for destruction by removing all of the
references it is holding (including its parent reference).  An object will
therefore only survive if it is additionally still referenced outside of
C<L<UI::Various>>, e.g. a variable used to create it in the first place.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _cleanup($)
{
    my ($self) = @_;

    # We recursively remove our references to Perl/Tk objects first in order
    # to ease the internal cleanup for Perl/Tk itself:
    if ($self->can('remove'))
    {
	local $_;
	while ($_ = $self->child)
	{   $_->_cleanup;   }
    }

    $self->{_tk}  and  delete $self->{_tk};

    $self->parent->remove($self);
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
