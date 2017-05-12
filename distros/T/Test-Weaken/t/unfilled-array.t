#!/usr/bin/perl

# These test cases were created by Kevin Ryde.

use strict;
use warnings;
use Test::Weaken;
use Test::More tests => 4;

{
    my $leaks = Test::Weaken::leaks(
        sub {
            my @array;
            $#array = 1;
            return \@array;
        }
    );
    Test::More::ok( !$leaks, 'pre-extended array' );
}
{
    my $leaks = Test::Weaken::leaks(
        sub {
            my @array = ( 123, 456 );
            delete $array[0];
            return \@array;
        }
    );
    Test::More::ok( !$leaks, 'array element delete()' );
}

{
    my @global;
    $#global = 1;
    my $leaks = Test::Weaken::leaks(
        sub {
            return \@global;
        }
    );
    Test::More::ok( !exists $global[0],
        q{leaks doesn't bring global[0] into existence} );
    Test::More::ok( !exists $global[1],
        q{leaks doesn't bring global[1] into existence} );
}

exit 0;
