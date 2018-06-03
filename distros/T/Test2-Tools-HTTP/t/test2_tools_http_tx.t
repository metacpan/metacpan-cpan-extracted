use Test2::V0 -no_srand => 1;
use Test2::Tools::HTTP::Tx;
use Test2::Tools::HTTP;
use HTTP::Request::Common;

psgi_app_add sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "xx\n" ] ] };

http_request  GET('/');

eval { Test2::Tools::HTTP::Tx->add_helper('tx.note', sub {}) };
like $@, qr/Test2::Tools::HTTP::Tx already can note/, 'do not add existing method to tx';

eval { Test2::Tools::HTTP::Tx->add_helper('req.new', sub {}) };
like $@, qr/Test2::Tools::HTTP::Tx::Request already can new/, 'do not add existing method to req';

eval { Test2::Tools::HTTP::Tx->add_helper('res.new', sub {}) };
like $@, qr/Test2::Tools::HTTP::Tx::Response already can new/, 'do not add existing method to res';

Test2::Tools::HTTP::Tx->add_helper('tx.foo', sub { 'foo' });
is( http_tx->foo, 'foo', 'add helper tx.foo' );

Test2::Tools::HTTP::Tx->add_helper('req.bar', sub { 'bar' });
is( http_tx->req->bar, 'bar', 'add helper req.bar' );

Test2::Tools::HTTP::Tx->add_helper('res.baz', sub { 'baz' });
is( http_tx->res->baz, 'baz', 'add helper res.baz' );

done_testing;
