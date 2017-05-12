
#!/usr/bin/perl -w

=head1 NAME

01_basic.t

=head1 DESCRIPTION

test App::Basis::ConvertText2::UtfTransform

=head1 AUTHOR

kevin mulholland, moodfarm@cpan.org

=cut

use v5.10;
use strict;
use warnings;
use Test::More tests => 27;

BEGIN { use_ok('WebColors'); }

my @colors = list_webcolors() ;
ok( scalar(@colors) > 100, 'There are lots of colors') ;

my ($r, $g, $b) = colorname_to_rgb( 'black') ;
ok( "$r-$g-$b" eq "0-0-0", "rgb black is OK") ;
($r, $g, $b) = colorname_to_rgb( 'white') ;
ok( "$r-$g-$b" eq "255-255-255", "rgb white is OK") ;
($r, $g, $b) = colorname_to_rgb( 'whiterthanwhite') ;
ok( !defined $r, "missing colour is undef") ;

my $hex = colorname_to_hex( 'red') ;
ok( lc($hex) eq "ff0000", "hex red is OK") ;
$hex = colorname_to_hex( 'green') ;
ok( lc($hex) eq "008000", "hex green is OK") ; # lime is 00ff00
$hex = colorname_to_hex( 'bluered') ;
ok( !defined $hex, "missing colour is undef") ;

($r, $g, $b) = colorname_to_rgb_percent( 'gray') ;
ok( "$r-$g-$b" eq "50-50-50", "% black is OK") ;
($r, $g, $b) = colorname_to_rgb_percent( 'lime') ;
ok( "$r-$g-$b" eq "0-100-0", "% lime is OK") ;

my $name = rgb_to_colorname( 0, 255, 255) ;
ok( $name eq "aqua", "rgb to aqua is OK") ;
$name = hex_to_colorname( '00ff00') ;
ok( $name eq "lime", "($name) hex to lime is OK") ;
$name = rgb_percent_to_colorname( 100, 100, 0) ;
ok( $name eq "yellow", "% yellow is OK") ;

# lets use the actual percentages from [ 50,  205, 50 ]
$name = rgb_percent_to_colorname( 19.6, 80.39, 19.6) ;
ok( $name eq "limegreen", "% likegreen is OK") ;

($r, $g, $b) = to_rgb( '008000') ;
ok( "$r-$g-$b" eq "0-128-0", "to_rgb 008000 is green is OK") ;

($r, $g, $b) = to_rgb( '0ff') ;
ok( "$r-$g-$b" eq "0-255-255", "to_rgb 0ff is yellow is OK") ;

($r, $g, $b) = to_rgb( '#FF0000') ;
ok( "$r-$g-$b" eq "255-0-0", "to_rgb #FF0000 is red is OK") ;

($r, $g, $b) = to_rgb( 'blue') ;
ok( "$r-$g-$b" eq "0-0-255", "to_rgb found blue OK") ;

my ($ir, $ig, $ib) = inverse_rgb(to_rgb( 'white')) ;
ok( "$ir-$ig-$ib" eq "0-0-0", "inverse_rgb white to black OK") ;
($ir, $ig, $ib) = inverse_rgb(to_rgb( 'black')) ;
ok( "$ir-$ig-$ib" eq "255-255-255", "inverse_rgb black to white OK") ;

my $y = luminance( to_rgb( 'white')) ;
ok( $y >= 254, "White is bright luminace") ;

$y = luminance( to_rgb( 'grey')) ;
ok( $y == 128, "Grey is middle luminace") ;

$y = luminance( to_rgb( 'black')) ;
ok( $y == 0 , "Black has no luminace") ;

# oc colors and variations
$hex = colorname_to_hex( 'oc-indigo-2') ;
ok( $hex eq 'bac8ff', "open color name") ;
$hex = colorname_to_hex( 'oc-indigo2') ;
ok( $hex eq 'bac8ff', "open colors variant 1") ;
$hex = colorname_to_hex( 'ocindigo2') ;
ok( $hex eq 'bac8ff', "open colors variant 2") ;
$hex = colorname_to_hex( 'oc-indigo2') ;
ok( $hex eq 'bac8ff', "open colors variant 3") ;


