use warnings;
use strict;

use lib 't/lib';
use Test::More tests => 4;

use ExporterTest qw( foo bar );

BEGIN {
    ok( main->can('foo'), 'methods are there before cleanup' );
    eval { require namespace::clean ;; namespace::clean->import };
    ok( !$@, 'module use ok' );
}

ok( !main->can($_), "$_ function removed" )
    for qw( foo bar );

