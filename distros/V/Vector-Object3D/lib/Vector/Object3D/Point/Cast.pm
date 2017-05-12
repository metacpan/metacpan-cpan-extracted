package Vector::Object3D::Point::Cast;

=head1 NAME

Vector::Object3D::Point::Cast - Three-dimensional point object casting into two-dimensional surface areas

=head2 SYNOPSIS

  package Vector::Object3D::Point;

  use Moose;
  with 'Vector::Object3D::Point::Cast';

  # Calling any method from this role requires providing an object of a base class
  # and results in creation of a new instance of the same class:
  my $point = Vector::Object3D::Point->new(coord => [-2, 3, 1]);

  # Project point onto a two-dimensional plane using an orthographic projection:
  my $point2D = $point->cast(type => 'parallel');

  # Project point onto a two-dimensional plane using a perspective projection:
  my $distance = 5;
  my $point2D = $point->cast(type => 'perspective', distance => $distance);

=head1 DESCRIPTION

C<Vector::Object3D::Point::Cast> is a Moose role that is meant to be applied to C<Vector::Object3D::Point> class in order to provide it with additional methods of mapping three-dimensional points to a two-dimensional plane.

=head1 METHODS

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use Moose::Role;

use Carp qw(croak);

use Vector::Object3D::Matrix;

=head2 cast

Project point onto a two-dimensional plane using an orthographic projection:

  my $point2D = $point->cast(type => 'parallel');

Project point onto a two-dimensional plane using a perspective projection:

  my $distance = 5;
  my $point2D = $point->cast(type => 'perspective', distance => $distance);

=cut

sub cast {
    my ($self, %args) = @_;

    my $type = $args{type};

    if ($type eq 'parallel') {
        my $point2D = $self->_cast_parallel(%args);
        return $point2D;
    }
    elsif ($type eq 'perspective') {
        my $point2D = $self->_cast_perspective(%args);
        return $point2D;
    }
    else {
        croak qq{Invalid projection type: "${type}"};
    }
}

sub _cast_parallel {
    my ($self, %args) = @_;

    my @xy = $self->get_xy;

    my $point2D = $self->new(coord => \@xy);
    return $point2D;
}

sub _cast_perspective {
    my ($self, %args) = @_;

    my $distance = $args{distance};

    my $x = $self->get_x;
    my $y = $self->get_y;
    my $z = $self->get_z || 0.00001; # avoid division by zero exception

    my $x_casted = $distance * $x / $z;
    my $y_casted = $distance * $y / $z;

    my $point2D  = $self->new(x => $x_casted, y => $y_casted);
    return $point2D;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Vector::Object3D::Point::Cast> exports nothing neither by default nor explicitly.

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
