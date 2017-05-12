package Vector::Object3D;

=head1 NAME

Vector::Object3D - Three-dimensional object type definitions and operations

=head2 SYNOPSIS

  use Vector::Object3D;

  # Create an instance of a class:
  my $object = Vector::Object3D->new(polygons => [$polygon1, $polygon2, $polygon3]);

  # Create a new object as a copy of an existing object:
  my $copy = $object->copy;

  # Get number of polygons that make up an object:
  my $num_faces = $object->num_faces;

  # Get index of last polygon:
  my $last_face_index = $object->last_face_index;

  # Get first polygon:
  my $polygon1 = $object->get_polygon(index => 0);

  # Get last polygon:
  my $polygonn = $object->get_polygon(index => $last_face_index);

  # Get all polygons:
  my @polygons = $object->get_polygons;
  my @polygons = $object->get_polygons(mode => 'all');

  # Get visible polygons only:
  my $observer = Vector::Object3D::Point->new(x => 0, y => 0, z => 5);
  my @polygons = $object->get_polygons(mode => 'visible', observer => $observer);

  # Print out formatted object data:
  $object->print(fh => $fh, precision => $precision);

  # Move object a constant distance in a specified direction:
  my $object_translated = $object->translate(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

  # Enlarge, shrink or stretch object by a scale factor:
  my $object_scaled = $object->scale(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

  # Rotate object by a given angle around three rotation axis:
  my $object_rotated = $object->rotate(
    rotate_xy => 30 * ($pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

  # Project object onto a two-dimensional plane using an orthographic projection:
  my $object2D = $object->cast(type => 'parallel');

  # Project object onto a two-dimensional plane using a perspective projection:
  my $distance = 5;
  my $object2D = $object->cast(type => 'perspective', distance => $distance);

  # Compare two objects:
  my $are_the_same = $object1 == $object2;

=head1 DESCRIPTION

C<Vector::Object3D> provides an abstraction layer for describing objects made of polygons in a three-dimensional space. It has been primarily designed to help with rapid prototyping of simple 3D vector graphic transformations, and is most likely unsuitable for realtime calculations that usually demand high computational CPU power.

This version of C<Vector::Object3D> package has been entirely rewritten using Moose object system and is significantly slower than its predecessor initially developed using classic Perl's object system. Main reasoning for switching over to Moose was my desire to comply with the concepts of modern Perl programming.

=head1 METHODS

=head2 new

Create an instance of a C<Vector::Object3D> class:

  my $object = Vector::Object3D->new(polygons => [$polygon1, $polygon2, $polygon3]);

C<Vector::Object3D> require provision of at least one polygon in order to successfully construct an object instance, there is no exception from this rule.

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use Moose;

use Carp qw(croak);
use Scalar::Util qw(looks_like_number);
use Vector::Object3D::Polygon;

use overload
    '==' => \&_comparison,
    '!=' => \&_negative_comparison;

has 'polygons' => (
    is       => 'ro',
    isa      => 'ArrayRef[Vector::Object3D::Polygon]',
    reader   => '_get_polygons',
    required => 1,
);

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $polygons_orig = $args{polygons};

    my @polygons_copy;

    if (defined $polygons_orig and ref $polygons_orig eq 'ARRAY') {

        for my $polygon (@{$polygons_orig}) {
            push @polygons_copy, $polygon->copy;
        }
    }

    $args{polygons} = \@polygons_copy;

    return $class->$orig(%args);
};

sub BUILD {
    my ($self) = @_;

    my $num_faces = $self->num_faces;

    if ($num_faces < 1) {
        croak qq{Insufficient number of polygons used to initialize object: $num_faces (expected at least 1 polygon)};
    }

    return;
}

=head2 copy

Create a new C<Vector::Object3D> object as a copy of an existing object:

  my $copy = $object->copy;

=cut

sub copy {
    my ($self) = @_;

    my $polygons = $self->_get_polygons;

    my $class = $self->meta->name;
    my $copy = $class->new(polygons => $polygons);

    return $copy;
}

=head2 num_faces

Get number of polygons that make up an object:

  my $num_faces = $object->num_faces;

=cut

sub num_faces {
    my ($self) = @_;

    my $faces = $self->_get_polygons;

    return scalar @{$faces};
}

=head2 last_face_index

Get index of last polygon:

  my $last_face_index = $object->last_face_index;

=cut

sub last_face_index {
    my ($self) = @_;

    my $faces = $self->_get_polygons;

    return $#{$faces};
}

=head2 get_polygon

Get C<$n>-th polygon, where C<$n> is expected to be any number between first and last polygon index:

  my $polygonn = $object->get_polygon(index => $n);

=cut

sub get_polygon {
    my ($self, %args) = @_;

    my $index = $args{index};

    unless (looks_like_number $index) {
        croak qq{Unable to get polygon with a non-numeric index value: $index};
    }

    if ($index < 0) {
        croak qq{Unable to get polygon with index value below acceptable range: $index};
    }

    if ($index > $self->last_face_index) {
        croak qq{Unable to get polygon with index value beyond acceptable range: $index};
    }

    my @polygons = $self->get_polygons;

    return $polygons[$index];
}

=head2 get_polygons

Get all polygons:

  my @polygons = $object->get_polygons;

The same effect is achieved by explicitly setting mode of getting polygons to C<all>:

  my @polygons = $object->get_polygons(mode => 'all');

Get visible polygons only by setting mode of getting polygons to C<visible> and specifying optional observer:

  my $observer = Vector::Object3D::Point->new(x => 0, y => 0, z => 5);
  my @polygons = $object->get_polygons(mode => 'visible', observer => $observer);

=cut

sub get_polygons {
    my ($self, %args) = @_;

    my $mode     = $args{mode} || 'all';
    my $observer = $args{observer};

    unless (grep { $mode eq $_ } qw/all visible/) {
        croak qq{Invalid mode used to get polygons: $mode};
    }

    my $polygons = $self->_get_polygons;

    my @polygons = map { $_->copy } grep {
        if ($mode eq 'visible') {
            $_->is_plane_visible(observer => $observer);
        }
        else {
            1;
        }
    } @{$polygons};

    return @polygons;
}

=head2 print

Print out text-formatted object data (which might be, for instance, useful for debugging purposes):

  $object->print(fh => $fh, precision => $precision);

C<fh> defaults to the standard output. C<precision> is intended for internal use by string format specifier that outputs individual point coordinates as decimal floating points, and defaults to 2 (unless adjusted individually for each vertex).

=cut

sub print {
    my ($self, %args) = @_;

    my $fh = $args{fh} || *STDOUT;

    my $stdout = select $fh;

    my $polygons = $self->_get_polygons;

    my $num_faces  = $self->num_faces;
    my $num_length = length $num_faces;

    for (my $i = 0; $i < @{$polygons}; $i++) {

        my $polygon = $polygons->[$i];

        printf "\nPolygon %0${num_length}d/%0${num_length}d:", $i + 1, $num_faces;

        $polygon->print(%args);
    }

    select $stdout;

    return;
}

=head2

Move object a constant distance in a specified direction:

  my $object_translated = $object->translate(
    shift_x => -2,
    shift_y => 1,
    shift_z => 3,
  );

=cut

sub translate {
    my ($self, %args) = @_;

    my $polygons = $self->_get_polygons;

    my @new_polygons;

    for my $polygon (@{$polygons}) {

        push @new_polygons, $polygon->translate(%args);
    }

    my $object_translated = $self->new(polygons => \@new_polygons);

    return $object_translated;
}

=head2

Enlarge, shrink or stretch object by a scale factor:

  my $object_scaled = $object->scale(
    scale_x => 2,
    scale_y => 2,
    scale_z => 3,
  );

=cut

sub scale {
    my ($self, %args) = @_;

    my $polygons = $self->_get_polygons;

    my @new_polygons;

    for my $polygon (@{$polygons}) {

        push @new_polygons, $polygon->scale(%args);
    }

    my $object_scaled = $self->new(polygons => \@new_polygons);

    return $object_scaled;
}

=head2

Rotate object by a given angle around three rotation axis:

  my $object_rotated = $object->rotate(
    rotate_xy => 30 * ($pi / 180),
    rotate_yz => -30 * ($pi / 180),
    rotate_xz => 45 * ($pi / 180),
  );

=cut

sub rotate {
    my ($self, %args) = @_;

    my $polygons = $self->_get_polygons;

    my @new_polygons;

    for my $polygon (@{$polygons}) {

        push @new_polygons, $polygon->rotate(%args);
    }

    my $object_rotated = $self->new(polygons => \@new_polygons);

    return $object_rotated;
}

=head2

Project object onto a two-dimensional plane using an orthographic projection:

  my $object2D = $object->cast(type => 'parallel');

Project object onto a two-dimensional plane using a perspective projection:

  my $distance = 5;
  my $object2D = $object->cast(type => 'perspective', distance => $distance);

=cut

sub cast {
    my ($self, %args) = @_;

    my $polygons = $self->_get_polygons;

    my @new_polygons;

    for my $polygon (@{$polygons}) {

        push @new_polygons, $polygon->cast(%args);
    }

    my $object_casted = $self->new(polygons => \@new_polygons);

    return $object_casted;
}

=head2 compare (==)

Compare two objects:

  my $are_the_same = $object1 == $object2;

Overloaded comparison operator evaluates to true whenever two object objects are identical (all their endpoints are located at exactly same positions, note that polygon order matters as well).

=cut

sub _comparison {
    my ($self, $arg) = @_;

    my $polygons1 = $self->_get_polygons;
    my $polygons2 = $arg->_get_polygons;

    return unless @{$polygons1} == @{$polygons2};

    for (my $i = 0; $i < @{$polygons1}; $i++) {

        my $polygon1 = $polygons1->[$i];
        my $polygon2 = $polygons2->[$i];

        return unless $polygon1 == $polygon2;
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

C<Vector::Object3D> exports nothing neither by default nor explicitly.

=head1 SEE ALSO

L<Vector::Object3D::Examples>, L<Vector::Object3D::Point>, L<Vector::Object3D::Polygon>.

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
