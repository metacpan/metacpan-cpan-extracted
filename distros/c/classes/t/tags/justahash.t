#; $Id: justahash.t 131 2006-09-07 19:25:03Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 9;
}

lives_and( sub {
    use classes
        name=>'JustAHash',
        attrs=>['foo'],
        justahash=>1,
    ;

    package main;
    isa_ok my $o1 = JustAHash->new({bar=>2}), 'JustAHash'; 
    isa_ok my $o2 = JustAHash->new(bar=>2), 'JustAHash'; 
    ok( !$o1->can('set_foo'));
    ok( !$o1->can('get_foo'));
    $o1->{'foo'} = 1;
    is $o1->{'foo'}, 1;
    is $o1->{'bar'}, 2;
    is $o1->{'JustAHash::foo'}, undef;
    is $o2->{'bar'}, 2;
    is $o2->{'JustAHash::foo'}, undef;

}, 'justahash');


