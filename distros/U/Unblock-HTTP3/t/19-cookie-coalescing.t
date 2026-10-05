use strict;
use warnings;

use Test2::V0;

use Uniform::HTTP::Response;
use Unblock::HTTP3::Connection;

my $response = Uniform::HTTP::Response->new(
    status  => 200,
    version => '3',
);

$response->add_trailer('cookie', 'trailer-one=1');
$response->add_trailer('x-trailer', 'preserved');
$response->add_trailer('cookie', 'trailer-two=2');

ok(
    Unblock::HTTP3::Connection::_coalesce_trailer_cookie_fields(
        $response,
    ),
    'multiple trailer Cookie field lines require coalescing',
);

is(
    $response->trailer_values('cookie'),
    [ 'trailer-one=1; trailer-two=2' ],
    'trailer Cookie field lines use the RFC delimiter',
);

is(
    [
        map {
            [
                $response->trailer_name($_),
                $response->trailer_value($_),
            ]
        } 0 .. $response->trailer_count - 1
    ],
    [
        [ 'cookie',    'trailer-one=1; trailer-two=2' ],
        [ 'x-trailer', 'preserved' ],
    ],
    'trailer Cookie coalescing preserves field ordering',
);

done_testing;
