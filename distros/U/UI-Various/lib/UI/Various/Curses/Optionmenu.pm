package UI::Various::Curses::Optionmenu;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Curses::Optionmenu - concrete implementation of L<UI::Various::Optionmenu>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Optionmenu;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Optionmenu>
using L<Curses::UI>.

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

our $VERSION = '0.25';

use UI::Various::core;
use UI::Various::Optionmenu;
use UI::Various::Curses::base;

require Exporter;
our @ISA = qw(UI::Various::Optionmenu UI::Various::Curses::base);
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
    my %labels = ();
    my @values = ();
    foreach my $opt (@{$self->{options}})
    {
	$labels{$opt->[1]} = $opt->[0];
	push @values, $opt->[1];
    }
    my @selected = ();
    if (defined $self->{_selected})
    {
	my $init = $self->{_selected};
	foreach my $i (0..$#values)
	{
	    if ($values[$i] eq $init)
	    {   @selected = (-selected => $i);   last;   }
	}
    }
    $self->_cui($_->_cui
		->add($self->_cid,
		      'Popupmenu', -x => $column, -y => $row,
		      -values => \@values,
		      -labels => \%labels,
		      @selected,
		      -onchange => sub {
			  local $_ =$self->_cui->get;
			  $self->{_selected} = $_;
			  $_ = $self->on_select;
			  defined $_  and  &$_($self->{_selected});
		      }));
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
