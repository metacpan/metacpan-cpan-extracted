# WebColors

## SYNOPSIS

    use 5.10.0 ;
    use strict ;
    use warnings ;
    use WebColors;

    my ($r, $g, $b) = colorname_to_rgb( 'goldenrod') ;

## DESCRIPTION

Get either the hex triplet value or the rgb values for a HTML named color.

Values have been taken from https://en.wikipedia.org/wiki/HTML_color_names#HTML_color_names

For me I want this module so that I can use the named colours to extend Device::Hynpocube so that it can use the full set of named colors
it is also used in Device::BlinkStick

Google material colors have spaces removed and their numerical values added, so

Red 400 becomes red400, with accents Deep Purple A100 becomes deeppurplea100

See Also

Google material colors <http://www.google.com/design/spec/style/color.html>

## Public Functions

### list_webcolors

list the colors covered in this module

my @colors = list_colors() ;

###  to_rbg

get rgb for a hex triplet, or a colorname. if the hex value is only 3 characters then it wil be expanded to 6

    my ($r,$g,$b) = to_rgb( 'ff00ab') ;
    ($r,$g,$b) = to_rgb( 'red') ;
    ($r,$g,$b) = to_rgb( 'abc') ;

entries will be null if there is no match

###  colorname_to_rgb

get the rgb values 0..255 to match a color

    my ($r, $g, $b) = colorname_to_rgb( 'goldenrod') ;

    # get a material color

    ($r, $g, $b) = colorname_to_rgb( 'bluegrey500') ;

entries will be null if there is no match

###  colorname_to_hex

get the color value as a hex triplet '12ffee' to match a color

    my $hex => colorname_to_hex( 'darkslategray') ;

    # get a material color, accented red

    $hex => colorname_to_hex( 'reda300') ;

entries will be null if there is no match

###  colorname_to_rgb_percent

get the rgb values as an integer percentage 0..100% to match a color

    my ($r, $g, $b) = colorname_to_percent( 'goldenrod') ;

entries will be null if there is no match

###  rgb_to_colorname

match a name from a rgb triplet, matches within +/-1 of the values

    my $name = rgb_to_colorname( 255, 0, 0) ;

returns null if there is no match

###  rgb_percent_to_colorname

match a name from a rgb_percet triplet, matches within +/-1 of the value

    my $name = rgb_percent_to_colorname( 100, 0, 100) ;

returns null if there is no match

###  hex_to_colorname

match a name from a hex triplet, matches within +/-1 of the value

    my $name = hex_to_colorname( 'ff0000') ;

returns null if there is no match


