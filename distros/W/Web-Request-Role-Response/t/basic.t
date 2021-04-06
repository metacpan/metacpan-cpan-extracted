use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use Web::Request;
use utf8;

# Generate a temp request class based on Web::Request and W:R:Role::JSON
my $req_class = Moose::Meta::Class->create(
    'MyReq',
    superclasses => ['Web::Request'],
    roles        => ['Web::Request::Role::Response'],
    methods      => {
        default_encoding => sub {'UTF-8'},
        uri_for          => sub {
            my ( $self, $uri ) = @_;
            return join( '/', '', $uri->{controller}, $uri->{action} );
        }
    }
);

# The fake app we use for testing
my $handler = builder {
    sub {
        my $env  = shift;
        my $req  = $req_class->name->new_from_env($env);
        my $path = $env->{PATH_INFO};

        my %dispatch = (
            # redirect
            '/redirect'           => [ redirect => '/new/location' ],
            '/redirect/absolute'  => [ redirect => 'http://example.com' ],
            '/redirect/uri-for'   => [ redirect => { controller => 'foo',
                                                     action     => 'bar' } ],
            '/redirect/307'       => [ redirect => '/we-love-specs', 307 ],
            '/redirect/permanent' => [ permanent_redirect => '/gone' ],
            '/redirect/URI'       => [ redirect =>
                                       URI->new('http://example.com') ],
            # file_download
            '/download'           => [ file_download_response =>
                                       'text/csv', 'a;b;c', 'alphabet.csv' ],
            # no_content
            '/no-content'         => [ 'no_content_response' ],

            # transparent_gif
            '/pixel'              => [ 'transparent_gif_response' ],
        );
        my ($method, @args) = @{ $dispatch{$path} };
        my $res = $req->$method(@args);
        return $res->finalize;
    };
};

# and finally the tests!
test_psgi(
    app    => $handler,
    client => sub {
        my $cb = shift;

        subtest 'redirect' => sub {
            subtest 'redirect string' => sub {
                my $res = $cb->( GET "http://localhost/redirect" );
                is( $res->code,               302,             'status 302' );
                is( $res->header('Location'), '/new/location', 'Location' );
            };

            subtest 'redirect absolute' => sub {
                my $res = $cb->( GET "http://localhost/redirect/absolute" );
                is( $res->code, 302, 'status 302' );
                is( $res->header('Location'),
                    'http://example.com', 'Location' );
            };
            subtest 'redirect uri_for' => sub {
                my $res = $cb->( GET "http://localhost/redirect/uri-for" );
                is( $res->code,               302,        'status 302' );
                is( $res->header('Location'), '/foo/bar', 'Location' );
            };
            subtest 'redirect 307' => sub {
                my $res = $cb->( GET "http://localhost/redirect/307" );
                is( $res->code,               307,     'status 307' );
                is( $res->header('Location'), '/we-love-specs', 'Location' );
            };
            subtest 'redirect permanent' => sub {
                my $res = $cb->( GET "http://localhost/redirect/permanent" );
                is( $res->code,               301,     'status 301' );
                is( $res->header('Location'), '/gone', 'Location' );
            };
            subtest 'redirect URI' => sub {
                my $res = $cb->( GET "http://localhost/redirect/URI" );
                is( $res->code,               302,     'status 302' );
                is( $res->header('Location'), 'http://example.com', 'Location' );
            };
        };

        subtest 'file_download csv' => sub {
            my $res = $cb->( GET "http://localhost/download" );
            is( $res->code, 200, 'status 200' );

            is( $res->content_type, 'text/csv', 'Content-Type' );
            my $dispo = $res->header('content-disposition');
            like( $dispo, qr/^attachment;/, 'disposition: attachment' );
            like( $dispo, qr/filename=alphabet.csv/,
                'disposition: filename' );
            is( $res->content, 'a;b;c', 'content' );
        };

        subtest 'no-content' => sub {
            my $res = $cb->( GET "http://localhost/no-content" );
            is( $res->code,    204, 'status 204' );
            is( $res->content, '',  'no content' );
        };

        subtest 'transparent_gif' => sub {
            my $res = $cb->( GET "http://localhost/pixel" );
            is( $res->code,           200,         'status 200' );
            is( $res->content_type,   'image/gif', 'gif' );
            is( $res->content_length, 42,          'content-length' );
            is( unpack( 'H*', $res->content ),
                '47494638396101000100800000000000ffffff21f90401000000002c000000000100010000020144003b',
                'payload: transparent pixel'
            );
        };
    }
);

done_testing;
