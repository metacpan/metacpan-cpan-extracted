package VRML::VRML2::Standard;

############################## Copyright ##############################
#                                                                     #
# This program is Copyright 1996,1998 by Hartmut Palm.                #
# This program is free software; you can redistribute it and/or       #
# modify it under the terms of the GNU General Public License         #
# as published by the Free Software Foundation; either version 2      #
# of the License, or (at your option) any later version.              #
#                                                                     #
# This program is distributed in the hope that it will be useful,     #
# but WITHOUT ANY WARRANTY; without even the implied warranty of      #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       #
# GNU General Public License for more details.                        #
#                                                                     #
# If you do not have a copy of the GNU General Public License write   #
# to the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,     #
# MA 02139, USA.                                                      #
#                                                                     #
#######################################################################

require 5.000;
require VRML::Base;
use strict;
use vars qw(@ISA $VERSION $AUTOLOAD);
@ISA = qw(VRML::Base);
$VERSION = "1.07";

=head1 NAME

VRML::VRML2::Standard.pm - implements VRML 2.0/97 standard nodes

=head1 SYNOPSIS

    use VRML::VRML2::Standard;

=head1 DESCRIPTION

Following nodes are currently implemented.

[C<Grouping Nodes>]
[C<Special Groups>]
[C<Common Nodes>]

[C<Geometry>]
[C<Geometric Properties>]
[C<Appearance>]

[C<Sensors>]
[C<Interpolators>]
[C<Bindable Nodes>]

=cut

sub new {
    my $class = shift;
    my $self = new VRML::Base;
    $self->{'Content-type'} = "model/vrml";
    $self->{'VRML'} = ["#VRML V2.0 utf8\n"];
    return bless $self, $class;
}

#####################################################################
#                        VRML Implementation                        #
#####################################################################

=head2 Grouping Nodes

These nodes B<NEED> B<End> if the $children parameter is empty !

=over 4

=cut

#--------------------------------------------------------------------

=item Anchor

C<Anchor($url, $description, $parameter, $bboxSize, $bboxCenter, $children)>

Currently only the first part of I<$parameter> is supported.

=cut

sub Anchor {
    my $self = shift;
    my ($url, $description, $parameter, $bboxSize, $bboxCenter, $children) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Anchor {\n";
    $vrml .= $self->{'TAB'}."    url    \"".$self->escape($url)."\"\n";
    $vrml .= $self->{'TAB'}."    description    \"".$self->utf8($description)."\"\n" if defined $description;
    $vrml .= $self->{'TAB'}."    parameter      \"$parameter\"\n" if $parameter;
    $vrml .= $self->{'TAB'}."    bboxSize       $bboxSize\n" if $bboxSize;
    $vrml .= $self->{'TAB'}."    bboxCenter     $bboxCenter\n" if $bboxCenter;
    $vrml .= $self->{'TAB'}."    children [\n";
    $self->{'TAB'} .= "\t";
    push @{$self->{'VRML'}}, $vrml;
    if (defined $children) {
        $vrml = "";
        if (ref($children) eq "CODE") {
            &$children;
        } else {
            $vrml .= $self->{'TAB'}."$children\n";
        }
        chop($self->{'TAB'});
        $vrml .= $self->{'TAB'}."    ]\n";
        $vrml .= $self->{'TAB'}."}\n";
        push @{$self->{'VRML'}}, $vrml;
    }
    return $self;
}

=item Billboard

C<Billboard($axisOfRotation, $children)>

=cut

sub Billboard {
    my $self = shift;
    my ($axisOfRotation,$children) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Billboard {\n";
    $vrml .= $self->{'TAB'}."    axisOfRotation $axisOfRotation\n";
    $vrml .= $self->{'TAB'}."    children [\n";
    $self->{'TAB'} .= "\t";
    push @{$self->{'VRML'}}, $vrml;
    if (defined $children) {
        $vrml = "";
        if (ref($children) eq "CODE") {
            &$children;
        } else {
            $vrml .= $self->{'TAB'}."$children\n";
        }
        chop($self->{'TAB'});
        $vrml .= $self->{'TAB'}."    ]\n";
        $vrml .= $self->{'TAB'}."}\n";
        push @{$self->{'VRML'}}, $vrml;
    }
    return $self;
}

=item Collision

C<Collision($collide, $proxy, $children)>

=cut

sub Collision {
    my $self = shift;
    my ($collide, $proxy, $children) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Collision {\n";
    $vrml .= $self->{'TAB'}."    collide        $collide\n";
    if (defined $proxy) {
        $vrml .= $self->{'TAB'}."    proxy \n";
        push @{$self->{'VRML'}}, $vrml;
        $vrml = "";
        $self->{'TAB'} .= "\t";
        if (ref($proxy) eq "CODE") {
            &$proxy;
        } else {
            $vrml .= $self->{'TAB'}."$proxy\n";
        }
        chop($self->{'TAB'});
    }
    $vrml .= $self->{'TAB'}."    children [\n";
    push @{$self->{'VRML'}}, $vrml;
    $self->{'TAB'} .= "\t";
    if (defined $children) {
        $vrml = "";
        if (ref($children) eq "CODE") {
            &$children;
        } else {
            $vrml .= $self->{'TAB'}."$children\n";
        }
        chop($self->{'TAB'});
        $vrml .= $self->{'TAB'}."    ]\n";
        $vrml .= $self->{'TAB'}."}\n";
        push @{$self->{'VRML'}}, $vrml;
    }
    return $self;
}

=item Group

C<Group($bboxSize, $bboxCenter)>

=cut

sub Group {
    my $self = shift;
    my ($bboxSize, $bboxCenter, $children) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Group {\n";
    $vrml .= $self->{'TAB'}."    bboxSize       $bboxSize\n" if $bboxSize;
    $vrml .= $self->{'TAB'}."    bboxCenter     $bboxCenter\n" if $bboxCenter;
    $vrml .= $self->{'TAB'}."    children [\n";
    $self->{'TAB'} .= "\t";
    push @{$self->{'VRML'}}, $vrml;
    if (defined $children) {
        $vrml = "";
        if (ref($children) eq "CODE") {
            &$children;
        } else {
            $vrml .= $self->{'TAB'}."$children\n";
        }
        chop($self->{'TAB'});
        $vrml .= $self->{'TAB'}."    ]\n";
        $vrml .= $self->{'TAB'}."}\n";
        push @{$self->{'VRML'}}, $vrml;
    }
    return $self;
}

=item Transform

C<Transform($translation, $rotation, $scale, $scaleOrientation, $center, $bboxSize, $bboxCenter)>

$translation is a SFVec3f

$rotation is a SFRotation

$scale is a SFVec3f

$scaleOrientation is a SFRotation

$center is a SFVec3f

=cut

sub Transform {
    my $self = shift;
    my ($translation, $rotation, $scale, $scaleOrientation, $center, $bboxSize, $bboxCenter) = @_;
    unless ($self->{'XYZ'}[0]) {
        $self->_row("# To many end's !\n");
    } else {
        unshift @{$self->{'XYZ'}}, [@{$self->{'XYZ'}[0]}];
        $self->xyz($self->string_to_array($translation)) if (defined $translation);
    }
    my $vrml = "";
    $vrml = $self->{'TAB'}."Transform {\n";
    $vrml .= $self->{'TAB'}."    translation    $translation\n" if $translation;
    $vrml .= $self->{'TAB'}."    rotation       $rotation\n" if $rotation;
    $vrml .= $self->{'TAB'}."    scale          $scale\n" if $scale;
    $vrml .= $self->{'TAB'}."    scaleOrientation       $scaleOrientation\n" if $scaleOrientation;
    $vrml .= $self->{'TAB'}."    center         $center\n" if $center;
    $vrml .= $self->{'TAB'}."    bboxSize       $bboxSize\n" if $bboxSize;
    $vrml .= $self->{'TAB'}."    bboxCenter     $bboxCenter\n" if $bboxCenter;
    $vrml .= $self->{'TAB'}."    children [\n";
    $self->{'TAB'} .= "\t";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

#--------------------------------------------------------------------

=back

=head2 Special Groups

=over 4

=cut

#--------------------------------------------------------------------

=item Inline

C<Inline($url, $bboxSize, $bboxCenter)>

=cut

sub Inline {
    my $self = shift;
    my $vrml = "";
    my ($url, $bboxSize, $bboxCenter) = @_;
    $vrml = $self->{'TAB'}."Inline {\n";
    $vrml .= $self->{'TAB'}."   url     \"".$self->escape($url)."\"\n";
    $vrml .= $self->{'TAB'}."   bboxSize $bboxSize\n" if $bboxSize;
    $vrml .= $self->{'TAB'}."   bboxCenter $bboxCenter\n" if $bboxCenter;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item LOD

C<LOD($range, $center)>

$range is a MFFloat

$center is a SFVec3f

Example: C<LOD([1, 2, 5], '0 0 0')>

=cut

sub LOD {
    my $self = shift;
    my ($range, $center) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."LOD {\n";
    if ($range) {
        if (ref($range) eq "ARRAY") {
            $vrml .= $self->{'TAB'}."    range [".join(',',@$range)."]\n";
        } else {
            $vrml .= $self->{'TAB'}."    range [$range]\n";
        }
    }
    $vrml .= $self->{'TAB'}."    center $center\n" if $center;
    $vrml .= $self->{'TAB'}."    level [\n";
    $self->{'TAB'} .= "\t";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Switch

C<Switch($whichChoice)>

=cut

sub Switch {
    my $self = shift;
    my ($whichChoice) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Switch {\n";
    $vrml .= $self->{'TAB'}."    whichChoice $whichChoice\n" if defined $whichChoice;
    $vrml .= $self->{'TAB'}."    choice [\n";
    $self->{'TAB'} .= "\t";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

#--------------------------------------------------------------------

=back

=head2 Common Nodes

=over 4

=cut

#--------------------------------------------------------------------

=item DirectionalLight

C<DirectionalLight($direction, $intensity, $ambientIntensity, $color, $on)>

=cut

sub DirectionalLight {
    my $self = shift;
    my ($direction, $intensity, $ambientIntensity, $color, $on) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."DirectionalLight {\n";
    $vrml .= $self->{'TAB'}."   direction       $direction\n" if $direction;
    $vrml .= $self->{'TAB'}."   intensity       $intensity\n" if $intensity;
    $vrml .= $self->{'TAB'}."   ambientIntensity        $ambientIntensity\n" if $ambientIntensity;
    $vrml .= $self->{'TAB'}."   color   $color\n" if $color;
    $vrml .= $self->{'TAB'}."   on      $on\n" if $on;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item PointLight

C<PointLight($location, $intensity, $ambientIntensity, $color, $on)>

=cut

sub PointLight {
    my $self = shift;
    my ($location, $intensity, $ambientIntensity, $color, $on) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."PointLight {\n";
    $vrml .= $self->{'TAB'}."   location        $location\n" if $location;
    $vrml .= $self->{'TAB'}."   intensity       $intensity\n" if $intensity;
    $vrml .= $self->{'TAB'}."   ambientIntensity        $ambientIntensity\n" if $ambientIntensity;
    $vrml .= $self->{'TAB'}."   color   $color\n" if $color;
    $vrml .= $self->{'TAB'}."   on      $on\n" if $on;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item SpotLight

C<SpotLight($location, $direction, $intensity, $color, $on)>

=cut

sub SpotLight {
    my $self = shift;
    my ($location, $direction, $intensity, $color, $on) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."SpotLight {\n";
    $vrml .= $self->{'TAB'}."   location        $location\n" if $location;
    $vrml .= $self->{'TAB'}."   direction       $direction\n" if $direction;
    $vrml .= $self->{'TAB'}."   intensity       $intensity\n" if $intensity;
    $vrml .= $self->{'TAB'}."   color   $color\n" if $color;
    $vrml .= $self->{'TAB'}."   on      $on\n" if $on;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Sound

C<Sound($source, $location, $direction, $intensity, $maxFront, $maxBack, $minFront, $minBack, $priority, $spatialize)>

=cut

sub Sound {
    my $self = shift;
    my ($source, $location, $direction, $intensity, $maxFront, $maxBack, $minFront, $minBack, $priority, $spatialize) = @_;
    my $vrml = $self->{'TAB'}."Sound {\n";
    $vrml .= $self->{'TAB'}."   location        $location\n" if $location;
    $vrml .= $self->{'TAB'}."   direction       $direction\n" if $direction;
    $vrml .= $self->{'TAB'}."   intensity       $intensity\n" if $intensity;
    $vrml .= $self->{'TAB'}."   maxFront        $maxFront\n" if $maxFront;
    $vrml .= $self->{'TAB'}."   maxBack         $maxBack\n" if $maxBack;
    $vrml .= $self->{'TAB'}."   minFront        $minFront\n" if $minFront;
    $vrml .= $self->{'TAB'}."   minBack         $minBack\n" if $minBack;
    $vrml .= $self->{'TAB'}."   priority        $priority\n" if $priority;
    $vrml .= $self->{'TAB'}."   spatialize      $spatialize\n" if $spatialize;
    if (defined $source) {
        if (ref($source) eq "CODE") {
            $vrml .= $self->{'TAB'}."   source ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$source;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   source $source\n";
        }
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item AudioClip

C<AudioClip($url, $description, $loop, $pitch, $startTime, $stopTime)>

=cut

sub AudioClip {
    my $self = shift;
    my $vrml = "";
    my ($url, $description, $loop, $pitch, $startTime, $stopTime) = @_;
    $vrml = $self->{'TAB'}."AudioClip {\n";
    $vrml .= $self->{'TAB'}."   url             \"".$self->escape($url)."\"\n" if $url;
    $vrml .= $self->{'TAB'}."   description     \"".$self->utf8($description)."\"\n" if defined $description;
    $vrml .= $self->{'TAB'}."   loop            $loop\n" if $loop;
    $vrml .= $self->{'TAB'}."   pitch           $pitch\n" if $pitch;
    $vrml .= $self->{'TAB'}."   startTime       $startTime\n" if defined $startTime;
    $vrml .= $self->{'TAB'}."   stopTime        $stopTime\n" if defined $stopTime;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item WorldInfo

C<WorldInfo($title, $info)>

=cut

sub WorldInfo {
    my $self = shift;
    my ($title, $info) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."WorldInfo {\n";
    $vrml .= $self->{'TAB'}."   title   \"".$self->utf8($title)."\"\n" if $title;
    if (defined $info) {
        if (ref($info) eq "ARRAY") {
            $info = "[\"".join("\",\n$self->{'TAB'}     \"",@$info)."\"]";
        } else {
            $info = qq{"$info"};
        }
        $vrml .= $self->{'TAB'}."       info    ".$self->utf8($info)."\n";
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Shape

C<Shape($geometry, $appearance)>

=cut

sub Shape {
    my $self = shift;
    my ($geometry, $appearance) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Shape {\n";
    if (defined $appearance) {
        if (ref($appearance) eq "CODE") {
            $vrml .= $self->{'TAB'}."   appearance ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$appearance;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   appearance $appearance\n";
        }
    }
    if (defined $geometry) {
        if (ref($geometry) eq "CODE") {
            $vrml .= $self->{'TAB'}."   geometry ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$geometry;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   geometry $geometry\n";
        }
    }
    $vrml .= $self->{'TAB'}."}";
    $vrml .= "# Shape" if $self->{'DEBUG'};
    $vrml .= "\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

#--------------------------------------------------------------------

=back

=head2 Geometry

=over 4

=cut

#--------------------------------------------------------------------

=item Box

C<Box($size)>

=cut

sub Box {
    my $self = shift;
    my ($size) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Box {\n";
    $vrml .= $self->{'TAB'}."   size    $size\n" if $size;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Cone

C<Cone($radius, $height, $side, $bottom)>

=cut

sub Cone {
    my $self = shift;
    my ($radius, $height, $side, $bottom) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Cone {\n";
    $vrml .= $self->{'TAB'}."   bottomRadius    $radius\n" if $radius;
    $vrml .= $self->{'TAB'}."   height  $height\n" if $height;
    $vrml .= $self->{'TAB'}."   side    $side\n" if $side;
    $vrml .= $self->{'TAB'}."   bottom  $bottom\n" if $bottom;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Cylinder

C<Cylinder($radius, $height, $top, $side, $bottom)>

=cut

sub Cylinder {
    my $self = shift;
    my ($radius, $height, $top, $side, $bottom) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Cylinder {\n";
    $vrml .= $self->{'TAB'}."   radius  $radius\n" if defined $radius;
    $vrml .= $self->{'TAB'}."   height  $height\n" if defined $height;
    $vrml .= $self->{'TAB'}."   top     $top\n" if $top;
    $vrml .= $self->{'TAB'}."   side    $side\n" if $side;
    $vrml .= $self->{'TAB'}."   bottom  $bottom\n" if $bottom;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item ElevationGrid

C<ElevationGrid($xDimension, $zDimension, $xSpacing, $zSpacing, $height, $creaseAngle, $color, $colorPerVertex, $solid)>

$height should be a reference of a list of height values
like C<['0 1 3 2', '2 3 5 4', ...]>

$color can be a reference to a subroutine or list of color values

=cut

sub ElevationGrid {
    my $self = shift;
    my ($xDimension, $zDimension, $xSpacing, $zSpacing, $height, $creaseAngle, $color, $colorPerVertex, $solid) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."ElevationGrid {\n";
    $vrml .= $self->{'TAB'}."   xDimension      $xDimension\n";
    $vrml .= $self->{'TAB'}."   zDimension      $zDimension\n";
    $vrml .= $self->{'TAB'}."   xSpacing        $xSpacing\n" if defined $xSpacing;
    $vrml .= $self->{'TAB'}."   zSpacing        $zSpacing\n" if defined $zSpacing;
    $vrml .= $self->{'TAB'}."   solid   $solid\n" if defined $solid;
    $vrml .= $self->{'TAB'}."   creaseAngle     $creaseAngle\n" if defined $creaseAngle;
    if (ref($height) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       height [\n";
        $vrml .= $self->{'TAB'}."\t\t";
        $vrml .= join("$self->{'TAB'}\t\t",@$height);
        $vrml .= $self->{'TAB'}."       ]\n";
    }
    if (defined $color) {
        if (ref($color) eq "ARRAY") {
            $vrml .= $self->{'TAB'}."   color Color { color [\n";
            $vrml .= $self->{'TAB'}."\t\t";
            $vrml .= join("$self->{'TAB'}\t\t",@$color);
            $vrml .= $self->{'TAB'}."   ] }\n";
        } else {
            $vrml .= $self->{'TAB'}."   color $color\n";
        }
        $vrml .= $self->{'TAB'}."       colorPerVertex  $colorPerVertex\n" if $colorPerVertex;
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Extrusion

C<Extrusion($crossSection, $spine, $scale, $orientation, $beginCap, $endCap, $creaseAngle, $solid, $convex, $ccw)>

$crossSection must be a reference of a list of XY values
like C<[ '1 1', '1 -1', '-1 -1', '-1 1', '1  1' ]>

$spine must be a reference of a list of spine values
like C<['0 0 0', '0 1 0', ...]>

=cut

sub Extrusion {
    my $self = shift;
    my ($crossSection, $spine, $scale, $orientation, $beginCap, $endCap, $creaseAngle, $solid, $convex, $ccw) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Extrusion {\n";
    $vrml .= $self->{'TAB'}."   beginCap        $beginCap\n" if defined $beginCap;
    $vrml .= $self->{'TAB'}."   endCap  $endCap\n" if defined $endCap;
    $vrml .= $self->{'TAB'}."   creaseAngle     $creaseAngle\n" if defined $creaseAngle;
    $vrml .= $self->{'TAB'}."   solid   $solid\n" if defined $solid;
    $vrml .= $self->{'TAB'}."   convex  $convex\n" if defined $convex;
    $vrml .= $self->{'TAB'}."   ccw     $ccw\n" if defined $ccw;
    if ($crossSection) {
        $vrml .= $self->{'TAB'}."       crossSection [\n";
        $vrml .= $self->{'TAB'}."\t\t";
        $vrml .= join("\n$self->{'TAB'}\t\t",@$crossSection);
        $vrml .= "\n".$self->{'TAB'}."  ]\n";
    }
    if ($spine) {
        $vrml .= $self->{'TAB'}."       spine [\n";
        $vrml .= $self->{'TAB'}."\t\t";
        $vrml .= join("\n$self->{'TAB'}\t\t",@$spine);
        $vrml .= "\n".$self->{'TAB'}."  ]\n";
    }
    if ($scale) {
        $vrml .= $self->{'TAB'}."       scale [\n";
        $vrml .= $self->{'TAB'}."\t\t";
        $vrml .= join("\n$self->{'TAB'}\t\t",@$scale);
        $vrml .= "\n".$self->{'TAB'}."  ]\n";
    }
    if ($orientation) {
        $vrml .= $self->{'TAB'}."       orientation [\n";
        $vrml .= $self->{'TAB'}."\t\t";
        $vrml .= join("\n$self->{'TAB'}\t\t",@$orientation);
        $vrml .= "\n".$self->{'TAB'}."  ]\n";
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item IndexedFaceSet

C<IndexedFaceSet($coord, $coordIndex, $color, $colorIndex, $colorPerVertex, $normal, $normalIndex, $texCoord, $texCoordIndex)>

$coordIndex can be a string with a list of point index
like C<'0 1 3 2', '2 3 5 4', ...> or a reference of list of point index

$coordIndex can be a string or a reference of a list of colors index

$normalIndex can be a string or a reference of a list of normals index

$texCoordIndex can be a string or a reference of a list of textures index

=cut

sub IndexedFaceSet {
    my $self = shift;
    my ($coord, $coordIndex, $color, $colorIndex, $colorPerVertex, $normal, $normalIndex, $texCoord, $texCoordIndex) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."IndexedFaceSet {\n";
    if (defined $coord) {
        if (ref($coord) eq "CODE") {
            $vrml .= $self->{'TAB'}."   coord ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$coord;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   coord $coord\n";
        }
    }
    if ($coordIndex) {
        if (ref($coordIndex) eq "ARRAY") {
            $vrml .= $self->{'TAB'}."   coordIndex [\n";
            $vrml .= $self->{'TAB'}."\t\t";
            $vrml .= join(", -1,\n$self->{'TAB'}\t\t",@$coordIndex);
            $vrml .= ", -1\n".$self->{'TAB'}."  ]\n";
        } else {
            $vrml .= $self->{'TAB'}."   coordIndex [ $coordIndex ]\n";
        }
    }
    if (defined $color) {
        if (ref($color) eq "CODE") { # Color Node
            $vrml .= $self->{'TAB'}."   color ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$color;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } elsif (ref($colorIndex) eq "ARRAY") {
            $vrml .= $self->{'TAB'}."   color Color { color [\n";
            $vrml .= $self->{'TAB'}."\t\t";
            $vrml .= join(",\n$self->{'TAB'}\t\t",@$colorIndex);
            $vrml .= "\n".$self->{'TAB'}."      ] }\n";
        } else {
            $vrml .= $self->{'TAB'}."   color $color\n";
        }
        if ($colorIndex) {
            $vrml .= $self->{'TAB'}."   colorIndex [\n";
            if (ref($colorIndex) eq "ARRAY") {
                $vrml .= $self->{'TAB'}."\t\t";
                if (defined $colorPerVertex && $colorPerVertex eq "FALSE") {
                    $vrml .= join(",\n$self->{'TAB'}\t\t",@$colorIndex);
                } else {
                    $vrml .= join(", -1\n$self->{'TAB'}\t\t",@$colorIndex);
                }
            } else {
                $vrml .= $colorIndex;
            }
            $vrml .= "\n".$self->{'TAB'}."      ]\n";
        }
        $vrml .= $self->{'TAB'}."       colorPerVertex  $colorPerVertex\n" if $colorPerVertex;
    }
    if ($normalIndex) {
        if (ref($normalIndex) eq "ARRAY") {
            $vrml .= $self->{'TAB'}."   normalIndex [\n";
            $vrml .= $self->{'TAB'}."\t\t";
            $vrml .= join(", -1,\n$self->{'TAB'}\t\t",@$normalIndex);
            $vrml .= ", -1\n".$self->{'TAB'}."  ]\n";
        } else {
            $vrml .= $self->{'TAB'}."   normalIndex [ $normalIndex ]\n";
        }
    }
    if ($texCoordIndex) {
        if (ref($texCoordIndex) eq "ARRAY") {
            $vrml .= $self->{'TAB'}."   texCoordIndex [\n";
            $vrml .= $self->{'TAB'}."\t\t";
            $vrml .= join(", -1,\n$self->{'TAB'}\t\t",@$texCoordIndex);
            $vrml .= ", -1\n".$self->{'TAB'}."  ]\n";
        } else {
            $vrml .= $self->{'TAB'}."   texCoordIndex [ $texCoordIndex ]\n";
        }
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item IndexedLineSet

C<IndexedLineSet($coord, $coordIndex, $color, $colorIndex, $colorPerVertex)>

$coord can be a string with the C<Coordinate> node or a reference to a
C<Coordinate> method

$coordIndex can be a string or a reference of a list of point index
like C<'0, 1, 3, 2', '2, 3, 5, 4', ...>

$color can be a string with the <Color> node or a reference of a <Color> method

$colorIndex can be a string or a reference of a list of color index

=cut

sub IndexedLineSet {
    my $self = shift;
    my ($coord, $coordIndex, $color, $colorIndex, $colorPerVertex) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."IndexedLineSet {\n";
    if (defined $coord) {
        if (ref($coord) eq "CODE") {
            $vrml .= $self->{'TAB'}."   coord ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$coord;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   coord $coord\n";
        }
    }
    if ($coordIndex) {
        if (ref($coordIndex) eq "ARRAY") {
            $vrml .= $self->{'TAB'}."   coordIndex [\n";
            $vrml .= $self->{'TAB'}."\t\t";
            $vrml .= join(", -1,\n$self->{'TAB'}\t\t",@$coordIndex);
            $vrml .= ", -1\n".$self->{'TAB'}."  ]\n";
        } else {
            $vrml .= $self->{'TAB'}."   coordIndex [ $coordIndex ]\n";
        }
    }
    if (defined $color) {
        if (ref($color) eq "CODE") {
            $vrml .= $self->{'TAB'}."   color ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$color;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   color $color\n";
        }
        if ($colorIndex) {
            $vrml .= $self->{'TAB'}."   colorIndex [\n";
            if (ref($colorIndex) eq "ARRAY") {
                $vrml .= $self->{'TAB'}."\t\t";
                if (defined $colorPerVertex && $colorPerVertex eq "FALSE") {
                    $vrml .= join(",\n$self->{'TAB'}\t\t",@$colorIndex);
                } else {
                    $vrml .= join(", -1\n$self->{'TAB'}\t\t",@$colorIndex);
                }
            } else {
                $vrml .= $colorIndex;
            }
            $vrml .= "\n".$self->{'TAB'}."      ]\n";
        }
        $vrml .= $self->{'TAB'}."       colorPerVertex  $colorPerVertex\n" if $colorPerVertex;
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item PointSet

C<PointSet($coord, $color)>

=cut

sub PointSet {
    my $self = shift;
    my ($coord, $color) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."PointSet {\n";
    if (defined $coord) {
        if (ref($coord) eq "CODE") {
            $vrml .= $self->{'TAB'}."   coord ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$coord;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   coord $coord\n";
        }
    }
    if (defined $color) {
        if (ref($color) eq "CODE") {
            $vrml .= $self->{'TAB'}."   color ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$color;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   color $color\n";
        }
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Sphere

C<Sphere($radius)>

$radius have to be > 0

=cut

sub Sphere {
    my $self = shift;
    my ($radius) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Sphere {\n";
    $vrml .= $self->{'TAB'}."   radius  $radius\n" if $radius;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Text

C<Text($string, $fontStyle, $length, $maxExtent)>

=cut

sub Text {
    my $self = shift;
    my ($string, $fontStyle, $length, $maxExtent) = @_;
    return unless $string;
    my $vrml = $self->{'TAB'}."Text {\n";
    $vrml .= $self->{'TAB'}."   string ".$self->utf8($string)."\n";
    if (defined $fontStyle) {
        if (ref($fontStyle) eq "CODE") { # FontStyle Node
            $vrml .= $self->{'TAB'}."   fontStyle ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$fontStyle;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   fontStyle $fontStyle\n";
        }
    }
    $vrml .= $self->{'TAB'}."   length $length\n" if $length;
    $vrml .= $self->{'TAB'}."   maxExtent $maxExtent\n" if $maxExtent;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

#--------------------------------------------------------------------

=back

=head2 Geometric Properties

=over 4

=cut

#--------------------------------------------------------------------

=item Coordinate

C<Coordinate(@point)>

@point should be a list of points with strings like C<'1.0 0.0 0.0', '-1 2 0'>

=cut

sub Coordinate {
    my $self = shift;
    my (@point) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Coordinate {\n";
    $vrml .= $self->{'TAB'}."   point [\n";
    $vrml .= $self->{'TAB'}."\t\t";
    $vrml .= join(",\n$self->{'TAB'}\t\t",@point);
    $vrml .= "\n".$self->{'TAB'}."      ]\n";
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Color

C<Color(@color)>

@color should be a list of colors with strings like C<'1.0 0.0 0.0', '.3 .2 .1'>

=cut

sub Color {
    my $self = shift;
    my (@color) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Color {\n";
    $vrml .= $self->{'TAB'}."   color [\n";
    $vrml .= $self->{'TAB'}."\t\t";
    $vrml .= join(",\n$self->{'TAB'}\t\t",@color);
    $vrml .= "\n".$self->{'TAB'}."      ]\n";
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Normal

C<Normal(@vector)>

@vector should be a list of vectors with strings like C<'1.0 0.0 0.0', '.4 .2 0'>

=cut

sub Normal {
    my $self = shift;
    my (@vector) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Normal {\n";
    $vrml .= $self->{'TAB'}."   vector [\n$self->{'TAB'}\t\t";
    $vrml .= join(",\n$self->{'TAB'}\t\t",@vector);
    $vrml .= "\n".$self->{'TAB'}."\t]\n";
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}


#--------------------------------------------------------------------

=back

=head2 Appearance

=over 4

=cut

#--------------------------------------------------------------------

=item Appearance

C<Appearance($material, $texture, $textureTransform)>

=cut

sub Appearance {
    my $self = shift;
    my ($material, $texture, $textureTransform) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Appearance {\n";
    if (defined $material) {
        $vrml .= $self->{'TAB'}."       material ";
        if (ref($material)) {
            push @{$self->{'VRML'}}, $vrml;
            $vrml = "";
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            if (ref($material) eq "CODE") { # Material Node
                &$material;
            } elsif (ref($material) eq "ARRAY") {
                $self->Material(@$material);
            } elsif (ref($material) eq "HASH") {
                $self->Material(%$material);
            }
            $self->_trim($pos);
            chop($self->{'TAB'});
        } else {
            $vrml .= "Material {$material}\n";
        }
    }
    if (defined $texture) {
        if (ref($texture) eq "CODE") {
            $vrml .= $self->{'TAB'}."   texture ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$texture;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   texture $texture\n";
        }
    }
    if (defined $textureTransform) {
        if (ref($textureTransform) eq "CODE") {
            $vrml .= $self->{'TAB'}."   textureTransform ";
            push @{$self->{'VRML'}}, $vrml;
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$textureTransform;
            $self->_trim($pos);
            chop($self->{'TAB'});
            $vrml = "";
        } else {
            $vrml .= $self->{'TAB'}."   textureTransform $textureTransform\n";
        }
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Fontstyle

C<FontStyle($size, $family, $style, $justify, $language)>
defines the current font style for the current C<Text> Nodes


$style can be 'PLAIN','BOLD','ITALIC','BOLD ITALIC'

$familiy can be 'SERIF','SANS','TYPEWRITER'

$justify can be 'BEGIN', 'MIDDLE', 'END'

=cut

sub FontStyle {
    my $self = shift;
    my ($size, $family, $style, $justify, $language) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."FontStyle {\n";
    $vrml .= $self->{'TAB'}."   size $size\n" if $size;
    $vrml .= $self->{'TAB'}."   family \"$family\"\n" if $family;
    $vrml .= $self->{'TAB'}."   style \"$style\"\n" if $style;
    $vrml .= $self->{'TAB'}."   justify \"$justify\"\n" if $justify;
    $vrml .= $self->{'TAB'}."   language \"$language\"\n" if $language;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Material

C<Material(%materials)>

=cut

sub Material {
    my $self = shift;
    my (%materials) = @_;
    my $vrml = "";
    my ($key, $value);
    $vrml = $self->{'TAB'}."Material {\n";
    while(($key,$value) = each %materials) {
        $vrml .= $self->{'TAB'}."       $key    $value\n";
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item ImageTexture

C<ImageTexture($url)>

=cut

sub ImageTexture {
    my $self = shift;
    my ($url, $repeatS, $repeatT) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."ImageTexture {\n";
    $vrml .= $self->{'TAB'}."   url     \"".$self->escape($url)."\"\n";
    $vrml .= $self->{'TAB'}."   repeatS $repeatS\n" if $repeatS;
    $vrml .= $self->{'TAB'}."   repeatT $repeatT\n" if $repeatT;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item MovieTexture

C<MovieTexture($url)>

=cut

sub MovieTexture {
    my $self = shift;
    my ($url, $loop, $startTime, $stopTime, $repeatS, $repeatT) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."MovieTexture {\n";
    $vrml .= $self->{'TAB'}."   url     \"".$self->escape($url)."\"\n";
    $vrml .= $self->{'TAB'}."   loop    $loop\n" if $loop;
    $vrml .= $self->{'TAB'}."   startTime       $startTime\n" if $startTime;
    $vrml .= $self->{'TAB'}."   stopTime        $stopTime\n" if $stopTime;
    $vrml .= $self->{'TAB'}."   repeatS $repeatS\n" if $repeatS;
    $vrml .= $self->{'TAB'}."   repeatT $repeatT\n" if $repeatT;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

#--------------------------------------------------------------------

=back

=head2 Sensors

=over 4

=cut

#--------------------------------------------------------------------

=item CylinderSensor

C<CylinderSensor($maxAngle, $minAngle, $diskAngle, $offset, $autoOffset, $enabled)>

=cut

sub CylinderSensor {
    my $self = shift;
    my ($maxAngle, $minAngle, $diskAngle, $offset, $autoOffset, $enabled) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."CylinderSensor {\n";
    $vrml .= $self->{'TAB'}."   maxAngle        $maxAngle\n" if defined $maxAngle;
    $vrml .= $self->{'TAB'}."   minAngle        $minAngle\n" if defined $minAngle;
    $vrml .= $self->{'TAB'}."   diskAngle       $diskAngle\n" if defined $diskAngle;
    $vrml .= $self->{'TAB'}."   offset  $offset\n" if $offset;
    $vrml .= $self->{'TAB'}."   autoOffset      $autoOffset\n" if $autoOffset;
    $vrml .= $self->{'TAB'}."   enabled $enabled\n" if $enabled;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item PlaneSensor

C<PlaneSensor($maxPosition, $minPosition, $offset, $autoOffset, $enabled)>

=cut

sub PlaneSensor {
    my $self = shift;
    my ($maxPosition, $minPosition, $offset, $autoOffset, $enabled) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."PlaneSensor {\n";
    $vrml .= $self->{'TAB'}."   maxPosition     $maxPosition\n" if $maxPosition;
    $vrml .= $self->{'TAB'}."   minPosition     $minPosition\n" if $minPosition;
    $vrml .= $self->{'TAB'}."   offset  $offset\n" if defined $offset;
    $vrml .= $self->{'TAB'}."   autoOffset      $autoOffset\n" if $autoOffset;
    $vrml .= $self->{'TAB'}."   enabled $enabled\n" if $enabled;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item ProximitySensor

C<ProximitySensor($size, $center, $enabled)>

=cut

sub ProximitySensor {
    my $self = shift;
    my ($size, $center, $enabled) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."ProximitySensor {\n";
    $vrml .= $self->{'TAB'}."   size    $size\n" if $size;
    $vrml .= $self->{'TAB'}."   center  $center\n" if $center;
    $vrml .= $self->{'TAB'}."   enabled $enabled\n" if $enabled;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item SphereSensor

C<SphereSensor($offset, $autoOffset, $enabled)>

=cut

sub SphereSensor {
    my $self = shift;
    my ($offset, $autoOffset, $enabled) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."SphereSensor {\n";
    $vrml .= $self->{'TAB'}."   offset  $offset\n" if $offset;
    $vrml .= $self->{'TAB'}."   autoOffset      $autoOffset\n" if $autoOffset;
    $vrml .= $self->{'TAB'}."   enabled $enabled\n" if $enabled;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item TimeSensor

C<TimeSensor($cycleInterval, $loop, $startTime, $stopTime, $enabled)>

=cut

sub TimeSensor {
    my $self = shift;
    my ($cycleInterval, $loop,  $startTime, $stopTime, $enabled) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."TimeSensor {\n";
    $vrml .= $self->{'TAB'}."   cycleInterval   $cycleInterval\n" if $cycleInterval;
    $vrml .= $self->{'TAB'}."   loop    $loop\n" if $loop;
    $vrml .= $self->{'TAB'}."   startTime       $startTime\n" if $startTime;
    $vrml .= $self->{'TAB'}."   stopTime        $stopTime\n" if $stopTime;
    $vrml .= $self->{'TAB'}."   enabled $enabled\n" if $enabled;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item TouchSensor

C<TouchSensor($enabled)>

=cut

sub TouchSensor {
    my $self = shift;
    my ($enabled) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."TouchSensor {";
    $vrml .= $self->{'TAB'}."   enabled $enabled\n" if $enabled;
    $vrml .= "}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item VisibilitySensor

C<VisibilitySensor($size, $center, $enabled)>

=cut

sub VisibilitySensor {
    my $self = shift;
    my ($size, $center, $enabled) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."VisibilitySensor {\n";
    $vrml .= $self->{'TAB'}."   size    $size\n" if $size;
    $vrml .= $self->{'TAB'}."   center  $center\n" if $center;
    $vrml .= $self->{'TAB'}."   enabled $enabled\n" if $enabled;
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

#--------------------------------------------------------------------

=back

=head2 Interpolators

=over 4

=cut

#--------------------------------------------------------------------

=item ColorInterpolator

C<ColorInterpolator($key, $keyValue)>

=cut

sub ColorInterpolator {
    my $self = shift;
    my ($key, $keyValue) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."ColorInterpolator {\n";
    if (ref($key) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       key [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$key)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       key [$key]\n";
    }
    if (ref($keyValue) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       keyValue [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$keyValue)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       keyValue [$keyValue]\n";
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item CoordinateInterpolator

C<CoordinateInterpolator($key, $keyValue)>

=cut

sub CoordinateInterpolator {
    my $self = shift;
    my ($key, $keyValue) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."CoordinateInterpolator {\n";
    if (ref($key) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       key [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$key)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       key [$key]\n";
    }
    if (ref($keyValue) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       keyValue [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$keyValue)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       keyValue [$keyValue]\n";
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item OrientationInterpolator

C<OrientationInterpolator($key, $keyValue)>

=cut

sub OrientationInterpolator {
    my $self = shift;
    my ($key, $keyValue) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."OrientationInterpolator {\n";
    if (ref($key) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       key [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$key)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       key [$key]\n";
    }
    if (ref($keyValue) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       keyValue [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$keyValue)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       keyValue [$keyValue]\n";
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item NormalInterpolator

C<NormalInterpolator($key, $keyValue)>

=cut

sub NormalInterpolator {
    my $self = shift;
    my ($key, $keyValue) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."NormalInterpolator {\n";
    if (ref($key) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       key [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$key)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       key [$key]\n";
    }
    if (ref($keyValue) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       keyValue [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$keyValue)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       keyValue [$keyValue]\n";
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item PositionInterpolator

C<PositionInterpolator($key, $keyValue)>

=cut

sub PositionInterpolator {
    my $self = shift;
    my ($key, $keyValue) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."PositionInterpolator {\n";
    if (ref($key) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       key [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$key)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       key [$key]\n";
    }
    if (ref($keyValue) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       keyValue [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$keyValue)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       keyValue [$keyValue]\n";
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item ScalarInterpolator

C<ScalarInterpolator($key, $keyValue)>

$key    MFFloat
$keyValue       MFFloat

=cut

sub ScalarInterpolator {
    my $self = shift;
    my ($key, $keyValue) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."ScalarInterpolator {\n";
    if (ref($key) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       key [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$key)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       key [$key]\n";
    }
    if (ref($keyValue) eq "ARRAY") {
        $vrml .= $self->{'TAB'}."       keyValue [\n$self->{'TAB'}\t\t".join(",\n$self->{'TAB'}\t\t",@$keyValue)."\n$self->{'TAB'}\t]\n";
    } else {
        $vrml .= $self->{'TAB'}."       keyValue [$keyValue]\n";
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

#--------------------------------------------------------------------

=back

=head2 Bindable Nodes

=over 4

=cut

#--------------------------------------------------------------------

=item Background

C<Background($hash)>

You only can use a hash. Parameter see VRML Spec

=cut

sub Background {
    my $self = shift;
    my (%hash) = @_;
    return unless %hash;
    my $key;
    my $vrml = "";
    $vrml = $self->{'TAB'}."Background {\n";
    foreach $key (keys %hash) {
        $vrml .= $self->{'TAB'}."       $key    $hash{$key}\n" if defined $hash{$key};
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item NavigationInfo

C<NavigationInfo($type, $speed, $headlight, $visibilityLimit, $avatarSize)>

You can use a hash reference or all parameter in the same order above

=cut

sub NavigationInfo {
    my $self = shift;
    my ($type, $speed, $headlight, $visibilityLimit, $avatarSize) = @_;
    my $key;
    my $vrml = "";
    $vrml = $self->{'TAB'}."NavigationInfo {\n";
    if (ref($type) eq "HASH") {
        foreach $key (keys %$type) {
            if (ref($type->{$key}) eq "ARRAY") {
                $vrml .= $self->{'TAB'}."       $key    [".join('","',@{$type->{$key}})."]\n";
            } else {
                $vrml .= $self->{'TAB'}."       $key    $type->{$key}\n";
            }
        }
    } else {
        $type = join('","',@$type) if ref($type) eq "ARRAY";
        $vrml .= $self->{'TAB'}."       type    [\"$type\"]\n" if $type;
        $vrml .= $self->{'TAB'}."       speed   $speed\n" if defined $speed;
        $vrml .= $self->{'TAB'}."       headlight       $headlight\n" if $headlight;
        $vrml .= $self->{'TAB'}."       visibilityLimit $visibilityLimit\n" if defined $visibilityLimit;
        $avatarSize = join(', ',@$avatarSize) if ref($avatarSize) eq "ARRAY";
        $vrml .= $self->{'TAB'}."       avatarSize      [$avatarSize]\n" if $avatarSize;
    }
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item Viewpoint

C<Viewpoint($description, $position, $orientation, $fieldOfView, $jump)>

=cut

sub Viewpoint {
    my $self = shift;
    my ($description, $position, $orientation, $fieldOfView, $jump) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB_VIEW'}."Viewpoint {\n";
    $vrml .= $self->{'TAB_VIEW'}."      description     \"".$self->utf8($description)."\"\n" if $description;
    $vrml .= $self->{'TAB_VIEW'}."      position        $position\n" if $position;
    $vrml .= $self->{'TAB_VIEW'}."      orientation     $orientation\n" if $orientation;
    $vrml .= $self->{'TAB_VIEW'}."      fieldOfView     $fieldOfView\n" if $fieldOfView;
    $vrml .= $self->{'TAB_VIEW'}."      jump    $jump\n" if $jump;
    $vrml .= $self->{'TAB_VIEW'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item PROTO

C<PROTO($name, $declaration, $definition)>

=cut

sub PROTO {
    my $self = shift;
    my ($name, $declaration, $definition) = @_;
    $self->{'PROTO'}{$name} = $#{$self->{'VRML'}};
    my $vrml = $self->{'TAB'}."PROTO $name ";
    $self->{'TAB'} .= "\t";
    push @{$self->{'VRML'}}, $vrml;
    $vrml = "";
    if (defined $declaration) {
        if (ref($declaration) eq "ARRAY") {
            $vrml .= "[\n$self->{'TAB'}".join("\n$self->{'TAB'}",@{$declaration})."\n]\n{\n";
        } else {
            $vrml .= "[$declaration]\n{\n";
        }
    }
    if (defined $definition) {
        if (ref($definition) eq "CODE") {
            &$definition;
        } else {
            $vrml .= "$definition\n";
        }
    }
    chop($self->{'TAB'});
    $vrml .= $self->{'TAB'}."}\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

#--------------------------------------------------------------------

=back

=head2 other

=over 4

=cut

#--------------------------------------------------------------------

=item USE

C<USE($name)>

=cut

sub USE {
    my $self = shift;
    my ($name) = @_;
    my $vrml = "";
    $vrml = $self->{'TAB'}."USE $name\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item DEF

C<DEF($name)>

=cut

sub DEF {
    my $self = shift;
    my ($name) = @_;
    my $vrml = $self->{'TAB'}."DEF $name\n";
    push @{$self->{'VRML'}}, $vrml;
    $self->{'DEF'}{$name} = $#{$self->{'VRML'}};
    return $self;
}

=item ROUTE

C<ROUTE($from, $to)>

=cut

sub ROUTE {
    my $self = shift;
    my ($from, $to) = @_;
    return $self unless $from && $to;
    my $vrml = $self->{'TAB'}."ROUTE $from TO $to\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item End

C<End($comment)>

Close an open node with }

=cut

sub End {
    my $self = shift;
    my ($comment) = @_;
    my $vrml = "";
    $comment = $comment &&  $self->{'DEBUG'} ? " # $comment" : "";
    $vrml .= $self->{'TAB'}."}$comment\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item EndChildren

C<EndChildren($comment)>

Close an open children part with ]

=cut

sub EndChildren {
    my $self = shift;
    my ($comment) = @_;
    my $vrml = "";
    return $self->_put("# ERROR: Too many Ends !\n") unless $self->{'TAB'};
    chop($self->{'TAB'});
    $comment = $comment &&  $self->{'DEBUG'} ? " # $comment" : "";
    $vrml .= $self->{'TAB'}."    ]$comment\n";
    push @{$self->{'VRML'}}, $vrml;
    return $self;
}

=item EndTransform

C<EndTransform($comment)>

Close an open children part with ] and the node with }

=cut

sub EndTransform {
    my $self = shift;
    my ($comment) = @_;
    return $self->_put("# ERROR: Too many Ends !\n") unless $self->{'TAB'};
    chop($self->{'TAB'});
    $comment = $comment &&  $self->{'DEBUG'} ? " # $comment" : "";
    my $vrml = $self->{'TAB'}."    ]\n";
    $vrml .= $self->{'TAB'}."}$comment\n";
    push @{$self->{'VRML'}}, $vrml;
    shift @{$self->{'XYZ'}};
    $self->_put("# EndTransform ".join(', ',@{$self->{'XYZ'}[0]})."\n") if $self->{'DEBUG'};
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://g;
    unless (exists $self->{'PROTO'}{$AUTOLOAD}) {
        my ($package, $filename, $line)  = caller;
        die qq{Unknown method "$AUTOLOAD" at $filename line $line.\n};
    }
    return $self->_row(qq#$AUTOLOAD { @_ } \n#);
}

1;

__END__

=back

=head1 SEE ALSO

VRML::VRML2::Standard

VRML::Base

http://www.gfz-potsdam.de/~palm/vrmlperl/ for a description of F<VRML-modules> and how to obtain it.

=head1 BUGS

Compatibility with VRML1.pm is only given if you use C<IndexedFaceSet> and C<IndexedLineSet>
with references

=head1 AUTHOR

Hartmut Palm F<E<lt>palm@gfz-potsdam.deE<gt>>

Homepage http://www.gfz-potsdam.de/~palm/

=cut
