use strict;
use warnings;
use lib qw(lib);

use Test::More tests => 8;

use_ok( 'eBay::API::Simple' );
use_ok( 'eBay::API::SimpleBase' );
use_ok( 'eBay::API::Simple::Trading' );
use_ok( 'eBay::API::Simple::Finding' );
use_ok( 'eBay::API::Simple::Shopping' );
use_ok( 'eBay::API::Simple::HTML' );
use_ok( 'eBay::API::Simple::RSS' );
use_ok( 'eBay::API::Simple::JSON' );

