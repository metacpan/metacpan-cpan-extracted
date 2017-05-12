
use Sub::Uplevel;

use strict;
use warnings;
use utf8;

use Test::More tests => 4;

use lib 't/lib';

BEGIN {
    eval {
        use Boo;
    };
    ok(!$@, 'Loading subclass');
};

isa_ok('Boo','Biga');
is(Boo->low,0);
is(Boo->high,1);

