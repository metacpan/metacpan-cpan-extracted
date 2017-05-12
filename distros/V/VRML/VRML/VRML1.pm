package VRML::VRML1;

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
require VRML::VRML1::Standard;
use strict;
use VRML::Color;
use VRML::Base;
use vars qw(@ISA $AUTOLOAD $VERSION %supported);
@ISA = qw(VRML::VRML1::Standard);

$VERSION = "1.10";
%supported = ('quote' => "Live3D|WorldView|Cosmo Player",
 'L3D_ext' => "Live3D|Cosmo Player",    # not WorldView
 'gzip'   => "Live3D|WorldView|Cosmo Player|libcosmoplayer|VRweb|GLview",
 'target' => "Live3D|WorldView|Cosmo Player|libcosmoplayer|MSVRML2OCX"
);

my $PI = 3.1415926;
my $PI_2 = $PI / 2;

#--------------------------------------------------------------------

sub new {
    my $class = shift;
    my $version = shift;
    my $self = new VRML::VRML1::Standard($version);
    $self->{'viewpoint'} = [];
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
sub at {
    my $self = shift;
    $self->transform_begin(@_);
    return $self;
}

sub back {
    my $self = shift;
    $self->transform_end();
    return $self;
}

sub begin {
    my $self = shift;
    $self->Group($_[0]);
    return $self;
}

sub end {
    my $self = shift;
    $self->End($_[0]);
    return $self;
}

sub anchor_begin {
    my $self = shift;
    return $self->_put(qq{# CALL: ->anchor_begin("Url","description","target=parameter");\n}) unless @_;
    my ($url, $description, $parameter) = @_;
    my $target = undef;
    my $quote = $self->{'BROWSER'} =~ /$supported{'quote'}/i ? '\\"' : "'";
    $description =~ s/"/$quote/g if defined $description;
    if (defined $parameter && $self->{'BROWSER'} =~ /$supported{'target'}/i) {
        ($target = $1) =~ s/"/$quote/g if ($parameter =~ /target\s*=(.+)/i);
    }
    $self->WWWAnchor($url, $description, $target);
    return $self;
}

sub anchor_end {
    my $self = shift;
    $self->End($_[0]);
    return $self;
}

sub collision_begin {
    my $self = shift;
    $self->_row("CollideStyle { collide TRUE }\n") if $self->{'BROWSER'} =~ /$supported{'L3D_ext'}/i;
    $self->_row("DEF CollisionDetection Info { string \"TRUE\" }\n");
    return $self;
}

sub collision_end {
    return shift;
}

sub group_begin {
    my $self = shift;
    $self->Group(@_);
    return $self;
}

sub group_end {
    my $self = shift;
    $self->End($_[0]);
    return $self;
}

sub lod_begin {
    my $self = shift;
    return $self->_put(qq{# CALL: ->lod_begin(range,"center");\n}) unless @_;
    my ($range, $center) = @_;
    $self->LOD($range,$center);
    return $self;
}

sub lod_end {
    my $self = shift;
    $self->End($_[0]);
    return $self;
}

sub switch_begin {
    my $self = shift;
    $self->Switch(@_);
    return $self;
}

sub switch_end {
    my $self = shift;
    $self->End($_[0]);
    return $self;
}

sub inline {
    my $self = shift;
    $self->WWWInline(@_);
    return $self;
}

#--------------------------------------------------------------------
#   VRML Methods
#--------------------------------------------------------------------

sub background {
    my $self = shift;
    my %hash = @_;
    $hash{skyColor} = ${$hash{skyColor}}[0] if ref($hash{skyColor}) eq "ARRAY";
    $self->backgroundcolor($hash{skyColor});
    $hash{frontUrl} = ${$hash{frontUrl}}[0] if ref($hash{frontUrl}) eq "ARRAY";
    $self->backgroundimage($hash{frontUrl});
    return $self;
}

sub backgroundcolor {
    my $self = shift;
    my ($skyColorString) = @_;
    my $skyColor;
    if (defined $skyColorString) {
        $skyColor = rgb_color($skyColorString);
        $self->def("BackgroundColor")->Info($skyColor)->_trim;
    }
    return $self;
}

sub backgroundimage {
    my $self = shift;
    my $bgimage = shift;
    if (defined $bgimage) {
        $self->def("BackgroundImage")->Info($bgimage)->_trim;
    }
    return $self;
}

sub title {
    my $self = shift;
    return $self->_put(qq{# CALL: ->title("string");\n}) unless @_;
    my $title = shift;
    $self->_row("DEF Title Info { string \"$title\" }\n");
    return $self;
}

sub info {
    my $self = shift;
    my $string = shift;
    return $self->_put(qq{# CALL: ->info("string");\n}) unless @_;
    my $quote = $self->{'BROWSER'} =~ /$supported{'quote'}/i ? '\\"' : "'";
    if (defined $string) {
        $string = join(',',@$string) if ref($string) eq "ARRAY";
        $string =~ s/"/$quote/g;
        $self->_row("Info { string \"$string\" }\n");
    }
    return $self;
}

sub worldinfo {
    my $self = shift;
    my $title = shift;
    my $string = shift;
    my $quote = $self->{'BROWSER'} =~ /$supported{'quote'}/i ? '\\"' : "'";
    $self->_row("DEF Title Info { string \"$title\" }\n") if defined $title;
    if (defined $string) {
        $string = join(',',@$string) if ref($string) eq "ARRAY";
        $string =~ s/"/$quote/g;
        $self->_row("Info { string \"$string\" }\n");
    }
    return $self;
}

sub navigationinfo {
    my $self = shift;
    my ($type, $speed, $headlight) = @_;
    $type = $$type[0] if ref($type) eq "ARRAY";
    $self->_row("DEF Viewer Info { string \"$type\" }\n");
    $self->_row("DEF ViewerSpeed Info { string \"$speed\" }\n");
    $headlight = defined $headlight && !$headlight ? "FALSE" : "TRUE";
    $self->_row("DEF Headlight Info { string \"$headlight\" }\n");
    return $self;
}
#--------------------------------------------------------------------

sub viewpoint_begin {
    my $self = shift;
    my ($whichChild) = @_;
    $whichChild = (defined $whichChild && $whichChild > 0) ? $whichChild-1 : 0;
    my $vrml = $self->{'TAB'}."DEF Cameras Switch {\n";
    $vrml .= $self->{'TAB'}."   whichChild $whichChild\n";
    $self->{'TAB_VIEW'} = $self->{'TAB'}."\t";
    $self->{'viewpoint_begin'} = $#{$self->{'VRML'}}+1 unless defined $self->{'viewpoint_begin'};
    push @{$self->{'viewpoint'}}, $vrml;
    return $self;
}

sub viewpoint_end {
    my $self = shift;
    chop($self->{'TAB_VIEW'});
    push @{$self->{'viewpoint'}}, $self->{'TAB_VIEW'}."}\n";
    splice(@{$self->{'VRML'}}, $self->{'viewpoint_begin'}, 0, @{$self->{'viewpoint'}});
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
        my $dx = abs($self->{'Xmax'}-$x); # todo: calculate angle
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
    my ($center, $distance, $heightAngle) = @_;
    $self->{'viewpoint_set'} = $#{$self->{'viewpoint'}}+1 unless defined $self->{'viewpoint_set'};
    my ($x, $y, $z) = $self->string_to_array($center) if defined $center;
    my ($dx, $dy, $dz) = defined $distance ? $self->string_to_array($distance) : (0,0,0);
    $x = 0 unless defined $x;
    $y = 0 unless defined $y;
    $z = 0 unless defined $z;
    $dx = 1 unless defined $dx;
    $dy = $dx unless defined $dy;
    $dz = $dx unless defined $dz;
    $self->viewpoint("Front", "$x $y ".($z+$dz), "0 0 1 0",$heightAngle);
    $self->viewpoint("Right", ($x+$dx)." $y $z", "0 1 0 90",$heightAngle);
    $self->viewpoint("Back", "$x $y ".($z-$dz), "0 1 0 180",$heightAngle);
    $self->viewpoint("Left", ($x-$dx)." $y $z", "0 1 0 -90",$heightAngle);
    $self->viewpoint("Top", "$x ".($y+$dy)." $z", "1 0 0 -90",$heightAngle);
    $self->viewpoint("Bottom", "$x ".($y-$dy)." $z", "1 0 0 90",$heightAngle);
    return $self;
}

sub viewpoint {
    my $self = shift;
    my ($name, $position, $orientation, $heightAngle) = @_;
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
    $heightAngle *= $PI/180 if defined $heightAngle && $self->{'CONVERT'};
    $self->{'TAB_VIEW'} = $self->{'TAB'} unless $self->{'TAB_VIEW'};
    $name =~ s/^#//;
    $name =~ s/[\x00-\x20\x22\x23\x27\x2b-\x2e\x30-\x39\x5b-\x5d\x7b\x7d\x7f]/_/g;
    push @{$self->{'viewpoint'}}, $self->{'TAB_VIEW'}."DEF $name\n";
    $self->PerspectiveCamera($position, $orientation, $heightAngle);
    push @{$self->{'viewpoint'}}, pop @{$self->{'VRML'}};
    unless (defined $self->{'viewpoint_begin'}) {
        splice(@{$self->{'VRML'}}, @{$self->{'VRML'}}, 0, @{$self->{'viewpoint'}});
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
    $self->DirectionalLight($direction, $intensity, $color, $on);
    return $self;
}

#--------------------------------------------------------------------

sub line {
    my $self = shift;
    return $self->_put(qq{# CALL: ->line("fromXYZ","toXYZ",radius,"appearance","[x][y][z]");\n}) unless @_;
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
    unless ($radius =~ /^(-?)([0-9]*)(\.?)([0-9]+)$/) { die "'$radius' is not a number\n" };
    $order = "" unless defined $order;
    $self->comment('line("'.join('", "',@_).'")') if $self->{'DEBUG'};
    $self->Separator;
    if ($appearance) {
        if (defined $radius && $radius==0 && ($self->{'BROWSER'} =~ /Cosmo Player/)) {
             $self->appearance("$appearance, 0 0 0");
        } else {
             $self->appearance($appearance);
        }
    }
    if (defined $radius && $radius>0) {
        if ($dx && $order =~ /x/) {
            $self->Separator("line_x");
            $t = ($x1-($dx/2))." $y1 $z1" if $order =~ /^x$/i;
            $t = ($x1-($dx/2))." $y1 $z1" if $order =~ /^x../i;
            $t = ($x1-($dx/2))." $y2 $z1" if $order =~ /yxz/i;
            $t = ($x1-($dx/2))." $y1 $z2" if $order =~ /zxy/i;
            $t = ($x1-($dx/2))." $y2 $z2" if $order =~ /..x$/i;
            $self->Transform($t,"0 0 1 ".$PI_2);
            $self->Cylinder($radius,abs($dx));
            $self->End();
        }
        if ($dy && $order =~ /y/) {
            $self->Separator("line_y");
            $t = "$x1 ".($y1-($dy/2))." $z1" if $order =~ /^y$/i;
            $t = "$x1 ".($y1-($dy/2))." $z1" if $order =~ /^y../i;
            $t = "$x2 ".($y1-($dy/2))." $z1" if $order =~ /xyz/i;
            $t = "$x1 ".($y1-($dy/2))." $z2" if $order =~ /zyx/i;
            $t = "$x2 ".($y1-($dy/2))." $z2" if $order =~ /..y$/i;
            $self->Transform($t);
            $self->Cylinder($radius,abs($dy));
            $self->End();
        }
        if ($dz && $order =~ /z/) {
            $self->Separator("line_z");
            $t = "$x1 $y1 ".($z1-($dz/2)) if $order =~ /^z$/i;
            $t = "$x1 $y1 ".($z1-($dz/2)) if $order =~ /^z../i;
            $t = "$x1 $y2 ".($z1-($dz/2)) if $order =~ /yzx/i;
            $t = "$x2 $y1 ".($z1-($dz/2)) if $order =~ /xzy/i;
            $t = "$x2 $y2 ".($z1-($dz/2)) if $order =~ /..z$/i;
            $self->Transform($t,"1 0 0 ".$PI_2);
            $self->Cylinder($radius,abs($dz));
            $self->End();
        }
        unless ($order) {
            $length = sqrt($dx*$dx + $dy*$dy + $dz*$dz);
            $t = ($x1-($dx/2))." ".($y1-($dy/2))." ".($z1-($dz/2));
            $r = "$dx ".($dy+$length)." $dz ".$PI;
            $self->Transform($t,$r);
            $self->Cylinder($radius,$length);
        }
    } else {
        $self->MaterialBinding("PER_FACE");
        $self->Coordinate3($from,$to);
        $self->IndexedLineSet(["0, 1"]);
    }
    $self->End("line");
    return $self;
}

#--------------------------------------------------------------------

sub box {
    my $self = shift;
    my ($dimension, $appearance) = @_;
    my ($width,$height,$depth) = $self->string_to_array($dimension);
    $self->Group->appearance($appearance) if $appearance;
    $self->Cube($width,$height,$depth);
    $self->End if $appearance;
    return $self;
}

sub cone {
    my $self = shift;
    my ($dimension, $appearance) = @_;
    my ($radius, $height) = $self->string_to_array($dimension);
    $self->Group->appearance($appearance) if $appearance;
    $self->Cone($radius, $height);
    $self->End if $appearance;
    return $self;
}

sub cube {
    my $self = shift;
    my ($dimension, $appearance) = @_;
    my ($width,$height,$depth) = $self->string_to_array($dimension);
    $height=$width unless defined $height;
    $depth=$width unless defined $depth;
    $self->Group->appearance($appearance) if $appearance;
    $self->Cube($width,$height,$depth);
    $self->End if $appearance;
    return $self;
}

sub cylinder {
    my $self = shift;
    my ($dimension, $appearance, $top, $side, $bottom) = @_;
    my ($radius, $height) = $self->string_to_array($dimension);
    my @parts;
    $self->Group->appearance($appearance) if $appearance;
    if (defined $top || defined $side || defined $bottom) {
        $top = 1 unless defined $top;
        $side = 1 unless defined $side;
        $bottom = 1 unless defined $bottom;
        push @parts, "TOP" if $top;
        push @parts, "SIDES" if $side;
        push @parts, "BOTTOM" if $bottom;
    }
    $self->Cylinder($radius, $height, @parts);
    $self->End if $appearance;
    return $self;
}

sub pyramid {
    my $self = shift;
    my ($dimension, $appearance) = @_;
    my ($width,$height,$depth) = $self->string_to_array($dimension);
    my $x_2 = $width/2;
    my $y_2 = $height/2;
    my $z_2 = defined $depth ? $depth/2 : $x_2;
    my $color_prop = "";
    if ($appearance) {
        if ($appearance =~ /,/) {
            $color_prop = [0..4];
            $self->MaterialBinding("PER_FACE_INDEXED");
        }
        $self->Group->appearance($appearance);
    }
    $self->Coordinate3("-$x_2 -$y_2 $z_2","$x_2 -$y_2 $z_2","$x_2 -$y_2 -$z_2","-$x_2 -$y_2 -$z_2","0 $y_2 0")
    ->IndexedFaceSet(["0, 1, 4","1, 2, 4","2, 3, 4","3, 0, 4","0, 3, 2, 1"],$color_prop);
    $self->End("pyramid") if $appearance;
    return $self;
}

sub sphere {
    my $self = shift;
    my ($radius, $appearance) = @_;
    $self->Group->appearance($appearance) if $appearance;
    $self->Sphere($radius);
    $self->End if $appearance;
    return $self;
}

sub text {
    my $self = shift;
    my ($string, $appearance, $font, $align) = @_;
    my $quote = $self->{'BROWSER'} =~ /$supported{'quote'}/i ? '\\"' : "'";
    $string =~ s/"/$quote/g if defined $string;
    $self->Group->appearance($appearance) if $appearance || $font;
    if (defined $string) {
        if (ref($string)) {
            $string = '["'.join('","',@$string).'"]';
        } else {
            $string =~ s/"/$quote/g;
            $string = "\"$string\"";
        }
    }
    if (defined $font) {
        my ($size, $family, $style) = split(/\s+/,$font,3);
        $self->FontStyle($size, $family, $style);
    }
    if (defined $align) {
        $align =~ s/BEGIN/LEFT/i;
        $align =~ s/MIDDLE/CENTER/i;
        $align =~ s/END/RIGHT/i;
    }
    $self->AsciiText($string, undef, $align);
    $self->End if $appearance || $font;
    return $self;
}

sub billtext {
    my $self = shift;
    $self->Separator;
    $self->_row("AxisAlignment { fields [SFBitMask alignment] alignment ALIGNAXISXYZ }\n") if $self->{'BROWSER'} =~ /$supported{'L3D_ext'}/i;
    $self->text(@_);
    $self->End;
}
#--------------------------------------------------------------------

sub appearance {
    my $self = shift;
    my ($appearance_list) = @_;
    return $self unless $appearance_list;
    my ($item, $color, $multi_color, $key, $value, @values, $num_color,
        $texture, %material, $def, $defmat, $deftex);
    ITEM:
    foreach $item (split(/\s*;\s*/,$appearance_list)) {
        ($key,$value) = split(/\s*=\s*/,$item,2);
        unless ($value) {       # color only
            $value = $key;
            $key = "diffuseColor";
        }
        MODE: {
            if ($key eq "d")  { $key = "diffuseColor";  last MODE; }
            if ($key eq "e")  { $key = "emissiveColor"; last MODE; }
            if ($key eq "s")  { $key = "specularColor"; last MODE; }
            if ($key eq "a")  { $key = "ambientColor";  last MODE; }
            if ($key eq "sh") { $key = "shininess";     last MODE; }
            if ($key eq "tr") { $key = "transparency";  last MODE; }
            if ($key eq "tex") { $texture = $value; next ITEM; }
            if ($key eq "def") { $def = $value; next ITEM; }
            if ($key eq "defmat") { $defmat = $value; next ITEM; }
            if ($key eq "deftex") { $deftex = $value; next ITEM; }
        }
        if ($key eq "diffuseColor" | $key eq "emissiveColor" | $key eq "specularColor" | $key eq "ambientColor") {
            if ($value =~ /,/) {        # multi color field
                foreach $color (split(/\s*,\s*/,$value)) {
                    ($num_color,$color) = rgb_color($color);
                    $value = $num_color;
                    $value .= " # $color" if $color && $self->{'DEBUG'};
                    push @values, $value;
                }
                $material{$key} = [@values];
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
    $self->def($def)->group_begin if $def;
    $self->def($defmat) if $defmat;
    $self->Material(%material);
#    $self->MaterialBinding("PER_FACE_INDEXED") if $multi_color;
    $self->def($deftex) if $deftex;
    $self->Texture2($self->string_to_array($texture)) if defined $texture;
    $self->group_end if $def;
    return $self;
}


#--------------------------------------------------------------------

sub transform_begin {
    my $self = shift;
    return $self->Separator unless @_;
    my (@transform_list) = @_;
    my @transform;
    if (ref($transform_list[0])) {
        @transform = @{$transform_list[0]};
    } else {
        @transform = @transform_list;
    }
    my ($item, $key, $value);
    my ($x,$y,$z,$angle,$t,$r,$s,$o,$c);
    foreach $item (@transform) {
        ($key,$value) = ref($item) ? @$item : split(/\s*=\s*/,$item);
        unless ($value) {
            ($x,$y,$z) = split(/\s/,$key);
            $x=0 unless defined $x;
            $y=0 unless defined $y;
            $z=0 unless defined $z;
            $t = "$x $y $z";
        }
        MODE: {
            if ($key eq "t") { $t = $value; last MODE; }
            if ($key eq "r" || $key eq "rotation") { $r = $value; last MODE; }
            if ($key eq "c") { $c = $value; last MODE; }
            if ($key eq "s") { $s = $value; last MODE; }
            if ($key eq "so") { $o = $value; last MODE; }
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
    $self->Separator->Transform($t,$r,$s,$o,$c);
    return $self;
}

sub transform_end {
    my $self = shift;
    $self->End();
    return $self;
}

#--------------------------------------------------------------------

sub sound {
    my $self = shift;
    return $self->_put(qq{# CALL: ->sound("url", "description", ...)\n}) unless @_;
    my ($url, $description, $location, $direction, $intensity, $loop, $pitch, $pause) = @_;
    $loop = defined $loop && $loop ? "TRUE" : "FALSE";
    $self->DirectedSound($url, $description, $location, $direction, $intensity, 100, 0, 0, 0, $loop);
    return $self;
}

#--------------------------------------------------------------------

sub def {
    my $self = shift;
    my ($name, $code) = @_;
    $name = "_DEF_".(++$self->{'ID'}) unless defined $name;
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
    return $self->_put(qq{# CALL: ->use("name");\n}) unless @_;
    my ($name) = @_;
    $self->USE($name);
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://g;
    unless ($AUTOLOAD =~ /^route|sensor$|^interpolator$|^elevationgrid$|^indexedfaceset$/) {
        my ($package, $filename, $line)  = caller;
        die qq{Unknown method "$AUTOLOAD" at $filename line $line.\n};
    }
    return $self->_row(qq{### "$AUTOLOAD" is not supported by VRML::VRML1\n});
}

1;

__END__

=head1 NAME

VRML::VRML1.pm - VRML methods with the VRML 1.0 standard

=head1 SYNOPSIS

  use VRML::VRML1;

  $vrml = new VRML::VRML1;
  $vrml->browser('Cosmo Player 2.0','Netscape');
  $vrml->at('-15 0 20');
  $vrml->box('5 3 1','yellow');
  $vrml->back;
  $vrml->print;
  $vrml->save;

  OR with the same result

  use VRML::VRML1;

  VRML::VRML1->new
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
