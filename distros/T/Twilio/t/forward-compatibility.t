use 5.016;
use warnings;

use Test::More;

use Twilio::Http::FakeClient;
use Twilio::Rest::Client;

# Twilio adds fields, drops them and adds enum values without notice. These are the cases of
# twilio-php's ResponseForwardCompatibilityTest and twilio-python's test_forward_compatibility:
# nothing new may break a response, and nothing it holds may be lost.

my $MESSAGE_SID = 'SM' . ('0' x 32);
my $SENDER_SID  = 'XE' . ('0' x 32);

my %MESSAGE = (
  sid              => $MESSAGE_SID,
  account_sid      => 'ACxx',
  body             => 'Hello owl',
  status           => 'sent',
  subresource_uris => { media => "/2010-04-01/Accounts/ACxx/Messages/$MESSAGE_SID/Media.json" },
  date_created     => 'Thu, 30 Jul 2015 20:12:31 +0000',
);

subtest 'a field removed from a record reads as undef' => sub {
  my %payload = %MESSAGE;
  delete @payload{qw(body status subresource_uris)};
  my $message = fetch_message(\%payload);

  is($message->sid,              $MESSAGE_SID, 'the fields left still read');
  is($message->body,             undef,        'body');
  is($message->status,           undef,        'status');
  is($message->subresource_uris, undef,        'subresource_uris');
};

subtest 'an enum value newer than the library is kept' => sub {
  is(fetch_message({ %MESSAGE, status => 'eagerly_delivered' })->status,
    'eagerly_delivered', 'status');
};

subtest 'an empty record is an empty instance' => sub {
  my $message = fetch_message({});

  isa_ok($message, 'Twilio::Rest::Api::V2010::Account::MessageInstance');
  is($message->sid,    undef, 'sid');
  is($message->status, undef, 'status');
  is_deeply($message->to_hash, {}, 'no fields');
};

subtest 'a field with no accessor is not a method' => sub {
  my $message = fetch_message({ %MESSAGE, brand_new_field => 'value' });

  ok(!$message->can('brand_new_field'), 'no accessor');
  my $ok = eval { $message->brand_new_field; 1 };
  ok(!$ok, 'calling one dies, as in twilio-php');
  is($message->to_hash->{brand_new_field}, 'value', 'the value is in to_hash');
};

subtest 'new fields inside nested objects are kept' => sub {
  my $sender = fetch_sender(
    sender(
      configuration =>
        { waba_id => '1234567890', verification_method => 'sms', new_setting => 'on' },
      compliance => compliance({ name => 'AT&T', status => 'ACTIVE', new_detail => 1 }),
    )
  );

  is($sender->configuration->{waba_id},                      '1234567890', 'a known nested field');
  is($sender->configuration->{new_setting},                  'on',         'a new nested field');
  is($sender->compliance->{countries}[0]{carriers}[0]{name}, 'AT&T',       'deep in a list');
  is($sender->compliance->{countries}[0]{carriers}[0]{new_detail}, 1,      'a new field there');
};

subtest 'a field removed inside a nested object leaves its siblings' => sub {
  my $sender = fetch_sender(
    sender(
      configuration => { verification_method => 'sms' },
      compliance    => { countries           => [{ country => 'US' }] },
    )
  );

  ok(!exists $sender->configuration->{waba_id}, 'the removed field is gone');
  is($sender->configuration->{verification_method}, 'sms', 'its sibling stays');
  ok(!exists $sender->compliance->{countries}[0]{carriers}, 'a removed list is gone');
  is($sender->compliance->{countries}[0]{country}, 'US', 'its sibling stays');
};

subtest 'a nested object removed whole reads as undef' => sub {
  my $sender = fetch_sender(sender());

  is($sender->configuration,   undef,      'configuration');
  is($sender->compliance,      undef,      'compliance');
  is($sender->profile->{name}, 'Owl Shop', 'the other objects stay');
};

subtest 'a new item in a nested list is kept' => sub {
  my $sender = fetch_sender(
    sender(
      offline_reasons => [
        { code => '30001', message => 'Queue overflow' },
        { code => '39999', message => 'Brand new reason' },
      ]
    )
  );

  is(scalar @{ $sender->offline_reasons },   2,                  'both items');
  is($sender->offline_reasons->[1]{message}, 'Brand new reason', 'the new one');
};

subtest 'an enum value newer than the library is kept inside a nested list' => sub {
  my $sender =
    fetch_sender(sender(compliance => compliance({ name => 'AT&T', status => 'LAUNCHING' })));

  is($sender->compliance->{countries}[0]{carriers}[0]{status}, 'LAUNCHING', 'status');
};

subtest 'records read from a list keep new fields too' => sub {
  my ($http, $client) = client();
  $http->mock(
    200,
    {
      senders => [sender(new_top_field => 'x', configuration => { new_setting => 'on' })],
      meta    => { key => 'senders', page => 0, page_size => 50, next_page_url => undef },
    }
  );
  my ($sender) = $client->messaging->v2->channels_senders->read;

  is($sender->sid,                          $SENDER_SID, 'a known field');
  is($sender->to_hash->{new_top_field},     'x',         'a new top-level field');
  is($sender->configuration->{new_setting}, 'on',        'a new nested field');
};

# twilio-php checks an answer that has its own shape with MemoryRetrievalResponseInstance; ours
# is RecallInstance, the class of the only operation Recall has.
subtest 'an answer with its own shape: new fields at both levels are kept' => sub {
  my $recall = recall(
    recall_payload(
      meta           => { queryTime => 120, new_metric => 7 },
      communications =>
        [{ author => { id => 'PT1', name => 'Agent Owl', channel => 'SMS', new_flag => 1 } }],
      brand_new => 'x',
    )
  );

  is($recall->meta->{queryTime},                     120,         'a known nested field');
  is($recall->meta->{new_metric},                    7,           'a new nested field');
  is($recall->communications->[0]{author}{name},     'Agent Owl', 'deep in a list');
  is($recall->communications->[0]{author}{new_flag}, 1,           'a new field there');
  is($recall->to_hash->{brand_new},                  'x',         'a new top-level field');
};

subtest 'an answer with its own shape: removed fields at both levels' => sub {
  my $recall =
    recall(recall_payload(communications => [{ author => { id => 'PT1', channel => 'SMS' } }]));

  is($recall->meta, undef, 'a removed object');
  ok(!exists $recall->communications->[0]{author}{name}, 'a removed nested field');
  is($recall->communications->[0]{author}{id},      'PT1', 'its siblings stay');
  is($recall->communications->[0]{author}{channel}, 'SMS', 'all of them');
};

subtest 'an answer with its own shape: a new enum value in a nested list' => sub {
  my $recall = recall(
    recall_payload(
      communications => [{ author => { id => 'PT1', channel => 'RCS_BUSINESS_MESSAGING' } }]
    )
  );

  is($recall->communications->[0]{author}{channel}, 'RCS_BUSINESS_MESSAGING', 'channel');
};

done_testing;

sub client {
  my $http = Twilio::Http::FakeClient->new;
  return ($http, Twilio::Rest::Client->new('ACxx', 'secret', { http_client => $http }));
}

sub fetch_message {
  my ($payload) = @_;
  my ($http, $client) = client();
  $http->mock(200, $payload);
  return $client->messages($MESSAGE_SID)->fetch;
}

sub fetch_sender {
  my ($payload) = @_;
  my ($http, $client) = client();
  $http->mock(200, $payload);
  return $client->messaging->v2->channels_senders($SENDER_SID)->fetch;
}

sub sender {
  my (%fields) = @_;
  return {
    sid       => $SENDER_SID,
    status    => 'ONLINE',
    sender_id => 'whatsapp:+15550001111',
    profile   => { name => 'Owl Shop' },
    %fields,
  };
}

sub compliance {
  my ($carrier) = @_;
  return { countries => [{ country => 'US', carriers => [$carrier] }] };
}

sub recall {
  my ($payload) = @_;
  my ($http, $client) = client();
  $http->mock(200, $payload);
  return $client->memory->v1->recall('mem_store_1', 'mem_profile_1')->create({ query => 'owls' });
}

sub recall_payload {
  my (%fields) = @_;
  return { observations => [], summaries => [], communications => [], %fields };
}
