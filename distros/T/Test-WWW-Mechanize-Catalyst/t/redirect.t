#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'Catty';
use HTTP::Request::Common;
use URI;
use Test::utf8;

my $root = "http://localhost";

my $m;
foreach my $where (qw{hi greetings bonjour}) {
    $m = Test::WWW::Mechanize::Catalyst->new;
    $m->get_ok( "$root/$where", "got something when we $where" );

    is( $m->base, "http://localhost/hello", "check got to hello 1/4" );
    is( $m->ct, "text/html", "check got to hello 2/4" );
    $m->title_is( "Hello",, "check got to hello 3/4" );
    $m->content_contains( "Hi there",, "check got to hello 4/4" );

    # check that the previous response is still there
    my $prev = $m->response->previous;
    ok( $prev, "have a previous" );
    is( $prev->code, 302, "was a redirect" );
    like( $prev->header('Location'), '/hello$/', "to the right place" );
}

# extra checks for bonjour (which is a double redirect)
my $prev = $m->response->previous->previous;
ok( $prev, "have a previous previous" );
is( $prev->code, 302, "was a redirect" );
like( $prev->header('Location'), '/hi$/', "to the right place" );

$m->get("$root/redirect_with_500");
is ($m->status, 500, "Redirect not followed on 500");

my $req = GET "$root/redirect_to_utf8_upgraded_string";
my $loc = $m->_do_catalyst_request($req)->header('Location'); 
my $uri = URI->new_abs( $loc, $req->uri )->as_string;
is_sane_utf8($uri);
isnt_flagged_utf8($uri);

# Check for max_redirects support
{
    $m = Test::WWW::Mechanize::Catalyst->new(max_redirect => 1);
    is( $m->max_redirect, 1, 'max_redirect set' );

    $m->get( "$root/bonjour" );
    ok( !$m->success, "get /bonjour with max_redirect=1 is not a success" );
    is( $m->response->redirects, 1, 'redirects only once' );
    like( $m->response->header('Client-Warning'), qr/Redirect loop detected/i,
          'sets Client-Warning header' );
}

# Make sure we can handle max_redirects=0
{
    $m = Test::WWW::Mechanize::Catalyst->new(max_redirect => 0);
    $m->get( "$root/hello" );
    ok( $m->success, "get /hello with max_redirect=0 succeeds" );
    is( $m->response->redirects, 0, 'no redirects' );
    ok( !$m->response->header('Client-Warning'), 'no Client-Warning header' );

    # shouldn't be redirected if max_redirect == 0
    $m->get( "$root/bonjour" );
    ok( !$m->success, "get /bonjour with max_redirect=0 is not a success" );
    is( $m->response->redirects, 0, 'no redirects' );
    like( $m->response->header('Client-Warning'), qr/Redirect loop detected/i,
          'sets Client-Warning header' );
}

done_testing;

