package UI::Various::Curses::Check;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Curses::Check - concrete implementation of L<UI::Various::Check>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Check;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Check> using
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

our $VERSION = '0.44';

use UI::Various::core;
use UI::Various::Check;
use UI::Various::Curses::base;

require Exporter;
our @ISA = qw(UI::Various::Check UI::Various::Curses::base);
our @EXPORT_OK = qw();

use Curses::UI;

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

    $row                relative row
    $column             relative column

=head3 description:

Prepare the UI element for L<Curses::UI>.  I<The method should only be
called from C<UI::Various::Curses> container elements!>

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
    $self->_cui($_->_cui
		->add($self->_cid,
		      'Checkbox', -x => $column, -y => $row,
		      -label => $self->text,
		      -checked => $self->var, # automatic dereference!
		      -onchange => sub {
			  # Don't do anything if called via another checkbox:
			  (caller(4))[3] =~ m/::base::_reference$/  and  return;
			  # no automatic dereference:
			  local $_ = $self->{var};
			  $$_ = $self->_cui->get;
			  $self->_reference($_, 1);
		      }));
    return 0;
}

#########################################################################

=head2 B<_update> - update UI element

    $ui_element->_update();

=head3 description:

Update the UI element after an external change of its SCALAR reference.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _update($)
{
    my ($self) = @_;
    debug(4, __PACKAGE__, '::_update ', $self->_cid,
	  ' with', (defined $self->_cui ? '' : 'out'), ' _cui');
    $self->_cui  and  $self->_cui->toggle;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Check>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
