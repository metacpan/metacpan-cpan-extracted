#/usr/bin/env perl

use warnings;
use strict;
use Test::More tests => 2;
use Test::RequiresInternet ('httpbin.org' => 'https');

use_ok('Test::HTTPStatus');
Test::HTTPStatus::user_agent()->max_redirects(5);

my $code = Test::HTTPStatus::_check_link('https://httpbin.org/status/403');

is( $code, 403, "Unauthorized code works" );
