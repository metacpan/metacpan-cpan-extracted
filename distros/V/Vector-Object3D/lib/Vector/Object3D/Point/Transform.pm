package Vector::Object3D::Point::Transform;

=head1 NAME

Vector::Object3D::Point::Transform - Three-dimensional point object transformations

=head2 SYNOPSIS

  package Vector::Object3D::Point;

  use Readonly;
  Readonly my $pi => 3.14159;

  use Moose;
  with 'Vector::Object3D::Point::Transform';

  # Calling any method from this role requires providing an object of a base class
  # and results in creation of a new instance of the same class:
  my $point = Vector::Object3D::Point->new(coord => [3, -2, 1]);

  # Rotate point on a 2D plane:
  my $rotatePoint2D = $point->rotate(
    rotate_xy => 30 * ($pi / 180),
  );

  # Scale point on a 2D plane:
  my $scalePoint2D = $point->scale(
    scale_x => 2,
    scale_y => 2,
  );

  # Translate point on a 2D plane:
  my $translatePoint2D = $point->translate(
    shift_x => -2,
    shift_y => 1,
  );

  # Rotate point in a 3D space:
  my $rotatePoint3D = $point->rotate(
    rotate_xy => 30 * ($pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

  # Scale point in a 3D space:
  my $scalePoint3D = $point->scale(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

  # Translate point in a 3D space:
  my $translatePoint3D = $point->translate(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

=head1 DESCRIPTION

C<Vector::Object3D::Point::Transform> is a Moose role that is meant to be applied to C<Vector::Object3D::Point> class in order to provide it with additional methods supporting fundamental transformations in the 3D space, such as rotation, scaling and translation.

=head1 METHODS

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use Moose::Role;

use Vector::Object3D::Matrix;

use Readonly;
Readonly our $pi => 3.14159;

sub _transform {
    my ($self, %args) = @_;

    my $point_matrix = $self->get_matrix;
    my $num_cols = $point_matrix->num_cols;

    $point_matrix->add(col => [1]);

    my $transformation_matrix = $args{transformation_matrix};
    my $matrix_transformed = $point_matrix * $transformation_matrix;

    my $data = $matrix_transformed->get_rows;
    my @xyz = @{$data->[0]}[0 .. $num_cols - 1];

    my $point_transformed = $self->new(coord => \@xyz);
    return $point_transformed;
}

=head2 rotate

Rotate point on a 2D plane:

  my $rotatePoint2D = $point->rotate(
    rotate_xy => 30 * ($pi / 180),
  );

Rotate point in a 3D space:

  my $rotatePoint3D = $point->rotate(
    rotate_xy => 30 * ($pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

=cut

sub rotate {
    my ($self, %args) = @_;

    my $rotate_matrix = Vector::Object3D::Matrix->get_rotation_matrix(%args);

    my $point_rotated = $self->_transform(transformation_matrix => $rotate_matrix);

    return $point_rotated;
}

=head2 scale

Scale point on a 2D plane:

  my $scalePoint2D = $point->scale(
    scale_x => 2,
    scale_y => 2,
  );

Scale point in a 3D space:

  my $scalePoint3D = $point->scale(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

=cut

sub scale {
    my ($self, %args) = @_;

    my $scale_matrix = Vector::Object3D::Matrix->get_scaling_matrix(%args);

    my $point_scaled = $self->_transform(transformation_matrix => $scale_matrix);

    return $point_scaled;
}

=head2 translate

Translate point on a 2D plane:

  my $translatePoint2D = $point->translate(
    shift_x => -2,
    shift_y => 1,
  );

Translate point in a 3D space:

  my $translatePoint3D = $point->translate(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

=cut

sub translate {
    my ($self, %args) = @_;

    my $translate_matrix = Vector::Object3D::Matrix->get_translation_matrix(%args);

    my $point_translated = $self->_transform(transformation_matrix => $translate_matrix);

    return $point_translated;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Vector::Object3D::Point::Transform> exports nothing neither by default nor explicitly.

=head1 SEE ALSO

L<Vector::Object3D::Point>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.01 (2012-12-24)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Pawel Krol.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

no Moose::Role;

1;
