# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl WWW-ConfixxBackup.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
use WWW::ConfixxBackup::Confixx;
ok(1); # If we made it this far, we're ok.

my $confixx = WWW::ConfixxBackup::Confixx->new();
ok(ref($confixx) eq 'WWW::ConfixxBackup::Confixx');

$confixx->user('user');
$confixx->server('server');
$confixx->password('password');

ok($confixx->user eq 'user');
ok($confixx->server eq 'server');
ok($confixx->password eq 'password');

my @methods = qw(
    new
    login
    backup
    user
    password
    default_version
    confixx_version
    available_confixx_versions
    mech_warnings
    server
    mech
    proxy
    debug
    DEBUG
);

can_ok($confixx,@methods);

my ($proxy,$user,$password,$server,$confixx_version) = qw(
  http://localhost:4444
  testuser
  testpass
  http://config.test.example
  confixx2.0
);
my $obj2 = WWW::ConfixxBackup::Confixx->new(
    proxy => $proxy,
    user  => $user,
    password => $password,
    server   => $server,
    confixx_version => $confixx_version,
);
is $obj2->proxy, $proxy;
is $obj2->user, $user;
is $obj2->password,$password;
is $obj2->server, $server;
is $obj2->confixx_version, $confixx_version;

$obj2->proxy( 'http://proxy:8081' );
is $obj2->proxy, 'http://proxy:8081';