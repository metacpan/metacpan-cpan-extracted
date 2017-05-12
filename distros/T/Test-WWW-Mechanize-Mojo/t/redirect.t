#!perl

use strict;
use warnings;

use Test::More tests => 28;
use Test::Mojo;
use Test::WWW::Mechanize::Mojo;

use lib './t/lib';
require MyMojjy;

my $root = "http://localhost";
my $t = Test::Mojo->new();

my $m;

# TEST:$n=3;
foreach my $where (qw{hi greetings bonjour}) {
    $m = Test::WWW::Mechanize::Mojo->new(tester => $t);
    # TEST*$n
    $m->get_ok( "$root/$where", "got something when we $where" );

    # TEST*$n
    is( $m->base, "http://localhost/hello", "check got to hello 1/4" );
    # TEST*$n
    is( $m->ct, "text/html", "check got to hello 2/4" );
    # TEST*$n
    $m->title_is( "Hello",, "check got to hello 3/4" );
    # TEST*$n
    $m->content_contains( "Hi there",, "check got to hello 4/4" );

    # check that the previous response is still there
    my $prev = $m->response->previous;
    # TEST*$n
    ok( $prev, "have a previous" );
    # TEST*$n
    is( $prev->code, 302, "was a redirect" );
    # TEST*$n
    like( $prev->header('Location'), '/hello$/', "to the right place" );
}

# extra checks for bonjour (which is a double redirect)
my $prev = $m->response->previous->previous;
# TEST
ok( $prev, "have a previous previous" );
# TEST
is( $prev->code, 302, "was a redirect" );
# TEST
like( $prev->header('Location'), '/hi$/', "to the right place" );

$m->get("$root/redirect_with_500");
# TEST
is ($m->status, 500, "Redirect not followed on 500");
