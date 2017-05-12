#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WordPress::Plugin::WallFlower' ) || print "Bail out!
";
}

diag( "Testing WordPress::Plugin::WallFlower $WordPress::Plugin::WallFlower::VERSION, Perl $], $^X" );
