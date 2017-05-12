use strict;
use Test::More;
use Test::Fatal qw/dies_ok/;
use Test::JSON::RPC::Autodoc;

dies_ok { Test::JSON::RPC::Autodoc->new() };
my $app = sub {
    my $json = '{ "message":"hello" }';
    return [ 200, [ 'Content-Type' => 'application/json' ], [$json] ];  
};
my $test = Test::JSON::RPC::Autodoc->new(
    app           => $app,
    document_root => './t',
    index_file    => 'index.md'
);
ok $test;
isa_ok $test, 'Test::JSON::RPC::Autodoc';

my $request = $test->new_request();
ok $request;
isa_ok $request, 'Test::JSON::RPC::Autodoc::Request';

$test->write('./blank.md');
ok -f './t/blank.md';
ok -f './t/index.md';
unlink './t/blank.md';
unlink './t/index.md';

done_testing();
