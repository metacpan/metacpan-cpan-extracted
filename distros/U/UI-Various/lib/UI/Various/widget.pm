package UI::Various::widget;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::widget - abstract base class for UI elements

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various;

=head1 ABSTRACT

This module is the common abstract base class for all kinds of objects in
the L<UI::Various> package aka UI elements or widgets.

=head1 DESCRIPTION

All C<UI::Various::[A-Z]*> modules are classes with the following common
attributes (inherited from C<UI::Various::widget>):

=head2 Attributes

(sorted alphabetically)

B<rw> attributes can be read and modified.  The later may have some
restrictions.  (See documentation of specific attribute).

B<ro> attributes can only be read and not modified.

B<optional> attributes may be empty or C<undef>.

B<recommended> attributes may be empty or C<undef>, but it is advisable to
give them a proper value.

B<inherited> attributes may be undefined, but if they are read, a possible
value will be searched for all the hierarchy up to either the L<main "Window
Manager"|UI::Various::Main> object or the top-level
L<Window|UI::Various::Window> or L<Dialogue|UI::Various::Dialog> objects.
They may still be undefined everywhere, though.

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.22';

use UI::Various::core;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

#########################################################################

=item height [rw, inherited]

preferred (maximum) height of a UI element in (approximately) characters,
should not exceed L<max_height of main "Window Manager"
|UI::Various::Main/max_height ro>

Be careful with small height values as this could lead to undisplayed or
even discarded UI elements in some of the possible UIs.  If this is the main
window, the application could be immediately exited!

=cut

sub height($;$)
{
    return _inherited_access('height', undef, @_);
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=item B<parent> [rw, optional]

a reference to the parent of the current UI element, usually C<undef> for
the C<L<UI::Various::Main>> object and defined for everything else

Note that usually this should only be manipulated by methods of
C<L<UI::Various::container>>.

=cut

sub parent($;$)
{
    return
	access('parent',
	       sub{
		   if (defined $_)
		   {
		       $_->isa('UI::Various::container')  or
			   fatal('invalid_parent__1_not_a_ui_various_container',
				 ref($_));
		   }
	       },
	       @_);
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=item width [rw, inherited]

preferred (maximum) width of a UI element in (approximately) characters,
should not exceed L<max_width of main "Window Manager"
|UI::Various::Main/max_width ro>

=cut

sub width($;$)
{
    return _inherited_access('width', undef, @_);
}

# TODO: fg, bg, x, y, align (1-9, default 5, 1 is sw)

#########################################################################
#
# internal constants and data:

use constant COMMON_PARAMETERS  => qw(height width);
use constant ALLOWED_PARAMETERS => qw(parent);
use constant DEFAULT_ATTRIBUTES => (parent => undef);

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors described above the following methods are available in
all C<UI::Various::[A-Z]*> classes:

=cut

#########################################################################

=head2 B<new> - constructor

see L<UI::Various::core::construct|UI::Various::core/construct - common
constructor for UI elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($;\[@$])
{
    return construct({ DEFAULT_ATTRIBUTES },
		     '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
		     @_);
}

#########################################################################

=head2 B<top> - determine top UI element of hierarchy

    $top = $ui_element->top;

=head3 example:

    $top = $ui_element->top;
    if ($top) { ... }

=head3 description:

This method follows the C<parent> relationship until it reaches the top UI
element of the hierarchy and returns it.  If the C<parent> relationship has
a cycle, an C<L<error|UI::Various::core/error / warning / info - print error
/ warning / info message>> is created and the method returns C<undef>.

=head3 returns:

top UI element

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub top($)
{
    my ($self) = @_;
    # sanity checks:
    $self->isa(__PACKAGE__)
	or  fatal('invalid_object__1_in_call_to__2__3',
		  ref($self), __PACKAGE__, 'top');

    my %seen = ();
    my $n = 0;
    local $_;

    # unrolled recursion with variable $self:
    while (not defined $seen{$self})
    {
	$_ = $self->parent;
	return $self unless $_;
	$seen{$self} = $n++;
	$self = $_;
    }
    return error('cyclic_parent_relationship_detected__1_levels_above',
		 $seen{$self});
}


#########################################################################

=head2 B<_inherited_access> - accessor for common inherited attributes

If a read access can't find a value for the object, it tries getting a value
from all ancestors up to the L<main "Window Manager"|UI::Various::Main>
object.  Otherwise see L<UI::Various::core::access|UI::Various::core/access
common accessor for UI elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _inherited_access($$@)
{
    my $attribute = shift;
    my $sub_set = shift;			# only needed in setter!
    my $self = shift;

    # write access (setter):
    exists $_[0]  and  return access($attribute, $sub_set, $self, @_);

    # read access:
    local $_;
    while ($self)
    {
	$_ = access($attribute, undef, $self);
	defined $_  and  return $_;
	$self = $self->parent;
    }
    return undef;
}

#########################################################################

=head2 B<_toplevel> - return visible toplevel UI element

    $ui_element->_toplevel;

=head3 description:

Return the toplevel parent UI element of any UI container.  While above
C<L<top|/top - determine top UI element of hierarchy>> usually returns the
L<UI::Various::Main> element this call usually returns a
L<UI::Various::Window> or L<UI::Various::Dialog>.  In addition it does not
have sanity checks.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _toplevel($)
{
    local ($_) = @_;
    while (defined $_  and  not $_->isa('UI::Various::toplevel'))
    {
	$_ = $_->parent;
    }
    return $_;
}

# TODO: Debug?, terminal_color

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
