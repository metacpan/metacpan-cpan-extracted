package UI::Various::Box;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Box - general box widget of L<UI::Various>

=head1 SYNOPSIS

    use UI::Various;
    my $main = UI::Various::main();
    my $box = UI::Various::Box(border => 1, columns => 2, rows => 3);
    $box->add(0, 0, UI::Various::Text->new(text => 'Hello World!'));
    ...
    $box->add(2, 1, UI::Various::Button->new(text => 'Quit',
                                             code => sub{ exit(); }));
    $main->window($box);
    $main->mainloop();

=head1 ABSTRACT

This module defines a general box object of an application using
L<UI::Various>.  A box is a container with rows and columns, where each
field can contain exactly one other UI element.  If more than one UI element
must be placed in a field, simply put them in another box inside of it.

Note that the L<UI::Various::PoorTerm> implementation does not display a box
but simply prints the fields one after another, as that makes it easier to
understand for the visually impaired or software parsing the output.  Also
note that a box in C<PoorTerm> is always considered to be an active element,
but its own active elements can only be selected after selecting the box
itself first.  (Exception: If a box contains only one own active element, it
is selected directly.)

=head1 DESCRIPTION

Besides the common attributes inherited from C<UI::Various::widget> and
C<UI::Various::container> the C<box> widget knows the following additional
attributes:

=head2 Attributes

=over

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

our $VERSION = '0.23';

use UI::Various::core;
use UI::Various::toplevel;
BEGIN  {  require 'UI/Various/' . UI::Various::core::using() . '/Box.pm';  }

require Exporter;
our @ISA = qw(UI::Various::container);
our @EXPORT_OK = qw();

#########################################################################

=item border [rw, optional]

a flag to indicate if the borders around the box and between its elements
are visible or not

A reference passed will be dereferenced and all values will be normalised to
C<0> or C<1> according Perl's standard true/false conversions.

Note that visible borders currently do not work in L<Curses::UI> as they
currently do not use a proper L<Curses::UI> element.

=cut

sub border($;$)
{
    return access('border',
		  sub{   $_ = $_ ? 1 : 0;   },
		  @_);
}

=item columns [rw, recommended]

the number of columns the box contains (numbering starts with 0)

=cut

sub columns($;$)
{
    return access('columns',
		  sub{
		      unless (m/^\d+$/  and  $_ > 0)
		      {
			  error('parameter__1_must_be_a_positive_integer',
				'columns');
			  $_ = 1;
		      }
		  },
		  @_);
}

=item rows [rw, recommended]

the number of rows the box contains (numbering starts with 0)

=cut

sub rows($;$)
{
    return access('rows',
		  sub{
		      unless (m/^\d+$/  and  $_ > 0)
		      {
			  error('parameter__1_must_be_a_positive_integer',
				'rows');
			  $_ = 1;
		      }
		  },
		  @_);
}

#########################################################################
#
# internal constants and data:

use constant ALLOWED_PARAMETERS =>
    (UI::Various::widget::COMMON_PARAMETERS, qw(border columns rows));
use constant DEFAULT_ATTRIBUTES => (border => 0, columns => 1, rows => 1);

#########################################################################
#########################################################################

=back

=head1 METHODS

Besides the accessors (attributes) described above and the attributes and
methods of L<UI::Various::widget> and L<UI::Various::container>, the
following additional methods are provided by the C<Box> class itself (note
the overloaded L<add|/add - add new children> method):

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
    return construct({ DEFAULT_ATTRIBUTES },
		     '^(?:' . join('|', ALLOWED_PARAMETERS) . ')$',
		     @_);
}

#########################################################################

=head2 B<field> - access child in specific field

    $ui_element = $box->field($row, $column);

=head3 example:

    $element_1 = $box->field(0, 0);

=head3 parameters:

    $row                the UI element's row
    $column             the UI element's column

=head3 description:

This method allows accessing the UI element of a specific field of the box.

=head3 returns:

the UI element in the specified field of the box

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub field($$$)
{
    my ($self, $row, $column) = @_;
    exists $self->{field}  or  return undef;
    return $self->{field}[$row][$column];
}

#########################################################################

=head2 B<add> - add new children

    $ui_container->add([$row, [$column,]] $other_ui_element, ...);

=head3 example:

    # example box using 2x2 fields:
    $self->add(0, 0, $this);
    $self->add($that);              # using next free position 0, 1
    $self->add(1, 0, $foo, 1, 1, $bar);
    $self->add(1, 0, $foo, $bar);   # the same but shorter

    # first three example commands combined in one using defaults:
    $self->add($this, $that, $foo, $bar);

=head3 parameters:

    $row                the row of the box for the next UI element
    $column             the column of the box for the next UI element
    $other_ui_element   one ore more UI elements to be added to the box

=head3 description:

This method overloads the standard L<add method of
UI::Various::container|UI::Various::container/add - add new children>.  It
adds one or more to the box.  If a specific field is given (row and column),
this is used (unless it already contains something which produces an error).
Otherwise the next free field after the "current" one in the same or a later
row is used.  Both row and column start counting with C<0>.  Basically the
algorithm fills a box row by row from left to right.  If a UI element can
not be placed, this is reported as error and the UI element is ignored.

Note that as in the standard L<add method of
UI::Various::container|UI::Various::container/add - add new children>
children already having a parent are removed from their old parent first.

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
    unless (defined $self->{field})
    {
	$self->{field} = [];
	push @{$self->{field}}, [(undef) x $self->columns]
	    foreach 1..$self->rows;
    }
    my ($row, $column, $number, $n) = (0, 0, 0, 0);
    while (@_)
    {
	$_ = shift;
	if (ref($_) eq '')
	{
	    unless ($number < 2)
	    {
		error('invalid_scalar__1_in_call_to__2__3',
		      $_, __PACKAGE__, 'add');
		return $n;
	    }
	    unless (m/^\d+$/)
	    {
		error('parameter__1_must_be_a_positive_integer_in_call_to__2__3',
		      $number == 0 ? 'row' : 'column', __PACKAGE__, 'add');
		return $n;
	    }
	    unless ($_ < ($number == 0 ? $self->rows : $self->columns))
	    {
		error('invalid_value__1_for_parameter__2_in_call_to__3__4',
		      $_, $number == 0 ? 'row' : 'column', __PACKAGE__, 'add');
		return $n;
	    }
	    if ($number++ == 0)
	    {   $row = $_;   $column = 0;   }
	    else
	    {   $column = $_;   }
	}
	elsif ($_->isa('UI::Various::widget'))
	{
	    if ($number > 1  and  defined $self->{field}[$row][$column])
	    {
		error('element__1_in_call_to__2__3_already_exists',
		      $row . '/' . $column, __PACKAGE__, 'add');
		# reset "scanner" to continue after failed explicit row/column:
		$number = 0;
		next;
	    }
	    # find next free field:
	    while (defined $self->{field}[$row][$column])
	    {
		unless (++$column < $self->columns)
		{
		    $column = 0;
		    ++$row < $self->rows  or  last;
		}
	    }
	    unless ($row < $self->rows)
	    {
		error('no_free_position_for__1_in_call_to__2__3',
		      ref($_), __PACKAGE__, 'add');
		($row, $column, $number) = (0, 0, 0);
		next;
	    }
	    if ($self->SUPER::add($_))
	    {
		$self->{field}[$row][$column] = $_;
		$n++;
	    }
	    $number = 0;	# reset "scanner" for explicit row/column
	}
	else
	{
	    fatal('invalid_object__1_in_call_to__2__3',
		  ref($_), __PACKAGE__, 'add');
	}
    }
    return $n;
}

#########################################################################

=head2 B<remove> - remove children

This method overloads the standard L<remove method of
UI::Various::container|UI::Various::container/remove - remove children>
using the identical interface.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub remove($@)
{
    my $self = shift;

    my $removed = undef;
    foreach my $child (@_)
    {
	if (defined $self->SUPER::remove($child))
	{
	    my $row = $self->rows;
	    while (--$row >= 0)
	    {
		my $column = $self->columns;
		while (--$column >= 0)
		{
		    if (defined   $self->{field}[$row][$column]  and
			$child eq $self->{field}[$row][$column])
		    {
			$self->{field}[$row][$column] = undef;
			$removed = $child;
		    }
		}
	    }
	}
    }
    return $removed;
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
