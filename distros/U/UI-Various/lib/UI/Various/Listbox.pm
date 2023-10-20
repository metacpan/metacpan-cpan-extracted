package UI::Various::Listbox;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Listbox - general listbox widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    my @variable = ('1st', '2nd', '3rd');
    $main->window(...
                  UI::Various::Listbox->new(height => 5,
                                            selection => 2,
                                            texts => \@variable),
                  ...);
    $main->mainloop();

=head1 ABSTRACT

This module defines the general listbox widget of an application using
L<UI::Various>.

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> the
C<Listbox> widget knows the following additional attributes:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.43';

use UI::Various::core;
use UI::Various::widget;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Listbox.pm';  }

require Exporter;
our @ISA = qw(UI::Various::widget);
our @EXPORT_OK = qw();

#########################################################################

=item first [ro]

the index of the first element to be shown

The last element shown will have the index C<first> + C<height> - 1, if
C<texts> is long enough.

=cut

sub first($)
{
    return get('first', $_[0]);
}

=item height [rw, fixed]

the height of the listbox is the maximum number of elements shown

Other then in other UI elements it is a mandatory parameter.  Note the the
C<*Term> UIs use one additional line for the position information at the top
of the listbox.

=cut

sub height($;$)
{
    return access('height',
		  sub{
		      unless (m/^\d+$/  and  $_ > 0)
		      {
			  error('parameter__1_must_be_a_positive_integer',
				'height');
			  $_ = 5;
		      }
		  },
		  @_);
}

=item on_select [rw, optional]

an optional callback called after changing the selection

Note that the callback routine is called without parameters.  If you need to
access the current selection, use the method C<L<selected|/selected - get
current selection of listbox>>.  Also note that when a user drags a
selection in L<Tk> the callback is called for each and every change, not
only for the final one after releasing the mouse button.

=cut

sub on_select($;$)
{
    return access('on_select',
		  sub{
		      unless (ref($_) eq 'CODE')
		      {
			  error('_1_attribute_must_be_a_2_reference',
				'on_select', 'CODE');
			  return undef;
		      }
		  },
		  @_);
}

=item selection [rw, fixed, recommended]

the selection type of the listbox, a number between 0 and 2, defaults to 2:

=over

=item 0 - the elements are not selectable

=item 1 - only single selection

=item 2 - multiple selection is possible

=back

Note that changing the value after displaying the listbox will not work
without recreating its container.

=cut

sub selection($;$)
{
    return access('selection',
		  sub{
		      unless (m/^[012]$/)
		      {
			  error('parameter__1_must_be_in__2__3',
				'selection', 0, 2);
			  $_ = 2;
		      }
		  },
		  @_);
}

=item texts [rw, fixed, recommended]

the texts of the elements of the listbox as strings

The default is an empty list.

Note that the content of the list may only be modified with the methods
provided by C<Listbox> (C<L<add|/add - add new element>> and
C<L<remove|/remove - remove element>>).  The only exception is when the
listbox did not yet contain any element.

=cut

sub texts($\@)
{
    return
	access
	('texts',
	 sub{
	     unless (ref($_) eq 'ARRAY')
	     {
		 error('_1_attribute_must_be_a_2_reference', 'texts', 'ARRAY');
		 return undef;
	     }
	     my ($self) = @_;
	     if ($self->{_initialised})
	     {
		 error('_1_may_not_be_modified_directly_after_initialisation',
		       'texts');
		 return undef;
	     }
	     my $entries = @$_;
	     if ($entries > 0)
	     {
		 local $_ = 0;
		 $self->{_selected} = [ (' ') x $entries ];
		 $self->{_initialised} = 1;
		 $self->{first} = 0;
	     }
	     else
	     {   $self->{first} = -1;   }
	 },
	 @_);
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS,
     qw(first on_select selection texts));
use constant DEFAULT_ATTRIBUTES => (first => -1, selection => 2, texts => []);

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and by
L<UI::Various::widget|UI::Various::widget/Attributes> and the methods
inherited from L<UI::Various::widget|UI::Various::widget/METHODS> only the
constructor is provided by the C<Listbox> class itself:

=cut

#########################################################################

=head2 B<new> - constructor

see L<UI::Various::core::construct|UI::Various::core/construct - common
constructor for UI elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($;\[@$])
{
    debug(3, __PACKAGE__, '::new');
    local $_ = construct({ DEFAULT_ATTRIBUTES },
			 '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
			 @_);
    unless (defined $_->{height})
    {
	error('mandatory_parameter__1_is_missing', 'height');
	return undef;
    }
    return $_;
}

#########################################################################

=head2 B<add> - add new element

    $listbox->add($text, ...);

=head3 example:

    $self->add('one more');
    $self->add('one more', 'still one more');

=head3 parameters:

    $text               another text to be added to the end of the listbox

=head3 description:

This method adds one or more new elements at the end of the listbox.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub add($@)
{
    my $self = shift;

    # sanity checks:
    $self->isa(__PACKAGE__)
	or  fatal('invalid_object__1_in_call_to__2__3',
		  ref($self), __PACKAGE__, 'add');

    push @{$self->{texts}}, @_;
    push @{$self->{_selected}}, (' ') x scalar(@_);
    0 < @_  and  $self->{first} < 0  and  $self->{first} = 0;
    # call UI-specific implementation, if applicable:
    if ($self->can('_add'))
    {   $self->_add(@_);   }
}

#########################################################################

=head2 B<modify> - modify element

    $listbox->modify($index, $value);

=head3 example:

    $self->modify(2, 'new value');

=head3 parameters:

    $index              the index of the element to be modified
    $value              the new value for the element

=head3 description:

This method modifies an element in the listbox by replacing its value.  The
element is identified by its index.  Indices start with 0.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub modify($$$)
{
    my ($self, $index, $value) = (@_);

    # sanity checks:
    $self->isa(__PACKAGE__)
	or  fatal('invalid_object__1_in_call_to__2__3',
		  ref($self), __PACKAGE__, 'modify');
    unless ($index =~ m/^\d+$/)
    {
	error('parameter__1_must_be_a_positive_integer_in_call_to__2__3',
	      'index', __PACKAGE__, 'modify');
	return;
    }
    unless (defined $value)
    {
	error('mandatory_parameter__1_is_missing', 'value');
	return;
    }
    if ($index <= $#{$self->{texts}})
    {
	$self->{texts}[$index] = $value;
	# call UI-specific implementation, if applicable:
	if ($self->can('_modify'))
	{   $self->_modify($index, $value);   }
    }
}

#########################################################################

=head2 B<remove> - remove element

    $listbox->remove($index);

=head3 example:

    $self->remove(2);

=head3 parameters:

    $index              the index of the element to be removed from the listbox

=head3 description:

This method removes an element from the listbox.  The element to be removed
is identified by its index.  Indices start with 0.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub remove($$)
{
    my ($self, $index) = (@_);

    # sanity checks:
    $self->isa(__PACKAGE__)
	or  fatal('invalid_object__1_in_call_to__2__3',
		  ref($self), __PACKAGE__, 'remove');
    unless ($index =~ m/^\d+$/)
    {
	error('parameter__1_must_be_a_positive_integer_in_call_to__2__3',
	      'index', __PACKAGE__, 'remove');
	return;
    }
    if ($index <= $#{$self->{texts}})
    {
	splice @{$self->{texts}}, $index, 1;
	splice @{$self->{_selected}}, $index, 1;
	$self->first <= $#{$self->{texts}}  or
	    $self->{first} = 0 < @{$self->{texts}} ? 0 : -1;
    }
    # call UI-specific implementation, if applicable:
    if ($self->can('_remove'))
    {   $self->_remove($index);   }
}

#########################################################################

=head2 B<replace> - replace all elements

    $listbox->replace(@new_elements);

=head3 example:

    $self->replace('one new entry', 'another new entry');

=head3 parameters:

    $text               list of texts to replace original entries

=head3 description:

This method replaces all elements in the listbox and removes all selections.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub replace($@)
{
    my $self = shift;

    # sanity checks:
    $self->isa(__PACKAGE__)
	or  fatal('invalid_object__1_in_call_to__2__3',
		  ref($self), __PACKAGE__, 'replace');
    my @new_entries = @_;	# create a copy!
    $self->{texts} = \@new_entries;
    $self->{_selected} = [ (' ') x scalar(@new_entries) ];
    $self->{first} = 0 < @{$self->{texts}} ? 0 : -1;
    # call UI-specific implementation, if applicable:
    if ($self->can('_replace'))
    {   $self->_replace(@_);   }
}

#########################################################################

=head2 B<selected> - get current selection of listbox

    $selection = $listbox->selected();  # C<selection =E<gt> 1>
    @selection = $listbox->selected();  # C<selection =E<gt> 2>

=head3 description:

This method returns the sorted indices of the currently selected element(s)
of the listbox.  Indices start with 0.  If there is nothing selected at all,
the method returns C<undef> for C<selection =E<gt> 1> and an empty list for
C<selection =E<gt> 2>.

=head3 returns:

selected element(s)  (or C<undef> for C<selection =E<gt> 0>)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub selected($)
{
    my ($self) = @_;
    unless ($self->{selection})
    {
	error('invalid_call_to__1__2', __PACKAGE__, 'selected');
	return undef;
    }
    my @selected = ();
    if ($self->can('_selected'))
    {
	@selected = $self->_selected;	# call UI-specific implementation
    }
    else
    {
	local $_ = 0;
	foreach (0..$#{$self->texts})
	{
	    $self->{_selected}[$_] ne ' '  and  push @selected, $_;
	}
    }
    return
	$self->selection > 1 ?	@selected :
	0 < @selected ?		$selected[0] :	undef;
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

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
