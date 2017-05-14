#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . "/../lib";

use Test::More tests => 2;
use Test::Exception;

# uncomment to debug tests
#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

use WebService::ReviewBoard;

lives_ok( sub { WebService::ReviewBoard->new( 'http://demo.review-board.org' ) }, "created new WebService::ReviewBoard object" );
dies_ok( sub { WebService::ReviewBoard->new( ) }, "new WebService::ReviewBoard object dies when missing url" );
