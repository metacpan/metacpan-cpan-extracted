package Vector::Object3D::Point;

=head1 NAME

Vector::Object3D::Point - Three-dimensional point object definitions and operations

=head2 SYNOPSIS

  use Vector::Object3D::Point;

  use Readonly;
  Readonly my $pi => 3.14159;

  # Create an instance of a class:
  my $point = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
  my $point = Vector::Object3D::Point->new(coord => [-2, 2, 1]);

  # Create a new object as a copy of an existing object:
  my $copy = $point->copy;

  # Get current X coordinate value:
  my $x = $point->get_x;
  # Get current Y coordinate value:
  my $y = $point->get_y;
  # Get current Z coordinate value:
  my $z = $point->get_z;

  # Get current coordinate values on two-dimensional plane:
  my ($x, $y) = $point->get_xy;
  # Get current coordinate values in three-dimensional space:
  my ($x, $y, $z) = $point->get_xyz;

  # Get current coordinates as a matrix object:
  my $pointMatrix = $point->get_matrix;

  # Set new X coordinate value:
  $point->set_x($x);
  # Set new Y coordinate value:
  $point->set_y($y);
  # Set new Z coordinate value:
  $point->set_z($z);

  # Set new precision value (which is used while printing out data and comparing
  # the point object with others):
  my $precision = 2;
  $point->set(parameter => 'precision', value => $precision);

  # Get currently used precision value (undef indicates maximum possible precision
  # which is designated to the Perl core):
  my $precision = $point->get(parameter => 'precision');

  # Print out formatted point data:
  $point->print(fh => $fh, precision => $precision);

  # Move point a constant distance in a specified direction:
  my $point_translated = $point->translate(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

  # Enlarge, shrink or stretch point by a scale factor:
  my $point_scaled = $point->scale(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

  # Rotate point by a given angle around three rotation axis:
  my $point_rotated = $point->rotate(
    rotate_xy => 30 * ($pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

  # Project point onto a two-dimensional plane using an orthographic projection:
  my $point2D = $point->cast(type => 'parallel');

  # Project point onto a two-dimensional plane using a perspective projection:
  my $point2D = $point->cast(type => 'perspective', distance => 5);

  # Compare two point objects:
  my $are_the_same = $point1 == $point2;

=head1 DESCRIPTION

C<Vector::Object3D::Point> describes point object in a three-dimensional space, providing basic operations to manipulate, transform and cast its coordinates.

=head1 METHODS

=head2 new

Create an instance of a C<Vector::Object3D::Point> class:

  my $point = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
  my $point = Vector::Object3D::Point->new(coord => [-2, 2, 1]);

There are two individual means of C<Vector::Object3D::Point> object construction, provided a hash of individual components or a list of coordinates. When present, C<coord> constructor parameter takes precedence over individual coordinates in case both values are provided at the same time.

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use Moose;
with 'Vector::Object3D::Parameters';
with 'Vector::Object3D::Point::Cast';
with 'Vector::Object3D::Point::Transform';

use Vector::Object3D::Matrix;

use overload
    '==' => \&_comparison,
    '!=' => \&_negative_comparison;

has 'x' => (
    is       => 'rw',
    isa      => 'Num',
    reader   => 'get_x',
    required => 1,
    writer   => 'set_x',
);

has 'y' => (
    default  => undef,
    is       => 'rw',
    isa      => 'Maybe[Num]',
    reader   => 'get_y',
    required => 0,
    writer   => 'set_y',
);

has 'z' => (
    default  => undef,
    is       => 'rw',
    isa      => 'Maybe[Num]',
    reader   => 'get_z',
    required => 0,
    writer   => 'set_z',
);

sub build_default_parameter_values {
    my %parameter_values = (
        precision => undef,
    );

    return \%parameter_values;
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $coord = $args{coord};

    if (defined $coord and ref $coord eq 'ARRAY') {
        my @fields = @{$coord} == 2 ? qw(x y) : qw(x y z);
        @args{@fields} = @{$coord};
    }

    return $class->$orig(%args);
};

=head2 copy

Create a new C<Vector::Object3D::Point> object as a copy of an existing object:

  my $copy = $point->copy;

=cut

sub copy {
    my ($self) = @_;

    my @coord = $self->get_xyz;

    my $class = $self->meta->name;
    my $copy = $class->new(coord => \@coord);

    my %parameter_values = $self->get_parameter_values;

    while (my ($param, $value) = each %parameter_values) {
        $copy->set(parameter => $param, value => $value);
    }

    return $copy;
}

=head2 get_x

Get current X coordinate value:

  my $x = $point->get_x;

=head2 get_y

Get current Y coordinate value:

  my $y = $point->get_y;

=head2 get_z

Get current Z coordinate value:

  my $z = $point->get_z;

=head2 get_xy

Get current coordinate values on two-dimensional plane:

  my ($x, $y) = $point->get_xy;

Note these values are not casted, they are the actual coordinate values that were used to initialize an object. See description of the C<cast> method for details about point projection onto a two-dimensional plane.

=cut

sub get_xy {
    my ($self) = @_;

    my $x = $self->get_x;
    my $y = $self->get_y;

    return ($x, $y);
}

=head2 get_xyz

Get current coordinate values in three-dimensional space:

  my ($x, $y, $z) = $point->get_xyz;

=cut

sub get_xyz {
    my ($self) = @_;

    my $x = $self->get_x;
    my $y = $self->get_y;
    my $z = $self->get_z;

    return ($x, $y, $z);
}

=head2 get_matrix

Get current coordinates as a matrix object:

  my $pointMatrix = $point->get_matrix;

=cut

sub get_matrix {
    my ($self) = @_;

    my @xyz = defined $self->get_z ? $self->get_xyz : $self->get_xy;

    my $pointMatrix = Vector::Object3D::Matrix->new(rows => [[ @xyz ]]);

    return $pointMatrix;
}

=head2 set_x

Set new X coordinate value:

  $point->set_x($x);

=head2 set_y

Set new Y coordinate value:

  $point->set_y($y);

=head2 set_z

Set new Z coordinate value:

  $point->set_z($z);

=head2 set

Set new precision value (which is used while comparing point objects with each other):

  my $precision = 2;
  $point->set(parameter => 'precision', value => $precision);

=head2 get

Get currently used precision value (undef indicates maximum possible precision which is designated to the Perl core):

  my $precision = $point->get(parameter => 'precision');

=head2 print

Print out text-formatted point data (which might be, for instance, useful for debugging purposes):

  $point->print(fh => $fh, precision => $precision);

C<fh> defaults to the standard output. C<precision> is intended for internal use by string format specifier that outputs individual point coordinates as decimal floating points, and defaults to 2.

=cut

sub print {
    my ($self, %args) = @_;

    my $pointMatrix = $self->get_matrix;
    $pointMatrix->print(%args);

    return;
}

=head2 rotate

Rotate point by a given angle around three rotation axis:

  my $point_rotated = $point->rotate(
    rotate_xy => 30 * ($pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

=head2 scale

Enlarge, shrink or stretch point by a scale factor:

  my $point_scaled = $point->scale(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

Non-uniform scaling (anisotropic scaling), obtained when at least one of the scaling factors is different from the others, is allowed.

=head2 translate

Move point a constant distance in a specified direction:

  my $point_translated = $point->translate(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

=head2 cast

Project point onto a two-dimensional plane using an orthographic projection:

  my $point2D = $point->cast(type => 'parallel');

Project point onto a two-dimensional plane using a perspective projection:

  my $point2D = $point->cast(type => 'perspective', distance => 5);

=head2 compare (==)

Compare two point objects:

  my $are_the_same = $point1 == $point2;

Overloaded comparison operator evaluates to true whenever two point objects are identical (all their coordinates are exactly the same).

=cut

sub _comparison {
    my ($self, $arg) = @_;

    # Get compare precision for both points:
    my $precision1 = $self->get(parameter => 'precision');
    $precision1 = defined $precision1 ? '.' . $precision1 : '';
    my $precision2 = $arg->get(parameter => 'precision');
    $precision2 = defined $precision2 ? '.' . $precision2 : '';

    my @coordinates1 = $self->get_xyz;
    my @coordinates2 = $arg->get_xyz;

    for (my $i = 0; $i < @coordinates1; $i++) {
        my $coordinate_value = $coordinates1[$i] || 0;
        my $val1 = sprintf qq{%${precision1}f}, $coordinate_value;
        $val1 =~ s/^(.*\..*?)0*$/$1/;
        $val1 =~ s/\.$//;

        $coordinate_value = $coordinates2[$i] || 0;
        my $val2 = sprintf qq{%${precision2}f}, $coordinate_value;
        $val2 =~ s/^(.*\..*?)0*$/$1/;
        $val2 =~ s/\.$//;

        return 0 if $val1 ne $val2;
    }

    return 1;
}

=head2 negative compare (!=)

Compare two point objects:

  my $are_not_the_same = $point1 != $point2;

Overloaded negative comparison operator evaluates to true whenever two point objects differ (any of their coordinates do not match).

=cut

sub _negative_comparison {
    my ($self, $arg) = @_;

    return not $self->_comparison($arg);
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Vector::Object3D::Point> exports nothing neither by default nor explicitly.

=head1 SEE ALSO

L<Vector::Object3D>, L<Vector::Object3D::Line>, L<Vector::Object3D::Parameters>, L<Vector::Object3D::Point::Cast>, L<Vector::Object3D::Point::Transform>, L<Vector::Object3D::Polygon>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.01 (2012-12-24)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Pawel Krol.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;
