#!/usr/bin/perl -w

#
# $Id: Conversions.t,v 1.5 2003/10/21 16:48:12 mertz Exp $
# Author: Christophe Mertz
#

# Some Conversion tests.

use strict;
use Config;

use SVG::SVG2zinc::Conversions;

BEGIN {
    if (!eval q{
#        use Test::More qw(no_plan);
        use Test::More => 60;
        1;
    }) {
        print "# tests only work properly with installed Test::More module\n";
        print "1..1\n";
        print "ok 1\n";
        exit;
    }

    use_ok( 'SVG::SVG2zinc::Conversions;' );
}

require_ok( 'SVG::SVG2zinc::Conversions' );
require_ok( 'Tk::Zinc::SVGExtension' );
require_ok( 'Math::Bezier::Convert' );
ok (&InitConv (sub { &diag("svg2zincWarning: ".$_[0])},
	       sub {return ""}), 'init' );

is (&removeComment('blabla /* blibli */ blublu'), 'blabla  blublu', 'removing comment');
is (&removeComment('blabla/* blibli */ blu /* bloblo */ blu'), 'blabla blu  blu', 'removing multiple comment');

# TODO:
TODO: {
    local $TODO = 'I do not know if this is legal';
    is (&removeComment('blabla/* blibli /* blibli */ */ blublu'), 'blabla blublu', 'removing recursive comment');
}

diag ('############ size conversions');


my $ratio = 1; # could be usefull if we used a real dpi value in the future 
is (&sizeConvert("0.1cm"), 4 * $ratio, 'cm');
is (&sizeConvert("10.5mm"), 42 * $ratio, 'mm');
is (&sizeConvert("1.1in"), 110 * $ratio, 'in');
is (&sizeConvert("72pt"), 100 * $ratio, 'pt');
is (&sizeConvert("6.6pc"), 110 * $ratio, 'pc');
is (&sizeConvert("10%"), 0.1 * $ratio, '%');
is (&sizeConvert("10.2"), 10, 'float');
is (&sizeConvert("11.8"), 12, 'float');

TODO:
    {
    local $TODO = 'conversions from em and ex units';
	is (&sizeConvert("10em"), "10em", 'em');
	is (&sizeConvert("10ex"), "10ex", 'ex');
    }

diag ('############ opacity conversions');

is (&convertOpacity("10"), 1, 'opacity 10');
is (&convertOpacity("-1"), 0, 'opacity -1');
is (&convertOpacity(), 1, 'opacity undef');

#sub test { warn }
diag ('############ gradient manipulation');

is (&namedGradient("foo"), "foo", "no such gradient");
is (&existsGradient("foo"), 0, "no such gradient");

ok (&defineNamedGradient ("foo", "=axial 0 | black;50 60| white;50"), "creating foo gradient");
is (&defineNamedGradient ("bar", "=axial 0 | black;50 60| white;50"), 0, "creating bar=foo gradient");

is (&defineNamedGradient ("refoo", " =axial 0 | black;50 60 | white;50 "), 0, "creating refoo=foo gradient with diffferents spaces!");

is (&namedGradient ("foo"), "foo", "foo gradient is foo gradient");
is (&namedGradient ("bar"), "foo", "bar gradient is foo gradient");
    is (&namedGradient ("refoo"), "foo", "refoo gradient is foo gradient");

is (&namedGradientDef ("foo"), "=axial 0 | black;50 60 | white;50", "comparing foo gradient with its definition");
is (&namedGradientDef ("bar"), "=axial 0 | black;50 60 | white;50", "comparing bar gradient, an alias of foo with the same definition");


is_deeply ( [&extractGradientTypeAndStops("foo")],
	    ['=axial 0', 'black;50 60', 'white;50'], "extractGradientTypeAndStops of foo");

is_deeply ( [&extractGradientTypeAndStops("bar")],
	    ['=axial 0', 'black;50 60', 'white;50'], "extractGradientTypeAndStops of bar");

is_deeply ( [&extractGradientTypeAndStops("refoo")],
	    ['=axial 0', 'black;50 60', 'white;50'],
	    "extractGradientTypeAndStops of refoo");


is (&addTransparencyToGradient('foo',100), "foo", "applying a 100% transparency");
is (&addTransparencyToGradient('foo',10), '=axial 0 | black;5 60 | white;5', "applying a 10% transparency");

diag ('############ color conversions');

is (&colorConvert(' none'), 'none', "converting a none color");
is (&colorConvert('rgb(100%,100%,100%)'), '#ffffff', "converting a rgb(%) color");
is (&colorConvert('rgb(100,200,255)'), '#64c8ff', "converting a rgb() color");
is (&colorConvert('#abc'), '#aabbcc', "converting a #rgb color");
is (&colorConvert('#a1b2c3'), '#a1b2c3', "converting a #rrggbb color");
is (&colorConvert('lime'), 'green', "converting a html color in x-named color");
is (&colorConvert('Crimson'), '#DC143C', "converting a html color in #rrggbb color");

diag ('############ points list conversion');
is (&points({'points' => '40  5, 62 73,81 22'}),'40,5, 62,73,81,22', 'adding commas when blanks are used as separator');
is_deeply ( [&SVG::SVG2zinc::Conversions::splitPoints('40.1.5, 62 73-81 22,12.1')],
	    [qw(40.1 .5 62 73 -81 22 12.1)], 'splitting curve list of points');
is_deeply ( [&SVG::SVG2zinc::Conversions::splitPoints('0.131-0.295,0.268-0.595,0.409-0.898')],
	    [qw(0.131 -0.295 0.268 -0.595 0.409 -0.898)], 'splitting curve list of points');

diag ('############ name conversion');
is(&cleanName("12"),"id_12", 'numeric id');
is(&cleanName("aa.bb"),"aa_bb", 'id containing a dot');
is(&cleanName("aa-bb"),"aa-bb", 'id containing a dash');


diag ('############ path points conversion');

is_deeply( [ &pathPoints({'d'=>'M1 0H2 V4 L-1-1-2-4 M10 10 5 5L20 30'}) ],
	   [ 1, ["[10, 10]", "[5, 5]", "[20, 30]" ], [ "[1, 0]",  "[2, 0]", "[2, 4]", "[-1, -1]", "[-2, -4]" ] ],
	   "path points with M,L,H,V commands");
is_deeply( [ &pathPoints({'d'=>'m1 0h2 v4 l-1-1-2-4 m10 10 5 5l20 30'}) ],
	   [ 1, ["[10, 9]", "[15, 14]", "[35, 44]" ], [ "[1, 0]",  "[3, 0]", "[3, 4]", "[2, 3]", "[0, -1]" ] ],
	   "path points with m,l,h,v commands");
is_deeply( [ &pathPoints({'d'=>'M0 0c0.131-0.295,0.268-0.595,0.409-0.898'}) ],
	   [ 0, [ '[0, 0]',  "[0.131, -0.295, 'c'], [0.268, -0.595, 'c'], [0.409, -0.898]" ] ],
	   "path points with M,c commands");
is_deeply( [ &pathPoints({'d'=>'"M205 124c-3.826 4.578e-005 -3.826e+00 5.166 -4 8 z'}) ],
	   [ 1, [ '[205, 124]', "[201.174, 124.00004578, 'c'], [201.174, 129.166, 'c'], [201, 132]" ] ],
	   "path points with coordinates being floats with exponent e");
is_deeply( [ &pathPoints({'d'=>'M10 12S2 4 7 10S-12 -14 -20 -22 10 11 6 5'}) ],
	   [ 0, ["[10, 12]", "[10, 12, 'c'], [2, 4, 'c'], [7, 10]", "[12, 16, 'c'], [-12, -14, 'c'], [-20, -22]",
		 "[-28, -30, 'c'], [10, 11, 'c'], [6, 5]"] ],
	   "path points with M,S commands");


# transform tests...
is_deeply( [ &transform ("'Id'", "translate(-0.9812,0.613251);") ],
    ["->translate('Id',-0.9812,0.613251);"],
    "transform of translate;");
is_deeply( [ &transform ("'Id'", "translate(12)") ],
    ["->translate('Id',12,0);"],
    "transform of translate");
use  Math::Trig;
is_deeply( [ &transform ("'Id'", "rotate(180)") ],
    ["->rotate('Id',".deg2rad(180).");"],
    "transform of rotate;");
is_deeply( [ &transform ("'Id'", "rotate(180);translate(12,32)") ],
    ["->translate('Id',12,32);", "->rotate('Id',".deg2rad(180).");"],
    "transform of rotate+translate;");
is_deeply( [ &transform ("'Id'", "matrix(1,0,0,4,5,6)") ],
    ["->scale('Id',1,4);", "->translate('Id',5,6);"],
    "transform of matrix");

TODO:
    {
    local $TODO = 'matrix containing a skew';

    is_deeply( [ &transform ("'Id'", "matrix(1,2,3,4,5,6)") ],
    [],
    "transform of matrix with a skew");
}




__END__
