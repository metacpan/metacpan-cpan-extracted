use strict;
use warnings;
use Test::More;

{
    package My::Cleaner;
    use namespace::allclean ();

    sub import {
        namespace::allclean->import(
            -cleanee => scalar(caller),
        );
        *{Foo::boom} = sub { 'boom' };
    }
}

{
    package Foo;
    BEGIN { My::Cleaner->import } # use My::Cleaner tries to load it from disk
    sub explode { 'explode' }
}

ok(!Foo->can('explode'), 'locally defined methods removed');
ok(!Foo->can('boom'), 'imported functions removed');

done_testing();
