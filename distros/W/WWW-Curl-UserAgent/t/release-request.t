
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib", "$FindBin::Bin/../../lib";

use Test::More tests => 24;

use HTTP::Request;
use Test::Webserver;
use WWW::Curl::UserAgent;
use Digest::MD5 qw(md5_hex);

Test::Webserver->start_webserver_daemon;

my $base_url = 'http://localhost:3000';

{
    note 'request methods';

    my $ua = WWW::Curl::UserAgent->new;

    foreach my $method (qw/GET HEAD PUT POST DELETE/) {
        my $res =
          $ua->request( HTTP::Request->new( $method => "$base_url/code/204" ) );
        ok $res->is_success, "$method request";
    }
}

{
    note 'parallel request methods';

    my $ua = WWW::Curl::UserAgent->new;

    foreach my $method (qw/GET HEAD PUT POST DELETE/) {
        $ua->add_request(
            request    => HTTP::Request->new( $method => "$base_url/code/204" ),
            on_success => sub {
                my ( $req, $res ) = @_;
                ok $res->is_success, "parallel $method request";
            },
            on_failure => sub {
                my ( $req, $err, $err_desc ) = @_;
                fail "$err: $err_desc";
            }
        ) for ( 1 .. 2 );
    }
    $ua->perform;
}

{
    note 'chaining requests';

    my $ua = WWW::Curl::UserAgent->new;

    my $on_failure = sub {
        my ( $req, $err, $err_desc ) = @_;
        fail "$err: $err_desc";
    };

    $ua->add_request(
        request    => HTTP::Request->new( GET => "$base_url/code/204" ),
        on_failure => $on_failure,
        on_success => sub {
            my ( $req, $res ) = @_;
            ok $res->is_success, "chained request";
            $ua->add_request(
                request    => HTTP::Request->new( GET => "$base_url/code/204" ),
                on_failure => $on_failure,
                on_success => sub {
                    my ( $req, $res ) = @_;
                    ok $res->is_success, "chained request";
                },
            );
        },
    );
    $ua->perform;
}

{
    note 'failing request serves 500 code';

    my $ua  = WWW::Curl::UserAgent->new;
    my $res = $ua->request( HTTP::Request->new('/') );

    ok $res;
    is $res->code, 500;
}

{
    note 'failing request with handler';

    my $ua = WWW::Curl::UserAgent->new;
    $ua->add_request(
        request    => HTTP::Request->new('/'),
        on_success => sub { fail },
        on_failure => sub {
            my ( $req, $err, $err_desc ) = @_;
            isa_ok $req,  'HTTP::Request';
            ok $err,      "err: $err";
            ok $err_desc, "err_desc: $err_desc";
        }
    );
    $ua->perform;
}

{
    note 'put with large body';

    my $content = '';
    for (my $i = 0; $i < 20_000; $i++) {
        $content .= int(rand(10));
    }
    my $content_md5 = md5_hex($content);

    my $request = HTTP::Request->new( PUT => "$base_url/content_md5" );
    $request->content($content);

    my $ua = WWW::Curl::UserAgent->new;
    my $res = $ua->request($request);

    ok $res->is_success, "PUT request";
    is $res->content, $content_md5;
}

Test::Webserver->stop_webserver_daemon;
