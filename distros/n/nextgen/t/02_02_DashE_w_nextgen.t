#!/usr/bin/env perl
use Test::More tests => 2;

BEGIN { $0 = '-e' }
use nextgen;

eval { Class->new };
Test::More::is ( $@, '', 'have an oose.pm new' );

package Foo;
use nextgen;

eval { Class->new };
Test::More::is ( $@, '', 'have an Moose new on reimport in different package' );


1;
