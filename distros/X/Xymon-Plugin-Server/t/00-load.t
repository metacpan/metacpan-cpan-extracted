#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;

BEGIN {
    use_ok( 'Xymon::Plugin::Server' );
    use_ok( 'Xymon::Plugin::Server::Status' );
    use_ok( 'Xymon::Plugin::Server::Devmon' );
    use_ok( 'Xymon::Plugin::Server::Dispatch' );
}

diag( "Testing Xymon::Plugin::Server $Xymon::Plugin::Server::VERSION, Perl $], $^X" );
