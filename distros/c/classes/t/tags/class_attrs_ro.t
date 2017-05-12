# $Id: class_attrs_ro.t 105 2006-08-02 17:01:57Z rmuhle $

use strict 'subs';no warnings;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 12;
}

lives_and( sub {
    use classes
        name=>'CAttrsRO1',
        new=>'classes::new_only',
        class_attrs_ro=>['foo']
    ;
    isa_ok my $o1 = CAttrsRO1->new, 'CAttrsRO1'; 
    ok( CAttrsRO1->can('get_foo'));
    ok( !CAttrsRO1->can('set_foo') );
    can_ok $o1, 'get_foo';
    ok( !$o1->can('set_foo') );
    dies_ok(sub { $o1->set_foo(2)});
    is $o1->get_foo, undef;
    $$CAttrsRO1::CLASS_ATTR_foo = 2;
    is $o1->get_foo, 2;
}, 'class_attrs_ro, public accessor' );

lives_and ( sub {
    package CAttrsRO2;
    no warnings 'redefine';
    use classes
        new      => 'classes::new_args',
        class_attrs_ro => [ 'bar' ],
    ;

    sub get_bar { $$CAttrsRO2::ATTR_CLASS_bar * 2 }

    package main;
    my $o2 = CAttrsRO2->new;
    is $o2->get_bar, 0; 
    $$CAttrsRO2::ATTR_CLASS_bar = 2;
    is $o2->get_bar, 4; 
}, 'class_attrs_ro, custom accessor');

lives_and ( sub {
    use classes name=>'CAttrsRO4', class_attrs=>['bar'];
    
    package CAttrsRO5;
    no warnings 'redefine';
    use classes
        extends  => 'CAttrsRO4',
        new      => 'classes::new_args',
        class_attrs_ro => [ 'bar' ],
    ;

    package main;
    my $o2 = CAttrsRO5->new;
    throws_ok(sub {$o2->set_bar}, 'X::AttrScope');
    throws_ok(sub {$o2->set_bar('blah')}, 'X::AttrScope');

}, 'class_attrs_ro, overriding rw with ro');

# also see extends.t and inherits.t for tests
# related to class attr inheritance
