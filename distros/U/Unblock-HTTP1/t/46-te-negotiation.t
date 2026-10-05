use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Uniform::HTTP::Response;
use Unblock::HTTP1::_Wire;

sub request_with {
    my (@headers) = @_;
    return Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        headers => [
            [ Host => 'example.test' ],
            @headers,
        ],
    );
}

subtest 'TE automatically carries the Connection option' => sub {
    my $request = request_with([ TE => 'trailers, deflate;q=0.5' ]);
    my $plan = Unblock::HTTP1::_Wire::request_plan($request);

    like($plan->{wire}, qr/\r\nTE: trailers, deflate;q=0\.5\r\n/,
        'TE field is preserved');
    like($plan->{wire}, qr/\r\nConnection: TE\r\n/,
        'Connection TE is synthesized on the wire');
    ok($plan->{keep_alive}, 'Connection TE does not disable persistence');
};

subtest 'TE is appended to an existing Connection field' => sub {
    my $request = request_with(
        [ Connection => 'close' ],
        [ TE => 'deflate' ],
    );
    my $plan = Unblock::HTTP1::_Wire::request_plan($request);

    like($plan->{wire}, qr/\r\nConnection: close, TE\r\n/,
        'TE token is appended to existing Connection options');
    ok(!$plan->{keep_alive}, 'existing close option still controls persistence');
};

subtest 'invalid TE sender forms are rejected' => sub {
    for my $case (
        [ 'chunked', qr/must not list the chunked/ ],
        [ 'trailers;q=0.5', qr/trailers TE keyword must not have parameters/ ],
        [ 'deflate;q=2', qr/invalid TE qvalue/ ],
        [ 'deflate;q="0.5"', qr/qvalue must not be quoted/ ],
        [ 'deflate;q=0.5;level=1', qr/qvalue must be the final parameter/ ],
    ) {
        my ($value, $pattern) = @$case;
        my $ok = eval {
            Unblock::HTTP1::_Wire::request_plan(
                request_with([ TE => $value ])
            );
            1;
        };
        ok(!$ok, "$value is rejected");
        like($@, $pattern, "$value has an explicit TE error");
    }
};

subtest 'HTTP/1.0 cannot emit TE' => sub {
    my $request = Uniform::HTTP::Request->new(
        method  => 'GET',
        target  => '/',
        version => '1.0',
        headers => [ [ TE => 'trailers' ] ],
    );

    my $ok = eval {
        Unblock::HTTP1::_Wire::request_plan($request);
        1;
    };
    ok(!$ok, 'HTTP/1.0 TE is rejected');
    like($@, qr/HTTP\/1\.0 request cannot send TE/,
        'HTTP/1.0 TE error is explicit');
};

subtest 'response transfer coding honors TE qvalue' => sub {
    my $response = Uniform::HTTP::Response->new(
        status  => 200,
        headers => [ [ 'Transfer-Encoding' => 'deflate, chunked' ] ],
        body    => 'encoded',
    );

    my $accepted = request_with(
        [ Connection => 'TE' ],
        [ TE => 'deflate;q=0.25' ],
    );
    my $plan = Unblock::HTTP1::_Wire::response_plan(
        $accepted, $response,
    );
    is($plan->{mode}, 'chunked',
        'positive TE qvalue permits the transfer coding');

    my $refused = request_with(
        [ Connection => 'TE' ],
        [ TE => 'deflate;q=0' ],
    );
    my $ok = eval {
        Unblock::HTTP1::_Wire::response_plan($refused, $response);
        1;
    };
    ok(!$ok, 'zero TE qvalue refuses the transfer coding');
    like($@, qr/not accepted by request TE: deflate/,
        'zero-quality transfer coding error is explicit');
};

done_testing;
