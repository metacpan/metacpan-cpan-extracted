#!/usr/bin/perl

##
## Tests for invalid accessors
##

use strict;
use warnings;

use Test::More tests => 9;
use Carp;

use_ok( "accessors" );

## invalid accessor names
do {
    eval { import accessors $_ };
    ok( $@, "invalid accessor - $_" );
} for (qw( BEGIN CHECK INIT END DESTROY AUTOLOAD 1notasub @$%*&^';\/ ));

