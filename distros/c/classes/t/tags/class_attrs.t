# $Id: class_attrs.t 109 2006-08-04 14:55:08Z rmuhle $

use strict 'subs'; no warnings;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 106;
}

lives_and( sub {
    package ClassAttrs1;
    use strict 'subs';no warnings;
    use classes
        new         => 'classes::new_only',
        class_attrs => ['foo'],
    ;

    package main;
    isa_ok my $o1 = ClassAttrs1->new, 'ClassAttrs1'; 
    can_ok 'ClassAttrs1','get_foo';
    can_ok 'ClassAttrs1','set_foo';
    is $o1->get_foo, undef, 'undef initial value';
    is $o1->set_foo(2), undef, 'setter';
    is $o1->get_foo, 2, 'setter confirmed';
    my $o2 = ClassAttrs1->new;
    is $o2->get_foo, 2, 'consistent across instances';
}, 'array form declaration');


lives_and ( sub {
    package ClassAttr2;
    use strict 'subs';no warnings;
    use classes
        new         => 'classes::new_args',
        class_attrs => { bar => 1 },
    ;
    sub set_bar { $$CLASS_ATTR_bar = $_[1]*2; return }

    package main;
    my $o = ClassAttr2->new;
    is $o->get_bar, 1, 'initial value set';
    is $o->set_bar(2), undef, 'customized overriden setter';
    is $o->get_bar, 4, 'setter modified value stored';

}, 'hash form declaration, overriden setter');

lives_and( sub {
    package CAOne;
    use strict 'subs';no warnings;
    use classes
        new         => 'classes::new_only',
        class_attrs => { ca1 => 'ca1' },
    ;

    package CATwo;
    use base 'CAOne';

    package CAThree;
    use classes inherits=>'CATwo', class_attrs => {ca1=>'CA1'};

    package CAFour;
    use classes extends => 'CAThree';

    package CAFive;
    use classes extends => 'CAFour';

    package main;
    my $ca1 = CAOne->new;
    my $ca2 = CATwo->new;
    my $ca3 = CAThree->new;
    my $ca4 = CAFour->new;
    my $ca5 = CAFive->new;

    is( CAOne->get_ca1, 'ca1',
        'base initial value by accessor');
    is( CATwo->get_ca1, 'ca1',
        'second level inherited value by accessor');
    is( CAThree->get_ca1, 'CA1',
        'third level redeclared, overriden by accessor');
    is( CAFour->get_ca1, 'CA1',
        'fourth level inherits redeclared by accessor');
    is( CAFive->get_ca1, 'CA1',
        'fifth level inherits redeclared by accessor');
 
    is($ca1->get_ca1, 'ca1',
        'base initial value by accessor from obj');
    is($ca2->get_ca1, 'ca1',
        'second level inherited value by accessor from obj');
    is($ca3->get_ca1, 'CA1',
        'third level redeclared, overriden by accessor from obj');
    is($ca4->get_ca1, 'CA1',
        'fourth level inherits redeclared by accessor from obj');
    is($ca5->get_ca1, 'CA1',
        'fifth level inherits redeclared by accessor from obj');

    is( $ca4->set_ca1('class_a_1'), undef,
        'setting fourth level by accessor');

    is($ca1->get_ca1, 'ca1',
        'first level value unchanged');
    is($ca2->get_ca1, 'ca1',
        'second level value unchanged');
    is($ca3->get_ca1, 'class_a_1',
        'third level value changed');
    is($ca4->get_ca1, 'class_a_1',
        'fourth level value changed');
    is($ca5->get_ca1, 'class_a_1',
        'fifth level value changed');

    is( $ca2->set_ca1('c_attr_1'), undef,
        'setting first level by accessor');

    is($ca1->get_ca1, 'c_attr_1',
        'first level value changed');
    is($ca2->get_ca1, 'c_attr_1',
        'second level value changed');
    is($ca3->get_ca1, 'class_a_1',
        'third level value unchanged');
    is($ca4->get_ca1, 'class_a_1',
        'fourth level value unchanged');
    is($ca5->get_ca1, 'class_a_1',
        'fifth level value unchanged');

    is($CAOne::CLASS_ATTR_ca1, 'CAOne::ca1',
        'first level attribute internal key, where declared');
    is($CATwo::CLASS_ATTR_ca1, undef,
        'second level attribute internal key, not in inherited');
    is($CAThree::CLASS_ATTR_ca1, 'CAThree::ca1',
        'third level attribute internal key, where declared');
    is($CAFour::CLASS_ATTR_ca1, undef,
        'fourth attribute internal key, not in inherited');
    is($CAFive::CLASS_ATTR_ca1, undef,
        'fifth attribute internal key, not in inherited');

    is($$CAOne::CLASS_ATTR_ca1, 'c_attr_1',
        'first level attribute internal key, where declared');
    is($$CATwo::CLASS_ATTR_ca1, undef,
        'second level attribute internal key, not in inherited');
    is($$CAThree::CLASS_ATTR_ca1, 'class_a_1',
        'third level attribute internal key, where declared');
    is($$CAFour::CLASS_ATTR_ca1, undef,
        'fourth attribute internal key, not in inherited');
    is($$CAFive::CLASS_ATTR_ca1, undef,
        'fifth attribute internal key, not in inherited');

}, 'inheritance behavior');

lives_and( sub {
    package CAMOne;
    use strict 'subs';no warnings;
    use classes
        type        => 'mixable',
        new         => 'classes::new_only',
        class_attrs => { ca1 => 'ca1' },
    ;

    package CAMTwo;
    use classes type => 'mixable', mixes => 'CAMOne';

    package CAMThree;
    use classes
        type        => 'mixable',
        mixes       => 'CAMTwo',
        new         => 'classes::new_only',
        class_attrs => { ca1=>'CA1' },
    ;

    package CAMFour;
    use classes type => 'mixable', mixes => 'CAMThree';

    package CAMFive;
    use classes mixes => 'CAMFour';

    package main;
    my $ca1 = CAMOne->new;
    my $ca2 = CAMTwo->new;
    my $ca3 = CAMThree->new;
    my $ca4 = CAMFour->new;
    my $ca5 = CAMFive->new;

    is( CAMOne->get_ca1, 'ca1',
        'base initial value by accessor');
    is( CAMTwo->get_ca1, 'ca1',
        'second level inherited value by accessor');
    is( CAMThree->get_ca1, 'CA1',
        'third level redeclared, overriden by accessor');
    is( CAMFour->get_ca1, 'CA1',
        'fourth level inherits redeclared by accessor');
    is( CAMFive->get_ca1, 'CA1',
        'fifth level inherits redeclared by accessor');
 
    is($ca1->get_ca1, 'ca1',
        'base initial value by accessor from obj');
    is($ca2->get_ca1, 'ca1',
        'second level inherited value by accessor from obj');
    is($ca3->get_ca1, 'CA1',
        'third level redeclared, overriden by accessor from obj');
    is($ca4->get_ca1, 'CA1',
        'fourth level inherits redeclared by accessor from obj');
    is($ca5->get_ca1, 'CA1',
        'fifth level inherits redeclared by accessor from obj');

    is( $ca4->set_ca1('class_a_1'), undef,
        'setting fourth level by accessor');

    is($ca1->get_ca1, 'ca1',
        'first level value unchanged');
    is($ca2->get_ca1, 'ca1',
        'second level value unchanged');
    is($ca3->get_ca1, 'class_a_1',
        'third level value changed');
    is($ca4->get_ca1, 'class_a_1',
        'fourth level value changed');
    is($ca5->get_ca1, 'class_a_1',
        'fifth level value changed');

    is( $ca2->set_ca1('c_attr_1'), undef,
        'setting first level by accessor');

    is($ca1->get_ca1, 'c_attr_1',
        'first level value changed');
    is($ca2->get_ca1, 'c_attr_1',
        'second level value changed');
    is($ca3->get_ca1, 'class_a_1',
        'third level value unchanged');
    is($ca4->get_ca1, 'class_a_1',
        'fourth level value unchanged');
    is($ca5->get_ca1, 'class_a_1',
        'fifth level value unchanged');

    is($CAMOne::CLASS_ATTR_ca1, 'CAMOne::ca1',
        'first level attribute internal key, where declared');
    is($CAMTwo::CLASS_ATTR_ca1, 'CAMOne::ca1',
        'second level attribute internal key same as mixin');
    is($CAMThree::CLASS_ATTR_ca1, 'CAMThree::ca1',
        'third level attribute internal key, where declared');
    is($CAMFour::CLASS_ATTR_ca1, 'CAMThree::ca1',
        'fourth attribute internal key, same as mixin');
    is($CAMFive::CLASS_ATTR_ca1, 'CAMThree::ca1',
        'fifth attribute internal key, same as mixin');

    is($$CAMOne::CLASS_ATTR_ca1, 'c_attr_1',
        'first level attribute internal key, where declared');
    is($$CAMTwo::CLASS_ATTR_ca1, 'c_attr_1',
        'second level attribute internal key, same as mixin');
    is($$CAMThree::CLASS_ATTR_ca1, 'class_a_1',
        'third level attribute internal key, where declared');
    is($$CAMFour::CLASS_ATTR_ca1, 'class_a_1',
        'fourth attribute internal key, same as mixin');
    is($$CAMFive::CLASS_ATTR_ca1, 'class_a_1',
        'fifth attribute internal key, same as mixin');

}, 'mixin attribute "inheritance" special for type = mixable');

lives_and( sub {
    package CAMSOne;
    use strict 'subs';no warnings;
    use classes
        type        => 'static',
        new         => 'classes::new_only',
        class_attrs => { ca1 => 'ca1' },
    ;

    package CAMSTwo;
    use classes type => 'static', mixes => 'CAMSOne';

    package CAMSThree;
    use classes
        type        => 'static',
        mixes       => 'CAMSTwo',
        new         => 'classes::new_only',
        class_attrs => { ca1=>'CA1' },
    ;

    package CAMSFour;
    use classes mixes => 'CAMSThree';

    package CAMSFive;
    use classes mixes => 'CAMSFour';

    package main;
    my $ca1 = CAMSOne->new;
    my $ca2 = CAMSTwo->new;
    my $ca3 = CAMSThree->new;
    my $ca4 = CAMSFour->new;
    my $ca5 = CAMSFive->new;

    is( CAMSOne->get_ca1, 'ca1',
        'base initial value by accessor');
    is( CAMSTwo->get_ca1, 'ca1',
        'second level inherited value by accessor');
    is( CAMSThree->get_ca1, 'CA1',
        'third level redeclared, overriden by accessor');
    is( CAMSFour->get_ca1, 'CA1',
        'fourth level inherits redeclared by accessor');
    is( CAMSFive->get_ca1, 'CA1',
        'fifth level inherits redeclared by accessor');
 
    is($ca1->get_ca1, 'ca1',
        'base initial value by accessor from obj');
    is($ca2->get_ca1, 'ca1',
        'second level inherited value by accessor from obj');
    is($ca3->get_ca1, 'CA1',
        'third level redeclared, overriden by accessor from obj');
    is($ca4->get_ca1, 'CA1',
        'fourth level inherits redeclared by accessor from obj');
    is($ca5->get_ca1, 'CA1',
        'fifth level inherits redeclared by accessor from obj');

    is( $ca4->set_ca1('class_a_1'), undef,
        'setting fourth level by accessor');

    is($ca1->get_ca1, 'ca1',
        'first level value unchanged');
    is($ca2->get_ca1, 'ca1',
        'second level value unchanged');
    is($ca3->get_ca1, 'class_a_1',
        'third level value changed');
    is($ca4->get_ca1, 'class_a_1',
        'fourth level value changed');
    is($ca5->get_ca1, 'class_a_1',
        'fifth level value changed');

    is( $ca2->set_ca1('c_attr_1'), undef,
        'setting first level by accessor');

    is($ca1->get_ca1, 'c_attr_1',
        'first level value changed');
    is($ca2->get_ca1, 'c_attr_1',
        'second level value changed');
    is($ca3->get_ca1, 'class_a_1',
        'third level value unchanged');
    is($ca4->get_ca1, 'class_a_1',
        'fourth level value unchanged');
    is($ca5->get_ca1, 'class_a_1',
        'fifth level value unchanged');

    is($CAMSOne::CLASS_ATTR_ca1, 'CAMSOne::ca1',
        'first level attribute internal key, where declared');
    is($CAMSTwo::CLASS_ATTR_ca1, undef,
        'second level attribute internal key, not in inherited');
    is($CAMSThree::CLASS_ATTR_ca1, 'CAMSThree::ca1',
        'third level attribute internal key, where declared');
    is($CAMSFour::CLASS_ATTR_ca1, undef,
        'fourth attribute internal key, not in inherited');
    is($CAMSFive::CLASS_ATTR_ca1, undef,
        'fifth attribute internal key, not in inherited');

    is($$CAMSOne::CLASS_ATTR_ca1, 'c_attr_1',
        'first level attribute internal key, where declared');
    is($$CAMSTwo::CLASS_ATTR_ca1, undef,
        'second level attribute internal key, not in inherited');
    is($$CAMSThree::CLASS_ATTR_ca1, 'class_a_1',
        'third level attribute internal key, where declared');
    is($$CAMSFour::CLASS_ATTR_ca1, undef,
        'fourth attribute internal key, not in inherited');
    is($$CAMSFive::CLASS_ATTR_ca1, undef,
        'fifth attribute internal key, not in inherited');

}, 'mixin attribute "inheritance" identical to regular for type = static');

lives_and( sub {
    #TODO
}, 'mixin and inheritance mixed together behavior');
