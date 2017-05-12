use strict;
use Test::More;
use Test::JSON::RPC::Autodoc::Request;

my $app = sub {
    my $json = '{ "message":"hello" }';
    return [ 200, [ 'Content-Type' => 'application/json' ], [$json] ];  
};
my $request = Test::JSON::RPC::Autodoc::Request->new( app => $app );
ok $request;

$request->params(
    foo => { isa => 'Int', required => 1 }
);
$request->post_not_ok('method', {});
$request->post_not_ok('method', { foo => 'bar' });
$request->post_ok('method', { foo => 10 });

is_deeply $request->rule, { foo => { isa => 'Int', required => 1 } };

my $res = $request->response();
ok $res;
isa_ok $res, 'HTTP::Response';

my $ref = $res->from_json();
ok $ref;
is_deeply $ref, { message => 'hello' };

$request->post_ok('method', { foo => 10 }, [ [Foo => 'bar'] ]);
is $request->headers->header('Foo'), 'bar';
my $res = $request->response();

done_testing();
