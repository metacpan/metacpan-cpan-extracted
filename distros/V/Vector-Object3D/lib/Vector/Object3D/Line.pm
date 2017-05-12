package Vector::Object3D::Line;

=head1 NAME

Vector::Object3D::Line - Three-dimensional line object definitions

=head2 SYNOPSIS

  use Vector::Object3D::Line;

  # Create two endpoints of a line:
  my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
  my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);

  # Create an instance of a class:
  my $line = Vector::Object3D::Line->new(vertex1 => $vertex1, vertex2 => $vertex2);
  my $line = Vector::Object3D::Line->new(vertices => [$vertex1, $vertex2]);

  # Create a new object as a copy of an existing object:
  my $copy = $line->copy;

  # Get first vertex point:
  my $vertex1 = $line->get_vertex1;
  # Get last vertex point:
  my $vertex2 = $line->get_vertex2;

  # Get both vertex points:
  my @vertices = $line->get_vertices;

  # Print out formatted line data:
  $line->print(fh => $fh, precision => $precision);

  # Compare two line objects:
  my $are_the_same = $line1 == $line2;

=head1 DESCRIPTION

C<Vector::Object3D::Line> provides an abstraction layer for describing line object in a three-dimensional space by composing it from two C<Vector::Object3D::Point> objects (referred onwards as vertices).

=head1 METHODS

=head2 new

Create an instance of a C<Vector::Object3D::Line> class:

  my $vertex1 = Vector::Object3D::Point->new(x => 3, y => -2, z => 1);
  my $vertex2 = Vector::Object3D::Point->new(x => -1, y => 2, z => 3);

  my $line = Vector::Object3D::Line->new(vertex1 => $vertex1, vertex2 => $vertex2);
  my $line = Vector::Object3D::Line->new(vertices => [$vertex1, $vertex2]);

There are two individual means of C<Vector::Object3D::Line> object construction, provided a hash of two vertex components or a list of two point objects. When present, C<vertices> constructor parameter takes precedence over C<vertex1> and C<vertex2> points in case both values are provided at the same time.

C<Vector::Object3D::Line> requires provision of two endpoints in order to successfully construct an object instance, there is no exception from this rule.

=cut

our $VERSION = '0.01';

use strict;
use warnings;

use Moose;

use overload
    '==' => \&_comparison,
    '!=' => \&_negative_comparison;

has 'vertex1' => (
    is       => 'ro',
    isa      => 'Vector::Object3D::Point',
    reader   => 'get_vertex1',
    required => 1,
);

has 'vertex2' => (
    is       => 'ro',
    isa      => 'Vector::Object3D::Point',
    reader   => 'get_vertex2',
    required => 1,
);

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $vertices = $args{vertices};

    if (defined $vertices and ref $vertices eq 'ARRAY') {
        my @fields = qw(vertex1 vertex2);
        @args{@fields} = @{$vertices};
    }

    my $vertex1 = $args{vertex1};
    my $vertex2 = $args{vertex2};

    $args{vertex1} = $vertex1->copy;
    $args{vertex2} = $vertex2->copy;

    return $class->$orig(%args);
};

=head2 copy

Create a new C<Vector::Object3D::Line> object as a copy of an existing object:

  my $copy = $line->copy;

=cut

sub copy {
    my ($self) = @_;

    my @vertices = $self->get_vertices;

    my $class = $self->meta->name;
    my $copy = $class->new(vertices => \@vertices);

    return $copy;
}

=head2 get_vertex1

Get first vertex point:

  my $vertex1 = $line->get_vertex1;

=head2 get_vertex2

Get last vertex point:

  my $vertex2 = $line->get_vertex2;

=head2 get_vertices

Get both vertex points:

  my @vertices = $line->get_vertices;

=cut

sub get_vertices {
    my ($self) = @_;

    my $vertex1 = $self->get_vertex1;
    my $vertex2 = $self->get_vertex2;

    return ($vertex1, $vertex2);
}

=head2 print

Print out text-formatted line data (which might be, for instance, useful for debugging purposes):

  $line->print(fh => $fh, precision => $precision);

C<fh> defaults to the standard output. C<precision> is intended for internal use by string format specifier that outputs individual point coordinates as decimal floating points, and defaults to 2 (unless adjusted individually for each vertex).

=cut

sub print {
    my ($self, %args) = @_;

    my $vertex1 = $self->get_vertex1;
    my $vertex2 = $self->get_vertex2;

    my $vertexMatrix1 = $vertex1->get_matrix;
    my $vertexMatrix2 = $vertex2->get_matrix;

    $vertexMatrix1->print(%args);
    $vertexMatrix2->print(%args);

    return;
}

=head2 compare (==)

Compare two line objects:

  my $are_the_same = $line1 == $line2;

Overloaded comparison operator evaluates to true whenever two line objects are identical (both their endpoints are located at exactly same positions, note that vertex order matters as well).

=cut

sub _comparison {
    my ($self, $arg) = @_;

    my $line1_point1 = $self->get_vertex1;
    my $line1_point2 = $self->get_vertex2;

    my $line2_point1 = $arg->get_vertex1;
    my $line2_point2 = $arg->get_vertex2;

    return $line1_point1 == $line2_point1 && $line1_point2 == $line2_point2;
}

=head2 negative compare (!=)

Compare two line objects:

  my $are_not_the_same = $line1 != $line2;

Overloaded negative comparison operator evaluates to true whenever two line objects differ (any of their coordinates do not match).

=cut

sub _negative_comparison {
    my ($self, $arg) = @_;

    return not $self->_comparison($arg);
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<Vector::Object3D::Line> exports nothing neither by default nor explicitly.

=head1 SEE ALSO

L<Vector::Object3D>, L<Vector::Object3D::Point>.

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
