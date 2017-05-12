# ABSTRACT:

=head1 NAME

WebColors

=head1 SYNOPSIS

    use 5.10.0 ;
    use strict ;
    use warnings ;
    use WebColors;

    my ($r, $g, $b) = colorname_to_rgb( 'goldenrod') ;

=head1 DESCRIPTION

Get either the hex triplet value or the rgb values for a HTML named color.

Values have been taken from https://en.wikipedia.org/wiki/HTML_color_names#HTML_color_names

For me I want this module so that I can use the named colours to
extend Device::Hynpocube so that it can use the full set of named colors it
is also used in Device::BlinkStick

Google material colors have spaces removed and their numerical values added, so

Red 400 becomes red400, with accents Deep Purple A100 becomes deeppurplea100

See Also

Google material colors L<http://www.google.com/design/spec/style/color.html>

=cut

package WebColors ;
$WebColors::VERSION = '0.4.4';
use 5.0.4 ;
use warnings ;
use strict ;
use Exporter ;
use vars qw( @EXPORT @ISA) ;

@ISA = qw(Exporter) ;

# this is the list of things that will get imported into the loading packages
# namespace
@EXPORT = qw(
    list_webcolors
    to_rgb
    colorname_to_hex
    colorname_to_rgb
    colorname_to_rgb_percent
    rgb_to_colorname
    hex_to_colorname
    rgb_percent_to_colorname
    inverse_rgb
    luminance
    ) ;

# ----------------------------------------------------------------------------

my %web_colors = (

    # basic
    black   => [ 0,   0,   0 ],
    silver  => [ 192, 192, 192 ],
    gray    => [ 128, 128, 128 ],
    white   => [ 255, 255, 255 ],
    maroon  => [ 128, 0,   0 ],
    red     => [ 255, 0,   0 ],
    purple  => [ 128, 0,   128 ],
    fuchsia => [ 255, 0,   255 ],
    green   => [ 0,   128, 0 ],
    lime    => [ 0,   255, 0 ],
    olive   => [ 128, 128, 0 ],
    yellow  => [ 255, 255, 0 ],
    navy    => [ 0,   0,   128 ],
    blue    => [ 0,   0,   255 ],
    teal    => [ 0,   128, 128 ],
    aqua    => [ 0,   255, 255 ],

    # extended
    aliceblue            => [ 240, 248, 255 ],
    antiquewhite         => [ 250, 235, 215 ],
    aqua                 => [ 0,   255, 255 ],
    aquamarine           => [ 127, 255, 212 ],
    azure                => [ 240, 255, 255 ],
    beige                => [ 245, 245, 220 ],
    bisque               => [ 255, 228, 196 ],
    black                => [ 0,   0,   0 ],
    blanchedalmond       => [ 255, 235, 205 ],
    blue                 => [ 0,   0,   255 ],
    blueviolet           => [ 138, 43,  226 ],
    brown                => [ 165, 42,  42 ],
    burlywood            => [ 222, 184, 135 ],
    cadetblue            => [ 95,  158, 160 ],
    chartreuse           => [ 127, 255, 0 ],
    chocolate            => [ 210, 105, 30 ],
    coral                => [ 255, 127, 80 ],
    cornflowerblue       => [ 100, 149, 237 ],
    cornsilk             => [ 255, 248, 220 ],
    crimson              => [ 220, 20,  60 ],
    cyan                 => [ 0,   255, 255 ],
    darkblue             => [ 0,   0,   139 ],
    darkcyan             => [ 0,   139, 139 ],
    darkgoldenrod        => [ 184, 134, 11 ],
    darkgray             => [ 169, 169, 169 ],
    darkgreen            => [ 0,   100, 0 ],
    darkgrey             => [ 169, 169, 169 ],
    darkkhaki            => [ 189, 183, 107 ],
    darkmagenta          => [ 139, 0,   139 ],
    darkolivegreen       => [ 85,  107, 47 ],
    darkorange           => [ 255, 140, 0 ],
    darkorchid           => [ 153, 50,  204 ],
    darkred              => [ 139, 0,   0 ],
    darksalmon           => [ 233, 150, 122 ],
    darkseagreen         => [ 143, 188, 143 ],
    darkslateblue        => [ 72,  61,  139 ],
    darkslategray        => [ 47,  79,  79 ],
    darkslategrey        => [ 47,  79,  79 ],
    darkturquoise        => [ 0,   206, 209 ],
    darkviolet           => [ 148, 0,   211 ],
    deeppink             => [ 255, 20,  147 ],
    deepskyblue          => [ 0,   191, 255 ],
    dimgray              => [ 105, 105, 105 ],
    dimgrey              => [ 105, 105, 105 ],
    dodgerblue           => [ 30,  144, 255 ],
    firebrick            => [ 178, 34,  34 ],
    floralwhite          => [ 255, 250, 240 ],
    forestgreen          => [ 34,  139, 34 ],
    fuchsia              => [ 255, 0,   255 ],
    gainsboro            => [ 220, 220, 220 ],
    ghostwhite           => [ 248, 248, 255 ],
    gold                 => [ 255, 215, 0 ],
    goldenrod            => [ 218, 165, 32 ],
    gray                 => [ 128, 128, 128 ],
    green                => [ 0,   128, 0 ],
    greenyellow          => [ 173, 255, 47 ],
    grey                 => [ 128, 128, 128 ],
    honeydew             => [ 240, 255, 240 ],
    hotpink              => [ 255, 105, 180 ],
    indianred            => [ 205, 92,  92 ],
    indigo               => [ 75,  0,   130 ],
    ivory                => [ 255, 255, 240 ],
    khaki                => [ 240, 230, 140 ],
    lavender             => [ 230, 230, 250 ],
    lavenderblush        => [ 255, 240, 245 ],
    lawngreen            => [ 124, 252, 0 ],
    lemonchiffon         => [ 255, 250, 205 ],
    lightblue            => [ 173, 216, 230 ],
    lightcoral           => [ 240, 128, 128 ],
    lightcyan            => [ 224, 255, 255 ],
    lightgoldenrodyellow => [ 250, 250, 210 ],
    lightgray            => [ 211, 211, 211 ],
    lightgreen           => [ 144, 238, 144 ],
    lightgrey            => [ 211, 211, 211 ],
    lightpink            => [ 255, 182, 193 ],
    lightsalmon          => [ 255, 160, 122 ],
    lightseagreen        => [ 32,  178, 170 ],
    lightskyblue         => [ 135, 206, 250 ],
    lightslategray       => [ 119, 136, 153 ],
    lightslategrey       => [ 119, 136, 153 ],
    lightsteelblue       => [ 176, 196, 222 ],
    lightyellow          => [ 255, 255, 224 ],
    lime                 => [ 0,   255, 0 ],
    limegreen            => [ 50,  205, 50 ],
    linen                => [ 250, 240, 230 ],
    magenta              => [ 255, 0,   255 ],
    maroon               => [ 128, 0,   0 ],
    mediumaquamarine     => [ 102, 205, 170 ],
    mediumblue           => [ 0,   0,   205 ],
    mediumorchid         => [ 186, 85,  211 ],
    mediumpurple         => [ 147, 112, 219 ],
    mediumseagreen       => [ 60,  179, 113 ],
    mediumslateblue      => [ 123, 104, 238 ],
    mediumspringgreen    => [ 0,   250, 154 ],
    mediumturquoise      => [ 72,  209, 204 ],
    mediumvioletred      => [ 199, 21,  133 ],
    midnightblue         => [ 25,  25,  112 ],
    mintcream            => [ 245, 255, 250 ],
    mistyrose            => [ 255, 228, 225 ],
    moccasin             => [ 255, 228, 181 ],
    navajowhite          => [ 255, 222, 173 ],
    navy                 => [ 0,   0,   128 ],
    oldlace              => [ 253, 245, 230 ],
    olive                => [ 128, 128, 0 ],
    olivedrab            => [ 107, 142, 35 ],
    orange               => [ 255, 165, 0 ],
    orangered            => [ 255, 69,  0 ],
    orchid               => [ 218, 112, 214 ],
    palegoldenrod        => [ 238, 232, 170 ],
    palegreen            => [ 152, 251, 152 ],
    paleturquoise        => [ 175, 238, 238 ],
    palevioletred        => [ 219, 112, 147 ],
    papayawhip           => [ 255, 239, 213 ],
    peachpuff            => [ 255, 218, 185 ],
    peru                 => [ 205, 133, 63 ],
    pink                 => [ 255, 192, 203 ],
    plum                 => [ 221, 160, 221 ],
    powderblue           => [ 176, 224, 230 ],
    purple               => [ 128, 0,   128 ],
    red                  => [ 255, 0,   0 ],
    rebeccapurple        => [ 102, 51,  153 ],
    rosybrown            => [ 188, 143, 143 ],
    royalblue            => [ 65,  105, 225 ],
    saddlebrown          => [ 139, 69,  19 ],
    salmon               => [ 250, 128, 114 ],
    sandybrown           => [ 244, 164, 96 ],
    seagreen             => [ 46,  139, 87 ],
    seashell             => [ 255, 245, 238 ],
    sienna               => [ 160, 82,  45 ],
    silver               => [ 192, 192, 192 ],
    skyblue              => [ 135, 206, 235 ],
    slateblue            => [ 106, 90,  205 ],
    slategray            => [ 112, 128, 144 ],
    slategrey            => [ 112, 128, 144 ],
    snow                 => [ 255, 250, 250 ],
    springgreen          => [ 0,   255, 127 ],
    steelblue            => [ 70,  130, 180 ],
    tan                  => [ 210, 180, 140 ],
    teal                 => [ 0,   128, 128 ],
    thistle              => [ 216, 191, 216 ],
    tomato               => [ 255, 99,  71 ],
    turquoise            => [ 64,  224, 208 ],
    violet               => [ 238, 130, 238 ],
    wheat                => [ 245, 222, 179 ],
    white                => [ 255, 255, 255 ],
    whitesmoke           => [ 245, 245, 245 ],
    yellow               => [ 255, 255, 0 ],
    yellowgreen          => [ 154, 205, 50 ],

# google material colors from http://www.google.com/design/spec/style/color.html

    red50   => [ 0xff, 0xeb, 0xee ],
    red100  => [ 0xff, 0xcd, 0xd2 ],
    red200  => [ 0xef, 0x9a, 0x9a ],
    red300  => [ 0xe5, 0x73, 0x73 ],
    red400  => [ 0xef, 0x53, 0x50 ],
    red500  => [ 0xf4, 0x43, 0x36 ],
    red600  => [ 0xe5, 0x39, 0x35 ],
    red700  => [ 0xd3, 0x2f, 0x2f ],
    red800  => [ 0xc6, 0x28, 0x28 ],
    red900  => [ 0xb7, 0x1c, 0x1c ],
    reda100 => [ 0xff, 0x8a, 0x80 ],
    reda200 => [ 0xff, 0x52, 0x52 ],
    reda400 => [ 0xff, 0x17, 0x44 ],
    reda700 => [ 0xd5, 0x00, 0x00 ],

    pink50   => [ 0xfc, 0xe4, 0xec ],
    pink100  => [ 0xf8, 0xbb, 0xd0 ],
    pink200  => [ 0xf4, 0x8f, 0xb1 ],
    pink300  => [ 0xf0, 0x62, 0x92 ],
    pink400  => [ 0xec, 0x40, 0x7a ],
    pink500  => [ 0xe9, 0x1e, 0x63 ],
    pink600  => [ 0xd8, 0x1b, 0x60 ],
    pink700  => [ 0xc2, 0x18, 0x5b ],
    pink800  => [ 0xad, 0x14, 0x57 ],
    pink900  => [ 0x88, 0x0e, 0x4f ],
    pinka100 => [ 0xff, 0x80, 0xab ],
    pinka200 => [ 0xff, 0x40, 0x81 ],
    pinka400 => [ 0xf5, 0x00, 0x57 ],
    pinka700 => [ 0xc5, 0x11, 0x62 ],

    purple50   => [ 0xf3, 0xe5, 0xf5 ],
    purple100  => [ 0xe1, 0xbe, 0xe7 ],
    purple200  => [ 0xce, 0x93, 0xd8 ],
    purple300  => [ 0xba, 0x68, 0xc8 ],
    purple400  => [ 0xab, 0x47, 0xbc ],
    purple500  => [ 0x9c, 0x27, 0xb0 ],
    purple600  => [ 0x8e, 0x24, 0xaa ],
    purple700  => [ 0x7b, 0x1f, 0xa2 ],
    purple800  => [ 0x6a, 0x1b, 0x9a ],
    purple900  => [ 0x4a, 0x14, 0x8c ],
    purplea100 => [ 0xea, 0x80, 0xfc ],
    purplea200 => [ 0xe0, 0x40, 0xfb ],
    purplea400 => [ 0xd5, 0x00, 0xf9 ],
    purplea700 => [ 0xaa, 0x00, 0xff ],

    deeppurple50   => [ 0xed, 0xe7, 0xf6 ],
    deeppurple100  => [ 0xd1, 0xc4, 0xe9 ],
    deeppurple200  => [ 0xb3, 0x9d, 0xdb ],
    deeppurple300  => [ 0x95, 0x75, 0xcd ],
    deeppurple400  => [ 0x7e, 0x57, 0xc2 ],
    deeppurple500  => [ 0x67, 0x3a, 0xb7 ],
    deeppurple600  => [ 0x5e, 0x35, 0xb1 ],
    deeppurple700  => [ 0x51, 0x2d, 0xa8 ],
    deeppurple800  => [ 0x45, 0x27, 0xa0 ],
    deeppurple900  => [ 0x31, 0x1b, 0x92 ],
    deeppurplea100 => [ 0xb3, 0x88, 0xff ],
    deeppurplea200 => [ 0x7c, 0x4d, 0xff ],
    deeppurplea400 => [ 0x65, 0x1f, 0xff ],
    deeppurplea700 => [ 0x62, 0x00, 0xea ],

    indigo50   => [ 0xe8, 0xea, 0xf6 ],
    indigo100  => [ 0xc5, 0xca, 0xe9 ],
    indigo200  => [ 0x9f, 0xa8, 0xda ],
    indigo300  => [ 0x79, 0x86, 0xcb ],
    indigo400  => [ 0x5c, 0x6b, 0xc0 ],
    indigo500  => [ 0x3f, 0x51, 0xb5 ],
    indigo600  => [ 0x39, 0x49, 0xab ],
    indigo700  => [ 0x30, 0x3f, 0x9f ],
    indigo800  => [ 0x28, 0x35, 0x93 ],
    indigo900  => [ 0x1a, 0x23, 0x7e ],
    indigoa100 => [ 0x8c, 0x9e, 0xff ],
    indigoa200 => [ 0x53, 0x6d, 0xfe ],
    indigoa400 => [ 0x3d, 0x5a, 0xfe ],
    indigoa700 => [ 0x30, 0x4f, 0xfe ],

    blue50   => [ 0xe3, 0xf2, 0xfd ],
    blue100  => [ 0xbb, 0xde, 0xfb ],
    blue200  => [ 0x90, 0xca, 0xf9 ],
    blue300  => [ 0x64, 0xb5, 0xf6 ],
    blue400  => [ 0x42, 0xa5, 0xf5 ],
    blue500  => [ 0x21, 0x96, 0xf3 ],
    blue600  => [ 0x1e, 0x88, 0xe5 ],
    blue700  => [ 0x19, 0x76, 0xd2 ],
    blue800  => [ 0x15, 0x65, 0xc0 ],
    blue900  => [ 0x0d, 0x47, 0xa1 ],
    bluea100 => [ 0x82, 0xb1, 0xff ],
    bluea200 => [ 0x44, 0x8a, 0xff ],
    bluea400 => [ 0x29, 0x79, 0xff ],
    bluea700 => [ 0x29, 0x62, 0xff ],

    lightblue50   => [ 0xe1, 0xf5, 0xfe ],
    lightblue100  => [ 0xb3, 0xe5, 0xfc ],
    lightblue200  => [ 0x81, 0xd4, 0xfa ],
    lightblue300  => [ 0x4f, 0xc3, 0xf7 ],
    lightblue400  => [ 0x29, 0xb6, 0xf6 ],
    lightblue500  => [ 0x03, 0xa9, 0xf4 ],
    lightblue600  => [ 0x03, 0x9b, 0xe5 ],
    lightblue700  => [ 0x02, 0x88, 0xd1 ],
    lightblue800  => [ 0x02, 0x77, 0xbd ],
    lightblue900  => [ 0x01, 0x57, 0x9b ],
    lightbluea100 => [ 0x80, 0xd8, 0xff ],
    lightbluea200 => [ 0x40, 0xc4, 0xff ],
    lightbluea400 => [ 0x00, 0xb0, 0xff ],
    lightbluea700 => [ 0x00, 0x91, 0xea ],

    cyan50   => [ 0xe0, 0xf7, 0xfa ],
    cyan100  => [ 0xb2, 0xeb, 0xf2 ],
    cyan200  => [ 0x80, 0xde, 0xea ],
    cyan300  => [ 0x4d, 0xd0, 0xe1 ],
    cyan400  => [ 0x26, 0xc6, 0xda ],
    cyan500  => [ 0x00, 0xbc, 0xd4 ],
    cyan600  => [ 0x00, 0xac, 0xc1 ],
    cyan700  => [ 0x00, 0x97, 0xa7 ],
    cyan800  => [ 0x00, 0x83, 0x8f ],
    cyan900  => [ 0x00, 0x60, 0x64 ],
    cyana100 => [ 0x84, 0xff, 0xff ],
    cyana200 => [ 0x18, 0xff, 0xff ],
    cyana400 => [ 0x00, 0xe5, 0xff ],
    cyana700 => [ 0x00, 0xb8, 0xd4 ],

    teal50   => [ 0xe0, 0xf2, 0xf1 ],
    teal100  => [ 0xb2, 0xdf, 0xdb ],
    teal200  => [ 0x80, 0xcb, 0xc4 ],
    teal300  => [ 0x4d, 0xb6, 0xac ],
    teal400  => [ 0x26, 0xa6, 0x9a ],
    teal500  => [ 0x00, 0x96, 0x88 ],
    teal600  => [ 0x00, 0x89, 0x7b ],
    teal700  => [ 0x00, 0x79, 0x6b ],
    teal800  => [ 0x00, 0x69, 0x5c ],
    teal900  => [ 0x00, 0x4d, 0x40 ],
    teala100 => [ 0xa7, 0xff, 0xeb ],
    teala200 => [ 0x64, 0xff, 0xda ],
    teala400 => [ 0x1d, 0xe9, 0xb6 ],
    teala700 => [ 0x00, 0xbf, 0xa5 ],

    green50   => [ 0xe8, 0xf5, 0xe9 ],
    green100  => [ 0xc8, 0xe6, 0xc9 ],
    green200  => [ 0xa5, 0xd6, 0xa7 ],
    green300  => [ 0x81, 0xc7, 0x84 ],
    green400  => [ 0x66, 0xbb, 0x6a ],
    green500  => [ 0x4c, 0xaf, 0x50 ],
    green600  => [ 0x43, 0xa0, 0x47 ],
    green700  => [ 0x38, 0x8e, 0x3c ],
    green800  => [ 0x2e, 0x7d, 0x32 ],
    green900  => [ 0x1b, 0x5e, 0x20 ],
    greena100 => [ 0xb9, 0xf6, 0xca ],
    greena200 => [ 0x69, 0xf0, 0xae ],
    greena400 => [ 0x00, 0xe6, 0x76 ],
    greena700 => [ 0x00, 0xc8, 0x53 ],

    lightgreen50   => [ 0xf1, 0xf8, 0xe9 ],
    lightgreen100  => [ 0xdc, 0xed, 0xc8 ],
    lightgreen200  => [ 0xc5, 0xe1, 0xa5 ],
    lightgreen300  => [ 0xae, 0xd5, 0x81 ],
    lightgreen400  => [ 0x9c, 0xcc, 0x65 ],
    lightgreen500  => [ 0x8b, 0xc3, 0x4a ],
    lightgreen600  => [ 0x7c, 0xb3, 0x42 ],
    lightgreen700  => [ 0x68, 0x9f, 0x38 ],
    lightgreen800  => [ 0x55, 0x8b, 0x2f ],
    lightgreen900  => [ 0x33, 0x69, 0x1e ],
    lightgreena100 => [ 0xcc, 0xff, 0x90 ],
    lightgreena200 => [ 0xb2, 0xff, 0x59 ],
    lightgreena400 => [ 0x76, 0xff, 0x03 ],
    lightgreena700 => [ 0x64, 0xdd, 0x17 ],

    lime50   => [ 0xf9, 0xfb, 0xe7 ],
    lime100  => [ 0xf0, 0xf4, 0xc3 ],
    lime200  => [ 0xe6, 0xee, 0x9c ],
    lime300  => [ 0xdc, 0xe7, 0x75 ],
    lime400  => [ 0xd4, 0xe1, 0x57 ],
    lime500  => [ 0xcd, 0xdc, 0x39 ],
    lime600  => [ 0xc0, 0xca, 0x33 ],
    lime700  => [ 0xaf, 0xb4, 0x2b ],
    lime800  => [ 0x9e, 0x9d, 0x24 ],
    lime900  => [ 0x82, 0x77, 0x17 ],
    limea100 => [ 0xf4, 0xff, 0x81 ],
    limea200 => [ 0xee, 0xff, 0x41 ],
    limea400 => [ 0xc6, 0xff, 0x00 ],
    limea700 => [ 0xae, 0xea, 0x00 ],

    yellow50   => [ 0xff, 0xfd, 0xe7 ],
    yellow100  => [ 0xff, 0xf9, 0xc4 ],
    yellow200  => [ 0xff, 0xf5, 0x9d ],
    yellow300  => [ 0xff, 0xf1, 0x76 ],
    yellow400  => [ 0xff, 0xee, 0x58 ],
    yellow500  => [ 0xff, 0xeb, 0x3b ],
    yellow600  => [ 0xfd, 0xd8, 0x35 ],
    yellow700  => [ 0xfb, 0xc0, 0x2d ],
    yellow800  => [ 0xf9, 0xa8, 0x25 ],
    yellow900  => [ 0xf5, 0x7f, 0x17 ],
    yellowa100 => [ 0xff, 0xff, 0x8d ],
    yellowa200 => [ 0xff, 0xff, 0x00 ],
    yellowa400 => [ 0xff, 0xea, 0x00 ],
    yellowa700 => [ 0xff, 0xd6, 0x00 ],

    amber50   => [ 0xff, 0xf8, 0xe1 ],
    amber100  => [ 0xff, 0xec, 0xb3 ],
    amber200  => [ 0xff, 0xe0, 0x82 ],
    amber300  => [ 0xff, 0xd5, 0x4f ],
    amber400  => [ 0xff, 0xca, 0x28 ],
    amber500  => [ 0xff, 0xc1, 0x07 ],
    amber600  => [ 0xff, 0xb3, 0x00 ],
    amber700  => [ 0xff, 0xa0, 0x00 ],
    amber800  => [ 0xff, 0x8f, 0x00 ],
    amber900  => [ 0xff, 0x6f, 0x00 ],
    ambera100 => [ 0xff, 0xe5, 0x7f ],
    ambera200 => [ 0xff, 0xd7, 0x40 ],
    ambera400 => [ 0xff, 0xc4, 0x00 ],
    ambera700 => [ 0xff, 0xab, 0x00 ],

    orange50   => [ 0xff, 0xf3, 0xe0 ],
    orange100  => [ 0xff, 0xe0, 0xb2 ],
    orange200  => [ 0xff, 0xcc, 0x80 ],
    orange300  => [ 0xff, 0xb7, 0x4d ],
    orange400  => [ 0xff, 0xa7, 0x26 ],
    orange500  => [ 0xff, 0x98, 0x00 ],
    orange600  => [ 0xfb, 0x8c, 0x00 ],
    orange700  => [ 0xf5, 0x7c, 0x00 ],
    orange800  => [ 0xef, 0x6c, 0x00 ],
    orange900  => [ 0xe6, 0x51, 0x00 ],
    orangea100 => [ 0xff, 0xd1, 0x80 ],
    orangea200 => [ 0xff, 0xab, 0x40 ],
    orangea400 => [ 0xff, 0x91, 0x00 ],
    orangea700 => [ 0xff, 0x6d, 0x00 ],

    deeporange50   => [ 0xfb, 0xe9, 0xe7 ],
    deeporange100  => [ 0xff, 0xcc, 0xbc ],
    deeporange200  => [ 0xff, 0xab, 0x91 ],
    deeporange300  => [ 0xff, 0x8a, 0x65 ],
    deeporange400  => [ 0xff, 0x70, 0x43 ],
    deeporange500  => [ 0xff, 0x57, 0x22 ],
    deeporange600  => [ 0xf4, 0x51, 0x1e ],
    deeporange700  => [ 0xe6, 0x4a, 0x19 ],
    deeporange800  => [ 0xd8, 0x43, 0x15 ],
    deeporange900  => [ 0xbf, 0x36, 0x0c ],
    deeporangea100 => [ 0xff, 0x9e, 0x80 ],
    deeporangea200 => [ 0xff, 0x6e, 0x40 ],
    deeporangea400 => [ 0xff, 0x3d, 0x00 ],
    deeporangea700 => [ 0xdd, 0x2c, 0x00 ],

    brown50  => [ 0xef, 0xeb, 0xe9 ],
    brown100 => [ 0xd7, 0xcc, 0xc8 ],
    brown200 => [ 0xbc, 0xaa, 0xa4 ],
    brown300 => [ 0xa1, 0x88, 0x7f ],
    brown400 => [ 0x8d, 0x6e, 0x63 ],
    brown500 => [ 0x79, 0x55, 0x48 ],
    brown600 => [ 0x6d, 0x4c, 0x41 ],
    brown700 => [ 0x5d, 0x40, 0x37 ],
    brown800 => [ 0x4e, 0x34, 0x2e ],
    brown900 => [ 0x3e, 0x27, 0x23 ],

    grey50  => [ 0xfa, 0xfa, 0xfa ],
    grey100 => [ 0xf5, 0xf5, 0xf5 ],
    grey200 => [ 0xee, 0xee, 0xee ],
    grey300 => [ 0xe0, 0xe0, 0xe0 ],
    grey400 => [ 0xbd, 0xbd, 0xbd ],
    grey500 => [ 0x9e, 0x9e, 0x9e ],
    grey600 => [ 0x75, 0x75, 0x75 ],
    grey700 => [ 0x61, 0x61, 0x61 ],
    grey800 => [ 0x42, 0x42, 0x42 ],
    grey900 => [ 0x21, 0x21, 0x21 ],

    bluegrey50  => [ 0xec, 0xef, 0xf1 ],
    bluegrey100 => [ 0xcf, 0xd8, 0xdc ],
    bluegrey200 => [ 0xb0, 0xbe, 0xc5 ],
    bluegrey300 => [ 0x90, 0xa4, 0xae ],
    bluegrey400 => [ 0x78, 0x90, 0x9c ],
    bluegrey500 => [ 0x60, 0x7d, 0x8b ],
    bluegrey600 => [ 0x54, 0x6e, 0x7a ],
    bluegrey700 => [ 0x45, 0x5a, 0x64 ],
    bluegrey800 => [ 0x37, 0x47, 0x4f ],
    bluegrey900 => [ 0x26, 0x32, 0x38 ],

    # open colors https://yeun.github.io/open-color/
    # variations in names handled in colorname_to_rgb
    'oc-gray-0'   => [ 0xf8, 0xf9, 0xfa ],
    'oc-gray-1'   => [ 0xf1, 0xf3, 0xf5 ],
    'oc-gray-2'   => [ 0xe9, 0xec, 0xef ],
    'oc-gray-3'   => [ 0xde, 0xe2, 0xe6 ],
    'oc-gray-4'   => [ 0xce, 0xd4, 0xda ],
    'oc-gray-5'   => [ 0xad, 0xb5, 0xbd ],
    'oc-gray-6'   => [ 0x86, 0x8e, 0x96 ],
    'oc-gray-7'   => [ 0x49, 0x50, 0x57 ],
    'oc-gray-8'   => [ 0x34, 0x3a, 0x40 ],
    'oc-gray-9'   => [ 0x21, 0x25, 0x29 ],
    'oc-red-0'    => [ 0xff, 0xf5, 0xf5 ],
    'oc-red-1'    => [ 0xff, 0xe3, 0xe3 ],
    'oc-red-2'    => [ 0xff, 0xc9, 0xc9 ],
    'oc-red-3'    => [ 0xff, 0xa8, 0xa8 ],
    'oc-red-4'    => [ 0xff, 0x87, 0x87 ],
    'oc-red-5'    => [ 0xff, 0x6b, 0x6b ],
    'oc-red-6'    => [ 0xfa, 0x52, 0x52 ],
    'oc-red-7'    => [ 0xf0, 0x3e, 0x3e ],
    'oc-red-8'    => [ 0xe0, 0x31, 0x31 ],
    'oc-red-9'    => [ 0xc9, 0x2a, 0x2a ],
    'oc-pink-0'   => [ 0xff, 0xf0, 0xf6 ],
    'oc-pink-1'   => [ 0xff, 0xde, 0xeb ],
    'oc-pink-2'   => [ 0xfc, 0xc2, 0xd7 ],
    'oc-pink-3'   => [ 0xfa, 0xa2, 0xc1 ],
    'oc-pink-4'   => [ 0xf7, 0x83, 0xac ],
    'oc-pink-5'   => [ 0xf0, 0x65, 0x95 ],
    'oc-pink-6'   => [ 0xe6, 0x49, 0x80 ],
    'oc-pink-7'   => [ 0xd6, 0x33, 0x6c ],
    'oc-pink-8'   => [ 0xc2, 0x25, 0x5c ],
    'oc-pink-9'   => [ 0xa6, 0x1e, 0x4d ],
    'oc-grape-0'  => [ 0xf8, 0xf0, 0xfc ],
    'oc-grape-1'  => [ 0xf3, 0xd9, 0xfa ],
    'oc-grape-2'  => [ 0xee, 0xbe, 0xfa ],
    'oc-grape-3'  => [ 0xe5, 0x99, 0xf7 ],
    'oc-grape-4'  => [ 0xda, 0x77, 0xf2 ],
    'oc-grape-5'  => [ 0xcc, 0x5d, 0xe8 ],
    'oc-grape-6'  => [ 0xbe, 0x4b, 0xdb ],
    'oc-grape-7'  => [ 0xae, 0x3e, 0xc9 ],
    'oc-grape-8'  => [ 0x9c, 0x36, 0xb5 ],
    'oc-grape-9'  => [ 0x86, 0x2e, 0x9c ],
    'oc-violet-0' => [ 0xf3, 0xf0, 0xff ],
    'oc-violet-1' => [ 0xe5, 0xdb, 0xff ],
    'oc-violet-2' => [ 0xd0, 0xbf, 0xff ],
    'oc-violet-3' => [ 0xb1, 0x97, 0xfc ],
    'oc-violet-4' => [ 0x97, 0x75, 0xfa ],
    'oc-violet-5' => [ 0x84, 0x5e, 0xf7 ],
    'oc-violet-6' => [ 0x79, 0x50, 0xf2 ],
    'oc-violet-7' => [ 0x70, 0x48, 0xe8 ],
    'oc-violet-8' => [ 0x67, 0x41, 0xd9 ],
    'oc-violet-9' => [ 0x5f, 0x3d, 0xc4 ],
    'oc-indigo-0' => [ 0xed, 0xf2, 0xff ],
    'oc-indigo-1' => [ 0xdb, 0xe4, 0xff ],
    'oc-indigo-2' => [ 0xba, 0xc8, 0xff ],
    'oc-indigo-3' => [ 0x91, 0xa7, 0xff ],
    'oc-indigo-4' => [ 0x74, 0x8f, 0xfc ],
    'oc-indigo-5' => [ 0x5c, 0x7c, 0xfa ],
    'oc-indigo-6' => [ 0x4c, 0x6e, 0xf5 ],
    'oc-indigo-7' => [ 0x42, 0x63, 0xeb ],
    'oc-indigo-8' => [ 0x3b, 0x5b, 0xdb ],
    'oc-indigo-9' => [ 0x36, 0x4f, 0xc7 ],
    'oc-blue-0'   => [ 0xe8, 0xf7, 0xff ],
    'oc-blue-1'   => [ 0xcc, 0xed, 0xff ],
    'oc-blue-2'   => [ 0xa3, 0xda, 0xff ],
    'oc-blue-3'   => [ 0x72, 0xc3, 0xfc ],
    'oc-blue-4'   => [ 0x4d, 0xad, 0xf7 ],
    'oc-blue-5'   => [ 0x32, 0x9a, 0xf0 ],
    'oc-blue-6'   => [ 0x22, 0x8a, 0xe6 ],
    'oc-blue-7'   => [ 0x1c, 0x7c, 0xd6 ],
    'oc-blue-8'   => [ 0x1b, 0x6e, 0xc2 ],
    'oc-blue-9'   => [ 0x18, 0x62, 0xab ],
    'oc-cyan-0'   => [ 0xe3, 0xfa, 0xfc ],
    'oc-cyan-1'   => [ 0xc5, 0xf6, 0xfa ],
    'oc-cyan-2'   => [ 0x99, 0xe9, 0xf2 ],
    'oc-cyan-3'   => [ 0x66, 0xd9, 0xe8 ],
    'oc-cyan-4'   => [ 0x3b, 0xc9, 0xdb ],
    'oc-cyan-5'   => [ 0x22, 0xb8, 0xcf ],
    'oc-cyan-6'   => [ 0x15, 0xaa, 0xbf ],
    'oc-cyan-7'   => [ 0x10, 0x98, 0xad ],
    'oc-cyan-8'   => [ 0x0c, 0x85, 0x99 ],
    'oc-cyan-9'   => [ 0x0b, 0x72, 0x85 ],
    'oc-teal-0'   => [ 0xe6, 0xfc, 0xf5 ],
    'oc-teal-1'   => [ 0xc3, 0xfa, 0xe8 ],
    'oc-teal-2'   => [ 0x96, 0xf2, 0xd7 ],
    'oc-teal-3'   => [ 0x63, 0xe6, 0xbe ],
    'oc-teal-4'   => [ 0x38, 0xd9, 0xa9 ],
    'oc-teal-5'   => [ 0x20, 0xc9, 0x97 ],
    'oc-teal-6'   => [ 0x12, 0xb8, 0x86 ],
    'oc-teal-7'   => [ 0x0c, 0xa6, 0x78 ],
    'oc-teal-8'   => [ 0x09, 0x92, 0x68 ],
    'oc-teal-9'   => [ 0x08, 0x7f, 0x5b ],
    'oc-green-0'  => [ 0xeb, 0xfb, 0xee ],
    'oc-green-1'  => [ 0xd3, 0xf9, 0xd8 ],
    'oc-green-2'  => [ 0xb2, 0xf2, 0xbb ],
    'oc-green-3'  => [ 0x8c, 0xe9, 0x9a ],
    'oc-green-4'  => [ 0x69, 0xdb, 0x7c ],
    'oc-green-5'  => [ 0x51, 0xcf, 0x66 ],
    'oc-green-6'  => [ 0x40, 0xc0, 0x57 ],
    'oc-green-7'  => [ 0x37, 0xb2, 0x4d ],
    'oc-green-8'  => [ 0x2f, 0x9e, 0x44 ],
    'oc-green-9'  => [ 0x2b, 0x8a, 0x3e ],
    'oc-lime-0'   => [ 0xf4, 0xfc, 0xe3 ],
    'oc-lime-1'   => [ 0xe9, 0xfa, 0xc8 ],
    'oc-lime-2'   => [ 0xd8, 0xf5, 0xa2 ],
    'oc-lime-3'   => [ 0xc0, 0xeb, 0x75 ],
    'oc-lime-4'   => [ 0xa9, 0xe3, 0x4b ],
    'oc-lime-5'   => [ 0x94, 0xd8, 0x2d ],
    'oc-lime-6'   => [ 0x82, 0xc9, 0x1e ],
    'oc-lime-7'   => [ 0x74, 0xb8, 0x16 ],
    'oc-lime-8'   => [ 0x66, 0xa8, 0x0f ],
    'oc-lime-9'   => [ 0x5c, 0x94, 0x0d ],
    'oc-yellow-0' => [ 0xff, 0xf9, 0xdb ],
    'oc-yellow-1' => [ 0xff, 0xf3, 0xbf ],
    'oc-yellow-2' => [ 0xff, 0xec, 0x99 ],
    'oc-yellow-3' => [ 0xff, 0xe0, 0x66 ],
    'oc-yellow-4' => [ 0xff, 0xd4, 0x3b ],
    'oc-yellow-5' => [ 0xfc, 0xc4, 0x19 ],
    'oc-yellow-6' => [ 0xfa, 0xb0, 0x05 ],
    'oc-yellow-7' => [ 0xf5, 0x9f, 0x00 ],
    'oc-yellow-8' => [ 0xf0, 0x8c, 0x00 ],
    'oc-yellow-9' => [ 0xe6, 0x77, 0x00 ],
    'oc-orange-0' => [ 0xff, 0xf4, 0xe6 ],
    'oc-orange-1' => [ 0xff, 0xe8, 0xcc ],
    'oc-orange-2' => [ 0xff, 0xd8, 0xa8 ],
    'oc-orange-3' => [ 0xff, 0xc0, 0x78 ],
    'oc-orange-4' => [ 0xff, 0xa9, 0x4d ],
    'oc-orange-5' => [ 0xff, 0x92, 0x2b ],
    'oc-orange-6' => [ 0xfd, 0x7e, 0x14 ],
    'oc-orange-7' => [ 0xf7, 0x67, 0x07 ],
    'oc-orange-8' => [ 0xe8, 0x59, 0x0c ],
    'oc-orange-9' => [ 0xd9, 0x48, 0x0f ],

) ;

=head1 Public Functions

=over 4

=cut

# ----------------------------------------------------------------------------

=item list_webcolors

list the colors covered in this module

    my @colors = list_colors() ;

=cut

sub list_webcolors
{
    return sort keys %web_colors ;
}


# ----------------------------------------------------------------------------

# get rgb values from a hex triplet

sub _hex_to_rgb
{
    my ($hex) = @_ ;

    $hex =~ s/^#// ;
    $hex = lc($hex) ;

    my ( $r, $g, $b ) ;
    if ( $hex =~ /^[0-9a-f]{6}$/ ) {
        ( $r, $g, $b ) = ( $hex =~ /(\w{2})/g ) ;
    } elsif ( $hex =~ /^[0-9a-f]{3}$/ ) {
        ( $r, $g, $b ) = ( $hex =~ /(\w)/g ) ;
        # double up to make the colors correct
        ( $r, $g, $b ) = ( "$r$r", "$g$g", "$b$b" ) ;
    } else {
        return ( undef, undef, undef ) ;
    }

    return ( hex($r), hex($g), hex($b) ) ;
}

# ----------------------------------------------------------------------------

=item to_rbg

get rgb for a hex triplet, or a colorname. if the hex value is only 3 characters
then it wil be expanded to 6

    my ($r,$g,$b) = to_rgb( 'ff00ab') ;
    ($r,$g,$b) = to_rgb( 'red') ;
    ($r,$g,$b) = to_rgb( 'abc') ;

entries will be null if there is no match

=cut

sub to_rgb
{
    my ($name) = @_ ;
    # first up try as hex
    my ( $r, $g, $b ) = _hex_to_rgb($name) ;

    # try as a name then
    if ( !defined $r ) {
        ( $r, $g, $b ) = colorname_to_rgb($name) ;
    }

    return ( $r, $g, $b ) ;
}

# ----------------------------------------------------------------------------

=item colorname_to_rgb

get the rgb values 0..255 to match a color

    my ($r, $g, $b) = colorname_to_rgb( 'goldenrod') ;

    # get a material color
    ($r, $g, $b) = colorname_to_rgb( 'bluegrey500') ;

    # open colors
    ($r, $g, $b) = colorname_to_rgb( 'oc-lime-5') ;

entries will be null if there is no match

=cut

sub colorname_to_rgb
{
    my ($name) = @_ ;

    $name = lc($name) ;

    # allow variations on open color names
    $name =~ s/^oc(\w+)(\d)$/oc-$1-$2/ ;
    $name =~ s/^oc(\w+)-(\d)$/oc-$1-$2/ ;
    $name =~ s/^oc-(\w+)(\d)$/oc-$1-$2/ ;

    # deref the arraryref
    my $rgb = $web_colors{ $name } ;

    $rgb = [ undef, undef, undef ] if ( !$rgb ) ;
    return @$rgb ;
}

# ----------------------------------------------------------------------------

=item colorname_to_hex

get the color value as a hex triplet '12ffee' to match a color

    my $hex => colorname_to_hex( 'darkslategray') ;

    # get a material color, accented red
    $hex => colorname_to_hex( 'reda300') ;

entries will be null if there is no match

=cut

sub colorname_to_hex
{
    my ($name) = @_ ;
    my @c = colorname_to_rgb($name) ;
    my $str ;
    $str = sprintf( "%02x%02x%02x", $c[0], $c[1], $c[2] )
        if ( defined $c[0] ) ;
    return $str ;
}

# ----------------------------------------------------------------------------

=item colorname_to_rgb_percent

get the rgb values as an integer percentage 0..100% to match a color

    my ($r, $g, $b) = colorname_to_percent( 'goldenrod') ;

entries will be null if there is no match

=cut

sub colorname_to_rgb_percent
{
    my ($name) = @_ ;

    my @c = colorname_to_rgb($name) ;

    if ( defined $c[0] ) {
        for ( my $i = 0; $i < scalar(@c); $i++ ) {
            $c[$i] = int( $c[$i] * 100 / 255 ) ;
        }
    }
    return @c ;
}

# ----------------------------------------------------------------------------
# test if a value is almost +/- 1 another value
sub _almost
{
    my ( $a, $b ) = @_ ;

    ( $a == $b || ( $a + 1 ) == $b || ( $a - 1 == $b ) ) ? 1 : 0 ;
}

# ----------------------------------------------------------------------------

=item rgb_to_colorname

match a name from a rgb triplet, matches within +/-1 of the values

    my $name = rgb_to_colorname( 255, 0, 0) ;

returns null if there is no match

=cut

sub rgb_to_colorname
{
    my ( $r, $g, $b ) = @_ ;

    my $color ;
    foreach my $c ( sort keys %web_colors ) {

        # no need for fancy compares
        my ( $r1, $g1, $b1 ) = @{ $web_colors{$c} } ;

        if ( _almost( $r, $r1 ) && _almost( $g, $g1 ) && _almost( $b, $b1 ) )
        {
            $color = $c ;
            last ;
        }
    }

    return $color ;
}

# ----------------------------------------------------------------------------

=item rgb_percent_to_colorname

match a name from a rgb_percet triplet, matches within +/-1 of the value

    my $name = rgb_percent_to_colorname( 100, 0, 100) ;

returns null if there is no match

=cut

sub rgb_percent_to_colorname
{
    my ( $r, $g, $b ) = @_ ;

    return rgb_to_colorname(
        int( $r * 255 / 100 ),
        int( $g * 255 / 100 ),
        int( $b * 255 / 100 )
    ) ;
}

# ----------------------------------------------------------------------------

=item hex_to_colorname

match a name from a hex triplet, matches within +/-1 of the value

    my $name = hex_to_colorname( 'ff0000') ;

returns null if there is no match

=cut

sub hex_to_colorname
{
    my ($hex) = @_ ;

    my ( $r, $g, $b ) = _hex_to_rgb($hex) ;

    return rgb_to_colorname( $r, $g, $b ) ;
}

# ----------------------------------------------------------------------------

=item inverse_rgb

Get the inverse of the RGB values

    my ($i_r, $i_g, $i_b) = inverse_rgb( 0xff, 0x45, 0x34) ;

=cut

sub inverse_rgb
{
    my ( $r, $g, $b ) = @_ ;

    return ( 255 - $r, 255 - $g, 255 - $b ) ;
}

# ----------------------------------------------------------------------------
# source was http://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color

=item luminance

Calculate the luminance of an rgb value

Rough calculation using Photometric/digital ITU-R:

Y = 0.2126 R + 0.7152 G + 0.0722 B

    my $luma = luminance( to_rgb( 'green')) ;

=cut

sub luminance
{
    my ( $r, $g, $b ) = @_ ;

    return int( ( 0.2126 * $r ) + ( 0.7152 * $g ) + ( 0.0722 * $b ) ) ;
}

# # ----------------------------------------------------------------------------

# =item approx_luminance

# Calculate the approximate luminance of an rgb value, rough/ready/fast

#     my $luma = approx_luminance( to_rgb( 'green')) ;

# =cut

# sub approx_luminance
# {
#     my ( $r, $g, $b ) = @_ ;

#     return int( ( ( 2 * $r ) + ( 3 * $g ) + ($b) ) / 6 ) ;
# }


=back

=cut

# ----------------------------------------------------------------------------

1 ;
