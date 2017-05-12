package Vector::Object3D::Polygon;

=head1 NAME

Vector::Object3D::Polygon - Three-dimensional polygon object definitions and operations

=head2 SYNOPSIS

  use Vector::Object3D::Polygon;

  # Create polygon vertices:
  my $vertex1 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
  my $vertex2 = Vector::Object3D::Point->new(x => 3, y => -1, z => -2);
  my $vertex3 = Vector::Object3D::Point->new(x => 2, y => 1, z => 1);

  # Create an instance of a class:
  my $polygon = Vector::Object3D::Polygon->new(vertices => [$vertex1, $vertex2, $vertex3]);

  # Create a new object as a copy of an existing object:
  my $copy = $polygon->copy;

  # Get number of polygon vertices:
  my $num_vertices = $polygon->num_vertices;

  # Get index of last polygon vertex:
  my $last_vertex_index = $polygon->last_vertex_index;

  # Get first vertex point:
  my $vertex1 = $polygon->get_vertex(index => 0);

  # Get last vertex point:
  my $vertexn = $polygon->get_vertex(index => $last_vertex_index);

  # Get all vertex points:
  my @vertices = $polygon->get_vertices;

  # Get polygon data as a set of line objects connecting vertices in construction order:
  my @lines = $polygon->get_lines;

  # Print out formatted polygon data:
  $polygon->print(fh => $fh, precision => $precision);

  # Move polygon a constant distance in a specified direction:
  my $polygon_translated = $polygon->translate(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

  # Enlarge, shrink or stretch polygon by a scale factor:
  my $polygon_scaled = $polygon->scale(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

  # Rotate polygon by a given angle around three rotation axis:
  my $polygon_rotated = $polygon->rotate(
    rotate_xy => 30 * ($pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

  # Project polygon onto a two-dimensional plane using an orthographic projection:
  my $polygon2D = $polygon->cast(type => 'parallel');

  # Project polygon onto a two-dimensional plane using a perspective projection:
  my $distance = 5;
  my $polygon2D = $polygon->cast(type => 'perspective', distance => $distance);

  # Check whether polygon's plane is visible to the observer:
  my $observer = Vector::Object3D::Point->new(x => 0, y => 0, z => $distance);
  my $is_plane_visible = $polygon->is_plane_visible(observer => $observer);

  # Get point coordinates located exactly in the middle of a polygon's plane:
  my $middle_point = $polygon->get_middle_point;

  # Get vector normal to a polygon's plane:
  my $normal_vector = $polygon->get_normal_vector;
  my $normal_vector = $polygon->get_orthogonal_vector;

  # Compare two polygon objects:
  my $are_the_same = $polygon1 == $polygon2;

=head1 DESCRIPTION

C<Vector::Object3D::Polygon> provides an abstraction layer for describing polygon object in a three-dimensional space by composing it from any number of C<Vector::Object3D::Point> objects (referred onwards as vertices).

=head1 METHODS

=head2 new

Create an instance of a C<Vector::Object3D::Polygon> class:

  my $vertex1 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);
  my $vertex2 = Vector::Object3D::Point->new(x => 3, y => -1, z => -2);
  my $vertex3 = Vector::Object3D::Point->new(x => 2, y => 1, z => 1);

  my $polygon = Vector::Object3D::Polygon->new(vertices => [$vertex1, $vertex2, $vertex3]);

C<Vector::Object3D::Polygon> requires provision of at least three endpoints in order to successfully construct an object instance, there is no exception from this rule. Furthermore, it is assumed that all vertex points are located on the same plane. This rule is neither enforced nor validated, however this assumption impacts all related calculations, i.a. normal vector computation.

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use Moose;

use Carp qw(croak);
use Math::VectorReal;
use Scalar::Util qw(looks_like_number);
use Vector::Object3D::Point;

use overload
    '==' => \&_comparison,
    '!=' => \&_negative_comparison;

has 'vertices' => (
    is       => 'ro',
    isa      => 'ArrayRef[Vector::Object3D::Point]',
    reader   => '_get_vertices',
    required => 1,
);

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $vertices_orig = $args{vertices};

    my @vertices_copy;

    if (defined $vertices_orig and ref $vertices_orig eq 'ARRAY') {

        for my $vertex (@{$vertices_orig}) {
            push @vertices_copy, $vertex->copy;
        }
    }

    $args{vertices} = \@vertices_copy;

    return $class->$orig(%args);
};

sub BUILD {
    my ($self) = @_;

    my $num_vertices = $self->num_vertices;

    if ($num_vertices < 3) {
        croak qq{Insufficient number of vertices used to initialize polygon object: $num_vertices (expected at least 3 points)};
    }

    my $num_2D_vertices = $self->_count_2D_vertices;
    my $num_3D_vertices = $self->_count_3D_vertices;

    if ($num_2D_vertices > 0 && $num_3D_vertices > 0) {
        croak qq{Initializing polygon object with mixed-up 2D/3D point coordinates: ${num_2D_vertices} 2D vertices and ${num_3D_vertices} 3D vertices (expected more consistent approach)};
    }

    return;
}

=head2 copy

Create a new C<Vector::Object3D::Polygon> object as a copy of an existing object:

  my $copy = $polygon->copy;

=cut

sub copy {
    my ($self) = @_;

    my $vertices = $self->_get_vertices;

    my $class = $self->meta->name;
    my $copy = $class->new(vertices => $vertices);

    return $copy;
}

=head2 num_vertices

Get number of polygon vertices:

  my $num_vertices = $polygon->num_vertices;

=cut

sub num_vertices {
    my ($self) = @_;

    my $vertices = $self->_get_vertices;

    return scalar @{$vertices};
}

sub _count_2D_vertices {
    my ($self) = @_;

    my $check = sub {
        my ($vertex) = @_;

        return not defined $vertex->get_z;
    };

    return $self->_count_vertices($check);
}

sub _count_3D_vertices {
    my ($self) = @_;

    my $check = sub {
        my ($vertex) = @_;

        return defined $vertex->get_z;
    };

    return $self->_count_vertices($check);
}

sub _count_vertices {
    my ($self, $check) = @_;

    my @vertices = $self->get_vertices;

    my $count = grep { $check->($_) } @vertices;

    return $count;
}

=head2 last_vertex_index

Get index of last polygon vertex:

  my $last_vertex_index = $polygon->last_vertex_index;

=cut

sub last_vertex_index {
    my ($self) = @_;

    my $vertices = $self->_get_vertices;

    return $#{$vertices};
}

=head2 get_vertex

Get C<$n>-th vertex point, where C<$n> is expected to be any number between first and last vertex index:

  my $vertexn = $polygon->get_vertex(index => $n);

=cut

sub get_vertex {
    my ($self, %args) = @_;

    my $index = $args{index};

    unless (looks_like_number $index) {
        croak qq{Unable to get vertex point with a non-numeric index value: $index};
    }

    if ($index < 0) {
        croak qq{Unable to get vertex point with index value below acceptable range: $index};
    }

    if ($index > $self->last_vertex_index) {
        croak qq{Unable to get vertex point with index value beyond acceptable range: $index};
    }

    my @vertices = $self->get_vertices;

    return $vertices[$index];
}

=head2 get_vertices

Get all vertex points:

  my @vertices = $polygon->get_vertices;

=cut

sub get_vertices {
    my ($self) = @_;

    my $vertices = $self->_get_vertices;

    return map { $_->copy } @{$vertices};
}

=head2 get_lines

Get polygon data as a set of line objects connecting vertices in construction order:

  my @lines = $polygon->get_lines;

=cut

sub get_lines {
    my ($self) = @_;

    my $vertices = $self->_get_vertices;

    my $last_vertex_index = $self->last_vertex_index;

    my @lines;

    for (my $i = 0; $i <= $last_vertex_index; $i++) {

        my @endpoints = ($vertices->[$i]);

        if ($i == $last_vertex_index) {
            push @endpoints, $vertices->[0];
        }
        else {
            push @endpoints, $vertices->[$i + 1];
        }

        my $line = Vector::Object3D::Line->new(vertices => \@endpoints);

        push @lines, $line;
    }

    return @lines;
}

=head2 print

Print out text-formatted polygon data (which might be, for instance, useful for debugging purposes):

  $polygon->print(fh => $fh, precision => $precision);

C<fh> defaults to the standard output. C<precision> is intended for internal use by string format specifier that outputs individual point coordinates as decimal floating points, and defaults to 2 (unless adjusted individually for each vertex).

=cut

sub print {
    my ($self, %args) = @_;

    my $vertices = $self->_get_vertices;

    for my $vertex (@{$vertices}) {

        $vertex->print(%args);
    }

    return;
}

=head2

Move polygon a constant distance in a specified direction:

  my $polygon_translated = $polygon->translate(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

=cut

sub translate {
    my ($self, %args) = @_;

    my $vertices = $self->_get_vertices;

    my @new_vertices;

    for my $vertex (@{$vertices}) {

        push @new_vertices, $vertex->translate(%args);
    }

    my $polygon_translated = $self->new(vertices => \@new_vertices);

    return $polygon_translated;
}

=head2

Enlarge, shrink or stretch polygon by a scale factor:

  my $polygon_scaled = $polygon->scale(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

=cut

sub scale {
    my ($self, %args) = @_;

    my $vertices = $self->_get_vertices;

    my @new_vertices;

    for my $vertex (@{$vertices}) {

        push @new_vertices, $vertex->scale(%args);
    }

    my $polygon_scaled = $self->new(vertices => \@new_vertices);

    return $polygon_scaled;
}

=head2

Rotate polygon by a given angle around three rotation axis:

  my $polygon_rotated = $polygon->rotate(
    rotate_xy => 30 * ($pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

=cut

sub rotate {
    my ($self, %args) = @_;

    my $vertices = $self->_get_vertices;

    my @new_vertices;

    for my $vertex (@{$vertices}) {

        push @new_vertices, $vertex->rotate(%args);
    }

    my $polygon_rotated = $self->new(vertices => \@new_vertices);

    return $polygon_rotated;
}

=head2

Project polygon onto a two-dimensional plane using an orthographic projection:

  my $polygon2D = $polygon->cast(type => 'parallel');

Project polygon onto a two-dimensional plane using a perspective projection:

  my $distance = 5;
  my $polygon2D = $polygon->cast(type => 'perspective', distance => $distance);

=cut

sub cast {
    my ($self, %args) = @_;

    my $vertices = $self->_get_vertices;

    my @new_vertices;

    for my $vertex (@{$vertices}) {

        push @new_vertices, $vertex->cast(%args);
    }

    my $polygon_casted = $self->new(vertices => \@new_vertices);

    return $polygon_casted;
}

=head2

Check whether polygon's plane is visible to the observer located at the given point:

  my $observer = Vector::Object3D::Point->new(x => 0, y => 0, z => 5);
  my $is_plane_visible = $polygon->is_plane_visible(observer => $observer);

=cut

sub is_plane_visible {
    my ($self, %args) = @_;

    my $observer = $args{observer};

    my $N = $self->get_orthogonal_vector;

    unless (defined $observer) {

        if ($N->z > 0) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else {

        # Check angle between normal and observer vectors:
        my ($normal_x, $normal_y, $normal_z) = $N->array;

        # First let's get another vector from one of vertices to an observer's eyes:
        my $observer_vector = _get_vector_from_polygon_to_observer($self, $observer);

        # SK = N razy (skalarnie) R = n1*r1+n2*r2+n3*r3
        my $sk = $observer_vector->{x} * $normal_x + $observer_vector->{y} * $normal_y + $observer_vector->{z} * $normal_z;

        if ($sk <= 0) {
            return 1;
        }
        else {
            return 0;
        }
    }
}

sub _get_vector_from_polygon_to_observer {
    my ($self, $observer_point) = @_;

    # Get middle point from a polygon:
    my $polygon_point = $self->get_middle_point;

    # Calculate vector directed from polygon to observer:
    my ($x1, $y1, $z1) = $observer_point->get_xyz;
    my ($x2, $y2, $z2) = $polygon_point->get_xyz;

    # my $v = vector($vx, $vy, $vz);
    my $vx = $x2 - $x1;
    my $vy = $y2 - $y1;
    my $vz = $z2 - $z1;

    my %v = (
        x => $vx,
        y => $vy,
        z => $vz,
    );

    return \%v;
}

=head2 get_middle_point

Get point coordinates located exactly in the middle of a polygon's plane (remember assumption that all vertex points are located on the same plane):

  my $middle_point = $polygon->get_middle_point;

=cut

sub get_middle_point {
    my ($self) = @_;

    my $vertices = $self->_get_vertices;

    my ($total_x, $total_y, $total_z);

    for my $vertex (@{$vertices}) {
        my ($x, $y, $z) = $vertex->get_xyz;

        $total_x += $x;
        $total_y += $y;
        $total_z += $z;
    }

    my $num_vertices = $self->num_vertices;

    $total_x /= $num_vertices;
    $total_y /= $num_vertices;
    $total_z /= $num_vertices;

    my $point = Vector::Object3D::Point->new(x => $total_x, y => $total_y, z => $total_z);
    return $point;
}

=head2 get_normal_vector

Get vector normal to a polygon's plane (remember assumption that all vertex points are located on the same plane):

  my $normal_vector = $polygon->get_normal_vector;

Result of calling this method is a L<Math::VectorReal> object instance. You may access individual x, y, z elements of the vector as a list of values using C<array> method:

  my ($x, $y, $z) = $normal_vector->array;

=cut

sub get_normal_vector {
    my ($self) = @_;

    my $vertices = $self->_get_vertices;

    my $vertex1 = $vertices->[0];
    my $vertex2 = $vertices->[1];
    my $vertex3 = $vertices->[2];

    my ($x1, $y1, $z1) = $vertex1->get_xyz;
    my ($x2, $y2, $z2) = $vertex2->get_xyz;
    my ($x3, $y3, $z3) = $vertex3->get_xyz;

    my $v1 = vector($x1, $y1, $z1);
    my $v2 = vector($x2, $y2, $z2);
    my $v3 = vector($x3, $y3, $z3);

    my $U = $v3 - $v2;
    my $V = $v1 - $v2;
    my $N = $V x $U;

    return $N;
}

=head2 get_orthogonal_vector

Get vector normal to a polygon's plane:

  my $normal_vector = $polygon->get_orthogonal_vector;

This is an alias for C<get_normal_vector>.

=cut

sub get_orthogonal_vector {
    my ($self) = @_;

    return $self->get_normal_vector;
}

=head2 compare (==)

Compare two polygon objects:

  my $are_the_same = $polygon1 == $polygon2;

Overloaded comparison operator evaluates to true whenever two polygon objects are identical (all their endpoints are located at exactly same positions, note that vertex order matters as well).

=cut

sub _comparison {
    my ($self, $arg) = @_;

    my $vertices1 = $self->_get_vertices;
    my $vertices2 = $arg->_get_vertices;

    return unless @{$vertices1} == @{$vertices2};

    for (my $i = 0; $i < @{$vertices1}; $i++) {

        my $vertex1 = $vertices1->[$i];
        my $vertex2 = $vertices2->[$i];

        return unless $vertex1 == $vertex2;
    }

    return 1;
}

sub _negative_comparison {
    my ($self, $arg) = @_;

    return not $self->_comparison($arg);
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Vector::Object3D::Polygon> exports nothing neither by default nor explicitly.

=head1 SEE ALSO

L<Math::VectorReal>, L<Vector::Object3D>, L<Vector::Object3D::Point>.

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
