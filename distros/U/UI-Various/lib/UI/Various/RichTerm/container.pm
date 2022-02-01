package UI::Various::RichTerm::container;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::RichTerm::container - abstract helper class for RichTerm's container UI elements

=head1 SYNOPSIS

    # This module should only be used by the container UI element classes of
    # UI::Various::RichTerm!

=head1 ABSTRACT

This module provides some helper functions for the container UI elements of
the rich terminal UI.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

All functions of the module will be included as second "base class" (in
C<@ISA>) like (and instead of) C<L<UI::Various::RichTerm::base>>.

=head2 Attributes

=over

=item _active [ro, global]

Top-level container elements (windows or dialogues) may contain a reference
to an array containing the references to all their active UI elements (those
that are accessible, basically everything not just a simple text output).
This allows accessing the functions behind the active UI elements.

=item _active_index [ro, global]

In addition the top-level container elements may also contain a reference to
a hash containing the reverse index of that array.  This allows any
container to access the indices of their own children.

=item _has_active [rw, optional]

TODO: not needed, check before, for box this depends on column anyway

Flag if a container has any active UI element as direct children.  This will
be used to determine if a container's child will get a prefix or not.

=back

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.16';

use UI::Various::core;
use UI::Various::RichTerm::base;

require Exporter;
our @ISA = qw(UI::Various::RichTerm::base);
our @EXPORT_OK = qw();

#########################################################################
#########################################################################

=head1 METHODS

The module provides the following common (internal) methods for all
UI::Various::RichTerm container UI element classes:

=cut

#########################################################################

=head2 B<_all_active> - gather and return list of active children

    my @active = $ui_element->_all_active;

=head3 description:

Recursively gather all active children in an array and return it.  The
top-level window or dialogue will store the final full array and its reverse
hash, see C<L<_active|/_active [ro, global]>> and
C<L<_active_index|/_active_index [ro, global]>> above.

=head3 returns:

array with active children

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _all_active($)
{
    my ($self) = @_;
    $self->{_has_active} = 0;
    my @active = ();
    local $_;
    while ($_ = $self->child)
    {
	# uncoverable branch false count:2 # TODO until Box
	if ($_->can('_process'))
	{   push @active, $_;   $self->{_has_active} = 1;   }
	elsif (not $_->can('_all_active'))
	{}			# TODO: invert (again) with Box
	else
	{   push @active, $_->_all_active();   } # uncoverable statement # TODO until Box
    }
    return @active;
}

#########################################################################

=head2 B<_self_destruct> - remove children and self-destruct

    $ui_element->_self_destruct;

=head3 description:

Remove all children (to get rid of possible circular references) and remove
itself from "Window Manager" C<L<UI::Various::RichTerm::Main>>.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _self_destruct($)
{
    my ($self) = @_;
    local $_;

    if (defined $self->{_active})
    {   delete $self->{_active};   delete $self->{_active_index};   }
    while ($_ = $self->child)
    {
	# uncoverable branch true # TODO until Box
	if ($_->can('_self_destruct'))
	{   $_->_self_destruct;   }	# uncoverable statement # TODO until Box
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
