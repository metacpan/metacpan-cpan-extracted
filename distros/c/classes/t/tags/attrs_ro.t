# $Id: attrs_ro.t 147 2008-03-08 16:04:33Z rmuhle $

no strict;
no warnings;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 13;
}

lives_and( sub {
    use classes
        name=>'AttrsRO1',
        new=>'classes::new_only',
        attrs_ro=>['foo']
    ;
    isa_ok my $o1 = AttrsRO1->new, 'AttrsRO1'; 
    ok( AttrsRO1->can('get_foo'));
    ok( !AttrsRO1->can('set_foo') );
    can_ok $o1, 'get_foo';
    ok( !$o1->can('set_foo') );
    dies_ok(sub {$o1->set_bar});
    dies_ok(sub {$o1->set_bar('blah')});
    is $o1->get_foo, undef;
    $o1->{'AttrsRO1::foo'} = 2;
    is $o1->get_foo, 2;
}, 'attrs_ro, public accessor' );

lives_and ( sub {
    package AttrsRO2;
    no warnings 'redefine';
    use classes
        new      => 'classes::new_args',
        attrs_ro => [ 'bar' ],
    ;

    sub get_bar { $_[0]->{$ATTR_bar} * 2 }

    package main;
    my $o2 = AttrsRO2->new;
    is $o2->get_bar, 0; 
    $o2->{'AttrsRO2::bar'} = 2;
    is $o2->get_bar, 4;

}, 'attrs_ro, custom accessor');

lives_and ( sub {
    use classes name=>'AttrsRO4', attrs=>['bar'];
    
    package AttrsRO5;
    no warnings 'redefine';
    use classes
        extends  => 'AttrsRO4',
        new      => 'classes::new_args',
        attrs_ro => [ 'bar' ],
    ;

    package main;
    my $o2 = AttrsRO5->new;
    throws_ok(sub {$o2->set_bar}, 'X::AttrScope');
    throws_ok(sub {$o2->set_bar('blah')}, 'X::AttrScope');

}, 'attrs_ro, overriding rw with ro');

# also see extends.t and inherits.t for tests
# related to attr inheritance
