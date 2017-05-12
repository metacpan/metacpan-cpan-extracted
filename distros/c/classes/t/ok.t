# $Id: ok.t 75 2006-07-21 15:05:07Z rmuhle $

use strict;

use Test::More tests => 63;
#use Test::More 'no_plan';

use_ok('classes');
ok $classes::ok_class_name, 'ok_class_name exists';
ok $classes::ok_attr_name, 'ok_attr_name exists';

# ATTRIBUTE NAMES
{
    my @good = qw( blah blah_blah _blah Blah ALLCAPS main );
    my @bad  = (qw(
        1blah  blah-blah  - : :: blah:: is? yes! 
        ), 'b b', '');

    for my $name (@good){
        ok $name =~ $classes::ok_attr_name,
            qq[attribute name '$name' is ok];
    }

    for my $name (@bad){
        ok ! ($name =~ $classes::ok_attr_name),
            qq[attribute name '$name' is not ok];
    }
}

# CLASS NAMES
{
    my @good = qw(
        blah blah_blah _blah _1 b Blah ALLCAPS
        b::blah b::blah_blah b::_blah b::_1 b::b
        b::A b::Blah b::ALLCAPS
        a::b::blah a::b::blah_blah a::b::_blah a::b::_1 a::b::b
        a::b::A a::b::Blah a::b::ALLCAPS
        blah::blah b1::blah b1::b1 b1::A b1::a
        blah::blah::blah blah::b::b 
        main
    );

    my @bad  = (qw(
        1blah blah-blah 1 - _ : :: blah:: b:b Mine? 
        B
        ), 'b b', '');

    for my $name (@good){
        ok $name =~ $classes::ok_class_name,
            qq[class name '$name' is ok];
    }

    for my $name (@bad){
        ok ! ($name =~ $classes::ok_class_name),
            qq[class name '$name' is ok];
    }
}

