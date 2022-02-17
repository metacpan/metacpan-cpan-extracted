#!perl

use 5.010;
use Text::ANSITable;

# don't forget this if you want to output utf8 characters
binmode(STDOUT, ":utf8");

my $t = Text::ANSITable->new;

# set styles
#$t->border_style('UTF8::SingleLineBold');  # if not, a nice default is picked
$t->color_theme('Standard::NoGradation');  # if not, a nice default is picked

# fill data
$t->columns(["name"       , "color" , "price"]);
$t->add_row(["chiki"      , "yellow",    2000]);
$t->add_row(["lays"       , "green" ,    7000]);
$t->add_row(["tao kae noi", "blue"  ,   18500]);

# draw it!
print "Set BORDER_STYLE to customize border style\n";
print $t->draw;
