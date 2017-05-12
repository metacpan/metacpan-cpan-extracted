use strict;
use Test::More;

use_ok('Yaadgom');

use HTTP::Request;
use HTTP::Response;

my $foo = Yaadgom->new;

$foo->process_response(
    folder => 'test',
    req    => HTTP::Request->new( GET => 'http://www.example.com/foobar' ),
    res    => HTTP::Response->new( 200, 'OK', [ 'content-type' => 'application/json' ], '{"ok":1}' ),
);

$foo->map_results(
    sub {
        my (%info) = @_;

        is( $info{file},   'foobar', '"foobar" file' );
        is( $info{folder}, 'test',   '"test" folder' );
        ok( $info{str}, 'has str' );
    }
);

done_testing;
