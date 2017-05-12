# $Id: attrs.t 69 2006-07-12 23:07:47Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 55;
}

lives_and( sub {

    use classes
         name => 'ExtendsOne',
         new => 'classes::new_args',
         attrs => [ 'one_a' ],
         class_attrs => { one_class_a => 'one_class_a' }, 
         methods => {one_m => sub {'one_m'}},
         class_methods => {one_class_m=>sub {'one_class_m'}},
    ;

    my $one = ExtendsOne->new(one_a=>'one_a');
    is $one->get_one_a, 'one_a';
    is $one->get_one_class_a, 'one_class_a';
    is $one->one_m, 'one_m';
    is $one->one_class_m, 'one_class_m';

    use classes
         name => 'ExtendsTwo',
         extends => 'ExtendsOne',
         attrs => [ 'two_a' ],
         class_attrs => { two_class_a => 'two_class_a' }, 
         methods => {two_m => sub {'two_m'}},
         class_methods => {two_class_m=>sub {'two_class_m'}},
    ;

    my $two = ExtendsTwo->new(one_a=>'one_a',two_a=>'two_a');
    is $two->get_one_a, 'one_a';
    is $two->get_one_class_a, 'one_class_a';
    is $two->one_m, 'one_m';
    is $two->one_class_m, 'one_class_m';
    is $two->get_two_a, 'two_a';
    is $two->get_two_class_a, 'two_class_a';
    is $two->two_m, 'two_m';
    is $two->two_class_m, 'two_class_m';

    use classes
         name => 'ExtendsThree',
         extends => 'ExtendsTwo',
         attrs => [ 'three_a' ],
         class_attrs => { three_class_a => 'three_class_a' }, 
         methods => {three_m => sub {'three_m'}},
         class_methods => {three_class_m=>sub {'three_class_m'}},
    ;

    use classes
         name => 'ExtendsFour',
        extends => 'ExtendsThree',
    ;

    use classes
         name => 'ExtendsFive',
        extends => 'ExtendsFour',
    ;

    my $five = ExtendsFive->new;
    isa_ok $five, 'ExtendsFive';
    isa_ok $five, 'ExtendsFour';
    isa_ok $five, 'ExtendsThree';
    isa_ok $five, 'ExtendsTwo';
    isa_ok $five, 'ExtendsOne';

    my $three = ExtendsThree->new(
        one_a=>'one_a',two_a=>'two_a',three_a=>'three_a');
    is $three->get_one_a, 'one_a';
    is $three->get_one_class_a, 'one_class_a';
    is $three->one_m, 'one_m';
    is $three->one_class_m, 'one_class_m';
    is $three->get_two_a, 'two_a';
    is $three->get_two_class_a, 'two_class_a';
    is $three->two_m, 'two_m';
    is $three->two_class_m, 'two_class_m';
    is $three->get_three_a, 'three_a';
    is $three->get_three_class_a, 'three_class_a';
    is $three->three_m, 'three_m';
    is $three->three_class_m, 'three_class_m';

    is $one->set_one_a('1a'), undef,
        'extends, instance attributes independent';
    is $one->get_one_a, '1a',
        'extends, instance attributes independent';
    is $two->get_one_a, 'one_a',
        'extends, instance attributes independent';
    is $three->get_one_a, 'one_a',
        'extends, instance attributes independent';
    is $two->set_one_a('1A'), undef,
        'extends, instance attributes independent';
    is $two->get_one_a, '1A',
        'extends, instance attributes independent';
    is $one->get_one_a, '1a',
        'extends, instance attributes independent';
    is $three->get_one_a, 'one_a',
        'extends, instance attributes independent';
    is $three->set_one_a('ONEA'), undef,
        'extends, instance attributes independent';
    is $three->get_one_a, 'ONEA',
        'extends, instance attributes independent';
    is $two->get_one_a, '1A',
        'extends, instance attributes independent';
    is $one->get_one_a, '1a',
        'extends, instance attributes independent';

    is $one->set_one_class_a('1ca'), undef,
        'extends, class attributes same for all';
    is $one->get_one_class_a, '1ca',
        'extends, class attributes same for all';
    is $two->get_one_class_a, '1ca',
        'extends, class attributes same for all';
    is $three->get_one_class_a, '1ca',
        'extends, class attributes same for all';
    is(ExtendsOne->get_one_class_a, '1ca',
        'extends, class attributes same for all');
    is(ExtendsTwo->get_one_class_a, '1ca',
        'extends, class attributes same for all');
    is(ExtendsThree->get_one_class_a, '1ca',
        'extends, class attributes same for all');

}, 'extends' );

lives_and( sub {
    package Inherits2;
    use classes
        inherits => ['ExtendsOne', 'ExtendsTwo'],
    ;
    package main;
    is_deeply(Inherits2->DECL->{'inherits'},
        ['ExtendsOne', 'ExtendsTwo']);
    is_deeply(\@Inherits2::ISA,
        ['ExtendsOne', 'ExtendsTwo']);

    classes::classes(name=>'Inherits2',extends=>'ExtendsThree');
    is_deeply(Inherits2->DECL->{'inherits'}, undef);
    is_deeply(Inherits2->DECL->{'extends'}, 'ExtendsThree');
    is_deeply(\@Inherits2::ISA, ['ExtendsThree']);
    
}, 'trumps inherits' );


throws_ok( sub {
    package ExtendsSix;
    classes::classes  extends => ['ExtendsFive'];
}, 'X::Usage');

throws_ok( sub {
    package ExtendsSeven;
    classes::classes  extends => 'ExtendsFive',  inherits=>['ExtendsSix']; }, 'X::Usage');


