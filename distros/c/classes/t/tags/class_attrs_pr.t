# $Id: class_attrs_pr.t 81 2006-07-24 16:34:38Z rmuhle $

use strict 'subs'; no warnings;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 7;
}

lives_and( sub {
    use classes
        name=>'CAttrsPR1',
        new=>'classes::new_only',
        class_attrs_pr=>['foo']
    ;
    isa_ok my $o1 = CAttrsPR1->new, 'CAttrsPR1'; 
    ok( !CAttrsPR1->can('get_foo'));
    ok( !CAttrsPR1->can('set_foo') );
    is $CAttrsPR1::CLASS_ATTR_foo, 'CAttrsPR1::foo';
}, 'class_attrs_pr, no accessors, but key var there' );

lives_and ( sub {
    package CAttrsPR2;
    use strict 'subs'; no warnings 'redefine';
    use classes
        new      => 'classes::new_args',
        class_attrs_pr => [ 'bar' ],
    ;

    sub bar_doubled { $$CLASS_ATTR_bar * 2 }

    package main;
    my $o = CAttrsPR2->new;
    $$CAttrsPR2::CLASS_ATTR_bar = 2;
    is $o->bar_doubled, 4;

}, 'class_attrs_pr, method that uses private attr object hash key var');

lives_and ( sub {
    use classes name=>'CAttrsPR4', attrs=>['bar'];
    
    package CAttrsPR5;
    no warnings 'redefine';
    use classes
        extends  => 'CAttrsPR4',
        new      => 'classes::new_args',
        class_attrs_pr => [ 'bar' ],
    ;

    package main;
    my $o = CAttrsPR5->new;
    throws_ok(sub {$o->get_bar}, 'X::AttrScope');
    throws_ok(sub {$o->set_bar('blah')}, 'X::AttrScope');

}, 'class_attrs_pr, overriding rw with pr');

# also see extends.t and inherits.t for tests
# related to attr inheritance
