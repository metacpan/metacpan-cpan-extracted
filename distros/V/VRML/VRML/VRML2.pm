package VRML::VRML2;

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
require VRML::VRML2::Standard;
use strict;
use VRML::Color;
use vars qw(@ISA $VERSION %supported);
@ISA = qw(VRML::VRML2::Standard);

$VERSION = "1.10";
%supported = (
  'quote' => "Cortona VRML Client|Cosmo Player|CosmoPlayer|Live3D|WorldView",
  'gzip'  => "Cortona VRML Client|Cosmo Player|CosmoPlayer|libcosmoplayer|Live3D|WorldView|VRweb|GLview",
  'target'=> "Cortona VRML Client|Cosmo Player|CosmoPlayer|libcosmoplayer|Live3D|WorldView|MSVRML2OCX"
);

my $PI = 3.1415926;
my $PI_2 = $PI / 2;

#--------------------------------------------------------------------

sub new {
    my $class = shift;
    my $version = shift;
    my $self = new VRML::VRML2::Standard($version);
    $self->{'viewpoint'} = [];
    $self->{'route'} = [];
    return bless $self, $class;
}

sub supported {
    my $self = shift;
    my $feature = shift;
    return $self->{'BROWSER'} =~ /$supported{$feature}/i;
}

#--------------------------------------------------------------------
#   VRML Grouping Methods
#--------------------------------------------------------------------
sub begin {
    my $self = shift;
    $self->Group(@_);
    return $self;
}

sub end {
    my $self = shift;
    $self->EndChildren->End($_[0]); #  close [ and { with comment
    for (@{$self->{'route'}}) { $self->ROUTE(@{$_}); }
    $self->{'route'} = [];
    return $self;
}

sub anchor_begin {
    my $self = shift;
    my ($url, $description, $parameter, $bboxSize, $bboxCenter) = @_;
    my $quote = $self->{'BROWSER'} =~ /$supported{'quote'}/i ? '\\"' : "'";
    $description =~ s/"/$quote/g if defined $description;
    $parameter =~ s/"/$quote/g if defined $parameter;
    undef $parameter if $self->{'BROWSER'} !~ /$supported{'target'}/i;
    $self->Anchor($url, $description, $parameter, $bboxSize, $bboxCenter);
    return $self;
}

sub anchor_end {
    my $self = shift;
    $self->EndChildren->End($_[0]); #  close [ and {
    return $self;
}

sub billboard_begin {
    my $self = shift;
    $self->Billboard(@_);
    return $self;
}

sub billboard_end {
    my $self = shift;
    $self->EndChildren->End($_[0]); #  close [ and {
    return $self;
}

sub collision_begin {
    my $self = shift;
    my ($collide, $proxy) = @_;
    $collide = defined $collide && $collide ? "TRUE" : "FALSE";
    $self->Collision($collide, $proxy);
    return $self;
}

sub collision_end {
    my $self = shift;
    $self->EndChildren->End($_[0]); #  close [ and {
    return $self;
}

sub group_begin {
    my $self = shift;
    $self->Group(@_);
    return $self;
}

sub group_end {
    my $self = shift;
    $self->EndChildren->End($_[0]); #  close [ and {
    return $self;
}

sub lod_begin {
    my $self = shift;
    $self->LOD(@_);
    return $self;
}

sub lod_end {
    my $self = shift;
    $self->EndChildren->End($_[0]); #  close [ and {
    return $self;
}

sub switch_begin {
    my $self = shift;
    $self->Switch(@_);
    return $self;
}

sub switch_end {
    my $self = shift;
    $self->EndChildren->End($_[0]); #  close [ and {
    return $self;
}

sub at {
    my $self = shift;
    $self->transform_begin(@_);
    return $self;
}

sub back {
   my $self = shift;
    $self->transform_end;
    return $self;
}

sub transform_begin {
    my $self = shift;
    my (@transform_list) = @_;
    my @transform;
    if (ref($transform_list[0])) {
        @transform = @{$transform_list[0]};
    } else {
        @transform = @transform_list;
    }
    return $self->Transform unless @transform;
    my ($item, $key, $value);
    my ($x,$y,$z,$angle,$t,$r,$s,$o,$c,$bbs,$bbc);
    foreach $item (@transform) {
        next if !defined $item or $item eq "";
        ($key,$value) = ref($item) ? @$item : split(/\s*=\s*/,$item);
        unless ($value) {
            ($x,$y,$z) = split(/\s/,$key);
            $x=0 unless defined $x;
            $y=0 unless defined $y;
            $z=0 unless defined $z;
            $t = "$x $y $z";
        }
        MODE: {
            if ($key eq "t" || $key eq "translation") { $t = $value; last MODE; }
            if ($key eq "r" || $key eq "rotation") { $r = $value; last MODE; }
            if ($key eq "c" || $key eq "center") { $c = $value; last MODE; }
            if ($key eq "s" || $key eq "scale") { $s = $value; last MODE; }
            if ($key eq "so" || $key eq "scaleOrientation") { $o = $value; last MODE; }
            if ($key eq "bbs" || $key eq "bboxSize") { $bbs = $value; last MODE; }
            if ($key eq "bbc" || $key eq "bboxCenter") { $bbc = $value; last MODE; }
        }
        if ($key eq "r" || $key eq "rotation") {
            ($x,$y,$z,$angle) = split(/\s/,$value);
            unless (defined $angle) { # if one param its the angle
                $angle=$x;
                $x=0;
                $y=0;
                $z=1;
            }
            $angle *= $PI/180 if $self->{'CONVERT'};
            $r = "$x $y $z $angle";
        }
    }
    $self->Transform($t,$r,$s,$o,$c,$b);
    return $self;
}

sub transform_end {
    my $self = shift;
    $self->EndTransform("Transform");
    unless ($self->{'TAB'}) {
        for (@{$self->{'route'}}) { $self->ROUTE(@{$_}); }
        $self->{'route'} = [];
    }
    return $self;
}

sub inline {
    my $self = shift;
    $self->Inline(@_);
    return $self;
}

#--------------------------------------------------------------------
#   VRML Methods
#--------------------------------------------------------------------

sub background {
    my $self = shift;
    my %hash = @_;
    my ($key,$value,@list);
    if (defined $hash{'skyColor'}) {
        if (ref($hash{'skyColor'}) eq "ARRAY") {
            @list = ();
            for $key (@{$hash{'skyColor'}}) {
                $value = rgb_color($key);
                push(@list, $value);
            }
            $hash{'skyColor'} = "[ ".join(", ",@list)." ]";
            if (defined $hash{'skyAngle'}) {
                if (ref($hash{'skyAngle'}) eq "ARRAY") {
                    @list = ();
                    for $key (@{$hash{'skyAngle'}}) {
                        $key *= $PI/180 if $self->{'CONVERT'};
                        push(@list, $key);
                    }
                    $hash{'skyAngle'} = "[ ".join(", ",@list)." ]";
                } else {
                    $hash{'skyAngle'} *= $PI/180 if $self->{'CONVERT'};
                }
            }
        } else {
            $hash{'skyColor'} = rgb_color($hash{'skyColor'});
        }
    }
    if (defined $hash{'groundColor'}) {
        if (ref($hash{'groundColor'}) eq "ARRAY") {
            @list = ();
            for $key (@{$hash{'groundColor'}}) {
                $value = rgb_color($key);
                push(@list, $value);
            }
            $hash{'groundColor'} = "[ ".join(", ",@list)." ]";
            if (defined $hash{'groundAngle'}) {
                if (ref($hash{'groundAngle'}) eq "ARRAY") {
                    @list = ();
                    for $key (@{$hash{'groundAngle'}}) {
                        $key *= $PI/180 if $self->{'CONVERT'};
                        push(@list, $key);
                    }
                    $hash{'groundAngle'} = "[ ".join(", ",@list)." ]";
                } else {
                    $hash{'groundAngle'} *= $PI/180 if $self->{'CONVERT'};
                }
            }
        } else {
            $hash{'groundColor'} = rgb_color($hash{'groundColor'});
        }
    }
    foreach $key (keys %hash) { $hash{$key} = "\"$hash{$key}\"" if $key =~
    /Url$/; }
    $self->Background(%hash);
    return $self;
}

sub backgroundcolor {
    my $self = shift;
    my ($skyColorString, $groundColorString) = @_;
    my ($skyColor, $groundColor);
    $skyColor = rgb_color($skyColorString) if defined $skyColorString;
    $groundColor = rgb_color($groundColorString) if defined $groundColorString;
    $self->Background(skyColor => $skyColor, groundColor => $groundColor);
    return $self;
}

sub backgroundimage {
    my $self = shift;
    my ($url) = @_;
    return unless $url;
    $self->Background(
        frontUrl => "\"$url\"",
        leftUrl => "\"$url\"",
        rightUrl => "\"$url\"",
        backUrl => "\"$url\"",
        bottomUrl => "\"$url\"",
        topUrl => "\"$url\""
    );
    return $self;
}

sub title {
    my $self = shift;
    my $title = shift;
    return unless defined $title;
    my $quote = $self->{'BROWSER'} =~ /$supported{'quote'}/i ? '\\"' : "'";
    $title =~ s/"/$quote/g;
    $self->WorldInfo($title);
    return $self;
}

sub info {
    my $self = shift;
    my ($info) = @_;
    my $quote = $self->{'BROWSER'} =~ /$supported{'quote'}/i ? '\\"' : "'";
    if (defined $info) {
        $info =~ s/"/$quote/g;
        $self->WorldInfo(undef, $info);
    }
    return $self;
}

sub worldinfo {
    my $self = shift;
    my ($title, $info) = @_;
    my $quote = $self->{'BROWSER'} =~ /$supported{'quote'}/i ? '\\"' : "'";
    $title =~ s/"/$quote/g if defined $title;
    $info =~ s/"/$quote/g if defined $info;
    $self->WorldInfo($title, $info);
    return $self;
}

sub navigationinfo {
    my $self = shift;
    my ($type, $speed, $headlight, $visibilityLimit, $avatarSize) = @_;
    $headlight = defined $headlight && !$headlight ? "FALSE" : "TRUE";
    $self->NavigationInfo($type, $speed, $headlight, $visibilityLimit,
    $avatarSize);
    return $self;
}
#--------------------------------------------------------------------

sub viewpoint_begin {
    my $self = shift;
    my ($whichChild) = @_;
    $whichChild = (defined $whichChild && $whichChild > 0) ? $whichChild-1 : 0;
    $self->{'TAB_VIEW'} = $self->{'TAB'};
    $self->{'viewpoint_begin'} = $#{$self->{'VRML'}}+1 unless defined
    $self->{'viewpoint_begin'};
    return $self;
}

sub viewpoint_end {
    my $self = shift;
    splice(@{$self->{'VRML'}}, $self->{'viewpoint_begin'}, 0,
    @{$self->{'viewpoint'}});
    $self->{'viewpoint'} = [];
    return $self;
}

sub viewpoint_auto_set {
    my $self = shift;
    my $factor = shift;
    $factor = 1 unless defined $factor;
    if (defined $self->{'viewpoint_set'}) {
        my $x = ($self->{'Xmax'}+$self->{'Xmin'})/2;
        my $y = ($self->{'Ymax'}+$self->{'Ymin'})/2;
        my $z = ($self->{'Zmax'}+$self->{'Zmin'})/2;
        my $dx = abs($self->{'Xmax'}-$x); # todo calculate angle
        my $dy = abs($self->{'Ymax'}-$y);
        my $dz = abs($self->{'Zmax'}-$z);
        my $dist = 0;
        $dist = $dx if $dx > $dist;
        $dist = $dy if $dy > $dist;
        $dist = $dz if $dz > $dist;
        my $offset = $#{$self->{'viewpoint'}}+1;
        $self->viewpoint_set("$x $y $z",$dist*$factor,60);
        @_ = splice(@{$self->{'viewpoint'}}, $offset);
        splice(@{$self->{'viewpoint'}}, $self->{'viewpoint_set'}, $#_+1, @_);
    } else {
        $self->viewpoint_set(@_);
    }
    return $self;
}

sub viewpoint_set {
    my $self = shift;
    my ($center, $distance, $fieldOfView) = @_;
    $self->{'viewpoint_set'} = $#{$self->{'viewpoint'}}+1 unless defined
    $self->{'viewpoint_set'};
    my ($x, $y, $z) = $self->string_to_array($center) if defined $center;
    my ($dx, $dy, $dz) = defined $distance ? $self->string_to_array($distance) : (0,0,0);
    $x = 0 unless defined $x;
    $y = 0 unless defined $y;
    $z = 0 unless defined $z;
    $dx = 1 unless defined $dx;
    $dy = $dx unless defined $dy;
    $dz = $dx unless defined $dz;
    $self->viewpoint("Front", "$x $y ".($z+$dz), "0 0 1 0",$fieldOfView);
    $self->viewpoint("Right", ($x+$dx)." $y $z", "0 1 0 90",$fieldOfView);
    $self->viewpoint("Back", "$x $y ".($z-$dz), "0 1 0 180",$fieldOfView);
    $self->viewpoint("Left", ($x-$dx)." $y $z", "0 1 0 -90",$fieldOfView);
    $self->viewpoint("Top", "$x ".($y+$dy)." $z", "1 0 0 -90",$fieldOfView);
    $self->viewpoint("Bottom", "$x ".($y-$dy)." $z", "1 0 0 90",$fieldOfView);
    return $self;
}

sub viewpoint {
    my $self = shift;
    my ($description, $position, $orientation, $fieldOfView, $jump) = @_;
    if (defined $orientation) {
         if ($orientation !~ /\s/) {
            my %val = ("FRONT" => "0 0 1 0", "BACK" => "0 1 0 3.14",
                "RIGHT" => "0 1 0  1.57", "LEFT" => "0 1 0 -1.57",
                "TOP" => "1 0 0 -1.57", "BOTTOM" => "1 0 0 1.57");
            my $string = uc($orientation);
            undef $orientation;
            $orientation = $val{$string};
            $orientation .= " # $string" if $orientation && $self->{'DEBUG'};
        } else {
            my ($x,$y,$z,$angle) = $self->string_to_array($orientation);
            if (defined $angle) {
                $angle *= $PI/180 if $self->{'CONVERT'};
                $orientation = "$x $y $z $angle";
            }
        }
    }
    $fieldOfView *= $PI/180 if defined $fieldOfView && $self->{'CONVERT'};
    if (defined $jump) { $jump = $jump ? "TRUE" : "FALSE"; }
    $self->{'TAB_VIEW'} = $self->{'TAB'} unless $self->{'TAB_VIEW'};
    if ($description =~ /^#/) {
        $description =~ s/^#//;
        my ($name) = $description;
        $name =~ s/[\x00-\x20\x22\x23\x27\x2b-\x2e\x30-\x39\x5b-\x5d\x7b\x7d\x7f]/_/g;
        push @{$self->{'viewpoint'}}, $self->{'TAB_VIEW'}."DEF $name\n";
    }
    $self->Viewpoint($description, $position, $orientation, $fieldOfView,
    $jump);
    push @{$self->{'viewpoint'}}, pop @{$self->{'VRML'}};
    unless (defined $self->{'viewpoint_begin'}) {
        splice(@{$self->{'VRML'}}, @{$self->{'VRML'}}, 0,
        @{$self->{'viewpoint'}});
        $self->{'viewpoint'} = [];
    }
    return $self;
}

#--------------------------------------------------------------------

sub directionallight {
    my $self = shift;
    my ($direction, $intensity, $ambientIntensity, $color, $on) = @_;
    if (defined $on) { $on = $on ? "TRUE" : "FALSE"; }
    $color = rgb_color($color) if defined $color;
    $self->DirectionalLight($direction, $intensity, $ambientIntensity, $color,
    $on);
    return $self;
}

#--------------------------------------------------------------------

sub line {
    my $self = shift;
    my ($from,$to,$radius,$appearance,$order) = @_;
    my ($x1,$y1,$z1) = $self->string_to_array($from);
    my ($x2,$y2,$z2) = $self->string_to_array($to);
    my ($t, $r, $length);

    $x1 = 0 unless $x1;
    $x2 = 0 unless $x2;
    $y1 = 0 unless $y1;
    $y2 = 0 unless $y2;
    $z1 = 0 unless $z1;
    $z2 = 0 unless $z2;
    my $dx=$x1-$x2;
    my $dy=$y1-$y2;
    my $dz=$z1-$z2;
    $order = "" unless defined $order;
    $self->comment('line("'.join('", "',@_).'")') if $self->{'DEBUG'};
    $self->Group();
    if (defined $radius && $radius>0) {
        if ($dx && $order =~ /x/i) {
            $t = ($x1-($dx/2))." $y1 $z1" if $order =~ /^x$/i;
            $t = ($x1-($dx/2))." $y1 $z1" if $order =~ /^x../i;
            $t = ($x1-($dx/2))." $y2 $z1" if $order =~ /yxz/i;
            $t = ($x1-($dx/2))." $y1 $z2" if $order =~ /zxy/i;
            $t = ($x1-($dx/2))." $y2 $z2" if $order =~ /..x$/i;
            $self->Transform($t,"0 0 1 ". $PI_2);
            $self->Shape(sub{$self->Cylinder($radius,abs($dx))},
                    sub{$self->appearance($appearance)});
            $self->EndTransform;
        }
        if ($dy && $order =~ /y/i) {
            $t = "$x1 ".($y1-($dy/2))." $z1" if $order =~ /^y$/i;
            $t = "$x1 ".($y1-($dy/2))." $z1" if $order =~ /^y../i;
            $t = "$x2 ".($y1-($dy/2))." $z1" if $order =~ /xyz/i;
            $t = "$x1 ".($y1-($dy/2))." $z2" if $order =~ /zyx/i;
            $t = "$x2 ".($y1-($dy/2))." $z2" if $order =~ /..y$/i;
            $self->Transform($t);
            $self->Shape(sub{$self->Cylinder($radius,abs($dy))},
                    sub{$self->appearance($appearance)});
            $self->EndTransform;
        }
        if ($dz && $order =~ /z/i) {
            $t = "$x1 $y1 ".($z1-($dz/2)) if $order =~ /^z$/i;
            $t = "$x1 $y1 ".($z1-($dz/2)) if $order =~ /^z../i;
            $t = "$x1 $y2 ".($z1-($dz/2)) if $order =~ /yzx/i;
            $t = "$x2 $y1 ".($z1-($dz/2)) if $order =~ /xzy/i;
            $t = "$x2 $y2 ".($z1-($dz/2)) if $order =~ /..z$/i;
            $self->Transform($t,"1 0 0 ". $PI_2);
            $self->Shape(sub{$self->Cylinder($radius,abs($dz))},
                    sub{$self->appearance($appearance)});
            $self->EndTransform;
        }
        unless ($order) {
            $length = sqrt($dx*$dx + $dy*$dy + $dz*$dz);
            $t = ($x1-($dx/2))." ".($y1-($dy/2))." ".($z1-($dz/2));
            $r = "$dx ".($dy+$length)." $dz ".$PI;
            $self->Transform($t,$r);
            $self->Shape(sub{$self->Cylinder($radius,$length)},
                    sub{$self->appearance($appearance)});
            $self->EndTransform;
        }
    } else {
        my $color = rgb_color($appearance);
        $self->Shape(sub{$self->IndexedLineSet(
            sub{$self->Coordinate($from,$to)},
            "0 1","Color { color [ $color ] }",undef,"FALSE")});
    }
    $self->EndChildren->End("line");
    return $self;
}

#--------------------------------------------------------------------

sub box {
    my $self = shift;
    my ($dimension, $appearance) = @_;
    my ($width,$height,$depth) = $self->string_to_array($dimension);
    $self->Shape(
        sub{$self->Box("$width $height $depth")},
        sub{$self->appearance($appearance)}
    );
    return $self;
}

sub cone {
    my $self = shift;
    my ($dimension, $appearance) = @_;
    my ($radius, $height) = $self->string_to_array($dimension);
    $self->Shape(
        sub{$self->Cone($radius, $height)},
        sub{$self->appearance($appearance)}
    );
    return $self;
}

sub cube {
    my $self = shift;
    my ($dimension, $appearance) = @_;
    my ($width,$height,$depth) = $self->string_to_array($dimension);
    $height = $width unless defined $height;
    $depth = $width unless defined $depth;
    $self->Shape(
        sub{$self->Box("$width $height $depth")},
        sub{$self->appearance($appearance)}
    );
    return $self;
}

sub cylinder {
    my $self = shift;
    my ($dimension, $appearance, $top, $side, $bottom, $inside) = @_;
    my ($radius, $height) = $self->string_to_array($dimension);
    $top = $top ? "TRUE" : "FALSE" if defined $top;
    $side = $side ? "TRUE" : "FALSE" if defined $side;
    $bottom = $bottom ? "TRUE" : "FALSE" if defined $bottom;
    if (defined $inside && $inside) {
        my $crossSection = "1.00  0.00, 0.92  0.38, 0.71  0.71, 0.38  0.92, 0.00  1.00, -0.38  0.92, -0.71  0.71, -0.92  0.38, -1.00  0.0, -0.92 -0.38, -0.71 -0.71, -0.38 -0.92, 0.00 -1.00, 0.38 -0.92, 0.71 -0.71, 0.92 -0.38, 1.00  0.00";
        $height /= 2;
        $self->Shape(
            sub{$self->Extrusion([$crossSection], ["0 -$height 0", "0 $height 0"], ["$radius $radius", "$radius $radius"], undef, $top, $bottom, 0.5, "FALSE")},
            sub{$self->appearance($appearance)}
        )
    } else {
        $self->Shape(
            sub{$self->Cylinder($radius, $height, $top, $side, $bottom)},
            sub{$self->appearance($appearance)}
        )
    }
    return $self;
}

sub elevationgrid {
    my $self = shift;
    my ($height, $color, $xDimension, $zDimension, $xSpacing, $zSpacing,
        $creaseAngle, $colorPerVertex, $solid) = @_;
    $xDimension = ($$height[0] =~ s/([+-]?\d+\.?\d*)/$1/g) unless defined $xDimension;
    $zDimension = @$height unless defined $zDimension;
    $xSpacing = 1 unless defined $xSpacing;
    $zSpacing = $xSpacing unless defined $zSpacing;
    $creaseAngle *= $PI/180 if defined $creaseAngle && $self->{'CONVERT'};
    $colorPerVertex = $colorPerVertex ? "TRUE" : "FALSE" if defined $colorPerVertex;
    $solid = $solid ? "TRUE" : "FALSE" if defined $solid;
    if (ref($color) eq "ARRAY") {
        $self->Shape(
            sub{$self->ElevationGrid($xDimension, $zDimension, $xSpacing, $zSpacing,
                $height, $creaseAngle, $color, $colorPerVertex, $solid)}
        )
    } else {
        $self->Shape(
            sub{$self->ElevationGrid($xDimension, $zDimension, $xSpacing, $zSpacing,
                $height, $creaseAngle, undef, $colorPerVertex, $solid)},
            sub{$self->appearance($color)}
        )
    }
    return $self;
}

sub indexedfaceset {
    my $self = shift;
    my ($coord, $coordIndex, $appearance, $color, $colorIndex) = @_;
    $colorIndex = [0..$#{@$color}] unless defined $colorIndex;
    my @color = split(",",$appearance);
    $self->Shape(
        sub{$self->IndexedFaceSet(
            sub{$self->Coordinate($coord)}, $coordIndex,
            sub{$self->color(@color)}, $colorIndex, "FALSE")
        },
        sub{$self->appearance($appearance)}
    );
    return $self;
}

sub pointset {
    my $self = shift;
    my ($coord, $color) = @_;
    $self->Shape(
        sub{$self->PointSet(
            sub{$self->Coordinate(@$coord)},
            sub{$self->color(@$color)})
        }
    );
    return $self;
}

sub pyramid {
    my $self = shift;
    my ($dimension, $appearance) = @_;
    my ($width,$height,$depth) = $self->string_to_array($dimension);
    my $x_2 = $width ? $width/2 : 1;
    my $y_2 = $height ? $height/2 : 1;
    my $z_2 = defined $depth ? $depth/2 : $x_2;
    my @color = split(",",$appearance) if $appearance;
    my @color_prop = ();
    @color_prop = (sub{$self->color(@color)},[0..4],"FALSE") if $#color > 0;
    $self->Shape(
        sub{$self->IndexedFaceSet(
            sub{$self->Coordinate("-$x_2 -$y_2 $z_2", "$x_2 -$y_2 $z_2",
            "$x_2 -$y_2 -$z_2", "-$x_2 -$y_2 -$z_2", "0 $y_2 0")},
            ["0, 1, 4","1, 2, 4","2, 3, 4","3, 0, 4","0, 3, 2, 1"],
            @color_prop)
        },sub{$self->appearance($appearance)}
    );
    return $self;
}

sub sphere {
    my $self = shift;
    my ($radius, $appearance) = @_;
    $self->Shape(
        sub{$self->Sphere($radius)},
        sub{$self->appearance($appearance)}
    );
    return $self;
}

sub torus {
    my $self = shift;
    my ($dimension, $appearance, $beginCap, $endCap, $angle) = @_;
    my ($r1, $r2, $from, $to, $dstep) = $self->string_to_array($dimension);
    $self->comment("torus($r1, $r2, $from, $to, $dstep)");
    $r2 ||= 0.5;
    $from ||= 0;
    $from *= $PI/180 if $self->{'CONVERT'};
    $to ||= 0;
    $to *= $PI/180 if $self->{'CONVERT'};
    $dstep ||= 10;
    $dstep *= $PI/180 if $self->{'CONVERT'};
    $beginCap = $beginCap ? "TRUE" : "FALSE" if defined $beginCap;
    $endCap = $endCap ? "TRUE" : "FALSE" if defined $endCap;
    my $crossSection = "1.00  0.00, 0.92  0.38, 0.71  0.71, 0.38  0.92, 0.00  1.00, -0.38  0.92, -0.71  0.71, -0.92  0.38, -1.00  0.0, -0.92 -0.38, -0.71 -0.71, -0.38 -0.92, 0.00 -1.00, 0.38 -0.92, 0.71 -0.71, 0.92 -0.38, 1.00  0.00";
    my $alpha = $from;
    my @spine = ();
    my @scale = ();
    for (my $i=0; $i<360; $i++) {
      #radius1 + radius2*Math.cos(alpha)) * Math.cos(beta)
      push @spine, sprintf("%.2f",$r1*cos($alpha))." 0 ".sprintf("%.2f",$r1*sin($alpha));
      push @scale, "$r2 $r2";
      $alpha += $dstep;
      last if $alpha>$to;
    }
    if ($from == $to) {
      push @spine, $spine[0];
    } else {
      push @spine, sprintf("%.2f",$r1*cos($to))." 0 ".sprintf("%.2f",$r1*sin($to));
      push @scale, "$r2 $r2";
    }
    #push @scale, "$r2 $r2";
    $self->Shape(
        sub{$self->Extrusion([$crossSection], [@spine], [@scale], undef, $beginCap, $endCap, 0.5, "FALSE")},
        sub{$self->appearance($appearance)}
    );
    return $self;
}

sub text {
    my $self = shift;
    my ($string, $appearance, $font, $align) = @_;
    my ($size, $family, $style, $language);
    my $quote = $self->{'BROWSER'} =~ /$supported{'quote'}/i ? '\\"' : "'";
    if (defined $string) {
        if (ref($string)) {
            map { s/"/$quote/g } @$string;
            $string = '["'.join('","',@$string).'"]';
        } else {
            $string =~ s/"/$quote/g;
            $string = "\"$string\"";
        }
    }
    $self->Shape(sub{
      if (defined $font || defined $align) {
        if (defined $font) {
            ($size, $family, $style, $language) = split(/\s+/,$font,4); # local variable !!!
        }
        if (defined $align) {
            $align =~ s/LEFT/BEGIN/i;
            $align =~ s/CENTER/MIDDLE/i;
            $align =~ s/RIGHT/END/i;
        }
        $self->Text($string,sub{$self->FontStyle($size, $family, $style,
        $align, $language)});
      } else {
        $self->Text($string);
      }},sub{$self->appearance($appearance)}
    );
    return $self;
}

sub billtext {
    my $self = shift;
    my @param = @_;
    $self->Billboard("0 0 0",sub{$self->text(@param)}); # don't use @_
}

#--------------------------------------------------------------------

sub color {
    my $self = shift;
    my ($rgb, $comment, @colors);
    for (@_) {
        ($rgb, $comment) = rgb_color($_);
        push(@colors, $rgb);
    }
    $self->Color(@colors);
    return $self;
}
#--------------------------------------------------------------------

sub appearance {
    my $self = shift;
    my ($appearance_list) = @_;
    return $self->_put("Appearance {}\n") unless $appearance_list;
    my ($item, $color, $multi_color, $key, $value, @values, $num_color,
        %material, $def, $defmat, $deftex, $textureTransform);
    my $texture = "";
    ITEM:
    foreach $item (split(/\s*;\s*/,$appearance_list)) {
        ($key,$value) = ref($item) ? @$item : split(/\s*=\s*/,$item,2);
#       ($key,$value) = split(/\s*=\s*/,$item,2);
        unless ($value) {       # color only
            $value = $key;
            $key = "diffuseColor";
        }
        MODE: {
            if ($key eq "d")  { $key = "diffuseColor";  last MODE; }
            if ($key eq "e")  { $key = "emissiveColor"; last MODE; }
            if ($key eq "s")  { $key = "specularColor"; last MODE; }
            if ($key eq "ai") { $key = "ambientIntensity";  last MODE; }
            if ($key eq "sh") { $key = "shininess";     last MODE; }
            if ($key eq "tr") { $key = "transparency";  last MODE; }
            if ($key eq "tex") { $texture = $value; next ITEM; }
            if ($key eq "textrans") { $textureTransform = $value; next ITEM; }
            if ($key eq "def") { $def = $value; next ITEM; }
            if ($key eq "deftex") { $deftex = $value; next ITEM; }
            if ($key eq "defmat") { $defmat = $value; next ITEM; }
            if ($key eq "use") {
                $self->use($value);
                return $self;
            }
        }
        if ($key eq "diffuseColor" | $key eq "emissiveColor" | $key eq
        "specularColor") {
            if ($value =~ /,/) {        # multi color field
                foreach $color (split(/\s*,\s*/,$value)) {
                    ($num_color,$color) = rgb_color($color);
                    $value = $num_color;
                    $value .= " # $color" if $color && $self->{'DEBUG'};
                    push @values, $value;
                }
                $material{$key} = $values[0]; # ignore foll. colors
                $multi_color = 1;
            } else {
                ($num_color,$color) = rgb_color($value);
                $value = $num_color;
                $value .= "     # $color" if $color && $self->{'DEBUG'};
                $material{$key} = $value;
            }
        } else {
                $material{$key} = $value;
        }
    }
    $self->def($def) if $def;
    $self->Appearance(
        %material ? sub{$self->def($defmat) if $defmat; $self->Material(%material)} : undef,
        $texture =~ /\.gif|\.jpg|\.png|\.bmp/i ? sub{$self->def($deftex) if $deftex; $self->ImageTexture($self->string_to_array($texture))} : undef ||
        $texture =~ /\.avi|\.mpg|\.mov/i ? sub{$self->def($deftex) if $deftex;
        $self->MovieTexture($self->string_to_array($texture))} : undef,
        $textureTransform
    );
    return $self;
}

#--------------------------------------------------------------------

sub sound {
    my $self = shift;
    return $self->_put(qq{# CALL: ->sound("url", "description", ...)\n})
      unless @_;
    my ($url, $description, $location, $direction, $intensity, $loop, $pitch) =
    @_;
    $loop = defined $loop && $loop ? "TRUE" : "FALSE";
    $self->Sound(sub{$self->DEF($description)->AudioClip($url, $description,
    $loop, $pitch)->_trim},     $location, $direction, $intensity, 100 );
    return $self;
}

#--------------------------------------------------------------------

sub cylindersensor {
    my $self = shift;
    return $self->_put(qq{# CALL: ->cylindersensor("name")\n}) unless @_;
    my ($name) = shift;
    $self->def($name)->CylinderSensor(@_)->_trim;
    return $self;
}

sub planesensor {
    my $self = shift;
    return $self->_put(qq{# CALL: ->planesensor("name")\n}) unless @_;
    my $name = shift;
    $self->def($name)->PlaneSensor(@_)->_trim;
    return $self;
}

sub proximitysensor {
    my $self = shift;
    return $self->_put(qq{# CALL: ->proximitysensor("name")\n}) unless @_;
    my $name = shift;
    $self->def($name)->ProximitySensor(@_)->_trim;
    return $self;
}

sub spheresensor {
    my $self = shift;
    return $self->_put(qq{# CALL: ->spheresensor("name")\n}) unless @_;
    my $name = shift;
    $self->def($name)->SphereSensor(@_)->_trim;
    return $self;
}

sub timesensor {
    my $self = shift;
    return $self->_put(qq{# CALL: ->timesensor("name")\n}) unless @_;
    my $name = shift;
    $self->def($name)->TimeSensor(@_)->_trim;
    return $self;
}

sub touchsensor {
    my $self = shift;
    return $self->_put(qq{# CALL: ->touchsensor("name")\n}) unless @_;
    my $name = shift;
    $self->def($name)->TouchSensor(@_)->_trim;
    return $self;
}

sub visibitysensor {
    my $self = shift;
    return $self->_put(qq{# CALL: ->visibitysensor("name")\n}) unless @_;
    my $name = shift;
    $self->def($name)->VisibilitySensor(@_)->_trim;
    return $self;
}

#--------------------------------------------------------------------

sub interpolator {
    my $self = shift;
    return $self->_put(qq{# CALL: ->interpolator("name","type",
    [keys],[keyValues])\n}) unless @_;
    my $name = shift;
    my $type = shift;
    $type .= "Interpolator";
    $self->def($name)->$type(@_)->_trim;
    return $self;
}

#--------------------------------------------------------------------
# other
#--------------------------------------------------------------------

sub route {
    # ROUTEs must be outside of nodes
    # collect them
    my $self = shift;
    if ($self->{'TAB'}) {
        push @{$self->{'route'}}, [$_[0],$_[1]];
    } else {
        $self->ROUTE($_[0],$_[1]);
    }
    return $self;
}

sub def {
    my $self = shift;
    my ($name, $code) = @_;
    $name = "DEF_".(++$self->{'ID'}) unless defined $name;
    $self->DEF($name);
    if (defined $code) {
        if (ref($code) eq "CODE") {
            $self->{'TAB'} .= "\t";
            my $pos = $#{$self->{'VRML'}}+1;
            &$code;
            $self->_trim($pos);
            chop($self->{'TAB'});
        } else {
            $self->_put($code);
        }
    }
    return $self;
}

sub use {
    my $self = shift;
    return $self->_put(qq{# CALL: ->use("name")\n}) unless @_;
    my ($name) = @_;
    $self->USE($name);
    return $self;
}

1;

__END__

=head1 NAME

VRML::VRML2 - VRML methods with the VRML 2.0/97 standard

=head1 SYNOPSIS

  use VRML::VRML2;

  $vrml = new VRML::VRML2;
  $vrml->browser('Cosmo Player 2.0','Netscape');
  $vrml->at('-15 0 20');
  $vrml->box('5 3 1','yellow');
  $vrml->back;
  $vrml->print;
  $vrml->save;

  OR with the same result

  use VRML::VRML2;

  VRML::VRML2->new
  ->browser('Cosmo Player 2.0','Netscape')
  ->at('-15 0 20')->box('5 3 1','yellow')->back
  ->print->save;

=head1 DESCRIPTION

The methods are identically implemented in VRML::VRML1 and VRML::VRML2. They
described in modul VRML.

=head1 SEE ALSO

VRML

VRML::Base

VRML::Color

http://www.gfz-potsdam.de/~palm/vrmlperl/ for a description of
F<VRML-modules> and how to obtain it.

=head1 AUTHOR

Hartmut Palm F<E<lt>palm@gfz-potsdam.deE<gt>>

Homepage http://www.gfz-potsdam.de/~palm/

=cut
