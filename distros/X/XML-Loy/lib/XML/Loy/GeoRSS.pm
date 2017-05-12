package XML::Loy::GeoRSS;
use strict;
use warnings;

use XML::Loy with => (
  prefix => 'georss',
  namespace => 'http://www.georss.org/georss'
);

use Carp qw/carp/;
use Scalar::Util qw/looks_like_number/;

# No constructor
sub new {
  carp 'Only use ' . __PACKAGE__ . ' as an extension';
  return;
};


# Add 'point' element
sub geo_point {
  my $self = shift;

  # Get
  if (@_ <= 1) {
    # Get point object
    my $point = $self->find('point') or return;
    $point = $point->[ shift // 0 ] or return;

    # Wrong namespace
    return if $point->namespace ne __PACKAGE__->_namespace;

    # Return point
    return [ split /\s+/, $point->text ];
  }

  # Set
  elsif (@_ == 2 && looks_like_number($_[0]) && looks_like_number($_[1])) {
    return $self->add(point => $_[0] . ' ' . $_[1]);
  }

  # Parameterlist has wrong length
  return;
};


# Add 'line' element
sub geo_line {
  my $self = shift;

  # Get
  if (@_ <= 1) {
    my $line = $self->find('line') or return;
    $line = $line->[ shift // 0 ] or return;

    # Wrong namespace
    return if $line->namespace ne __PACKAGE__->_namespace;

    # Return line
    my @points;
    my @v = split /\s+/, $line->text;
    push @points, [ shift(@v), shift(@v) // 0 ] while @v;
    return \@points;
  };

  # Parameterlist not even or too small
  return if @_ % 2 || @_ < 4;

  # Set
  return $self->add(line => join(' ',@_) );
};


# Add 'polygon' element
sub geo_polygon {
  my $self = shift;

  # Get
  if (@_ <= 1) {
    my $poly = $self->find('polygon') or return;
    $poly = $poly->[ shift // 0 ] or return;

    # Wrong namespace
    return if $poly->namespace ne __PACKAGE__->_namespace;

    # Return polygon
    my @points;
    my @v = split /\s+/, $poly->text;
    push @points, [ shift(@v), shift(@v) // 0 ] while @v;
    return \@points;
  };

  # Parameterlist not even or too small
  return if @_ % 2 || @_ < 6;

  # Last pair is not identical to first pair
  if ($_[0] != $_[$#_ - 1] && $_[1] != $_[$#_]) {
    push(@_, @_[0..1]);
  };

  # Add polygon
  return $self->add(polygon => join(' ', @_));
};


# Add properties
sub geo_property {
  my $self = shift;

  my %properties = @_;

  # Add all available properties
  foreach my $tag (grep(/^(?:(?:relationship|featuretype)tag|featurename)$/i,
		keys %properties)) {

    my $val = $properties{$tag};

    # Add as an array, if it is one
    foreach (ref $val ? @$val : ($val)) {
      $self->add( lc($tag) => $_ );
    };
  };

  return $self;
};


# Add 'floor' element
sub geo_floor {
  shift->add(floor => shift);
};


# Add 'elev' element
sub geo_elev {
  shift->add(elev => shift);
};


# Add 'radius' element
sub geo_radius {
  shift->add(radius => shift);
};


# Add 'where' element
sub geo_where {
  shift->add('where');
};


# Add 'box' element
sub geo_box {
  my $self = shift;

  if (@_ <= 1) {
    my $box = $self->find('box') or return;
    $box = $box->[ shift // 0 ] or return;

    # Wrong namespace
    return if $box->namespace ne __PACKAGE__->_namespace;

    # Return box
    my @points;
    my @v = split /\s+/, $box->text;
    return [
      [$v[0], $v[1]],
      [$v[2], $v[3]]
    ];
  };

  # Parameterlist has wrong length
  return unless @_ == 4;

  return $self->add(box => join(' ',@_));
};


# Add 'circle' element
sub geo_circle {
  my $self = shift;

  if (@_ <= 1) {
    my $circle = $self->find('circle') or return;
    $circle = $circle->[ shift // 0 ] or return;

    # Wrong namespace
    return if $circle->namespace ne __PACKAGE__->_namespace;

    # Return point
    my @v = split /\s+/, $circle->text;
    return [ [ $v[0], $v[1] ], $v[2] ];
  };

  # Parameterlist has wrong length
  return unless @_ == 3;

  return $self->add(circle => join(' ',@_));
};


1;


__END__

=pod

=head1 NAME

XML::Loy::GeoRSS - GeoRSS (Simple) Format Extension


=head1 SYNOPSIS

  use XML::Loy::Atom;

  my $atom = XML::Loy::Atom->new('entry');
  $atom->extension(-GeoRSS);

  my $geo = $atom->geo_where;
  $geo->geo_point(4.56, 5.67);

  say $geo->geo_point->[0];


=head1 DESCRIPTION

L<XML::Loy::GeoRSS> is an extension
for L<XML::Loy> base classes and provides addititional
functions for the work with geographic location as described in the
L<specification|http://georss.org/simple>.
This represents the simple variant rather than the GML flavour.

B<This module is an early release! There may be significant changes in the future.>


=head1 METHODS

L<XML::Loy::GeoRSS> inherits all methods
from L<XML::Loy> and implements the
following new ones.


=head2 C<geo_box>

  # Add box
  $atom->geo_box(4, 5, 9, 8);
  $atom->geo_box(7, 8, 12, 15);

  say $atom->geo_box->[1]->[0];
  # 9

  say $atom->geo_box(1)->[1]->[0];
  # 12

Add C<box> element based on two coordinates,
or get box.


=head2 C<geo_circle>

  # Add circle
  $atom->geo_circle(14.5, 20.4, 13);

  say $atom->geo_circle->[0]->[1];
  # 20.4

  say $atom->geo_circle->[1];
  # 13

Add C<circle> element based on one coordinate
and a value for radius, or get circle.


=head2 C<geo_elev>

  $atom->geo_elev(40);

Add C<elev> element.


=head2 C<geo_floor>

  $atom->geo_floor(46);

Add C<floor> element.


=head2 C<geo_line>

  $atom->geo_line(45.34, -23.67, 16.3, 17.89);
  $atom->geo_line(45.34, -23.67, 16.3, 17.89, 15.4, 17.3);

  say $atom->geo_line->[0]->[0];
  # 45.34

  say $atom->geo_line(1)->[2]->[0];
  # 15.4

Add C<line> element based on at least 2 coordinates,
or get coordinates.


=head2 C<geo_point>

  # Add point
  $atom->geo_point(4.56, 5.67);

  say $atom->geo_point->[0];
  # 4.56

Add C<point> element based on one coordinate,
or get it.


=head2 C<geo_polygon>

  $atom->geo_polygon(45.34, -23.67, 16.3, 17.89, 15.4, 17.3);

  say $atom->geo_polygon->[2]->[0];
  # 15.4

Add C<polygon> element based on at least 3 coordinates,
or get coordinates.


=head2 C<geo_property>

  $atom->geo_property(
    relationshiptag => 'test',
    featuretypetag  => [qw/foo bar/]
  );

Add geo features by means of C<relationshiptag>,
C<featuretypetag> or C<featurename> element.

=head2 C<geo_radius>

  $atom->geo_radius(17);

Add C<radius> element.

=head2 C<geo_where>

  my $where = $atom->geo_where;
  $where->geo_point(4, 5);

Add C<where> element.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016, Nils Diewald.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
