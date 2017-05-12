package Vector::Object3D::Matrix::Transform;

=head1 NAME

Vector::Object3D::Matrix::Transform - construction of graphical transformation matrices

=head2 SYNOPSIS

  package Vector::Object3D::Matrix;

  use Readonly;
  Readonly my $pi => 3.14159;

  use Moose;
  with 'Vector::Object3D::Matrix::Transform';

  # Calling any method from this role results in creating an instance of the given class:
  my $class = 'Vector::Object3D::Matrix';

  # Construct rotation matrix on a 2D plane:
  my $rotateMatrix2D = $class->get_rotation_matrix(
    rotate_xy => (30 * $pi / 180),
  );

  # Construct scaling matrix on a 2D plane:
  my $scaleMatrix2D = $class->get_scaling_matrix(
    scale_x => 2,
    scale_y => 2,
  );

  # Construct translation matrix on a 2D plane:
  my $translateMatrix2D = $class->get_translation_matrix(
    shift_x => -2,
    shift_y => 1,
  );

  # Construct rotation matrix in a 3D space:
  my $rotateMatrix3D = $class->get_rotation_matrix(
    rotate_xy => (30 * $pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

  # Construct scaling matrix in a 3D space:
  my $scaleMatrix3D = $class->get_scaling_matrix(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

  # Construct translation matrix in a 3D space:
  my $translateMatrix3D = $class->get_translation_matrix(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

=head1 DESCRIPTION

C<Vector::Object3D::Matrix::Transform> is a Moose role that is meant to be applied to C<Vector::Object3D::Matrix> class in order to provide it with additional methods supporting construction of graphical transformation matrices, which currently handle rotation, scaling and translation functionalities.

=head1 METHODS

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use Moose::Role;

use Readonly;
Readonly our $pi => 3.14159;

=head2 get_rotation_matrix

Construct rotation matrix on a 2D plane:

  my $rotateMatrix2D = $class->get_rotation_matrix(
    rotate_xy => (30 * $pi / 180),
  );

Construct rotation matrix in a 3D space:

  my $rotateMatrix3D = $class->get_rotation_matrix(
    rotate_xy => (30 * $pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

=cut

sub get_rotation_matrix {
    my ($class, %args) = @_;

    my $is3D = (defined $args{rotate_yz} || defined $args{rotate_xz}) ? 1 : 0;

    my $x_axis_rotation_angle = $args{rotate_yz} || 0;
    my $y_axis_rotation_angle = $args{rotate_xz} || 0;
    my $z_axis_rotation_angle = $args{rotate_xy} || 0;

    my $z_axis_rotation_sin = sin $z_axis_rotation_angle;
    my $z_axis_rotation_cos = cos $z_axis_rotation_angle;

    my $rows;

    if ($is3D) {
        my $x_axis_rotation_sin = sin $x_axis_rotation_angle;
        my $x_axis_rotation_cos = cos $x_axis_rotation_angle;
        my $y_axis_rotation_sin = sin $y_axis_rotation_angle;
        my $y_axis_rotation_cos = cos $y_axis_rotation_angle;

        $rows = [
            [$y_axis_rotation_cos * $z_axis_rotation_cos, -$z_axis_rotation_sin, -$y_axis_rotation_sin, 0],
            [$z_axis_rotation_sin, $x_axis_rotation_cos * $z_axis_rotation_cos, $x_axis_rotation_sin, 0],
            [$y_axis_rotation_sin, -$x_axis_rotation_sin, $x_axis_rotation_cos * $y_axis_rotation_cos, 0],
            [0, 0, 0, 1],
        ];
    }
    else {
        $rows = [[$z_axis_rotation_cos, -$z_axis_rotation_sin, 0], [$z_axis_rotation_sin, $z_axis_rotation_cos, 0], [0, 0, 1]];
    }

    my $matrix = $class->new(rows => $rows);
    return $matrix;
}

=head2 get_scaling_matrix

Construct scaling matrix on a 2D plane:

  my $scaleMatrix2D = $class->get_scaling_matrix(
    scale_x => 2,
    scale_y => 2,
  );

Construct scaling matrix in a 3D space:

  my $scaleMatrix3D = $class->get_scaling_matrix(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

=cut

sub get_scaling_matrix {
    my ($class, %args) = @_;

    my $is3D    = defined $args{scale_z} ? 1 : 0;
    my $scale_x = $args{scale_x} || 0;
    my $scale_y = $args{scale_y} || 0;
    my $scale_z = $args{scale_z} || 0;

    my $rows;

    if ($is3D) {
        $rows = [[$scale_x, 0, 0, 0], [0, $scale_y, 0, 0], [0, 0, $scale_z, 0], [0, 0, 0, 1]];
    }
    else {
        $rows = [[$scale_x, 0, 0], [0, $scale_y, 0], [0, 0, 1]];
    }

    my $matrix = $class->new(rows => $rows);
    return $matrix;
}

=head2 get_translation_matrix

Construct translation matrix on a 2D plane:

  my $translateMatrix2D = $class->get_translation_matrix(
    shift_x => -2,
    shift_y => 1,
  );

Construct translation matrix in a 3D space:

  my $translateMatrix3D = $class->get_translation_matrix(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

=cut

sub get_translation_matrix {
    my ($class, %args) = @_;

    my $is3D    = defined $args{shift_z} ? 1 : 0;
    my $shift_x = $args{shift_x} || 0;
    my $shift_y = $args{shift_y} || 0;
    my $shift_z = $args{shift_z} || 0;

    my $rows;

    if ($is3D) {
        $rows = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [$shift_x, $shift_y, $shift_z, 1]];
    }
    else {
        $rows = [[1, 0, 0], [0, 1, 0], [$shift_x, $shift_y, 1]];
    }

    my $matrix = $class->new(rows => $rows);
    return $matrix;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Vector::Object3D::Matrix::Transform> exports nothing neither by default nor explicitly.

=head1 SEE ALSO

L<Math::VectorReal>, L<Vector::Object3D::Matrix>.

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
