use utf8;
use warnings;
use strict;
use Test::More;
use Encode 2.21 'decode_utf8', 'encode_utf8';
use lib 't/lib';

{
  package MyApp::Controller::Root;
  $INC{'MyApp/Controller/Root.pm'} = __FILE__;

  use base 'Catalyst::Controller';

  sub heart :Path('♥') {
    my ($self, $c) = @_;
    $c->response->content_type('text/html');
    $c->response->body("<p>This is path-heart action ♥</p>");
  }

  package MyApp;
  use Catalyst;

  MyApp->setup;
}

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $root = "http://localhost";
my $m = Test::WWW::Mechanize::Catalyst->new( autocheck => 0 );

if(MyApp->can('encoding') and MyApp->can('clear_encoding') and MyApp->encoding eq 'UTF-8') {
  $m->get_ok("$root/root/♥", 'got page');
  is( $m->ct, "text/html" );
  $m->content_contains("This is path-heart action ♥", 'matched expected content');
} else {
  ok 1, 'Skipping the UTF8 Tests for older installed catalyst';
}

done_testing;

