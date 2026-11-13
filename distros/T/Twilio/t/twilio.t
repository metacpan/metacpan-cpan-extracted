use 5.016;
use warnings;

use Test::More;

use Twilio;

ok(!$INC{'Twilio/Rest/Client.pm'}, 'use Twilio does not load the client');

subtest 'the same client as Twilio::Rest::Client->new' => sub {
  my $client =
    Twilio->new('SKxx', 'secret', { account_sid => 'ACxx', region => 'au1', edge => 'sydney' });

  isa_ok($client, 'Twilio::Rest::Client');
  is($client->get_username,    'SKxx',   'username');
  is($client->get_password,    'secret', 'password');
  is($client->get_account_sid, 'ACxx',   'account');
  is($client->get_region,      'au1',    'region');
  is($client->get_edge,        'sydney', 'edge');
};

subtest 'credentials from the environment' => sub {
  local $ENV{TWILIO_ACCOUNT_SID} = 'ACenv';
  local $ENV{TWILIO_AUTH_TOKEN}  = 'tokenenv';
  my $client = Twilio->new;

  isa_ok($client, 'Twilio::Rest::Client');
  is($client->get_username,    'ACenv',    'username');
  is($client->get_password,    'tokenenv', 'password');
  is($client->get_account_sid, 'ACenv',    'account');
};

subtest '1.x named arguments are refused' => sub {
  for my $name (qw(sid token trace debug use_threads)) {
    my $client = eval { Twilio->new($name => 'ACxx', token => 'secret') };
    my $error  = $@;
    ok(!$client, "$name: no client");
    isa_ok($error, 'Twilio::Exceptions::ConfigurationException', $name);
    like("$error", qr/\QTwilio->new($name => ...) is the 1.x interface\E/, "$name: message");
    ok(index("$error", '($username, $password, \%options)') >= 0, "$name: the new form");
  }
};

done_testing;
