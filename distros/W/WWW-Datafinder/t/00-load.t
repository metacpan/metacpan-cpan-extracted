#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::Datafinder' ) || print "Bail out!\n";
}

diag( "Testing WWW::Datafinder $WWW::Datafinder::VERSION, Perl $], $^X" );
