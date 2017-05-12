#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 2;

BEGIN {
    use_ok( 'VIM::Packager' );
}

diag( "Testing VIM::Packager $VIM::Packager::VERSION, Perl $], $^X" );

ok( *say  ,'found say');
