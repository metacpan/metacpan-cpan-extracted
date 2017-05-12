use strict;
use Test::More tests => 1;

use Yahoo::BBAuth;

my $bbauth = Yahoo::BBAuth->new(
    appid  => 'testappid',
    secret => 'testsecret',
);
like($bbauth->auth_url, qr!^https?://!);
