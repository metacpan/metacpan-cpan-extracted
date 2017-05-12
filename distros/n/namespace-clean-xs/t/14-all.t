use strict;
use Test::More;

use namespace::clean::xs ();

package Foo;
our $foo;

sub reap {}

BEGIN {
    $foo = 0;
    my $old_import = *namespace::clean::xs::import{CODE};
    *namespace::clean::xs::import = sub { $foo = 42; goto &$old_import };

    eval 'use namespace::clean::xs::all';
}

BEGIN {
    ::is(!!__PACKAGE__->can('reap'), 1);

    ::is($foo, 0);
    eval 'use namespace::clean 0.26';
    ::is($foo, 42);
}

::is(!!__PACKAGE__->can('reap'), '');

::done_testing;
