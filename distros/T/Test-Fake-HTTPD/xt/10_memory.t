use Test::More;
eval "use Test::Memory::Cycle";
plan skip_all => "Test::Memory::Cycle required for testing memory leaks" if $@;
plan skip_all => "set TEST_MEMORY or TEST_ALL to enable this test"
    unless $ENV{TEST_MEMORY} or $ENV{TEST_ALL};

use Test::Fake::HTTPD;

my $httpd = run_http_server {
    my $req = shift;
    [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
};

memory_cycle_ok($httpd);
memory_cycle_ok($httpd->{server});

done_testing;
