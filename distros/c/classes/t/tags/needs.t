# $Id: needs.t 100 2006-07-29 17:29:41Z rmuhle $

use strict;

use Test::More;
eval 'use Test::Exception';
if ($@) {
    plan skip_all => 'Test::Exception needed';
} else {
    plan tests => 1;
}

lives_ok( sub {
    #TODO: need to write out the Needed class module to test loading
} );



