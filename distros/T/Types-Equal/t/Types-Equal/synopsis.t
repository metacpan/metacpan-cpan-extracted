use strict;
use warnings;
use Test::More;

use Types::Equal qw( Eq Equ );
use Types::Standard -types;
use Type::Utils qw( match_on_type );


subtest 'Check single string equality' => sub {
    my $Foo = Eq['foo'];
    ok $Foo->check('foo');
    ok !$Foo->check('bar');

    eval { Eq[undef]; };
    ok $@;
};

subtest 'Check single string equality with undefined' => sub {
    my $Bar = Equ['bar'];
    ok $Bar->check('bar');

    my $Undef = Equ[undef];
    ok $Undef->check(undef);
};

subtest 'Can combine with other types' => sub {
    my $Baz = Eq['baz'];
    my $ListBaz = ArrayRef[$Baz];
    my $Type = $ListBaz | $Baz;

    ok $Type->check(['baz']);
    ok $Type->check('baz');
};

subtest 'Easily use pattern matching' => sub {

    my $Publish = Eq['publish'];
    my $Draft = Eq['draft'];

    my $post = {
        status => 'publish',
        title => 'Hello World',
    };

    is match_on_type($post->{status},
        $Publish => sub { "Publish!" },
        $Draft => sub { "Draft..." },
    ), 'Publish!';
};

subtest 'Create simple Algebraic Data Types(ADT)' => sub {

    my $LoginUser = Dict[
        _type => Eq['LoginUser'],
        id => Int,
        name => Str,
    ];

    my $Guest = Dict[
        _type => Eq['Guest'],
        name => Str,
    ];

    my $User = $LoginUser | $Guest;

    my $user = { _type => 'Guest', name => 'ken' };
    $User->assert_valid($user);

    is match_on_type($user,
        $LoginUser => sub { "You are LoginUser!" },
        $Guest => sub { "You are Guest!" },
    ), 'You are Guest!';
};

done_testing;;
