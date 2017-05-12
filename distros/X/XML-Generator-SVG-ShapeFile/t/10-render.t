use strict;
use Test::More;

plan tests => 17;

use_ok("XML::Generator::SVG::ShapeFile");

my $svg = XML::Generator::SVG::ShapeFile->new();

isa_ok($svg,"XML::Generator::SVG::ShapeFile");

$svg->set_width(512);
cmp_ok($svg->{'__width'},"==",512);

$svg->set_decimals(1);
cmp_ok($svg->{'__decimals'},"==",1);

$svg->set_title("hello world");
cmp_ok($svg->{'__metadata'}{'title'},"eq","hello world");

$svg->set_description("you are here");
cmp_ok($svg->{'__metadata'}{'description'},"eq","you are here");

$svg->set_publisher("foo bar");
cmp_ok($svg->{'__metadata'}{'publisher'},"eq","foo bar");

$svg->set_language("en");
cmp_ok($svg->{'__metadata'}{'language'},"eq","en");

$svg->set_stylesheet("test.css");
cmp_ok($svg->{'__css'},"eq","test.css");

#

my $geo = Geo::ShapeFile->new("./examples/urban.shp");
isa_ok($geo,"Geo::ShapeFile");

my ($min_x,$min_y,$max_x,$max_y) = $geo->bounds();

cmp_ok($min_x,"==",'-74.1522834');
cmp_ok($max_x,"==",'-73.1776734');
cmp_ok($min_y,"eq",'45.2442894');
cmp_ok($max_y,"eq",'45.7953682');

my $scale = 512 / ($max_x - $min_x);
cmp_ok($scale,"eq",'525.338340464392');
    
my $height = int((($max_y - $min_y) * $scale) + 0.5);
cmp_ok($height,"==",290);

$geo->DESTROY();

#

ok($svg->render("./examples/urban.shp"));
