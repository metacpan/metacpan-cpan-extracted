#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Web::ACL' ) || print "Bail out!\n";
}

diag( "Testing Web::ACL $Web::ACL::VERSION, Perl $], $^X" );
