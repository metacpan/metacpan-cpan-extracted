#! perl

{
    package Test::Overloaded::String;

    use vars qw( $called_string_overload );

    use strict;
    use warnings;

    use overload '""' => sub { $called_string_overload++ };

    sub new { bless {}, shift }

    sub foo { }
}

package main;

use strict;
use warnings;

use Test::More tests => 3;
use UNIVERSAL::can;

ok( eval { Test::Overloaded::String->new->can('foo') },
    "->can should return true for an existing method" );
ok( !eval { Test::Overloaded::String->new->can('bar') },
    "->can should return false for a non-existent method" );
ok( !$Test::Overloaded::String::called_string_overload,
    "it should not trigger the string overload on the invocant in either case" );
