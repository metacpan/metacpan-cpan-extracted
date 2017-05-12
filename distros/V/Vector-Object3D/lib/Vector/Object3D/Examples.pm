package Vector::Object3D::Examples;

our $VERSION = '0.01';

use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

Vector::Object3D::Examples - Examples of how to use Vector::Object3D

=head1 DESCRIPTION

C<Vector::Object3D> is Perl module providing most basic procedures to facilitate handling of vector object calculations in the 3D space, including fundamental transformations (translating, scaling, rotating) as well as perspective 2D casting.

=head1 EXAMPLES

=head2 tetrahedron.pl

This example shows how to use C<Vector::Object3D> to precalculate rotating 3D tetrahedron and animate it using C<Tk>:

  #!/usr/bin/perl

  use strict;
  use warnings;

  package My::Vector::Object3D::Polygon;

  use Moose;
  extends 'Vector::Object3D::Polygon';

  has colour => (
    is  => 'rw',
    isa => 'Maybe[Str]',
  );

  override 'copy' => sub {
    my ($self) = @_;

    my $colour = $self->colour;
    my $copy = $self->super();
    $copy->colour($colour);

    return $copy;
  };

  package main;

  use Readonly;
  use Term::ProgressBar 2.00;
  use Tk;
  use Vector::Object3D;

  Readonly our $distance => 100;
  Readonly our $fps => 100;
  Readonly our $height => 480;
  Readonly our $num_frames => 360;
  Readonly our $pi => 3.14159;
  Readonly our $rotate_factor => 360 / $num_frames * $pi / 180;
  Readonly our $scale => 50;
  Readonly our $width => 640;

  {
    my $current_rotation = 0;

    sub next_rotation {
      $current_rotation += $rotate_factor;

      return $current_rotation;
    }
  }

  my $object = define_object();
  my $frames = prepare_frames();

  my $mw = MainWindow->new;
  my $canvas = $mw->Canvas(-width => $width, -height => $height, -background => '#AAEEAA')->pack;

  draw_polygons(0);

  MainLoop;

  sub define_object {
    my $point1 = Vector::Object3D::Point->new(x => -3, y => 2, z => 0);
    my $point2 = Vector::Object3D::Point->new(x => 3, y => 2, z => 0);
    my $point3 = Vector::Object3D::Point->new(x => 0, y => -4, z => 0);
    my $point4 = Vector::Object3D::Point->new(x => 0, y => 0, z => 3);

    my $polygon1 = My::Vector::Object3D::Polygon->new(vertices => [$point2, $point1, $point3], colour => '#CCCC00');
    my $polygon2 = My::Vector::Object3D::Polygon->new(vertices => [$point1, $point4, $point3], colour => '#22CCCC');
    my $polygon3 = My::Vector::Object3D::Polygon->new(vertices => [$point2, $point3, $point4], colour => '#88CC22');
    my $polygon4 = My::Vector::Object3D::Polygon->new(vertices => [$point1, $point2, $point4], colour => '#22CC22');

    return Vector::Object3D->new(polygons => [$polygon1, $polygon2, $polygon3, $polygon4]);
  }

  sub prepare_frames {
    my @frames;

    my $progress = Term::ProgressBar->new({
      name  => 'Calculating',
      count => $num_frames,
    });

    for (my $i = 0; $i < $num_frames; $i++) {
      push @frames, setup_frame($object);

      $progress->update($i);
    }

    $progress->update($num_frames);

    return \@frames;
  }

  sub draw_polygons {
    my ($step) = @_;

    $step = 0 if ++$step == $num_frames;

    my @precalculated_polygons = @{ $frames->[$step] };

    $canvas->delete('polygon' . $_) for (0 .. @precalculated_polygons);

    for (my $i = 0; $i < @precalculated_polygons; $i++) {
      my $polygon = $precalculated_polygons[$i];
      my $colour = $polygon->{colour};
      my @vertices = @{ $polygon->{vertices} };
      $canvas->createPolygon(@vertices, -fill => $colour, -outline => '#002200', -width => 5, -tags => 'polygon' . $i);
    }

    $mw->after(1000 / $fps => sub { draw_polygons($step) });
  }

  sub setup_frame {
    my ($object) = @_;

    my $rotation = next_rotation();

    my @colours = map { $_->colour } $object->get_polygons;

    $object = $object->scale(scale_x => $scale, scale_y => $scale, scale_z => $scale);
    $object = $object->rotate(rotate_xy => 0, rotate_yz => 0, rotate_xz => $rotation);
    $object = $object->rotate(rotate_xy => -2 * $rotation, rotate_yz => 0, rotate_xz => 0);
    $object = $object->translate(shift_x => $width / 2, shift_y => $height / 2, shift_z => 0);

    my @polygons = $object->get_polygons;

    $_->colour(shift @colours) for @polygons;

    my @polygons_visible = grep { $_->is_plane_visible } @polygons;

    my @polygons_casted = map { project_polygon($_) } @polygons_visible;

    return \@polygons_casted;
  }

  sub project_polygon {
    my $polygon = shift;
    my @vertices = map { $_->get_xy } $polygon->cast(type => 'parallel')->get_vertices;
    return {
      colour   => $polygon->colour,
      vertices => \@vertices,
    };
  }

=head2 cube-outline.pl

This example shows how to use C<Vector::Object3D> to precalculate rotating 3D cube, hide object's invisible faces and animate its outlines using C<Tk>:

  #!/usr/bin/perl

  use strict;
  use warnings;

  use Readonly;
  use Term::ProgressBar 2.00;
  use Tk;
  use Vector::Object3D::Point;
  use Vector::Object3D::Polygon;

  Readonly our $draw_scale => 3;
  Readonly our $height => $draw_scale * 128;
  Readonly our $width => $draw_scale * 128;
  Readonly our $fps => 50;
  Readonly our $num_frames => 256;
  Readonly our $pi => 3.14159;
  Readonly our $push_away => 50;
  Readonly our $distance => 200;
  Readonly our $scale => 9;

  my @polygon = setup_object_polygons();

  my @precalculated_data;

  for (my $i = 0; $i < @polygon; $i++) {
    printf "[POLYGON %d/%d]\n", $i + 1, scalar @polygon;
    push @precalculated_data, calculate_polygon_frames($polygon[$i]);
  }

  my $mw = MainWindow->new;
  our $canvas = $mw->Canvas(
    -width => $width,
    -height => $height,
    -background => '#CCCCCC'
  )->pack;

  draw_object(0);
  MainLoop;

  sub setup_object_polygons {
    my $point = [
      [-1, -1, +1],
      [-1, +1, +1],
      [+1, +1, +1],
      [+1, -1, +1],
      [-1, -1, -1],
      [-1, +1, -1],
      [+1, +1, -1],
      [+1, -1, -1],
    ];

    my $vertex1 = Vector::Object3D::Point->new(coord => [$point->[0][0], $point->[0][1], $point->[0][2]]);
    my $vertex2 = Vector::Object3D::Point->new(coord => [$point->[1][0], $point->[1][1], $point->[1][2]]);
    my $vertex3 = Vector::Object3D::Point->new(coord => [$point->[2][0], $point->[2][1], $point->[2][2]]);
    my $vertex4 = Vector::Object3D::Point->new(coord => [$point->[3][0], $point->[3][1], $point->[3][2]]);

    my $vertex5 = Vector::Object3D::Point->new(coord => [$point->[4][0], $point->[4][1], $point->[4][2]]);
    my $vertex6 = Vector::Object3D::Point->new(coord => [$point->[5][0], $point->[5][1], $point->[5][2]]);
    my $vertex7 = Vector::Object3D::Point->new(coord => [$point->[6][0], $point->[6][1], $point->[6][2]]);
    my $vertex8 = Vector::Object3D::Point->new(coord => [$point->[7][0], $point->[7][1], $point->[7][2]]);

    my @vertices = (
      [$vertex1, $vertex2, $vertex3, $vertex4],
      [$vertex5, $vertex8, $vertex7, $vertex6],
      [$vertex1, $vertex5, $vertex6, $vertex2],
      [$vertex2, $vertex6, $vertex7, $vertex3],
      [$vertex3, $vertex7, $vertex8, $vertex4],
      [$vertex4, $vertex8, $vertex5, $vertex1],
    );

    return map { Vector::Object3D::Polygon->new(vertices => $_) } @vertices;
  }

  sub calculate_polygon_frames {
    my ($polygon) = @_;

    my %rotation = (
      rotation_xy => -2 * $pi / $num_frames,
      rotation_xz => +4 * $pi / $num_frames,
      rotation_yz => +2 * $pi / $num_frames,
    );

    my $observer = Vector::Object3D::Point->new(x => 0, y => 0, z => 0);

    my $progress = Term::ProgressBar->new({
      name  => 'Calculating',
      count => $num_frames,
    });

    my @frame;

    for (my $i = 0; $i < $num_frames; $i++) {
      my %current_step_rotation = map { $_ => $i * $rotation{$_} } keys %rotation;

      my $rotated_polygon = calculate_rotated_frame($polygon, \%current_step_rotation);

      my $is_plane_visible = $rotated_polygon->is_plane_visible(observer => $observer);

      if ($is_plane_visible) {
        my @vertices = get_polygon_vertices($rotated_polygon);

        $frame[$i] = \@vertices;
      }

      $progress->update($i);
    }

    $progress->update($num_frames);

    return \@frame;
  }

  sub calculate_rotated_frame {
    my ($polygon, $rotation) = @_;

    $polygon = $polygon->rotate(rotate_xy => 0, rotate_yz => 0, rotate_xz => $rotation->{rotation_xz});
    $polygon = $polygon->rotate(rotate_xy => 0, rotate_yz => $rotation->{rotation_yz}, rotate_xz => 0);
    $polygon = $polygon->rotate(rotate_xy => $rotation->{rotation_xy}, rotate_yz => 0, rotate_xz => 0);

    $polygon = $polygon->scale(scale_x => $scale, scale_y => $scale, scale_z => $scale);

    $polygon = $polygon->translate(shift_x => 0, shift_y => 0, shift_z => $push_away);

    return $polygon;
  }

  sub get_polygon_vertices {
    my ($polygon) = @_;

    my $casted_polygon = $polygon->cast(type => 'perspective', distance => $distance);
    my $translated_polygon = $casted_polygon->translate(shift_x => $width / 6, shift_y => $height / 6);

    my @vertices = $translated_polygon->get_vertices;

    return map { $draw_scale * int $_ } map { $_->get_xy } @vertices;
  }

  sub draw_object {
    my ($step) = @_;

    $canvas->delete('polygon' . $_) for (0 .. @precalculated_data);

    for (my $i = 0; $i < @precalculated_data; $i++) {
      my $polygon = $precalculated_data[$i];

      my $data = $polygon->[$step];
      next unless defined $data;

      $canvas->createPolygon(@{$data}, -fill => undef, -outline => '#002200', -width => 5, -tags => 'polygon' . $i);
    }

    $step = 0 if ++$step == $num_frames;

    $mw->after(1000 / $fps => sub { draw_object($step) });

    return;
  }

=head1 SEE ALSO

L<Tk>, L<Vector::Object3D>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.01 (2012-12-24)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Pawel Krol.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut
