package UI::Various::PoorTerm::container;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::PoorTerm::container - abstract helper class for PoorTerm's container UI elements

=head1 SYNOPSIS

    # This module should only be used by the container UI element classes of
    # UI::Various::PoorTerm!

=head1 ABSTRACT

This module provides some helper functions for the container UI elements of
the minimal fallback UI.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

All functions of the module will be included as second "base class" (in
C<@ISA>) like (and instead of) C<L<UI::Various::PoorTerm::base>>.

=head2 Attributes

=over

=item _active

Container elements may contain a reference to an array containing only the
references to the active UI elements (those that are accessible, basically
everything not just a simple text output).

=back

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.15';

use UI::Various::core;
use UI::Various::PoorTerm::base;

require Exporter;
our @ISA = qw(UI::Various::PoorTerm::base);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

The module provides the following common (internal) methods for all
UI::Various::PoorTerm container UI element classes:

=cut

#########################################################################

=head2 B<_self_destruct> - remove children and self-destruct

    $ui_element->_self_destruct;

=head3 description:

Remove all children (to get rid of possible circular references) and remove
itself from "Window Manager" C<L<UI::Various::PoorTerm::Main>>.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _self_destruct($)
{
    my ($self) = @_;
    local $_;

    defined $self->{_active}  and  delete $self->{_active};
    while ($_ = $self->child)
    {
	if ($_->can('_self_destruct'))
	{   $_->_self_destruct;   }
	else
	{   $self->remove($_);   }
    }
    $self->parent->remove($self);
    $self = undef;
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
