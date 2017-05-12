use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Path::Tiny;
use Test::LWP::UserAgent;

# the root problem here was that the real send_request calls LWP::Protocol::*
# with all the arguments, some of which are then processed via the collect()
# method -- including the option to save the content to a file.

# I thought about creating a new LWP::Protocol subclass, which did the heavy
# lifting that is in my send_request, but that's overboard, even for me... and
# after looking at LWP::Protocol::http::request, all it does after handling
# the networking itself is call $self->collect with all the args.

{
    # internally-mapped responses

    my $useragent = Test::LWP::UserAgent->new;
    $useragent->map_response(
        qr/foo.com/,
        HTTP::Response->new(
            200, 'OK',
            ['Content-Type' => 'text/plain'], 'all good!',
        ),
    );

    my $tmpfile = Path::Tiny->tempfile;

    my $response = $useragent->get(
        'http://foo.com',
        ':content_file' => $tmpfile->stringify,
    );

    my $contents = $tmpfile->slurp_utf8;
    is($contents, 'all good!', 'response body is saved to file (internal responses)');
    is($response->content, '', 'response body is removed');
    cmp_deeply(
        $response,
        methods(
            [ header => 'X-Died' ] => undef,
            [ header => 'Content-Type' ], => 'text/plain',
            [ header => 'Client-Date' ] => ignore,
        ),
        'response headers look ok',
    );
}

{
    # and another, using mirror() directly

    my $useragent = Test::LWP::UserAgent->new;
    $useragent->map_response(
        qr/foo.com/,
        HTTP::Response->new(
            200, 'OK',
            ['Content-Type' => 'text/plain'], 'all good!',
        ),
    );

    my $tmpfile = Path::Tiny->tempfile;

    my $response = $useragent->mirror('http://foo.com', $tmpfile->stringify);

    my $contents = $tmpfile->slurp_utf8;
    is($contents, 'all good!', 'response body is saved to file (internal responses)');
    is($response->content, '', 'response body is removed');
    cmp_deeply(
        $response,
        methods(
            [ header => 'X-Died' ] => undef,
            [ header => 'Content-Type' ], => 'text/plain',
            [ header => 'Client-Date' ] => ignore,
        ),
        'response headers look ok',
    );
}

done_testing;
