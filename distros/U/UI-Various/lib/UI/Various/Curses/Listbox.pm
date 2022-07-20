package UI::Various::Curses::Listbox;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Curses::Listbox - concrete implementation of L<UI::Various::Listbox>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Listbox;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Listbox> using
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

our $VERSION = '0.26';

use UI::Various::core;
use UI::Various::Listbox;
use UI::Various::Curses::base;

require Exporter;
our @ISA = qw(UI::Various::Listbox UI::Various::Curses::base);
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
		      'Listbox', -x => $column, -y => $row,
		      -border => 1,
		      -height => $self->height + 2,
		      -width => $self->width + 2,
		      -multi => $self->selection == 2,
		      -onchange => sub {
			  defined $self->{on_select}  and
			      # onchange is also called via _remove!
			      not defined $self->{no_on_select}  and
			      &{$self->{on_select}};
			  return 0;
		      },
		      -vscrollbar => 1,
		      -values => $self->{texts}));
    return 0;
}

#########################################################################

=head2 B<_add> - add new element

C<PoorTerm>'s specific implementation of
L<UI::Various::Listbox::add|UI::Various::Listbox/add - add new element>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _add($@)
{
    my ($self) = shift;
    $self->_cui->intellidraw();
}

#########################################################################

=head2 B<_remove> - remove element

C<PoorTerm>'s specific implementation of
L<UI::Various::Listbox::remove|UI::Various::Listbox/remove - remove element>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _remove($$)
{
    my ($self, $index) = (@_);
    # simply deleting the element of the list ignores the selections, so we
    # need to work around that:
    local $_;
    my %selected = map { ($_ => 1) } $self->_cui->id;
    $selected{$index}  and  delete $selected{$index};
    my @selected =
	map { $_ < $index ? $_ : $_ - 1 }
	sort { $a <=> $b }
	keys %selected;
    $self->_cui->clear_selection();
    defined $self->{on_select}  and  $self->{no_on_select} = 1;
    $self->_cui->set_selection(@selected);
    defined $self->{on_select}  and  delete $self->{no_on_select};
    $self->_cui->intellidraw();
}

#########################################################################

=head2 B<_replace> - replace all elements

C<PoorTerm>'s specific implementation of
L<UI::Various::Listbox::replace|UI::Various::Listbox/replace - replace all
elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _replace($@)
{
    my ($self) = shift;
    $self->_cui->clear_selection();
    $self->_cui->values($self->{texts});
    $self->_cui->intellidraw();
}

#########################################################################

=head2 B<_selected> - get current selection of listbox

C<PoorTerm>'s specific implementation of
L<UI::Various::Listbox::selected|UI::Various::Listbox/selected -get current
selection of listbox>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _selected($)
{
    my ($self) = @_;
    return sort { $a <=> $b } $self->_cui->id;
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<UI::Various>, L<UI::Various::Listbox>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
