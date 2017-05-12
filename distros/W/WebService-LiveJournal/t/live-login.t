use strict;
use warnings;
use Test::More;
use WebService::LiveJournal::Client;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 8;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal::Client->new(
  server => $server,
  username => $user,
  password => $pass,
);

diag $WebService::LiveJournal::Client::error unless defined $client;

isa_ok $client, 'WebService::LiveJournal::Client';

is eval { $client->server },   $server, "client.server = $server";
is eval { $client->username }, $user, "client.username = $user";
is eval { $client->port },     80, 'client.port = 80';

like eval { $client->userid }, qr{^\d+$}, "client.userid = " . eval { $client->userid };
ok( eval { defined($client->fullname) && $client->fullname ne '' }, "client.fullname = " . eval { $client->fullname });

note 'client.usejournals = ' . ($client->usejournals // 'undef');
note 'client.fastserver  = ' . ($client->fastserver // 'undef');
note 'client.message     = ' . ($client->message // 'undef');

isa_ok $client->useragent, 'LWP::UserAgent';
isa_ok $client->cookie_jar, 'HTTP::Cookies';
