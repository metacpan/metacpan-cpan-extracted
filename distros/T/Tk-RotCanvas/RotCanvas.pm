package Tk::RotCanvas;

use vars qw/$VERSION/;
$VERSION = 1.2;

use Tk::widgets qw/Canvas/;
use base qw/Tk::Derived Tk::Canvas/;

use strict;
use Carp;

Construct Tk::Widget 'RotCanvas';

sub ClassInit {
    my $class = shift;

    $class->SUPER::ClassInit(@_);
}

sub Populate {
    my ($self, $args) = @_;

    $self->SUPER::Populate($args);
}

my %_cant_handle = (
		    bitmap => 1,
		    image  => 1,
		    arc    => 1,
		    text   => 1,
		    window => 1,
		   );

my %_rotate_methods = (
		       line      => \&_rotate_line,
		       polygon   => \&_rotate_poly,
		       oval      => \&_rotate_poly,
		      );

use constant PI => 3.14159269;

# This is the new rotate() method. It takes as input the
# id of the object to rotate, and the angle to rotate it with.
# It then rotates the object about its center by the given angle

sub rotate {
    my ($self, $id, $angle, $x, $y) = @_;

    unless (defined $angle) {
	croak "rotate: Must supply an angle -";
    }

    # Get the current coordinates of the object.
    my $type = $self->type($id);

    # For now, I don't know how to handle some of these!
    if (exists $_cant_handle{$type}) {
	croak "rotate: Can't handle objects of type '$type' yet -";
    }

    $_rotate_methods{$type}->($self, $id, $angle, $x, $y);
}

sub _rotate_line {
    my ($self, $id, $angle, $midx, $midy) = @_;

    # Get the old coordinates.
    my @coords = $self->coords($id);

    # If the center of rotation is not given, get the default.
    # Get the center of the line. We use this to translate the
    # above coords back to the origin, and then rotate about
    # the origin, then translate back.

    unless (defined $midx) {
	$midx = $coords[0] + 0.5*($coords[2] - $coords[0]);
	$midy = $coords[1] + 0.5*($coords[3] - $coords[1]);
    }

    my @new;

    # Precalculate the sin/cos of the angle, since we'll call
    # them a few times.
    my $rad = PI*$angle/180;
    my $sin = sin $rad;
    my $cos = cos $rad;

    # Calculate the new coordinates of the line.
    while (my ($x, $y) = splice @coords, 0, 2) {
	my $x1 = $x - $midx;
	my $y1 = $y - $midy;

	push @new => $midx + ($x1 * $cos - $y1 * $sin);
	push @new => $midy + ($x1 * $sin + $y1 * $cos);
    }

    # Redraw the line.
    $self->coords($id, @new);
}

sub _rotate_poly {
    my ($self, $id, $angle, $midx, $midy) = @_;

    # Get the old coordinates.
    my @coords = $self->coords($id);

    # Get the center of the poly. We use this to translate the
    # above coords back to the origin, and then rotate about
    # the origin, then translate back. (old)

    ($midx, $midy) = _get_CM(@coords) unless defined $midx;

    my @new;

    # Precalculate the sin/cos of the angle, since we'll call
    # them a few times.
    my $rad = PI*$angle/180;
    my $sin = sin $rad;
    my $cos = cos $rad;

    # Calculate the new coordinates of the line.
    while (my ($x, $y) = splice @coords, 0, 2) {
	my $x1 = $x - $midx;
	my $y1 = $y - $midy;

	push @new => $midx + ($x1 * $cos - $y1 * $sin);
	push @new => $midy + ($x1 * $sin + $y1 * $cos);
    }

    # Redraw the poly.
    $self->coords($id, @new);
}

# We have to intercept any calls to createRectangle and
# create('rectangle') and call createPolygon instead.

sub createRectangle {
    my $self = shift;

    $self->_rect_to_poly(@_);
}

sub create {
    my $self = shift;

    my $type = shift;

    if ($type eq 'rectangle') {
	$self->_rect_to_poly(@_);
    } elsif ($type eq 'oval') {
	$self->_oval_to_poly(@_);
    } else {
	$self->SUPER::create($type, @_);
    }
}

sub createOval {
    my $self = shift;
    $self->_oval_to_poly(@_);
}

# This sub transforms the rectangle coords to poly coords.
sub _rect_to_poly {
    my $self = shift;

    my ($x1, $y1, $x2, $y2) = splice @_ => 0, 4;

    $self->createPolygon(
			 $x1, $y1,
			 $x2, $y1,
			 $x2, $y2,
			 $x1, $y2,
			 @_,
			);
}

sub _oval_to_poly {
    my $self = shift;

    my ($x1, $y1, $x2, $y2) = splice @_ => 0, 4;

    my $steps = 100;
    my $xc = ($x2 - $x1) / 2;
    my $yc = ($y2 - $y1) / 2;
    my @pointlist;

    for my $i (0..$steps) {
	my $theta = (PI * 2)* ($i / $steps);
	my $x = $xc * cos($theta) - $xc + $x2;
	my $y = $yc * sin($theta) + $yc + $y1;
	push(@pointlist, $x, $y);
    }

    push(@_, '-fill', undef)      unless grep {/-fill/   } @_;
    push(@_, '-outline', 'black') unless grep {/-outline/} @_;

    $self->createPolygon(@pointlist, @_);
}

# This sub finds the center of mass of a polygon.
# I grabbed the algorithm somewhere from the web.
sub _get_CM {
    my ($x, $y, $area);

    my $i = 0;

    while ($i < $#_) {
	my $x0 = $_[$i];
	my $y0 = $_[$i+1];

	my ($x1, $y1);
	if ($i+2 > $#_) {
	    $x1 = $_[0];
	    $y1 = $_[1];
	} else {
	    $x1 = $_[$i+2];
	    $y1 = $_[$i+3];
	}

	$i += 2;

	my $a1 = 0.5*($x0 + $x1);
	my $a2 = ($x0**2 + $x0*$x1 + $x1**2)/6;
	my $a3 = ($x0*$y1 + $y0*$x1 + 2*($x1*$y1 + $x0*$y0))/6;
	my $b0 = $y1 - $y0;

	$area += $a1 * $b0;
	$x    += $a2 * $b0;
	$y    += $a3 * $b0;
    }

    return split ' ', sprintf "%.0f %0.f" => $x/$area, $y/$area;
}

1;

__END__

=head1 NAME

Tk::RotCanvas - Canvas widget with arbitrary rotation support

=for category Tk Widget Classes

=head1 SYNOPSIS

    $canvas = $parent->RotCanvas(?options?);
    my $obj = $canvas->create('polygon', @coords, %options);
    $canvas->rotate($obj, $angle, ?x, y?);

=head1 DESCRIPTION

This module is a small wrapper around the C<Canvas> widget that adds a
new rotate() method. This method allows the rotation of various canvas
objects by arbitrary angles.

=head1 NEW METHODS

As mentioned previously, there is only one new method. All other canvas
methods work as expected.

=over 4

=item I<$canvas>-E<gt>B<rotate>(I<TagOrID, angle> ?,I<x, y>?)

This method rotates the object identified by TagOrID by an angle I<angle>.
The angle is specified in I<degrees>. If a coordinate is specified, then
the object is rotated about that point. Else, the object is rotated
about its center of mass.

=back

=head1 LIMITATIONS

As it stands, the module can only handle the following object types:

=over 4

=item *

Lines

=item *

Rectangles

=item *

Polygons

=item *

Ovals

=back

All other object types (bitmap, image, arc, text and window) can
not be handled yet. A warning is issued if the user tries to rotate one
of these object types. Hopefully, more types will be handled in the future.

=head1 MORE DETAILS YOU DON'T NEED TO KNOW

To be able to handle rectangles, the module intercepts any calls to
B<createRectangle()> and B<create()> and changes all rectangles to polygons.
The user should not be alarmed if B<type()> returned I<polygon> when a
I<rectangle> was expected.

Similarly, ovals are converted into polygons.

=head1 THANKS

Special thanks go to Larry Shatzer for developing the code to handle ovals.

=head1 AUTHOR

Ala Qumsieh I<qumsieh@cim.mcgill.ca>

=head1 COPYRIGHTS

This module is distributed under the same terms as Perl itself.

=cut
