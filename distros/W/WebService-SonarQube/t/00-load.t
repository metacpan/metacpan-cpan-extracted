#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'WebService::SonarQube' );
}

diag( "Testing WebService::SonarQube $WebService::SonarQube::VERSION, Perl $], $^X" );
done_testing();
