use 5.016;
use warnings;

use Test::More;

use Scalar::Util qw(weaken);
use Time::Piece  ();

use Twilio::Http::FakeClient;
use Twilio::Rest::Client;

my $ACCOUNT = 'ACxx';
my $SID     = 'SM00000000000000000000000000000001';
my $BASE    = "https://api.twilio.com/2010-04-01/Accounts/$ACCOUNT";

my %MESSAGE = (
  account_sid           => $ACCOUNT,
  api_version           => '2010-04-01',
  body                  => 'Hello',
  date_created          => 'Thu, 30 Jul 2015 20:12:31 +0000',
  date_sent             => 'Thu, 30 Jul 2015 20:12:33 +0000',
  date_updated          => 'Thu, 30 Jul 2015 20:12:34 +0000',
  direction             => 'outbound-api',
  error_code            => undef,
  error_message         => undef,
  from                  => '+15017250604',
  messaging_service_sid => 'MGxx',
  num_media             => '0',
  num_segments          => '1',
  price                 => '-0.00750',
  price_unit            => 'USD',
  sid                   => $SID,
  status                => 'sent',
  subresource_uris      => { media => "/2010-04-01/Accounts/$ACCOUNT/Messages/$SID/Media.json" },
  to                    => '+15558675309',
  uri                   => "/2010-04-01/Accounts/$ACCOUNT/Messages/$SID.json",
);

sub client {
  my ($options) = @_;
  my $http = Twilio::Http::FakeClient->new;
  return ($http,
    Twilio::Rest::Client->new($ACCOUNT, 'secret', { http_client => $http, %{ $options // {} } }));
}

sub only_request {
  my ($http) = @_;
  my @requests = $http->requests;
  is(scalar @requests, 1, 'one request');
  return $requests[0];
}

sub message_page {
  my ($next, @sids) = @_;
  return {
    messages      => [map { +{ %MESSAGE, sid => $_ } } @sids],
    next_page_uri => $next,
  };
}

sub sids {
  return [map { $_->sid } @_];
}

subtest 'send a message, as in the documentation' => sub {
  my ($http, $client) = client();
  $http->mock(201, {%MESSAGE});

  my $message = $client->messages->create(
    '+15558675309',
    {
      from => '+15017250604',
      body => 'Hello',
    }
  );

  isa_ok($message, 'Twilio::Rest::Api::V2010::Account::MessageInstance');
  is($message->sid, $SID, 'sid');

  my $request = only_request($http);
  is($request->{method}, 'POST',                'POST');
  is($request->{url},    "$BASE/Messages.json", 'url');
  is(
    $request->{content},
    'Body=Hello&From=%2B15017250604&To=%2B15558675309',
    'only what was given is sent'
  );
  is($request->{headers}{'Content-Type'}, 'application/x-www-form-urlencoded', 'form');
  is($request->{headers}{Accept},         'application/json',                  'accepts JSON');
  like($request->{headers}{Authorization}, qr/\ABasic /, 'authenticated on the first request');
};

subtest 'every create option reaches its wire name' => sub {
  my ($http, $client) = client();
  $http->mock(201, {});

  $client->messages->create(
    '+1',
    {
      address_retention     => 'retain',
      application_sid       => 'APxx',
      attempt               => 2,
      content_retention     => 'retain',
      content_sid           => 'HXxx',
      content_variables     => '{"1":"a"}',
      fallback_from         => '+2',
      force_delivery        => 1,
      from                  => '+3',
      max_price             => '0.5',
      media_url             => ['https://a.test/1.png', 'https://a.test/2.png'],
      message_intent        => 'otp',
      messaging_service_sid => 'MGxx',
      persistent_action     => ['geo:1,2'],
      provide_feedback      => 1,
      risk_check            => 'enable',
      schedule_type         => 'fixed',
      send_as_mms           => 0,
      send_at               => scalar Time::Piece->gmtime(1_438_287_151),
      shorten_urls          => 'true',
      smart_encoded         => 'false',
      status_callback       => 'https://a.test/cb',
      traffic_type          => 'free',
      validity_period       => 60,
      body                  => 'Hi',
    }
  );

  my %sent;
  for my $pair (split /&/, only_request($http)->{content}) {
    my ($key, $value) = split /=/, $pair;
    push @{ $sent{$key} }, $value;
  }

  is_deeply(
    \%sent,
    {
      AddressRetention    => ['retain'],
      ApplicationSid      => ['APxx'],
      Attempt             => [2],
      Body                => ['Hi'],
      ContentRetention    => ['retain'],
      ContentSid          => ['HXxx'],
      ContentVariables    => ['%7B%221%22%3A%22a%22%7D'],
      FallbackFrom        => ['%2B2'],
      ForceDelivery       => ['true'],
      From                => ['%2B3'],
      MaxPrice            => ['0.5'],
      MediaUrl            => ['https%3A%2F%2Fa.test%2F1.png', 'https%3A%2F%2Fa.test%2F2.png'],
      MessageIntent       => ['otp'],
      MessagingServiceSid => ['MGxx'],
      PersistentAction    => ['geo%3A1%2C2'],
      ProvideFeedback     => ['true'],
      RiskCheck           => ['enable'],
      ScheduleType        => ['fixed'],
      SendAsMms           => ['false'],
      SendAt              => ['2015-07-30T20%3A12%3A31Z'],
      ShortenUrls         => ['true'],
      SmartEncoded        => ['false'],
      StatusCallback      => ['https%3A%2F%2Fa.test%2Fcb'],
      To                  => ['%2B1'],
      TrafficType         => ['free'],
      ValidityPeriod      => [60],
    },
    'wire names'
  );
};

subtest 'a rejected message throws what Twilio said' => sub {
  my ($http, $client) = client();
  $http->mock(
    400,
    {
      code      => 21211,
      message   => "The 'To' number is not valid",
      more_info => 'https://www.twilio.com/docs/errors/21211',
      status    => 400,
    }
  );

  my $ok    = eval { $client->messages->create('nope', { from => '+1', body => 'x' }); 1 };
  my $error = $@;

  ok(!$ok, 'died');
  isa_ok($error, 'Twilio::Exceptions::RestException');
  is($error->get_code,        21211, 'Twilio code');
  is($error->get_status_code, 400,   'HTTP status');
  is(
    $error->get_message,
    "[HTTP 400] Unable to create record: The 'To' number is not valid",
    'message like PHP'
  );
};

subtest 'read returns a list and honours the limit' => sub {
  my ($http, $client) = client();
  $http->mock(200, message_page(undef, 'SM1', 'SM2', 'SM3'));

  my @messages = $client->messages->read({}, 2);

  is_deeply(sids(@messages), ['SM1', 'SM2'], 'two messages');
  isa_ok($messages[0], 'Twilio::Rest::Api::V2010::Account::MessageInstance');
  is(only_request($http)->{url}, "$BASE/Messages.json?PageSize=2", 'limit used as page size');
};

subtest 'read works with no arguments, across pages' => sub {
  my ($http, $client) = client();
  my $next = "/2010-04-01/Accounts/$ACCOUNT/Messages.json?Page=1&PageToken=PA1";
  $http->mock(200, message_page($next, 'SM1'))->mock(200, message_page(undef, 'SM2'));

  is_deeply(sids($client->messages->read), ['SM1', 'SM2'], 'all messages');

  my @requests = $http->requests;
  is($requests[0]{url}, "$BASE/Messages.json",         'first page');
  is($requests[1]{url}, "https://api.twilio.com$next", 'second page');
};

subtest 'read filters reach their wire names' => sub {
  my ($http, $client) = client();
  $http->mock(200, message_page(undef));

  $client->messages->read(
    {
      to               => '+1',
      from             => '+2',
      date_sent        => '2015-07-30',
      date_sent_before => scalar Time::Piece->gmtime(1_438_287_151),
      date_sent_after  => '2015-07-29',
    }
  );

  is(
    only_request($http)->{url},
    "$BASE/Messages.json?"
      . 'DateSent=2015-07-30&DateSent%3C=2015-07-30T20%3A12%3A31Z&DateSent%3E=2015-07-29'
      . '&From=%2B2&To=%2B1',
    'url'
  );
};

subtest 'stream walks the pages one record at a time' => sub {
  my ($http, $client) = client();
  my $next = "/2010-04-01/Accounts/$ACCOUNT/Messages.json?Page=1";
  $http->mock(200, message_page($next, 'SM1'))->mock(200, message_page(undef, 'SM2'));

  my $stream = $client->messages->stream({}, 100, 50);

  isa_ok($stream, 'Twilio::Stream');
  is(scalar($http->requests), 1,     'second page is not fetched yet');
  is($stream->next->sid,      'SM1', 'first');
  is(scalar($http->requests), 1,     'still not');
  is($stream->next->sid,      'SM2', 'second');
  is(scalar($http->requests), 2,     'now it is');
  is($stream->next,           undef, 'end');

  like(($http->requests)[0]{url}, qr/PageSize=50\b/, 'page size');
};

subtest 'page fetches one page' => sub {
  my ($http, $client) = client();
  my $next = "/2010-04-01/Accounts/$ACCOUNT/Messages.json?Page=1&PageToken=PA1";
  $http->mock(200, message_page($next, 'SM1'))->mock(200, message_page(undef, 'SM2'));

  my $page = $client->messages->page({ to => '+1' }, 50, 'PA0', 3);
  isa_ok($page, 'Twilio::Rest::Api::V2010::Account::MessagePage');
  is(($http->requests)[0]{url},
    "$BASE/Messages.json?Page=3&PageSize=50&PageToken=PA0&To=%2B1", 'url');

  my ($message) = $page->records;
  is($message->sid,                     'SM1',    'record');
  is($message->{solution}{account_sid}, $ACCOUNT, 'record knows its account');

  is_deeply(sids($page->next_page->records), ['SM2'], 'next page');
};

subtest 'a new list in the response does not confuse a message page' => sub {
  my ($http, $client) = client();
  $http->mock(200, { %{ message_page(undef, 'SM1') }, notices => ['new'] });

  is_deeply(sids($client->messages->read), ['SM1'], 'messages found by name');
};

subtest 'get_page follows a URL from Twilio' => sub {
  my ($http, $client) = client();
  my $url = "$BASE/Messages.json?Page=7&PageToken=PA7";
  $http->mock(200, message_page(undef, 'SM7'));

  my $page = $client->messages->get_page($url);

  isa_ok($page, 'Twilio::Rest::Api::V2010::Account::MessagePage');
  is_deeply(sids($page->records), ['SM7'], 'record');
  is(only_request($http)->{url}, $url, 'url');
};

subtest 'fetch' => sub {
  my ($http, $client) = client();
  $http->mock(200, {%MESSAGE});

  my $message = $client->messages($SID)->fetch;

  isa_ok($message, 'Twilio::Rest::Api::V2010::Account::MessageInstance');
  is($message->body, 'Hello', 'body');

  my $request = only_request($http);
  is($request->{method}, 'GET',                      'GET');
  is($request->{url},    "$BASE/Messages/$SID.json", 'url');
};

subtest 'update' => sub {
  my ($http, $client) = client();
  $http->mock(200, { %MESSAGE, body => q{}, status => 'canceled' });

  my $message = $client->messages($SID)->update({ body => q{}, status => 'canceled' });

  is($message->status, 'canceled', 'result');

  my $request = only_request($http);
  is($request->{method},  'POST',                     'POST');
  is($request->{url},     "$BASE/Messages/$SID.json", 'url');
  is($request->{content}, 'Body=&Status=canceled',    'an empty body is sent, to redact the text');
};

subtest 'update with nothing to change' => sub {
  my ($http, $client) = client();
  $http->mock(200, {%MESSAGE});

  $client->messages($SID)->update;
  is(only_request($http)->{content}, q{}, 'empty body');
};

subtest 'delete' => sub {
  my ($http, $client) = client();
  $http->mock(204, q{});

  ok($client->messages($SID)->delete, 'true');

  my $request = only_request($http);
  is($request->{method}, 'DELETE',                   'DELETE');
  is($request->{url},    "$BASE/Messages/$SID.json", 'url');
  ok(!exists $request->{headers}{Accept}, 'no Accept header');

  # twilio-python's test_delete_with_invalid_json: the body of a delete is never read.
  ($http, $client) = client();
  $http->mock(200, '<html>deleted</html>');
  ok($client->messages($SID)->delete, 'a body that is not JSON is still a success');
};

subtest 'failures of each operation throw and name it' => sub {
  my @cases = (
    ['fetch',  sub { $_[0]->fetch }],
    ['update', sub { $_[0]->update({ body => q{} }) }],
    ['delete', sub { $_[0]->delete }],
  );

  for my $case (@cases) {
    my ($operation, $call)   = @{$case};
    my ($http,      $client) = client();
    $http->mock(404, { code => 20404, message => 'Not found' });

    my $ok    = eval { $call->($client->messages($SID)); 1 };
    my $error = $@;

    ok(!$ok, "$operation died");
    is($error->get_message, "[HTTP 404] Unable to $operation record: Not found", 'message');
    is($error->get_code,    20404,                                               'code');
  }
};

subtest 'an instance acts on itself' => sub {
  my ($http, $client) = client();
  $http->mock(200, {%MESSAGE});
  my $message = $client->messages($SID)->fetch;

  $http->mock(200, { %MESSAGE, status => 'delivered' });
  is($message->fetch->status, 'delivered', 'fetch returns the new state');
  is($message->status,        'sent',      'the old object is unchanged');

  $http->mock(200, { %MESSAGE, body => q{} });
  is($message->update({ body => q{} })->body, q{}, 'update');

  $http->mock(204, q{});
  ok($message->delete, 'delete');

  my @requests = $http->requests;
  is($requests[$_]{url},   "$BASE/Messages/$SID.json", "request $_ url") for 1 .. 3;
  is($requests[3]{method}, 'DELETE',                   'last one is DELETE');
};

subtest 'an instance built from a create response can act too' => sub {
  my ($http, $client) = client();
  $http->mock(201, {%MESSAGE})->mock(200, {%MESSAGE});

  $client->messages->create('+1', { body => 'x' })->fetch;
  is(($http->requests)[1]{url}, "$BASE/Messages/$SID.json", 'sid from the payload');
};

subtest 'every field has an accessor' => sub {
  my ($http, $client) = client();
  $http->mock(200, {%MESSAGE});
  my $message = $client->messages($SID)->fetch;

  my %dates = map { $_ => 1 } qw(date_created date_sent date_updated);
  for my $field (grep { !$dates{$_} } sort keys %MESSAGE) {
    is_deeply($message->$field, $MESSAGE{$field}, $field);
  }

  isa_ok($message->date_created, 'Time::Piece', 'date_created');
  is($message->date_created->datetime, '2015-07-30T20:12:31', 'date_created value');
  is($message->date_sent->datetime,    '2015-07-30T20:12:33', 'date_sent value');
  is($message->date_updated->datetime, '2015-07-30T20:12:34', 'date_updated value');
};

subtest 'dates are one value in list context' => sub {
  my ($http, $client) = client();
  $http->mock(200, {%MESSAGE});

  my @values = ($client->messages($SID)->fetch->date_created);
  is(scalar @values, 1, 'one value');
  isa_ok($values[0], 'Time::Piece');
};

subtest 'dates that have not happened yet are undef' => sub {
  my ($http, $client) = client();
  $http->mock(200, { %MESSAGE, date_sent => undef });
  is($client->messages($SID)->fetch->date_sent, undef, 'undef');
};

subtest 'fields newer than the library are kept' => sub {
  my ($http, $client) = client();
  $http->mock(200, { %MESSAGE, brand_new_field => 'value' });
  my $message = $client->messages($SID)->fetch;

  is($message->sid,                        $SID,    'known fields work');
  is($message->to_hash->{brand_new_field}, 'value', 'new one reachable');
};

subtest 'sids are encoded in the path' => sub {
  my ($http, $client) = client();
  $http->mock(200, {});

  $client->messages('a/b')->fetch;
  is(only_request($http)->{url}, "$BASE/Messages/a%2Fb.json", 'cannot leave the resource path');
};

subtest 'API keys act on the account they are given' => sub {
  my $http   = Twilio::Http::FakeClient->new;
  my $client = Twilio::Rest::Client->new(
    'SKxx', 'secret',
    {
      account_sid => 'ACother',
      http_client => $http,
    }
  );
  $http->mock(200, message_page(undef));

  $client->messages->read;
  like(only_request($http)->{url}, qr{/Accounts/ACother/Messages[.]json}, 'url');
};

subtest 'edge and region apply to every operation' => sub {
  my ($http, $client) = client({ edge => 'dublin', region => 'ie1' });
  $http->mock(201, {%MESSAGE})->mock(200, {%MESSAGE});

  $client->messages->create('+1', { body => 'x' });
  $client->messages($SID)->fetch;

  like($_->{url}, qr{\Ahttps://api[.]dublin[.]ie1[.]twilio[.]com/}, 'routed') for $http->requests;
};

subtest 'the long route reaches the same place' => sub {
  my ($http, $client) = client();
  $http->mock(200, message_page(undef))->mock(200, message_page(undef));

  my $list = $client->api->v2010->account->messages;
  isa_ok($list, 'Twilio::Rest::Api::V2010::Account::MessageList');
  $list->read;

  $list = $client->account->messages;
  $list->read;

  my @requests = $http->requests;
  is($requests[$_]{url}, "$BASE/Messages.json", "route $_") for 0, 1;
};

subtest 'get_context matches the short form' => sub {
  my (undef, $client) = client();

  my $context = $client->messages->get_context($SID);
  isa_ok($context, 'Twilio::Rest::Api::V2010::Account::MessageContext');
  is_deeply($context->{solution}, $client->messages($SID)->{solution}, 'same message');
};

subtest 'a context makes no request until asked' => sub {
  my ($http, $client) = client();
  $client->messages($SID);
  is(scalar($http->requests), 0, 'nothing sent');
};

# twilio-php caches these objects, which would be a reference cycle in Perl. A long-running
# process would keep every client it ever created.
subtest 'clients are freed' => sub {
  my $weak;
  {
    my ($http, $client) = client();
    $http->mock(200, message_page(undef, 'SM1'));
    $client->messages->read;
    $client->messages($SID);
    $weak = $client;
    weaken($weak);
  }
  is($weak, undef, 'nothing keeps the client alive');
};

subtest 'an object keeps its client alive' => sub {
  my $list = do {
    my (undef, $client) = client();
    $client->messages;
  };

  my $http = $list->{version}->get_domain->get_client->get_http_client;
  $http->mock(200, message_page(undef, 'SM1'));
  is_deeply(sids($list->read), ['SM1'], 'still usable after the client variable is gone');
};

done_testing;
