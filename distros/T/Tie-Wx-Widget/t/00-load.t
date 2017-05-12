#!usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' } # making local lib favoured

ok( $] >= 5.006, 'Your perl is new enough' );
use_ok( 'Wx' );
use_ok( 'Tie::Scalar' );
use_ok( 'Tie::Wx::Widget' ) || print "Bail out!\n";

diag( "Testing Tie::Wx::Widget $Tie::Wx::Widget::VERSION with Perl $] from $^X" );

exit(0);