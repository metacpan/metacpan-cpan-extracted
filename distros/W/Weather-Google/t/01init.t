#!/usr/bin/perl -w

use strict;
use warnings;

# use Test::Simple tests => 10;
use Test::Simple skip_all => "Deprecated";

use Weather::Google;

my $w = new Weather::Google;
ok( defined $w, 'new() returns a value' );
ok( $w->isa('Weather::Google'), 'The right class' );

ok( $w->zip(90210), 'Works with zip');
ok( $w->city('Beverly Hills, CA'), 'And with city');

ok ( my $g = new Weather::Google (90210), 'new(zip)');

ok( defined $g );
ok( $g->isa('Weather::Google') );

ok ( $g = new Weather::Google('Beverly Hills, CA'), 'new(city)');
ok( defined $g );
ok( $g->isa('Weather::Google') );
