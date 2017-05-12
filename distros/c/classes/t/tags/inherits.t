# $Id: attrs.t 69 2006-07-12 23:07:47Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 58;
}

lives_and( sub {

    use classes
         name => 'InheritsOne',
         new => 'classes::new_only',
         attrs => [ 'one_a' ],
         class_attrs => { one_class_a => 'one_class_a' }, 
         methods => {one_m => sub {'one_m'}},
         class_methods => {one_class_m=>sub {'one_class_m'}},
    ;

    my $one = InheritsOne->new;
    is $one->set_one_a('one_a'), undef;
    is $one->get_one_a, 'one_a';
    is $one->get_one_class_a, 'one_class_a';
    is $one->one_m, 'one_m';
    is $one->one_class_m, 'one_class_m';

    use classes
         name => 'InheritsTwo',
         inherits => 'InheritsOne',
         new => 'classes::new_only',
         attrs => [ 'two_a' ],
         class_attrs => { two_class_a => 'two_class_a' }, 
         methods => {two_m => sub {'two_m'}},
         class_methods => {two_class_m=>sub {'two_class_m'}},
    ;

    my $two = InheritsTwo->new;
    can_ok $two, 'set_one_a';
    is $two->get_one_a, undef;
    is $two->get_one_class_a, 'one_class_a';
    is $two->one_m, 'one_m';
    is $two->one_class_m, 'one_class_m';
    is $two->get_two_a, undef;
    is $two->get_two_class_a, 'two_class_a';
    is $two->two_m, 'two_m';
    is $two->two_class_m, 'two_class_m';

    use classes
         name => 'InheritsThree',
         inherits => 'InheritsTwo',
         new => 'classes::new_only',
         attrs => [ 'three_a' ],
         class_attrs => { three_class_a => 'three_class_a' }, 
         methods => {three_m => sub {'three_m'}},
         class_methods => {three_class_m=>sub {'three_class_m'}},
    ;

    use classes
         name => 'InheritsFour',
        inherits => 'InheritsThree',
    ;

    use classes
         name => 'InheritsFive',
        inherits => 'InheritsFour',
    ;

    my $five = InheritsFive->new;
    isa_ok $five, 'InheritsFive';
    isa_ok $five, 'InheritsFour';
    isa_ok $five, 'InheritsThree';
    isa_ok $five, 'InheritsTwo';
    isa_ok $five, 'InheritsOne';

    my $three = InheritsThree->new;
    $three->set_three_a('three_a');
    can_ok $three, 'get_one_a';
    is $three->get_one_a, undef;
    is $three->get_one_class_a, 'one_class_a';
    is $three->one_m, 'one_m';
    is $three->one_class_m, 'one_class_m';
    can_ok $three, 'get_two_a';
    is $three->get_two_a, undef; 
    is $three->get_two_class_a, 'two_class_a';
    is $three->two_m, 'two_m';
    is $three->two_class_m, 'two_class_m';
    is $three->get_three_a, 'three_a';
    is $three->get_three_class_a, 'three_class_a';
    is $three->three_m, 'three_m';
    is $three->three_class_m, 'three_class_m';

    is $one->set_one_a('1a'), undef,
        'inherits, instance attributes independent';
    is $one->get_one_a, '1a',
        'inherits, instance attributes independent';
    is $two->get_one_a, undef,
        'inherits, instance attributes independent';
    is $three->get_one_a, undef,
        'inherits, instance attributes independent';
    is $two->set_one_a('1A'), undef,
        'inherits, instance attributes independent';
    is $two->get_one_a, '1A',
        'inherits, instance attributes independent';
    is $one->get_one_a, '1a',
        'inherits, instance attributes independent';
    is $three->get_one_a, undef,
        'inherits, instance attributes independent';
    is $three->set_one_a('ONEA'), undef,
        'inherits, instance attributes independent';
    is $three->get_one_a, 'ONEA',
        'inherits, instance attributes independent';
    is $two->get_one_a, '1A',
        'inherits, instance attributes independent';
    is $one->get_one_a, '1a',
        'inherits, instance attributes independent';

    is $one->set_one_class_a('1ca'), undef,
        'inherits, class attributes same for all';
    is $one->get_one_class_a, '1ca',
        'inherits, class attributes same for all';
    is $two->get_one_class_a, '1ca',
        'inherits, class attributes same for all';
    is $three->get_one_class_a, '1ca',
        'inherits, class attributes same for all';
    is(InheritsOne->get_one_class_a, '1ca',
        'inherits, class attributes same for all');
    is(InheritsTwo->get_one_class_a, '1ca',
        'inherits, class attributes same for all');
    is(InheritsThree->get_one_class_a, '1ca',
        'inherits, class attributes same for all');

}, 'inherits' );

throws_ok( sub {
    package InheritsSix;
    classes::classes  inherits => {};
}, 'X::Usage');

throws_ok( sub {
    package InheritsSeven;
    classes::classes  inherits => '12h';
}, 'X::InvalidName');

throws_ok( sub {
    package InheritsEight;
    classes::classes  inherits => 'h2';
}, 'X::Empty');

lives_ok( sub {
    package InheritsSeven;
    classes::classes  inherits => undef;
}, 'inherits, undef value ignored but valid');

throws_ok( sub {
    package InheritsSeven;
    classes::classes  inherits => ['InheritsSix', ''];
}, 'X::InvalidName');

lives_ok( sub {
    package InheritsFive;
    classes::classes  inherits => 'InheritsFour';
}, 'inherits, already inherited');

