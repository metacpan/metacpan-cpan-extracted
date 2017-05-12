use strict;
use warnings;

BEGIN {
    use Test::Mock::Apache2 { SomeConfig => 42, OtherConfig => 'foo', server_hostname => 'myhost', };
}

use Test::More tests => 14;

my $u = Apache2::RequestUtil->new();
ok($u, 'Apache2::RequestUtil->new returns something');
isa_ok($u, 'Apache2::RequestUtil', '... an Apache2::RequestUtil object');
ok($u->dir_config("SomeConfig"), "SomeConfig exists");
is($u->dir_config("SomeConfig"), 42, "SomeConfig is 42");
is($u->dir_config("OtherConfig"), 'foo', "OtherConfig is 'foo'");

# $r->dir_config should also work
my $r = $u->request();
ok($r, 'Apache2::RequestUtil->request() returns something');
isa_ok($r, 'Apache2::RequestRec');
ok($r->dir_config("SomeConfig"), "SomeConfig exists");
is($r->dir_config("SomeConfig"), 42, "SomeConfig is 42");
is($r->dir_config("OtherConfig"), 'foo', "OtherConfig is 'foo'");

# $r->server->server_hostname
my $s = $r->server();
ok($s, 'Apache2::RequestUtil->server() returns something');
isa_ok($s, 'Apache2::ServerRec');
ok($s->server_hostname, "server_hostname (ServerName) exists");
is($s->server_hostname, "myhost", "server_hostname returns correct value");


# Fin

