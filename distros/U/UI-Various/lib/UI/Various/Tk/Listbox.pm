package UI::Various::Tk::Listbox;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Tk::Listbox - concrete implementation of L<UI::Various::Listbox>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Listbox;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Listbox> using
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

our $VERSION = '0.23';

use UI::Various::core;
use UI::Various::Listbox;
use UI::Various::Tk::base;

require Exporter;
our @ISA = qw(UI::Various::Listbox UI::Various::Tk::base);
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
    my @options =
	(-scrollbars => 'oe',
	 ($self->width < $self->top->max_width ? (-width => $self->width) : ()),
	 -height => $self->height, # height is mandatory, width is not!
	 ($self->selection == 2 ? (-selectmode => 'extended') :
	  (			   -selectmode => 'browse')),
	 -exportselection => 0);
    my $tk_listbox =
	$_->_tk->Scrolled('Listbox', @options)
	->grid(-row => $row, -column => $column);
    $self->_tk($tk_listbox);
    $tk_listbox->insert(0, @{$self->{texts}});
    if ($self->selection == 0)
    {				# disable selection-bindings:
	$tk_listbox->bind('Tk::Listbox', $_, '')
	    foreach ('<B1-Enter>', '<B1-Leave>', '<B1-Motion>',
		     '<Button-1>', '<Shift-Button-1>');
    }
    if ($self->{on_select})
    {
	$tk_listbox->bind('<<ListboxSelect>>', $self->{on_select});
    }
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
    $self->_tk->insert('end', @_);
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
    $self->_tk->delete($index);
}

#########################################################################

=head2 B<_selected> - get current selection of listbox

C<PoorTerm>'s specific implementation of
L<UI::Various::Listbox::selected|UI::Various::Listbox/selected - get current
selection of listbox>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _selected($)
{
    my ($self) = @_;
    return $self->_tk->curselection;
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
