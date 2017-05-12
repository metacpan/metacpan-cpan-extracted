# $Id: attrs.t 147 2008-03-08 16:04:33Z rmuhle $

# I will do my own checking, thank you very much
no strict;
no warnings;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 19;
}

lives_and( sub {
    use classes
        name=>'Attrs1',
        new=>'classes::new_only',
        attrs=>['foo']
    ;
    isa_ok my $o1 = Attrs1->new, 'Attrs1'; 
    ok( Attrs1->can('get_foo'));
    ok( Attrs1->can('set_foo'));
    can_ok $o1, 'get_foo';
    can_ok $o1, 'set_foo';
    is $o1->get_foo, undef;
    is $o1->set_foo(2), undef, 'attrs, set must always return void';
    is $o1->get_foo, 2;
}, 'attrs, public and private accessors' );

lives_and ( sub {
    package Attr2;
    no warnings 'redefine';
    use classes
        new   => 'classes::new_args',
        attrs => [ 'bar' ],
    ;

    sub set_bar { $_[0]->{$ATTR_bar} = $_[1]*2; return }

    package main;
    my $o2 = Attr2->new(bar=>1);
    is $o2->get_bar, 2; 
    is $o2->set_bar(2), undef, 'attrs, set must always return void';
    is $o2->get_bar, 4;

}, 'attrs, custom accessor');

lives_and ( sub {
    package Attr4;
    no warnings 'redefine';
    use classes
        new   => 'classes::new_args',
        attrs => [ 'bar' ],
    ;

    sub get_bar {'bar'};

    package main;
    no warnings 'redefine';
    can_ok 'Attr4', 'set_bar';
    can_ok 'Attr4', 'get_bar';
    my $o = Attr4->new;
    is $o->get_bar, 'bar';
    
    classes::define name=>'Attr4', attrs=>['bar'];
    is $o->get_bar, undef;

}, 'attrs, dynamic redefines');

lives_and ( sub {
    package Attr5;
    no strict 'vars';
    no warnings 'redefine';
    use classes
        new   => 'classes::new_args',
        attrs => [ '_bar' ],
    ;
    sub test {$_[0]->{$ATTR_bar}=1};
    #is( $Attr5::ATTR_bar, 'Attr5::bar');

    package main;
    ok(!Attr5->can('set_bar'));
    ok(!Attr5->can('get_bar'));
    my $o = Attr5->new;
    is $ATTR_bar, undef,
        'attrs, private attributes, $ATTR_ scope only within class';
    is $o->test, 1;

}, 'attrs, private attributes');

# also see extends.t and inherits.t and mixes.t for tests
# related to attr in other classes
