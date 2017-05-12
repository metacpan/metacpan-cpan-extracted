# $Id: attrs_pr.t 81 2006-07-24 16:34:38Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 7;
}

lives_and( sub {
    use classes
        name=>'AttrsPR1',
        new=>'classes::new_only',
        attrs_pr=>['foo']
    ;
    isa_ok my $o1 = AttrsPR1->new, 'AttrsPR1'; 
    ok( !AttrsPR1->can('get_foo'));
    ok( !AttrsPR1->can('set_foo') );
    is $AttrsPR1::ATTR_foo, 'AttrsPR1::foo';
}, 'attrs_pr, no accessors, but key var there' );

lives_and ( sub {
    package AttrsPR2;
    no warnings 'redefine';
    use classes
        new      => 'classes::new_args',
        attrs_pr => [ 'bar' ],
    ;

    sub bar_doubled { $_[0]->{$ATTR_bar} * 2 }

    package main;
    my $o = AttrsPR2->new;
    $o->{'AttrsPR2::bar'} = 2;
    is $o->bar_doubled, 4;

}, 'attrs_pr, method that uses private attr object hash key var');

lives_and ( sub {
    use classes name=>'AttrsPR4', attrs=>['bar'];
    
    package AttrsPR5;
    no warnings 'redefine';
    use classes
        extends  => 'AttrsPR4',
        new      => 'classes::new_args',
        attrs_pr => [ 'bar' ],
    ;

    package main;
    my $o = AttrsPR5->new;
    throws_ok(sub {$o->get_bar}, 'X::AttrScope');
    throws_ok(sub {$o->set_bar('blah')}, 'X::AttrScope');

}, 'attrs_pr, overriding rw with pr');

# also see extends.t and inherits.t for tests
# related to attr inheritance
