use warnings; use strict;
use Test::More;
use Test::LWP::UserAgent;
use Test::Warn;
use FindBin;

use_ok ("Web::Mention");

my $source = 'http://example.com/webmention-source';

my $good_webmention_endpoint = 'http://example.com/webmention-endpoint';
my $bad_webmention_endpoint = 'http://example.com/some-other-endpoint';

my $target = 'http://example.com/target';
my $http_target = "$target/a";
my $html_a_target = "$target/b";
my $html_link_target = "$target/c";
my $no_endpoint_target = "$target/d";
my $no_webmention_target = "$target/e";
my $garbage_target = "$target/f";
my $evil_target = "http://localhost/muhuhuhahaha";

set_up_test_useragent();

note("Valid target - Endpoint info in target's HTTP headers");
{
    Web::Mention->ua->map_response(
        qr{$http_target}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'application/x-www-form-urlencoded',
                'Link' => qq{<$good_webmention_endpoint>; rel="webmention";}
            ],
            'Look in the headers for the endpoint, genius.',
        )
    );


    my $wm = Web::Mention->new(
        source => $source,
        target => $http_target,
    );
    ok ( $wm->send );
}

note("Valid target - Endpoint info is target's HTML content (<a> tag)");
{

    Web::Mention->ua->map_response(
        qr{$html_a_target}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'text/html',
            ],
            qq{<body><p>Hey, <a href="$good_webmention_endpoint" rel="webmention">check it out</a></p></body>},
        )
    );

    my $wm = Web::Mention->new(
        source => $source,
        target => $html_a_target,
    );
    ok ( $wm->send );
}

note("Valid target - Endpoint info is target's HTML content (<link> tag)");
{
    Web::Mention->ua->map_response(
        qr{$html_link_target}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'text/html',
            ],
            qq{<body><p>Hey, <link href="$good_webmention_endpoint" rel="webmention">check it out</link></p></body>},
        )
    );
    my $wm = Web::Mention->new(
        source => $source,
        target => $html_link_target,
    );
    ok ( $wm->send );
}

note("Invalid target - Provides no endpoint URL");
{
    Web::Mention->ua->map_response(
        qr{$no_endpoint_target}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'text/html',
            ],
            qq{<body><p>Hey, <a href="$good_webmention_endpoint">check it out</link></p></body>},
        )
    );
    my $wm = Web::Mention->new(
        source => $source,
        target => $no_endpoint_target,
    );
    ok ( ! $wm->send );
}

note("Invalid target - Provides an endpoint URL, but it doesn't handle Webmention");
{
    Web::Mention->ua->map_response(
        qr{$no_webmention_target}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'text/html',
            ],
            qq{<body><p>Hey, <a href="$bad_webmention_endpoint" rel="webmention">check it out</link></p></body>},
        )
    );
    my $wm = Web::Mention->new(
        source => $source,
        target => $no_webmention_target,
    );
    ok ( ! $wm->send );
}

note("Invalid target - Provides a garbage non-URL as its endpoint");
{
    Web::Mention->ua->map_response(
        qr{$garbage_target}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'text/html',
            ],
            qq{<body><p>Hey, <a href="lol this isn't a URL!" rel="webmention">check it out</link></p></body>},
        )
    );
    my $wm = Web::Mention->new(
        source => $source,
        target => $garbage_target,
    );
    ok ( ! $wm->send );
}

note("Evil target - Specifies a loopback address as its endpont");
{
    Web::Mention->ua->map_response(
        qr{$evil_target}, HTTP::Response->new(
            200,
            'OK',
            [
                'Content-Type' => 'text/html',
            ],
            qq{<body><p>Hey, <a href="$evil_target" rel="webmention">check it out</link></p></body>},
        )
    );
    my $wm = Web::Mention->new(
        source => $source,
        target => $evil_target,
    );
    my $send_success;
    warning_like (sub{ $wm->send }, qr/loopback/);
    ok ( ! $send_success );
}

done_testing();

sub set_up_test_useragent {
    my $ua = Test::LWP::UserAgent->new;
    Web::Mention->ua( $ua );

    $ua->map_response(
        qr{$good_webmention_endpoint}, HTTP::Response->new(
            202,
            'Accepted',
            [
                'Content-Type' => 'text/plain',
            ],
            'Webmention accepted and queued. Thank you!',
         )
    );

    $ua->map_response(
        qr{$bad_webmention_endpoint}, HTTP::Response->new(
            404,
            'Huh?',
            [
                'Content-Type' => 'text/plain',
            ],
            '"Source"? "Target"? What are you talking about?',
         )
    );
}
