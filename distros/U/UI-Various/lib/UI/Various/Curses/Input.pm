package UI::Various::Curses::Input;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Curses::Input - concrete implementation of L<UI::Various::Input>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Input;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Input> using
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

our $VERSION = '0.15';

use UI::Various::core;
use UI::Various::Input;
use UI::Various::Curses::base;

require Exporter;
our @ISA = qw(UI::Various::Input UI::Various::Curses::base);
our @EXPORT_OK = qw();

use Curses;

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
		      'TextEditor', -x => $column, -y => $row,
		      -singleline => 1,
		      -text => $self->textvar, # automatic dereference!
		      -onblur => sub {
			  # no automatic dereference:
			  local $_ = $self->{textvar};
			  $$_ = $self->_cui->get;
			  $self->_reference($_);
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
    defined $self->_cui  and  $self->_cui->text($self->textvar);
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Input>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner@cpan.orgE<gt>

=cut
