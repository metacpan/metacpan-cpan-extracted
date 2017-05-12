# $Id: attrs.t 69 2006-07-12 23:07:47Z rmuhle $
use strict 'subs'; no warnings;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 103;
}

lives_ok( sub {
    package Declared;
    use strict 'subs'; no warnings;
    use classes
        type => 'mixable',
        attrs => [qw( attr1 foo )],
        attrs_ro => [qw( attr_ro1 )],
        attrs_pr => [qw( private )],
        class_attrs => { class_attr1 => 'ca1' }, 
        class_attrs_ro => [qw( class_attr_ro1 )],
        class_attrs_pr => [qw( private_ca )],
        methods => [qw( me_only outted )],
        class_methods => [qw( class_me_only )],
    ;

    sub not_me { 'not me' };

    sub me { 'me' };

    sub outted { $_[0]->{$ATTR_private} = 20; return $_[0] };
}, 'type = mixable' );

lives_ok( sub {
    package MixesOnce;
    use strict 'subs'; no warnings;
    use classes
        type => 'mixable',
        mixes => 'Declared',
        class_attrs_pr => ['prca1'],
    ;

    package MixesTwice;
    use classes
        type => 'mixable',
        mixes => 'MixesOnce',
    ;

    package main;
    is($$Declared::CLASS_ATTR_class_attr1, 'ca1',
        'original');
    is($$MixesOnce::CLASS_ATTR_class_attr1, 'ca1',
        'mixing a mixed in carries down one level');
    is($$MixesTwice::CLASS_ATTR_class_attr1, 'ca1',
        'mixing a mixed in carries down two levels');

    $$MixesTwice::CLASS_ATTR_class_attr1 = 'blah';

    is($$Declared::CLASS_ATTR_class_attr1, 'blah',
        'original');
    is($$MixesOnce::CLASS_ATTR_class_attr1, 'blah',
        'mixing a mixed in carries down one level');
    is($$MixesTwice::CLASS_ATTR_class_attr1, 'blah',
        'mixing a mixed in carries down two levels');

}, 'second level mixing' );

lives_ok( sub {
    #TODO
}, 'undeclared methods not mixed in if type = mixable' );

lives_ok( sub {
    #TODO
}, 'undeclared still visible to declared methods if type = mixable' );

lives_ok( sub {
    #TODO
}, 'MIXIN updated for methods' );

lives_ok( sub {
    #TODO
}, 'MIXIN updated for keys' );

lives_and( sub {
    package Mixes0;
    no strict 'vars';
    use classes new=>'classes::new_only', mixes => 'Declared';

    sub blah { $ATTR_attr1 }

    package Mixes01;
    no strict 'vars', 'refs';
    use classes new=>'classes::new_only', mixes => 'Declared';

    sub blahblah { $$CLASS_ATTR_class_attr1 }

    package main;
    can_ok 'Mixes0', 'set_attr1';
    can_ok 'Mixes0', 'get_attr1';

    is( Mixes0->blah(), 'Declared::attr1' );
    is( $Mixes0::ATTR_attr1, 'Declared::attr1' );
    is( $Mixes01::ATTR_attr1, 'Declared::attr1' );
    is( $Declared::ATTR_attr1, 'Declared::attr1' );

    is( $Mixes0::CLASS_ATTR_class_attr1, 'Declared::class_attr1' );
    is( $Declared::CLASS_ATTR_class_attr1, 'Declared::class_attr1' );

    $Declared::ATTR_attr1 = 'cool';
    is( $Mixes0::ATTR_attr1, 'cool',
        'changing the master ATTR_ key changes the others' );
    
    my $o = Mixes0->new; 
    $o->set_attr1('something');
    is $o->get_attr1, 'something', 'accessor always refers to same';
    is $o->{'cool'}, 'something', 'actual key name changes also';

    my $o2 = Mixes01->new;
    is $o->get_class_attr1, 'blah','ca initial value carries';
    is $Mixes0::class_attr1, undef,'ca stored in mixed in pkg';
    is $Mixes01::class_attr1, undef,'ca stored in mixed in pkg';
    is $Declared::class_attr1, 'blah','ca stored in mixed in pkg';
    is $o2->blahblah, 'blah','ca initial value carries';
    is $o2->get_class_attr1, 'blah', 'ca initial value carries';

    $o->set_class_attr1('another');
    is $o->get_class_attr1, 'another', 'mixed ca change changes all';
    is $o2->get_class_attr1, 'another', 'mixed ca change changes all';

    $Declared::class_attr1 = 'directly';
    is $o->get_class_attr1, 'directly',
        'directly changing ca in mixed in pkg change changes all';
    is $o2->get_class_attr1, 'directly',
        'directly changing ca in mixed in pkg change changes all';
    is $$Mixes0::CLASS_ATTR_class_attr1, 'directly',
        'directly changing ca in mixed in pkg change changes all';
    is $$Mixes01::CLASS_ATTR_class_attr1, 'directly',
        'directly changing ca in mixed in pkg change changes all';

    $Declared::class_attr_ro1 = 'directly';
    is $o->get_class_attr_ro1, 'directly',
        'directly changing ca in mixed in pkg change changes all';
    is $o2->get_class_attr_ro1, 'directly',
        'directly changing ca in mixed in pkg change changes all';
    is $$Mixes0::CLASS_ATTR_class_attr_ro1, 'directly',
        'directly changing ca in mixed in pkg change changes all';
    is $$Mixes01::CLASS_ATTR_class_attr_ro1, 'directly',
        'directly changing ca in mixed in pkg change changes all';

    $Declared::private_ca = 'directly';
    dies_ok( sub { $o->get_private_ca }, 
        'directly changing ca in mixed in pkg change changes all');
    dies_ok( sub { $o2->get_private_ca }, 
        'directly changing ca in mixed in pkg change changes all');
    is $$Mixes0::CLASS_ATTR_private_ca, 'directly',
        'directly changing ca in mixed in pkg change changes all';
    is $$Mixes01::CLASS_ATTR_private_ca, 'directly',
        'directly changing ca in mixed in pkg change changes all';

    #Mixes0->new->outted->classes::dump;
    $o->outted;
    is $o->{'Declared::private'}, 20;
    is( $Declared::ATTR_private, 'Declared::private' );
    is( $Mixes0::ATTR_private, 'Declared::private',
        'private key is mixed' );
    is( $Mixes01::ATTR_private, 'Declared::private',
        'private key not mixed' );
    ok( !Mixes0->can('get_private'), 'cannot get_private()');
    ok( !Mixes01->can('get_private'), 'cannot get_private()');
    ok( !Declared->can('get_private'), 'cannot get_private()');
    ok( !Mixes0->can('get__private'), 'cannot get__private()');
    ok( !Mixes01->can('get__private'), 'cannot get__private()');
    ok( !Declared->can('get__private'), 'cannot get__private()');
    ok( !Mixes0->can('_get_private'), 'cannot _get_private()');
    ok( !Mixes01->can('_get_private'), 'cannot _get_private()');
    ok( !Declared->can('_get_private'), 'cannot _get_private()');

}, 'mixes, single form, attr check' );

lives_and( sub {
    package HasUndeclared;
    use classes
        type => 'mixable',
        methods => [qw( local_dep )],
    ;

    sub local_dep { _undeclared() }

    sub _undeclared { '_undeclared' }

    package UsesUndeclared;
    use classes mixes => 'HasUndeclared';

    package main;
    can_ok 'HasUndeclared', 'local_dep';
    can_ok 'UsesUndeclared', 'local_dep';
    can_ok 'HasUndeclared', '_undeclared';
    ok( !UsesUndeclared->can('_undeclared'),
        'UsesUndeclared cannot \'_undeclared\'');
    is( UsesUndeclared->local_dep(), '_undeclared');
    
}, 'mixes, undeclared dependent methods do not cause problems' );

lives_and( sub {
    package Plain;
    sub by_name {'by name'};    # SAFE, ALL, PUB
    sub by_regx {'by regx'};    # SAFE, ALL, PUB
    sub public {'method1'};     # SAFE, ALL, PUB
    sub RESERVED {'RESERVED'};  # ALL, PUB
    sub _private {'_private'};  # ALL
}, 'mixes, Plain' );

lives_and( sub {
    package MixesPlainSAFE;
    use classes
        mixes => 'Plain',
        mixes_def => 'SAFE',
    ;

    package main;
    can_ok 'MixesPlainSAFE', 'by_name';
    can_ok 'MixesPlainSAFE', 'by_regx';
    can_ok 'MixesPlainSAFE', 'public';
    ok( !MixesPlainSAFE->can('RESERVED'));
    ok( !MixesPlainSAFE->can('_private'));
}, 'mixes, single form, plain SAFE' );

lives_and( sub {
    package MixesPlainALL;
    use classes
        mixes => 'Plain',
        mixes_def => 'ALL',
    ;

    package main;
    can_ok 'MixesPlainALL', 'by_name';
    can_ok 'MixesPlainALL', 'by_regx';
    can_ok 'MixesPlainALL', 'public';
    can_ok 'MixesPlainALL', 'RESERVED';
    can_ok 'MixesPlainALL', '_private';
}, 'mixes, single form, plain ALL' );

lives_and( sub {
    package MixesPlainPUB;
    use classes
        mixes => 'Plain',
        mixes_def => 'PUB',
    ;

    package main;
    can_ok 'MixesPlainPUB', 'by_name';
    can_ok 'MixesPlainPUB', 'by_regx';
    can_ok 'MixesPlainPUB', 'public';
    can_ok 'MixesPlainPUB', 'RESERVED';
    ok( !MixesPlainPUB->can('_private'));
}, 'mixes, single form, plain PUB' );

lives_and( sub {
    package MixesPlainByName;
    use classes
        mixes => { Plain => ['by_name'] },
    ;

    package main;
    can_ok 'MixesPlainByName', 'by_name';
    ok( !MixesPlainByName->can('by_regx'));
    ok( !MixesPlainByName->can('public'));
    ok( !MixesPlainByName->can('RESERVED'));
    ok( !MixesPlainByName->can('_private'));
}, 'mixes, hash form, plain by name' );

lives_and( sub {
    package MixesPlainByNameDef;
    use classes
        mixes => 'Plain',
        mixes_def => ['by_name'],
    ;

    package main;
    can_ok 'MixesPlainByNameDef', 'by_name';
    ok( !MixesPlainByNameDef->can('by_regx'));
    ok( !MixesPlainByNameDef->can('public'));
    ok( !MixesPlainByNameDef->can('RESERVED'));
    ok( !MixesPlainByNameDef->can('_private'));
}, 'mixes, single form, plain by name from mixes_def' );

lives_and( sub {
    package MixesPlainByRegx;
    use classes
        mixes => { Plain => qr/regx/o },
    ;

    package main;
    ok( !MixesPlainByRegx->can('by_name'));
    can_ok 'MixesPlainByRegx', 'by_regx';
    ok( !MixesPlainByRegx->can('public'));
    ok( !MixesPlainByRegx->can('RESERVED'));
    ok( !MixesPlainByRegx->can('_private'));
}, 'mixes, hash form, plain by regx' );

lives_and( sub {
    package MixesPlainByRegxDef;
    use classes
        mixes => 'Plain',
        mixes_def => qr/regx/o,
    ;

    package main;
    ok( !MixesPlainByRegxDef->can('by_name'));
    can_ok 'MixesPlainByRegxDef', 'by_regx';
    ok( !MixesPlainByRegxDef->can('public'));
    ok( !MixesPlainByRegxDef->can('RESERVED'));
    ok( !MixesPlainByRegxDef->can('_private'));
}, 'mixes, single form, plain by regx' );

lives_and( sub {
    package Simple;
    sub simple {'simple'};
    sub by_name {'simple_by_name'};
   
    package MixesPlainSimple;
    use classes
        mixes => ['Plain', 'Simple'],
        mixes_def => 'ALL',
    ;

    package main;
    can_ok 'MixesPlainSimple', 'by_name';
    can_ok 'MixesPlainSimple', 'by_regx';
    can_ok 'MixesPlainSimple', 'public';
    can_ok 'MixesPlainSimple', 'RESERVED';
    can_ok 'MixesPlainSimple', '_private';
    can_ok 'MixesPlainSimple', 'simple';
    is( MixesPlainSimple->by_name, 'by name', 'first wins');
}, 'mixes, multiple, all named' );

