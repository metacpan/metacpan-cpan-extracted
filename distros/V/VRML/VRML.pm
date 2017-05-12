package VRML;

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
use strict;
use vars qw(@ISA $VERSION);
$VERSION="1.10";

sub new {
    my $class = shift;
    my ($version) = @_ ? @_ : 0;
    my $self;
    if ( $version == 2 || $version == 97 ) {
        require VRML::VRML2;
        @ISA = qw(VRML::VRML2);
        $self = new VRML::VRML2;
    } elsif ( $version == 1 ) {
        require VRML::VRML1;
        @ISA = qw(VRML::VRML1);
        $self = new VRML::VRML1;
    } else {
        require VRML::VRML1;
        @ISA = qw(VRML::VRML1);
        $self = new VRML::VRML1;
    }
    return bless $self, $class;
}

sub DESTROY {
    my $self = shift;
}
1;

__END__

=head1 NAME

VRML - Specification independent VRML methods (1.0, 2.0, 97)

=head1 SYNOPSIS

  use VRML;

  $vrml = new VRML(2);
  $vrml->browser('Cosmo Player 2.0','Netscape');
  $vrml->at('-15 0 20');
  $vrml->box('5 3 1','yellow');
  $vrml->back;
  $vrml->print;
  $vrml->save;

  OR with the same result

  use VRML;

  VRML->new(2)
  ->browser('Cosmo Player 2.0','Netscape')
  ->at('-15 0 20')->box('5 3 1','yellow')->back
  ->print->save;

=head1 DESCRIPTION

These modules were conceived for the production of VRML worlds on WWW servers
via GCI and/or for generating abstract worlds. They are the clarity of Perl
scripts with VRML code to increase and (hopefully) for VRML beginners the
entrance in VRML facilitate. In the following the modules are described
briefly.

=over 4

=item VRML::Base

contains base functionality such as a producing, an outputting and saving. It
represents the base class for all other modules

=item VRML::VRML1

combines several VRML 1.0 nodes into complex methods - e.g. geometric shapes
inclusive there material. This module accepts angle data in degrees and as
material color names. The methods have the same names as in the VRML
specification (if meaningfully), are however in lower case.

=item VRML::VRML1::Standard

implemented only the VRML 1.0 nodes. All method names are identical (in the
way of writing) with those of the VRML specification. The parameters are
arranged after the frequency of their use (subjective estimate). This module
is possibly omitted in the next version. The production of the VRML nodes
takes over then VRML::Base.

=item VRML::VRML2

combines several VRML 2.0 nodes into complex methods - e.g. geometric shapes
inclusive there material. This module accepts angle data in degrees and as
material color names. The methods have the same names as in the VRML
specification (if meaningfully), are however in lower case. The names are also
as far as possible identical to those of the module VRML::VRML1. Thus the
user between the VRML versions which can be produced can switch.

Contains for example $in{VRML} '1' or '2' (e.g. via CGI), then only the following
line at the start of the Perl script must be inserted.

    new VRML($in{'VRML'})

=item VRML::VRML2::Standard

implemented only the VRML 2.0 nodes. All method names are identical (in the
way of writing) with those the VRML specification. The parameters are
arranged after the frequency of their use (subjective estimate) This module
is possibly omitted in the next version. The production of the VRML nodes
takes over then VRML::Base.

=item VRML::Color

contains the color names and conversion functions.

=back

The VRML methods are at present identically in the modules VRML::VRML1.pm and
VRML::VRML2.pm implemented. The basic methods like C<new>, C<print>
or C<save> are in the module VRML::Base described.

=head1 DESCRIPTION

The methods of this module are easier to use than the VRML::*::Standard methods
because the methods are on a higher level. For example you can use X11 color
names and it's simple to apply textures to an object. All angles could be
assigned in degrees.

If a method does the same like its VRML pedant then it has the same name but in
lowercase (e.g. box). The open part of a group method ends with a
_begin (e.g. anchor_begin). The closing part ends with an _end (e.g.
anchor_end). For a detailed description how the generated node works, take a
look at the VRML 2.0 specification on VAG.

Following methods are currently implemented. (Values in '...' must be strings!)

=head2 Groups

=over 4

=item begin

F<begin('comment')>

Before you use an geometry or transform method please call this method.
It's necessary to calculate something at the end.

Example:

    new VRML
    ->begin
      ->at('0 0.1 -0.3')
        ->sphere(1,'red')
      ->back
    ->end
    ->print;

=item end

F<end('comment')>

After C<end> there should no geometry or transformation. This method completes
the calculations of viewpoints etc.

=item at('type=value','type=value', ...)

is the short version of the method C<transform_begin>. It has the same
parameters as C<transform_begin>.

Example:

    $vrml
    ->at('0 2 0')
      ->sphere(0.5,'red')
    ->back

=item back

is the short version of the method C<transform_end>.

=item anchor_begin

F<anchor_begin('url', 'description', 'parameter', 'bboxSize', 'bboxCenter')>

 url         MFString []
 description SFString ""
 parameter   MFString []
 bboxSize    SFVec3f  undef
 bboxCenter  SFVec3f  '0 0 0'

Example:

    $vrml
    ->anchor_begin('http://www.gfz-potsdam.de/~palm/vrmlperl/',
      'VRML-Perl Moduls', 'target=_blank')
      ->sphere(1,'blue')
    ->anchor_end;

=item anchor_end

close C<anchor_begin>.

=item billboard_begin

F<billboard_begin('axisOfRotation', 'bboxSize', 'bboxCenter')>

 axisOfRotation  SFVec3f  '0 1 0'
 bboxSize        SFVec3f  undef
 bboxCenter      SFVec3f  '0 0 0'

=item billboard_end

close C<billboard_begin>.


=item collision_begin

F<collision_begin(collide, proxy, 'bboxSize', 'bboxCenter')>

 collide    SFBool  1
 proxy      SFNode  NULL
 bboxSize   SFVec3f undef
 bboxCenter SFVec3f '0 0 0'

Example:

    $vrml
    ->collision_begin(1, sub{$vrml->box('5 1 0.01')})
      ->text('collide','yellow',1,'MIDDLE')
    ->collision_end

=item collision_end

close C<collision_begin>.

=item group_begin('comment')

Example:

    $vrml
    ->group_begin
      ->sphere(1,'red')
    ->group_end


=item group_end

close C<group_begin>.

=item lod_begin

F<lod_begin('range', 'center')>

 range  MFFloat []
 center SFVec3f '0 0 0'

Example:

    $vrml
    ->lod_begin('30')
      ->text('good readable')
      ->group_begin->group_end # empty Group
    ->lod_end

=item lod_end

close C<lod_begin>.

=item switch_begin

F<switch_begin(whichChoice)>

 whichChoice SFInt32 -1


=item switch_end

close C<switch_begin>.

=item transform_begin

F<transform_begin('type=value','type=value', ...)>

I<Where type can be:>

    t = translation
    r = rotation
    c = center
    s = scale
    so = scaleOrientation
    bbs = bboxSize
    bbc = bboxCenter

Example:

    $vrml
    ->transform_begin('t=0 1 0','r=180')
      ->cone('0.5 2','red')
    ->transform_end

=item transform_end

close C<transform_begin>.

=item inline

F<inline('url', 'bboxSize', 'bboxCenter')>

 url        MFString []
 bboxSize   SFVec3f  undef
 bboxCenter SFVec3f  '0 0 0'

=back

=head2 Independent Methods

=over 4

=item background

F<background(
frontUrl =E<gt> '...',
leftUrl =E<gt> '...',
rightUrl =E<gt> '...',
backUrl =E<gt> '...',
bottomUrl =E<gt> '...',
topUrl =E<gt> '...',
skyColor =E<gt> '...',
skyAngle =E<gt> '...',
groundColor =E<gt> '...',
groundAngle =E<gt> '...'
)>

 frontUrl    MFString []
 leftUrl     MFString []
 rightUrl    MFString []
 backUrl     MFString []
 bottomUrl   MFString []
 topUrl      MFString []
 skyColor    MFColor  ['0 0 0']
 skyAngle    MFFloat  []
 groundColor MFColor  []
 groundAngle MFFloat  []


This is a parameter hash. Only use the parts you need.

Example:

    $vrml->background(skyColor => 'lightblue',
                      frontUrl => 'http://www.yourdomain.de/bg/berge.gif');

=item backgroundcolor

F<backgroundcolor('skyColor', 'groundColor')>

 skyColor     SFColor  '0 0 0'
 groundColor  SFColor  '0 0 0'


is the short version of C<background>. It specifies only colors.

Example:

    $vrml->backgroundcolor('lightblue');


=item backgroundimage

F<backgroundimage('url')>

 url SFString ""

is the short version of C<background>. It needs only one image. The
given Url will assigned to all parts of the background cube.

Example:

    $vrml->backgroundimage('http://www.yourdomain.de/bg/stars.gif');

=item title

F<title('string')>

 string SFString ""

Example:

    $vrml->title('My virtual world');

=item info

F<info('string')>

 string MFString []

Example:

    $vrml->info('last update: 8.05.1997');

=item worldinfo

F<worldinfo('title', 'info')>

 title  SFString ""
 info   MFString []

combines C<title> and C<info>.

=item navigationinfo

F<navigationinfo('type', speed, headlight, visibilityLimit, avatarSize)>

 type         MFEnum     ['WALK', 'ANY'] # ANY, WALK, FLY, EXAMINE, NONE
 speed        SFFloat    1.0
 headlight    SFBool     1
 visibilityLimit SFFloat 0.0
 avatarSize   MFFloat    [0.25, 1.6, 0.75]

Example:

    $vrml->navigationinfo('WALK', 1.5, 0, 1000);

=item viewpoint_begin

starts the hidden calculation of viewpoint center and distance for the
method C<viewpoint_auto_set()>. It collects also the viepoints to place
they in the first part of the VRML source.

=item viewpoint

F<viewpoint('description', 'position', 'orientation', fieldOfView, jump)>

 description SFString          ""
 position    SFVec3f           0 0 10
 orientation SFRotation/SFEnum 0 0 1 0 # FRONT, LEFT, BACK, RIGHT, TOP, BOTTOM
 fieldOfView SFFloat           45 # Grad
 jump        SFBool            1

Example:

    $vrml->viewpoint('Start','0 0 0','0 0 -1 0',60);

is the same like

    $vrml->viewpoint('Start',undef,'FRONT',60);


=item viewpoint_set

F<viewpoint_set('center', distance, fieldOfView, avatarSize)>

 center       SFVec3f '0 0 0'
 distance     SFFloat 10
 fieldOfView  SFFloat 45 # Grad
 avatarSize   MFFloat [0.25, 1.6, 0.75]

places six viewpoints around the center.

=item viewpoint_auto_set

sets all parameters of C<viewpoint_set> automatically.

=item viewpoint_end

close C<viewpoint_begin>.

=back

=head2 Shapes

=over 4

=item box

F<box('size', 'appearance')>

 size       SFVec3f  '2 2 2' # width height depth
 appearance SFString ""      # see Appearance

=item cone

F<cone('bottomRadius height', 'appearance')>

 bottomRadius height SFVec2f '1 2'
 appearance          SFString "" # see Appearance

=item cylinder

F<cylinder('radius height', 'appearance')>

 radius height SFVec2f  '1 2'
 appearance    SFString "" # see Appearance

=item line

F<line('from', 'to', radius, 'appearance', 'path')>

 from        SFVec3f   ""
 to          SFVec3f   ""
 radius      SFFloat   0 # 0 = haarline
 appearance  SFString  ""
 path        SFEnum    "" # XYZ, XZY, YXZ, YZX, ZXY, ZYX

draws a line (cylinder) between two points with a given radius. If radius
is '0' only a hairline will be printed. The last parameter specifies the
devolution along the axes. An empty stands for direct connection.

Example:

    new VRML(2)
    ->begin
      ->line('1 -1 1', '-3 2 2', 0.03, 'red', 'XZY')
      ->line('1 -1 1', '-3 2 2', 0.03, 'white')
    ->end
    ->print;

=item pyramid

F<pyramid('size', 'appearance')>

 size       SFVec3f  '2 2 2' # width height depth
 appearance SFString ""      # see Appearance

Example:

    $vrml->pyramid('1 1 1','blue,green,red,yellow,white');

=item sphere

F<sphere(radius, 'appearance')>

 radius     SFFloat  1
 appearance SFString "" # see Appearance

=item elevationgrid

F<elevationgrid(height, color, xDimension, zDimension, xSpacing,
zSpacing, creaseAngle, colorPerVertex, solid)>

 height          MFFloat  []
 color           MFColor  [] # resp. material and color
 xDimension      SFInt32  0
 zDimension      SFInt32  0
 xSpacing        SFFloat  1.0
 zSpacing        SFFloat  1.0
 creaseAngle     SFFloat  0
 colorPerVertex  SFBool   1
 solid           SFBool   0

If I<color> is not a reference of an ARRAY it would be assumed that I<color>
is the appearance.

Example:

    open(FILE,"<height.txt");
    my @height = <FILE>;
    open(COL,"<color.txt");
    my @color = <COL>;
    $vrml->navigationinfo(["EXAMINE","FLY"],200)
         ->viewpoint("Top","1900 6000 1900","TOP")
         ->elevationgrid(\@height, \@color, undef, undef, 250, undef, 0)
         ->print;

=item text

F<text('string', 'appearance', 'font', 'align')>

 string     MFString []
 appearance SFString "" # see Appearance
 font       SFString '1 SERIF PLAIN'
 align      SFEnum   'BEGIN' # BEGIN, MIDDLE, END


=item billtext

F<billtext('string', 'appearance', 'font', 'align')>

 string     MFString []
 appearance SFString "" # see Appearance
 font       SFString '1 SERIF PLAIN'
 align      SFEnum   'BEGIN' # BEGIN, MIDDLE, END


does the same like method C<text>, but the text better readable.

=item Appearance

F<appearance('type=value1,value2 ; type=...')>

The appearance method specifies the visual properties of geometry by defining
the material and texture. If more than one type is needed separate the types
by semicolon. The types can choosen from the following list.

Note: one character mnemonic are colors
      two characters mnemonic are values in range of [0..1]
      more characters are strings like file names or labels

        d = diffuseColor
        e = emissiveColor
        s = specularColor
        ai = ambientIntensity
        sh = shininess
        tr = transparency
        tex = texture filename,wrapS,wrapT
        name = names the MovieTexture node (for a later route)

The color values can be strings (X11 color names) or RGB-triples. It is
possible to reduce the intensity of colors (names) by appending a two digit
value (percent). This value must be separated by an underscore (_) or
a percent symbol (%). Note: Do not use a percent symbol in URL's. It would
be decoded in an ascii character.

Sample (valid color values):
        '1 1 0' # VRML standard
        'FFFF00' or 'ffff00', '255 255 0', 'yellow'

or reduced to 50%
        '.5 .5 .5' # VRML standard
        '808080', '128 128 0', 'yellow%50' or 'yellow_50'


For a list of I<X11 color names> take a look at VRML::Color

=back

=head2 Misc

=over 4

=item directionallight

F<directionallight('direction', intensity, ambientIntensity, 'color', on)>

 direction         SFVec3f  '0 0 -1'
 intensity         SFFloat  1
 ambientIntensity  SFFloat  1
 color             SFColor  '1 1 1' #white
 on                SFBool   1

Example:

    $vrml->directionallight("0 0 -1", 0.3);


=item sound

F<sound('url','description', 'location', 'direction', intensity, loop, pitch)>

 url         MFString []
 description SFString ""
 location    SFVec3f  '0 0 0'
 direction   SFVec3f  '0 0 1'
 intensity   SFFloat  1.0
 loop        SFBool   0
 pitch       SFFloat  1.0

=item def

F<def('name')>

 name SFString ""

Example:

    $vrml->def('RedSphere')->sphere(1,'red')

=item use

F<use('name')>

 name SFString ""

Example:

    $vrml->use('RedSphere')


=item route

F<route('from','to')>

 FROM.feldname SFString ""
 TO.feldname   SFString ""

=back

=head2 Interpolators

=over 4

=item interpolator

F<interpolator('name','type',[keys],[keyValues])>

 name      SFString ""
 type      SFEnum   "" # Color, Coordinate, Normal, Orientation,
                       # Position und Scalar
 keys      MFFloat  [] # [0,1]
 keyValues MF...    [] # Type of Interpolator


=back

=head2 Sensors

=over 4

=item cylindersensor

F<cylindersensor('name',maxAngle,minAngle,diskAngle,offset,autoOffset,enabled)>

 name       SFString ""
 maxAngle   SFFloat  undef
 minAngle   SFFloat  0
 diskAngle  SFFloat  15
 offset     SFFloat  0
 autoOffset SFBool   1
 enabled    SFBool   1

=item planesensor

F<planesensor('name',maxPosition,minPosition,offset,autoOffset,enabled)>

 name         SFString  ""
 maxPosition  SFVec2f  undef
 minPosition  SFVec2f  '0 0'
 offset       SFVec3f  '0 0 0'
 autoOffset   SFBool  1
 enabled      SFBool  1

=item proximitysensor

F<proximitysensor('name',size,center,enabled)>

 name    SFString ""
 size    SFVec3f  '0 0 0'
 center  SFVec3f  '0 0 0'
 enabled SFBool   1

=item spheresensor

F<spheresensor('name',offset,autoOffset,enabled)>

 name       SFString   ""
 offset     SFRotation '0 1 0 0'
 autoOffset SFBool     1
 enabled    SFBool     1

=item timesensor

F<timesensor('name',cycleInterval,loop,startTime,stopTime,enabled)>

 name          SFString ""
 cycleInterval SFFloat  1
 loop          SFBool   0
 startTime     SFFloat  0
 stopTime      SFFloat  0
 enabled       SFBool   1

=item touchsensor

F<touchsensor('name',enabled)>

    name    SFString ""
    enabled SFBool   1

Example:

    $vrml
    ->begin
        ->touchsensor('Switch')
        ->sphere(1,'white')
        ->def('Light')->directionallight("", 1, 0, 'red', 0)
        ->route('Switch.isActive', 'Light.on')
    ->end
    ->print->save;

=item visibitysensor

F<visibitysensor('name',size,center,enabled)>

    name    SFString ""
    size    SFVec3f  '0 0 0'
    center  SFVec3f  '0 0 0'
    enabled SFBool   1

=back

=head1 SEE ALSO

VRML::VRML2

VRML::VRML2::Standard

VRML::Base

http://www.gfz-potsdam.de/~palm/vrmlperl/ for a description of F<VRML-modules> and how to obtain it.

=head1 AUTHOR

Hartmut Palm F<E<lt>palm@gfz-potsdam.deE<gt>>

Homepage http://www.gfz-potsdam.de/~palm/

=cut
