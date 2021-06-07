use 5.012;
use warnings;
use Test::More;

plan skip_all => 'Plack required to test Plack handler' unless eval {require Plack::Test::Suite; 1};

Plack::Test::Suite->run_server_tests('UniEvent::HTTP');

done_testing();
