package UI::Various::Tk::Box;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Tk::Box - concrete implementation of L<UI::Various::Box>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Box;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Box> using
Perl/Tk.

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
use UI::Various::Box;
use UI::Various::Tk::base;

require Exporter;
our @ISA = qw(UI::Various::Box UI::Various::Tk::base);
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

    $row                grid row of UI element within parent
    $column             grid column of UI element within parent

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
    my @border = ($self->border ? (-relief => 'solid', -borderwidth => 1) : ());
    my @attributes = ($self->_attributes(), @border);
    my $grid = $_->_tk->Frame(@attributes)
	->grid(-row => $row, -column => $column);
    my $errors = 0;
    my @tk = ();
    # From now on $row and $column are those of the box itself:
    foreach $row (0..($self->rows - 1))
    {
	foreach $column (0..($self->columns - 1))
	{
	    # We temporarily store the frame for the field in the main Tk
	    # member variable as that's what our children expect from us:
	    $self->_tk($grid->Frame(@border)
		       ->grid(-row => $row, -column => $column,
			      -sticky => 'nswe'));
	    $_ = $self->field($row, $column);
	    defined $_  and  $errors += $_->_prepare(0, 0);
	    # Now move the frame to its proper place in the array ...
	    push @tk, $self->_tk;
	}
    }
    # ... and store the array in the main Tk member variable:
    $self->_tk(\@tk);
    return $errors;
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
