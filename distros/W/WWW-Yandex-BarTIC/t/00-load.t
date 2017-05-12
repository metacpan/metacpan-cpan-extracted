#!/usr/bin/env perl

use Test::More 'no_plan';

BEGIN {
    use_ok( 'WWW::Yandex::BarTIC' ) || print "Bail out!\n";
}

diag( "Testing WWW::Yandex::BarTIC $WWW::Yandex::BarTIC::VERSION, Perl $], $^X" );
