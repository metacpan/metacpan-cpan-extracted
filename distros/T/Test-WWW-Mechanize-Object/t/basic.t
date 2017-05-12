#!perl

use strict;
use warnings;

use lib 'lib';
use lib 't/lib';
use Test::More 'no_plan';

use TWMO;
use Test::WWW::Mechanize::Object;
#$LWP::Debug::current_level{debug} = 1;

my $mech = Test::WWW::Mechanize::Object->new(
  handler => TWMO->new,
);

isa_ok $mech, 'Test::WWW::Mechanize::Object';

my $i;
TESTS: {
  $mech->get_ok("/", "get no pie");

  $mech->content_like(qr/to nowhere/, "got nowhere");
  $mech->content_like(qr/a void pie/, "got a void pie");
  
  $mech->get_ok(
    "/kitchen?pie=cherry", 
    "get cherry pie"
  );
  
  $mech->content_like(qr{to /kitchen},  "got to the kitchen");
  $mech->content_like(qr{a cherry pie}, "got a cherry pie");
  #diag $mech->content;
  
  $mech->get_ok(
    "/windowsill?pie=random",
    "get random pie (redirect)"
  );
  
  $mech->content_like(qr{to /windowsill}, "path preserved");
  $mech->content_unlike(qr{a random pie}, "no longer random pie");
  $mech->content_unlike(qr{a void pie},   "not a void pie either");
  #diag $mech->content;

  $mech->get_ok(
    "/cookie",
    "get cookie",
  );
  $mech->content_like(qr{to /cookie}, "got cookie url");
  like $mech->cookie_jar->as_string, qr/cookie=yummy/, "cookie set";
  #diag $mech->content;

  unless ($i++) {
    # switch to remote-possible mode and try them all again
    $ENV{TWMO_SERVER} = 'http://myserver.com/myurl';
    $mech->{handler} = TWMO::Remote->new;
    delete @{$mech}{qw(__default_url_base __url_base)};
    $mech->cookie_jar({});
    redo TESTS;
  }
}
