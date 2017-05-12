#!/usr/bin/env perl
use warnings;
#use strict;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More tests => 4;

use ExporterTest qw( foo bar );

BEGIN {
    ok( main->can('foo'), 'methods are there before cleanup' );
    eval { require namespace::clean::xs ;; namespace::clean::xs->import };
    ok( !$@, 'module use ok' );
}

ok( !main->can($_), "$_ function removed" )
    for qw( foo bar );
