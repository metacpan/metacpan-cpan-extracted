package UI::Various::container;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::container - abstract container class for UI elements

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::...;

=head1 ABSTRACT

This module is the common abstract container class for all kinds UI elements
that may contain other UI elements (e.g. C<L<UI::Various::Window>>,
C<L<UI::Various::Dialog>> or C<L<UI::Various::Box>>).

=head1 DESCRIPTION

The documentation of this module is mainly intended for developers of the
package itself.

All container classes share the following common attributes (inherited from
C<UI::Various::container>):

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

require Exporter;
our @ISA = qw(UI::Various::widget);
our @EXPORT_OK = qw();

#########################################################################

=item children [private]

a list with the children of the container UI element, which must not be
directly accessed (use C<L<child|/child - access children or iterate through
them>> for access and iteration, use C<L<children|/children - return number
of children>> to get their quantity and use C<L<add|/add - add new
children>> and C<L<remove|/remove - remove children>> for manipulation)

=cut

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS => qw();
use constant DEFAULT_ATTRIBUTES => (children => []);

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the common methods inherited from C<UI::Various::widget> the
following additional ones are available in all C<UI::Various::[A-Z]*>
container classes (UI elements containing other UI elements):

=cut

#########################################################################

=head2 B<new> - constructor

see L<UI::Various::core::construct|UI::Various::core/construct - common
constructor for UI elements>

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub new($;\[@$])
{
    return construct({ (DEFAULT_ATTRIBUTES) },
		     '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
		     @_);
}

#########################################################################

=head2 B<add> - add new children

    $ui_container->add($other_ui_element, ...);

=head3 example:

    $self->add($that);
    $self->add($foo, $bar);

=head3 parameters:

    $other_ui_element   one ore more UI elements to be added to container

=head3 description:

This method adds new children to a container element.  Note that children
already having a parent are removed from their old parent first.

=head3 returns:

number of elements added

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub add($@)
{
    my $self = shift;

    # sanity checks:
    $self->isa(__PACKAGE__)
	or  fatal('invalid_object__1_in_call_to__2__3',
		  ref($self), __PACKAGE__, 'add');

    local $_;
    my $n = 0;
    foreach (@_)
    {
	$_->isa('UI::Various::widget')
	    or  fatal('invalid_object__1_in_call_to__2__3',
		      ref($_), __PACKAGE__, 'add');
	my $parent = $_->parent();
	if (defined $parent)
	{
	    unless ($parent->remove($_))
	    {
		error('can_t_remove__1_from_old_parent__2', $_, $parent);
		return $n;
	    }
	}
	$_->parent($self);
	$n++;
    }
    defined $self->{children}  or  $self->{children} = [];
    push @{$self->{children}}, @_;
    return $n;
}

#########################################################################

=head2 B<remove> - remove children

    $ui_container->remove($other_ui_element, ...);

=head3 example:

    $self->remove($that);
    $self->remove($foo, $bar);

=head3 parameters:

    $other_ui_element   one ore more UI elements to be removed from container

=head3 description:

This method removes children from a container element.

=head3 returns:

the last node that has been removed or C<undef> if nothing could be removed

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub remove($@)
{
    my $self = shift;

    # sanity checks:
    $self->isa(__PACKAGE__)
	or  fatal('invalid_object__1_in_call_to__2__3',
		  ref($self), __PACKAGE__, 'remove');

    my $children = $self->{children};
    my $removed = undef;
    local $_;
 CHILD:
    foreach my $child (@_)
    {
	$child->isa('UI::Various::widget')
	    or  fatal('invalid_object__1_in_call_to__2__3',
		      ref($child), __PACKAGE__, 'remove');
	foreach (0..$#{$children})
	{
	    next unless $children->[$_] eq $child;
	    $removed = splice @{$children}, $_, 1;
	    # instead of: $child->parent(undef);
	    # we need direct assignment for Perl < 5.20 here:
	    $child->{parent} = undef;
	    defined $self->{_index}  and  $_ < $self->{_index}  and
		$self->{_index}--;
	    next CHILD;
	}
	return error('can_t_remove__1_no_such_node_in__2',
		     ref($child), ref($self));
    }
    return $removed;
}

#########################################################################

=head2 B<children> - return number of children

    $_ = $ui_container->children;

=head3 description:

This method returns the number of children a container element has.

=head3 returns:

number of children

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub children($)
{
    my $self = shift;
    return scalar(@{$self->{children}});
}

#########################################################################

=head2 B<child> - access children or iterate through them

    $ui_element = $ui_container->child($index);
    $ui_element = $ui_container->child();
    $ui_container->child(undef);

=head3 example:

    $ui_element = $self->child(0);
    while ($_ = $self->child())
    {
        ...
        if ($abort)
        {
            $self->child(undef);
            last;
	}
        ...
    }

=head3 parameters:

    $index              optional index for direct access,
                        C<undef> for reset of iterator

=head3 description:

When called with a (positive or negative) numeric index this method returns
the container's element at that index.  When called without parameter this
method iterates over all elements until the end, when it returns C<undef>
and automatically resets the iterator.  Calling the method with an explicit
C<undef> resets the iterator before it reaches the end.  An empty string
instead of C<undef> is also possible to allow avoiding Perl bugs #7508 and
#109726 in Perl versions prior to 5.20.

Note that removing takes care of keeping the index valid, so it's perfectly
possible to use a loop to remove some or all children of a container.

Note that each container object can only have one active iterator at any
time.

=head3 returns:

element at index or iterator, or C<undef> if not existing or at end of
iteration

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub child($;$)
{
    my ($self, $index) = @_;

    # sanity checks:
    $self->isa(__PACKAGE__)
	or  fatal('invalid_object__1_in_call_to__2__3',
		  ref($self), __PACKAGE__, 'child');

    local $_ = undef;
    # called with index:
    if (defined $index  and  $index ne '')
    {
	if ($index !~ m/^-?\d+$/)
	{
	    error('invalid_parameter__1_in_call_to__2__3',
		  $index, __PACKAGE__, 'child');
	}
	elsif (exists $self->{children}[$index])
	{   $_ = $self->{children}[$index];   }
	else
	{
	    # TODO: Do we really want this warning or is the empty $_ enough?
	    warning('no_element_found_for_index__1', $index);
	}
    }
    # called with undef -> reset iterator:
    elsif (exists $_[1])	# $index can't distinguish undef / missing!
    {
	defined $self->{_index}  and  delete $self->{_index};
    }
    # iterate:
    else
    {
	defined $self->{_index}  or  $self->{_index}=0;
	if (exists $self->{children}[$self->{_index}])
	{
	    $_ = $self->{children}[$self->{_index}];
	    $self->{_index}++;
	}
	else
	{   delete $self->{_index};   }
    }
    return $_;
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
