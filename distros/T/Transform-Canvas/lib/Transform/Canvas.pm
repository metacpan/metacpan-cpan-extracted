package Transform::Canvas;

use 5.006;
use strict;
use warnings;
use Carp;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Transform::Canvas ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.


=head1 NAME

Transform::Canvas - Perl extension for performing Coordinate transformation 
operations from the cartesion to the traditional drawing-model canvas coordinate systems.

=head2 VERSION

VERSION 0.14 15 Febuary, 2009

=cut

our $VERSION = 0.15;

=head1 SYNOPSIS

  use Transform::Canvas;
  # create a mapping transform for data from 
  #x=-100,y=-100,x=100,y=100  to x=10,y=10,x=100,y=100
  $t = Transform::Canvas->new(canvas=>[10,10,100,100],data=>[-100,-100,100,100]);
  # create a arrays of x and y values
  $r_x = [-100,-10, 0, 20, 40, 60, 80, 100];
  $r_y = [-100,-10, 0, 20, 40, 60, 80, 100];
  #map the two arrays into the canvas data space
  ($pr_x,$pr_y) = $t->map($r_x,$r_y);

=head1 DESCRIPTION

Transform::Canvas is a module which automates reference-frame transformations beween two cartesian coordinate systems. it is specifically intended to be used as a facilitator for coordinate-system transformation procedures between the traditional, right-hand-rule coordinate system used in mathematics graphing and the visual-arts coordinate system with a y-axis pointing down. 

The module allows for arbitrary 2-D transform mappings.

=head1 Methods

=head2 new

Module constructor.

 #there are two ways to invoke this module
 #one-step constructo
 $t = Transform::Canvas->new (canvas => [x0 y0 x1 y1], data=>[x0 y0 x1 y1])
 # or two-step connstructor
 $t-> Transform::Canvas->new ();
 $t->prepareMap (canvas => [x0 y0 x1 y1], data=>[x0 y0 x1 y1])

generate the conversion object through which all data points will be passed.
NB: svg drawings use the painter's model and use a coordinate system which
starts at the top, left corner of the document and has x-axis increasing to
the right and y-axis increasing down.

In certain drawings, the y-axis is inverted compared to mathematical 
representation systems which prefer y to increase in the upwards direction.

 canvas (target):
        x0 = paper-space minimum x value
        y0 = paper-space maximum x value
        x1 = paper-space minimum y value
        y1 = paper-space maximum y value
 data (source):
        x0 = data-space minimum x value
        y0 = data--space maximum x value
        x1 = data-space minimum y value
        y1 = data-space maximum y value

=cut

sub new ($;@) {
    my ( $proto, %attrs ) = @_;
    my $class = ref $proto || $proto;
    my $self;
    $self->{_config_} = {};

    #define the mappings
    if (%attrs) {
        $self->{_config_} = \%attrs;

        confess("Mising canvas data")
          unless scalar( @{ $self->{_config_}->{canvas} } ) == 4;
        confess("Mising data data")
          unless scalar( @{ $self->{_config_}->{data} } ) == 4;

        # establish defaults for unspecified attributes
        bless $self, $class;
        $self->_initialize()
          || croak("Failed to initialize Transform::Canvas object");
        $self->prepareMap() || croak("Failed to prepare transformation map");
    }
    return $self;
}

sub _initialize ($) {
    my $self = shift;
}

=head2 prepareMap hash %args

Prepare the transformation space for the conversions;
Currently only handles linear transformations, but this is a perfect candidate
for non-spacial, non-cartesian transforms... 

=cut

sub prepareMap ($;@) {
    my $self = shift;
    my %args = @_;

    if (%args) {
        $self->{_config_} = \%args;
    }

    #scale factors

    #flip
    #scale
    #translate (?)
    my $sy = ( $self->cy1 - $self->cy0 ) / ( $self->dy1 - $self->dy0 );    #ok
    my $sx = ( $self->cx1 - $self->cx0 ) / ( $self->dx1 - $self->dx0 );    #ok

    #translation factors
    my $tx = $self->cx0;
    my $ty = $self->cy0;

    $self->{map} = {
        x => {
            s => $sx,
            t => $tx,
        },
        y => {
            s => $sy,
            t => $ty,
        },
    };

}

# helper methods which return or set the corners of the canvas and data windows

=head2 sub cx0 [string $value]

set and/or return the canvas x min value

=head2 sub cx1 [string $value]

set and/or return the canvas x max value

=head2 sub cy0 [string $value]

set and/or return return the canvas y min value

=head2 sub cy1 [string $value]

set and/or return the canvas y max value

=head2 sub dx0 [string $value]

set and/or return the data space x min value

=head2 sub dx1  [string $value]

set and/or return the data space x max value

=head2 sub dy0  [string $value]

set and/or return the data space y min value

=head2 sub dy1 [string $value]

set and/or return the data space y max value.

=cut 

sub cx0 ($;$) {
    my $self = shift;
    my $val  = shift;
    $self->{_config_}->{canvas}->[0] = $val if defined $val;
    confess("canvas min x value not set")
      unless defined $self->{_config_}->{canvas}->[0];

    return $self->{_config_}->{canvas}->[0];
}

sub cx1 ($;$) {
    my $self = shift;
    my $val  = shift;
    $self->{_config_}->{canvas}->[2] = $val if defined $val;
    confess("canvas max x value not set")
      unless defined $self->{_config_}->{canvas}->[2];
    return $self->{_config_}->{canvas}->[2];
}

sub dx0 ($;$) {
    my $self = shift;
    my $val  = shift;
    $self->{_config_}->{data}->[0] = $val if defined $val;
    confess("data min x value not set")
      unless defined $self->{_config_}->{data}->[0];
    return $self->{_config_}->{data}->[0];
}

sub dx1 ($;$) {
    my $self = shift;
    my $val  = shift;
    $self->{_config_}->{data}->[2] = $val if defined $val;
    confess("data max x value not set")
      unless defined $self->{_config_}->{data}->[2];
    return $self->{_config_}->{data}->[2];
}

sub cy0 ($;$) {
    my $self = shift;
    my $val  = shift;
    $self->{_config_}->{canvas}->[1] = $val if defined $val;
    confess("canvas min y value not set")
      unless defined $self->{_config_}->{canvas}->[1];
    return $self->{_config_}->{canvas}->[1];
}

sub cy1 ($;$) {
    my $self = shift;
    my $val  = shift;
    $self->{_config_}->{canvas}->[3] = $val if defined $val;
    confess("canvas max y value not set")
      unless defined $self->{_config_}->{canvas}->[3];
    return $self->{_config_}->{canvas}->[3];
}

sub dy0 ($;$) {
    my $self = shift;
    my $val  = shift;
    $self->{_config_}->{data}->[1] = $val if defined $val;
    confess("datamin y value not set")
      unless defined $self->{_config_}->{data}->[1];
    return $self->{_config_}->{data}->[1];
}

sub dy1 ($;$) {
    my $self = shift;
    my $val  = shift;
    $self->{_config_}->{data}->[3] = $val if defined $val;
    confess("data max y value not set")
      unless defined $self->{_config_}->{data}->[3];
    return $self->{_config_}->{data}->[3];
}

=head2 map($x,$y)

Map an array or a value from the (x,y) data axes to the (x,y) canvas axes

=cut

sub map ($$$) {
    my $self = shift;
    my $x    = shift;
    my $y    = shift;
    croak "map error: x is undefined" unless defined $x;
    croak "map error: y is undefined" unless defined $y;

    #be flexible about single values or array refs
    $x = [$x] unless ref($x) eq 'ARRAY';
    $y = [$y] unless ref($y) eq 'ARRAY';
    croak "Error: x and y arrays different lengths"
      unless ( scalar @$x == scalar @$y );

    my @p_x = map {
        ( ( $_ - $self->dx0 ) * $self->{map}->{x}->{s} ) +
          $self->{map}->{x}->{t}
    } @$x;
    my @p_y = map {
        ( ( $self->dy1 - $_ ) * $self->{map}->{y}->{s} ) +
          $self->{map}->{y}->{t}
    } @$y;

    return ( \@p_x, \@p_y );
}

=head2 mapX

Map an array or a value of the x data axis to the x canvas axis

=cut

sub mapX ($$) {
    my $self = shift;
    my $x    = shift;
    croak "x is undefined" unless defined $x;

    #be flexible about single values or array refs
    $x = [$x] unless ref($x) eq 'ARRAY';

    my @p_x = map {
        ( ( $_ - $self->dx0 ) * $self->{map}->{x}->{s} ) +
          $self->{map}->{x}->{t}
    } @$x;
    return $p_x[0] if scalar @p_x == 1;
    return ( \@p_x );
}

=head2 mapY

Map an array or a value of the y data axis to the y canvas axis

=cut

sub mapY ($$) {
    my $self = shift;
    my $y    = shift;
    croak "y is undefined" unless defined $y;

    #be flexible about single values or array refs
    $y = [$y] unless ref($y) eq 'ARRAY';
    my @p_y = map {
        ( ( $self->dy1 - $_ ) * $self->{map}->{y}->{s} ) +
          $self->{map}->{y}->{t}
    } @$y;
    return $p_y[0] if scalar @p_y == 1;
    return ( \@p_y );
}

=head2 Max

Find th of an array

 my $x = $t->Max([1,2,3,4,5]);

This utility needed a home and this seems like a convenient place to stick it

=cut

#subs Max, Min from:
#https://lists.dulug.duke.edu/pipermail/dulug/2001-March/009326.html

sub Max {

    my $self = shift;

    # takes an array ref - returns the max

    my $list = shift;
    my $max  = $list->[0];

    #foreach (@$list) {
    map { $max = $_ if ( $_ > $max ) } @$list;

    #}

    return ($max);
}

=head2 Min

Find th of an array

 my $x = $t->Max([1,2,3,4,5]);


=cut

sub Min {

    # takes an array ref - returns the min
    my $self = shift;
    my $list = shift;
    my $min  = $list->[0];

    #foreach (@$list) {
    map { $min = $_ if ( $_ < $min ) } @$list;

    #$min = $_ if ( $_ < $min );
    #}

    return ($min);
}

=head1 SEE ALSO

SVG SVG::Parser SVG::DOM SVG::Element SVG::Graph SVG::Extension

=head1 AUTHOR

Ronan Oger, E<lt>ronan@cpan.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2009 by Ronan Oger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
__END__
