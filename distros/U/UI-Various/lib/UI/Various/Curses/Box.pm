package UI::Various::Curses::Box;

# Author, Copyright and License: see end of file

=head1 NAME

UI::Various::Curses::Box - concrete implementation of L<UI::Various::Box>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly via the following:
    use UI::Various::Box;

=head1 ABSTRACT

This module is the specific implementation of L<UI::Various::Box> using
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

our $VERSION = '0.37';

use UI::Various::core;
use UI::Various::Box;
use UI::Various::Curses::base;

require Exporter;
our @ISA = qw(UI::Various::Box UI::Various::Curses::base);
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
called from other C<UI::Various::Curses> container elements!>

Note that this implementation does not use an explicit C<Curses::Ui> element
as there does not exist something similar (and in tests C<Container> had
problems handling the focus correctly).  It just places its children at
linear distributed positions instead.

=head3 returns:

number of errors encountered

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sub _prepare($$$)
{
    my ($self, $row0, $column0) = @_;
    my ($rows, $columns) = ($self->rows, $self->columns);
    local $_ =  $self->parent;
    $self->_cui($_->_cui);

    # save explicit dimensions of whole box (we need to modify them so that
    # the children can inherit the correct values):
    my ($explicit_width, $explicit_height) = ($self->{width}, $self->{height});
    my $width = $self->width - $columns + 1;
    my $height = $self->height - $rows + 1;

    # place children:
    my ($errors, $row_off) = (0, 0);
    foreach my $row (0..($rows - 1))
    {
	$self->{height} = int($height / ($rows - $row));
	my ($max_height, $col_off) = (1, 0);
	foreach my $column (0..($columns - 1))
	{
	    # later columns may be 1 character wider:
	    $self->{width} = int(($width + $column) / $columns);
	    $_ = $self->field($row, $column);
	    if (defined $_)
	    {
		$errors += $_->_prepare($row0 + $row_off, $column0 + $col_off);
		my $h = $_->_cui->height;
		$max_height < $h  and  $max_height = $h;
	    }
	    $col_off += $self->{width} + 1;
	}
	$row_off += $max_height + 1;
	$height -= $max_height;
    }

    # create dummy Curses::UI element to get height back to caller:
    package Curses::UI::DummyBox {
	sub new {
	    my $self = shift;
	    $self = {@_};
	    bless $self, 'Curses::UI::DummyBox';
	}
	sub height {
	    my $self = shift;
	    return $self->{-height};
	}
	sub delete {
	    my ($self, $cid) = @_;
	    my $parent_cui = $self->{_various_ui}->parent->_cui;
	    $parent_cui->delete($cid);
	    return $self;	# do what Curses::UI::Container::delete does
	};
	# uncoverable statement
    };
    my $dummy_box = Curses::UI::DummyBox->new(-height => $row_off,
					      _various_ui => $self);
    $self->_cui($dummy_box);

    # restore explicit dimensions:
    if (defined $explicit_width)
    {   $self->{width} = $explicit_width;   }
    else
    {   delete $self->{width};   }
    if (defined $explicit_height)
    {   $self->{height} = $explicit_height;   }
    else
    {   delete $self->{height};   }

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
