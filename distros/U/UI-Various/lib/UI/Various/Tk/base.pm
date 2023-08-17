package UI::Various::Tk::base;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Tk::base - abstract helper class for Tk's UI elements

=head1 SYNOPSIS

    # This module should only be used by the UI::Various::Tk UI
    # element classes!

=head1 ABSTRACT

This module provides some helper functions for the UI elements of the
Perl/Tk GUI.

=head1 DESCRIPTION

The documentation of this module is only intended for developers of the
package itself.

All functions of the module will be included as second "base class" (in
C<@ISA>).  Note that this is not a diamond pattern as this "base class" does
not import anything besides C<Exporter>, though it add a common private
attribute to all C<UI::Various::Tk> classes:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.40';

use UI::Various::core;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

#########################################################################

=item B<_tk> [rw, optional]

a reference to the main Perl/Tk element used for the implementation of the
UI element

Note that usually this should only be used within C<UI::Various::Tk>.

=cut

sub _tk($;$)
{   return access('_tk', undef, @_);   }

#########################################################################
#########################################################################

=back

=head1 METHODS

The module also provides the following common (internal) methods for all
UI::Various::Tk UI element classes:

=cut

#########################################################################

=head2 B<_attributes> - return common attributes of UI element

    my @attributes = $self->_attributes();

=head3 description:

This method determines returns all defined common attributes of a UI element
in the representation needed by L<Tk> (as key / value pairs).  It returns an
array, that could be empty, as all common attributes are optional.

Note that certain L<Tk> widgets ignore some of the L<options|Tk::options>
returned here.

=head3 returns:

array of all defined common attributes in L<Tk> representation

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

my @alignment = ([],
		 ['-justify' => 'left',   '-anchor' => 'sw'],	# 1
		 ['-justify' => 'center', '-anchor' => 's'],	# 2
		 ['-justify' => 'right',  '-anchor' => 'se'],	# 3
		 ['-justify' => 'left',	  '-anchor' => 'w'],	# 4
		 ['-justify' => 'center'],			# 5
		 ['-justify' => 'right',  '-anchor' => 'e'],	# 6
		 ['-justify' => 'left',	  '-anchor' => 'nw'],	# 7
		 ['-justify' => 'center', '-anchor' => 'n'],	# 8
		 ['-justify' => 'right',  '-anchor' => 'ne']);	# 9
sub _attributes($)
{
    my ($self) = @_;
    my @attributes = ();
    if (defined $self->{align})
    {   push @attributes, @{$alignment[$self->{align}]};   }
    if (defined $self->{height})
    {   push @attributes, '-height', $self->{height};   }
    if (defined $self->{width})
    {
	push @attributes, '-width',  $self->{width};
	if (ref($self) =~ m/::(?:Button|Check|Radio|Text)/)
	{
	    # FIXME: The assignment should return a reasonable value, but
	    # something is still calculated wrong:
	    local $_ = $self->{width} * $self->top->{_char_avg_width};
	    push @attributes, '-wraplength', int($_ / 2);
	}
    }
    return @attributes;
}

#########################################################################

=head2 B<_cleanup> - cleanup UI element

    $ui_element->cleanup;

=head3 description:

This method prepares a UI element for destruction by removing all of the
references it is holding (including its parent reference).  An object will
therefore only survive if it is additionally still referenced outside of
C<L<UI::Various>>, e.g. a variable used to create it in the first place.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _cleanup($)
{
    my ($self) = @_;

    # We recursively remove our references to Perl/Tk objects first in order
    # to ease the internal cleanup for Perl/Tk itself:
    if ($self->can('remove')  and  $self->can('child'))
    {
	local $_;
	while ($_ = $self->child)
	{   $_->_cleanup;   }
    }

    if ($self->{_tk})
    {
	if (ref($self->{_tk}) eq 'ARRAY')
	{
	    local $_;
	    # explicitly dereference each array ( GUI) element:
	    $_ = undef foreach (@{$self->{_tk}});
	}
	delete $self->{_tk};
    }

    $self->parent->remove($self);
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
