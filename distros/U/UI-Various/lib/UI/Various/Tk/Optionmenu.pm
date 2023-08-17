package UI::Various::Tk::Optionmenu;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Tk::Optionmenu - concrete implementation of L<UI::Various::Optionmenu>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Optionmenu;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Optionmenu>
using Perl/Tk.

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

our $VERSION = '0.40';

use UI::Various::core;
use UI::Various::Optionmenu;
use UI::Various::Tk::base;

require Exporter;
our @ISA = qw(UI::Various::Optionmenu UI::Various::Tk::base);
our @EXPORT_OK = qw();

use Tk;

#########################################################################
#########################################################################

=head1 METHODS

=cut

#########################################################################

=head2 B<_prepare> - prepare UI element

    $ui_element->_prepare($row, $column);

=head3 example:

    my ($errors, $row) = (0, 0);
    while ($_ = $self->child)
    {   $errors += $_->_prepare($row++, 0);   }

=head3 parameters:

    $row                grid row
    $column             grid column

=head3 description:

Prepare the UI element for L<Tk>.  I<The method should only be called from
C<UI::Various::Tk> container elements!>

=head3 returns:

1 in case of errors, 0 otherwise

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _prepare($$$)
{
    my ($self, $row, $column) = @_;
    local $_ = $self->parent;

    unless ($_)
    {
	error('_1_element_must_be_accompanied_by_parent', __PACKAGE__);
	return 1;
    }
    my @attributes = ($self->_attributes());
    $self->_tk(	$_->_tk
		->Optionmenu(-options => $self->{options},
			     # Note that -variable and -textvariable are
			     # apparently copied, so a reference would be
			     # lost.
			     -command => sub {
				 $self->{_selected} = $_[0];
				 local $_ = $self->on_select;
				 defined $_  and  &$_($self->{_selected});
			     },
			     @attributes)
		->grid(-row => $row, -column => $column));
    return 0;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Optionmenu>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
