use strict;
use warnings;
use Test::More;
use Plack::Test::Suite;

Plack::Test::Suite->run_server_tests('Twiggy::Prefork');
done_testing();
