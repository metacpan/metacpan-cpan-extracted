#!/usr/bin/perl -w
use warnings;
use strict;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use aliased;

ok defined &prefix, 'prefix() should be in our namespace if we ask for it';
ok defined &alias,  'alias() should be in our namespace if we ask for it';

{
    package Foo;
    sub checkit { 'foo checkit' }
}
{
    package Foo::Bar;
    sub checkit { 'foobar checkit' }
}
BEGIN {
    @INC{qw<Foo.pm Foo/Bar.pm>} = (1,1);
}
ok my $foo = prefix('Foo'), 'Calling prefix should succeed';
is ref $foo, 'CODE', '... returning a code ref';
is $foo->()->checkit, 'foo checkit', '... and called directly, returns the correct class';
is $foo->('Bar')->checkit, 'foobar checkit',
    '... and if called with a subpackage name, should also return the correct class';

done_testing;
