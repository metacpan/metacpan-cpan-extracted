use warnings;
use strict;
use Test::More tests => 17;

use lib 't/local';
use LocalServer;

BEGIN { delete @ENV{ qw( http_proxy HTTP_PROXY ) }; }
BEGIN {
    use_ok( 'WWW::Mechanize::Pluggable' );
}

sub pre_hook {
  my ($self) = shift;
  $self->{HOOK_OUTPUT} .= "pre done ";
  1;
}

sub post_hook {
  my ($self) = shift;
  $self->{HOOK_OUTPUT} .= "and post done";
  1;
}

eval "use Test::Memory::Cycle";
my $canTMC = !$@;

my $server = LocalServer->spawn;
isa_ok( $server, 'LocalServer' );

my $mech = WWW::Mechanize::Pluggable->new;
isa_ok( $mech, 'WWW::Mechanize::Pluggable', 'Created object' );

$mech->pre_hook('get',\&pre_hook);

my $response = $mech->get($server->url);
isa_ok( $response, 'HTTP::Response' );
isa_ok( $mech->response, 'HTTP::Response' );
ok( $response->is_success );
ok( $mech->success, "Get webpage" );
is( $mech->ct, "text/html", "Got the content-type..." );
ok( $mech->is_html, "... and the is_html wrapper" );
is( $mech->title, "WWW::Mechanize::Shell test page" );
is $mech->{HOOK_OUTPUT}, "pre done ", "hooks were called";

$mech->post_hook('get',\&post_hook);

$mech->get( '/foo/' );
ok( $mech->success, 'Got the /foo' );
is( $mech->uri, sprintf('%sfoo/',$server->url), "Got relative OK" );
ok( $mech->is_html,"Got HTML back" );
is( $mech->title, "WWW::Mechanize::Shell test page", "Got the right page" );
is $mech->{HOOK_OUTPUT}, "pre done pre done and post done", "hooks were called";

SKIP: {
    skip "Test::Memory::Cycle not installed", 1 unless $canTMC;

    memory_cycle_ok( $mech, "Mech: no cycles" );
}
