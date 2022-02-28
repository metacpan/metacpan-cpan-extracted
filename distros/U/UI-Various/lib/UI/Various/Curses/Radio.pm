package UI::Various::Curses::Radio;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Curses::Radio - concrete implementation of L<UI::Various::Radio>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Radio;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Radio> using
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

our $VERSION = '0.18';

use UI::Various::core;
use UI::Various::Radio;
use UI::Various::Curses::base;

require Exporter;
our @ISA = qw(UI::Various::Radio UI::Various::Curses::base);
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
    my $selected = undef;
    # Note that the accessor automatically dereferences the SCALAR here:
    my $var = $self->var;
    defined $var  or  $var = '$ ^ }!\\"{]}[%]'; # magic invalid string
    foreach my $i (0..$#{$self->{_button_keys}})
    {
	$var eq $self->{_button_keys}[$i]  and  $selected = $i;
    }
    $self->_cui($_->_cui
		->add($self->_cid,
		      'Radiobuttonbox', -x => $column, -y => $row,
		      -height => scalar(@{$self->{_button_keys}}),
		      -labels => $self->{_button_hash},
		      -values => $self->{_button_values},
		      -selected => $selected,
		      -onblur => sub {
			  # no automatic dereference:
			  my $var = $self->{var};
			  local $_ = $self->_cui->id;
			  defined $_  and  $$var = $self->{_button_keys}[$_];
			  $self->_reference($var, 1);
		      }));
    return 0;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Radio>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
