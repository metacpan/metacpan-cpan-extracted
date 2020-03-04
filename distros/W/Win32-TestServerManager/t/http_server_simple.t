use strict;
use warnings;
use Test::More;
use Win32::TestServerManager;

BEGIN {
  eval { require HTTP::Server::Simple::CGI };
  plan skip_all => "this test requires HTTP::Server::Simple" if $@;

  eval { require LWP::UserAgent };
  plan skip_all => "this test requires LWP::UserAgent" if $@;
}

plan tests => 9;

my $server_script = 't/script/http_server_simple.pl';

# spawn ready-made perl script

my $ua = LWP::UserAgent->new;
my $response = $ua->get('http://localhost:8999');

isnt $response->code, 200, 'there is no server yet';

my $manager = Win32::TestServerManager->new;

eval {
  $manager->spawn( hss => $server_script );
};
ok !$@, 'HTTP::Server::Simple server is launched successfully';

ok $manager->pid('hss') > 0, 'and the pid is positive';

$response = $ua->get('http://127.0.0.1:8999');
is $response->code, 200, 'now server should return 200';

$manager->kill('hss');

$response = $ua->get('http://127.0.0.1:8999');

isnt $response->code, 200, 'there is no server now again';

# spawn on-the-fly perl script

my $script_source = do { open my $fh, '<', $server_script; local $/; <$fh>; };

eval {
  $manager->spawn(
    hss_on_the_fly => '',
    { create_server_with => $script_source }
  );
};
ok !$@, 'HTTP::Server::Simple server is launched successfully again';

ok $manager->pid('hss_on_the_fly') > 0, 'and the pid is positive';

$response = $ua->get('http://127.0.0.1:8999');
is $response->code, 200, 'now server should return 200';

$manager->kill('hss_on_the_fly');

$response = $ua->get('http://127.0.0.1:8999');

isnt $response->code, 200, 'there is no server now again';

