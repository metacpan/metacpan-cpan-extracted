use Test::More;

use_ok('Tiny::OpenSSL::Config');

use Tiny::OpenSSL::Config qw($CONFIG);

ok(defined $CONFIG );

done_testing;
