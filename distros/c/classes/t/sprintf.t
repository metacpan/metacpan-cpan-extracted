# $Id: sprintf.t 110 2006-08-07 18:27:07Z rmuhle $

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 9;
}

use_ok( 'classes' );
can_ok 'classes', 'sprintf';
can_ok 'classes', 'printf';

lives_and( sub {
    package HasPrintf;
    use classes
        new            => 'classes::new_args',
        attrs          => ['foo'],
        class_attrs    => {Foo=>'Phoo'},
        class_methods  => {
            sprintf => 'classes::sprintf',
            printf  => 'classes::printf',
        },
    ;
    package main;
    my $o = HasPrintf->new(foo=>'phoo'); 
    can_ok( HasPrintf, 'sprintf');
    can_ok( HasPrintf, 'printf');
    can_ok( $o, 'sprintf');
    can_ok( $o, 'printf');
    is(HasPrintf->sprintf('%s %s', 'foo', 'Foo'), ' Phoo');
    is($o->sprintf('%s %s', 'foo', 'Foo'), 'phoo Phoo');
#FIXME: figure out how to capture and test output, without cmd
#    ok(HasPrintf->printf('%s %s', 'foo', 'Foo'));
#    ok($o->printf('%s %s', 'foo', 'Foo'));
}, 's/printf');
