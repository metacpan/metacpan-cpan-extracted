use strict;
use Test::More;

use_ok('Yaadgom');

use HTTP::Request;
use HTTP::Response;

my $foo = Yaadgom->new;

$foo->process_response(
    req    => HTTP::Request->new( GET => "http://www.example.com/" ),
    res    => HTTP::Response->new( 200, 'OK', [ 'content-type' => 'application/json' ], '{"ok":1}' ),
);

my $rand = rand;
mkdir '/tmp/testing-yaadgom' . $rand;
$foo->export_to_dir(
    dir => '/tmp/testing-yaadgom' . $rand
);

ok(-e "/tmp/testing-yaadgom$rand/default/_index.md", 'document saved on file');

done_testing;
