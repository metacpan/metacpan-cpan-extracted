use 5.016;
use warnings;

use Scalar::Util qw(blessed);
use Test::More;

# Free calls to the real API, to see that Twilio accepts what t/contract.t shows the classes send.
# Nothing here sends a message, makes a call or buys a number. With TWILIO_LIVE_TESTS=1 alone the
# calls only read. TWILIO_LIVE_WRITES=1 adds checks that create free resources, whose names start
# with twilio-perl-live-, and delete them before they end, even when they fail.
my %live =
  map { $_ => $ENV{"TWILIO_LIVE_$_"} } qw(TESTS WRITES ACCOUNT_SID API_KEY API_SECRET);
plan skip_all => 'Set TWILIO_LIVE_TESTS=1 to call the real API' if !$live{TESTS};
plan skip_all => 'Set TWILIO_LIVE_ACCOUNT_SID, TWILIO_LIVE_API_KEY and TWILIO_LIVE_API_SECRET'
  if grep { !length($live{$_} // q{}) } qw(ACCOUNT_SID API_KEY API_SECRET);

require Twilio::Rest::Client;

my ($client, $http) = client($live{API_KEY}, $live{API_SECRET});
my ($number);

# A Standard API key can't fetch the account itself, so a record of it stands in.
live(
  'one record, by its sid' => sub {
    my ($listed) = $client->messages->read({}, 1);
    return 'The account has no messages' if !$listed;

    my $message = $client->messages($listed->sid)->fetch;
    is($message->sid,         $listed->sid,       'the same message');
    is($message->account_sid, $live{ACCOUNT_SID}, 'of the account');
    isa_ok($message->date_created, 'Time::Piece', 'its creation date');
    return;
  }
);

live(
  'the status and headers of an answer' => sub {
    my $listed = $client->messages->with_metadata(read => {}, 1);
    return 'The account has no messages' if !@{ $listed->get_data };
    is($listed->get_status_code, 200, 'a read');

    my $fetched = $client->messages($listed->get_data->[0]->sid)->with_metadata('fetch');
    is($fetched->get_status_code, 200, 'a fetch');
    like($fetched->get_header('Twilio-Request-Id'), qr/\ARQ[0-9a-f]{32}\z/, 'with its request id');
    return;
  }
);

live(
  'the balance' => sub {
    my $balance = eval { $client->balance->fetch };
    return 'Twilio keeps the balance of a subaccount in its parent'
      if !$balance && status($@) == 404;
    die $@ if !$balance;    ## no critic (ErrorHandling::RequireCarping)

    like($balance->balance,  qr/\A-?[0-9]+(?:[.][0-9]+)?\z/, 'an amount');
    like($balance->currency, qr/\A[A-Z]{3}\z/,               'in a currency');
    return;
  }
);

live(
  'phone numbers' => sub {
    ($number) = $client->incoming_phone_numbers->read({}, 1);
    return 'The account has no phone numbers' if !$number;

    like($number->phone_number, qr/\A[+][0-9]+\z/, 'in E.164');
    isa_ok($number->capabilities, 'Twilio::Base::PhoneNumberCapabilities', 'its capabilities');
    return;
  }
);

live(
  'a basic Lookup, which is free' => sub {
    return 'The account has no phone numbers' if !$number;

    my $lookup = $client->lookups->v2->phone_numbers($number->phone_number)->fetch;
    ok($lookup->valid, 'the number is valid');
    is($lookup->phone_number, $number->phone_number, 'and the same');
    return;
  }
);

# The + of an E.164 number must reach Twilio as %2B; sent bare, it would be read as a space.
live(
  'a phone number found by its number' => sub {
    return 'The account has no phone numbers' if !$number;

    my @found = $client->incoming_phone_numbers->read({ phone_number => $number->phone_number });
    is(scalar(@found), 1,            'one number');
    is($found[0]->sid, $number->sid, 'the same');
    like(($http->requests)[-1]{url}, qr/[?&]PhoneNumber=%2B[0-9]+(?:&|\z)/, 'its + encoded');
    return;
  }
);

live(
  'prices, on another host' => sub {
    my $country = $client->pricing->v1->messaging->countries('MX')->fetch;
    is($country->iso_country, 'MX', 'Mexico');
    return;
  }
);

live(
  'a list of another product' => sub {
    my @services = $client->verify->v2->services->read({}, 1);
    ok(@services <= 1, 'read');
    return;
  }
);

live(
  'paging' => sub {
    my $before   = () = $http->requests;
    my @messages = $client->messages->read({}, 2, 1);
    my $made     = (() = $http->requests) - $before;

    ok(@messages <= 2, 'no more than the limit');
    is($made, scalar(@messages) || 1, 'one request for each page of one message');
    return;
  }
);

live(
  'OAuth' => sub {
    my ($id, $secret) = map { $ENV{"TWILIO_LIVE_OAUTH_$_"} } qw(CLIENT_ID CLIENT_SECRET);
    return 'Set TWILIO_LIVE_OAUTH_CLIENT_ID and TWILIO_LIVE_OAUTH_CLIENT_SECRET'
      if grep { !length($_ // q{}) } $id, $secret;

    require Twilio::CredentialProvider::ClientCredentialProvider;
    my $provider = Twilio::CredentialProvider::ClientCredentialProvider->new(
      { client_id => $id, client_secret => $secret });
    my ($oauth, $oauth_http) = client(undef, undef, { credential_provider => $provider });

    $oauth->messages->read({}, 1) for 1 .. 2;
    my @urls = map { $_->{url} } $oauth_http->requests;
    is(scalar(grep { m{\Ahttps://oauth[.]twilio[.]com/v2/token} } @urls), 1, 'one token');
    is(scalar(grep { m{/Messages[.]json} } @urls),                        2, 'for two requests');
    return;
  }
);

live(
  'OAuth refuses credentials it does not know' => sub {
    require Twilio::CredentialProvider::NoAuthCredentialProvider;
    my ($anonymous) = client(undef, undef,
      { credential_provider => Twilio::CredentialProvider::NoAuthCredentialProvider->new });

    my $token = eval {
      $anonymous->oauth->v2->token->create('client_credentials',
        { client_id => 'twilio-perl-live-unknown', client_secret => 'not-a-secret' });
    };
    my $error = $@;
    ok(!$token, 'no token');
    isa_ok($error, 'Twilio::Exceptions::RestException', 'the error');
    is(status($error), 401, 'HTTP 401');
    like(message($error), qr/\A\[HTTP 401\] Unable to create record/, 'its message');
    return;
  }
);

# Names and data with the characters that break form and URL encoding come back as sent.
live(
  'special characters in names and data' => sub {
    return 'Set TWILIO_LIVE_WRITES=1 to create and delete a Sync service' if !$live{WRITES};

    my $sync = $client->sync->v1;
    my %name = (
      service  => 'twilio-perl-live-service|friendly&name',
      document => 'twilio-perl-live-document|unique&name',
    );
    my $data = { text => "a&b|c<d=e+f caf\x{e9}", list => [1, 'two'] };

    return with_cleanup(
      sub {
        my ($undo) = @_;
        my $service = $sync->services->create({ friendly_name => $name{service} });
        $undo->('the Sync service', sub { $sync->services($service->sid)->delete });
        is($service->friendly_name, $name{service}, 'the service is created with its name');

        my $created = $sync->services($service->sid)
          ->documents->create({ unique_name => $name{document}, data => $data });
        $undo->('the document', sub { $created->delete });
        is($created->unique_name, $name{document}, 'the document is created with its name');

        is($sync->services($service->sid)->fetch->friendly_name,
          $name{service}, 'the service name comes back');
        my $fetched = $sync->services($service->sid)->documents($name{document})->fetch;
        is($fetched->sid, $created->sid, 'the document is found by its name in the URL');
        is_deeply($fetched->data, $data, 'its data comes back');
        return;
      }
    );
  }
);

# A list of objects in a form body is sent as one Types value for each, each one JSON.
live(
  'a list in a create' => sub {
    return 'Set TWILIO_LIVE_WRITES=1 to create and delete an Events sink' if !$live{WRITES};

    my $events = $client->events->v1;
    my @types  = map { "com.twilio.messaging.message.$_" } qw(delivered sent);

    return with_cleanup(
      sub {
        my ($undo) = @_;
        my $sink = $events->sinks->create(
          'twilio-perl-live-sink',
          {
            destination  => 'https://example.org/twilio-perl-live',
            method       => 'POST',
            batch_events => \0,
          },
          'webhook'
        );
        $undo->('the sink', sub { $events->sinks($sink->sid)->delete });
        is($sink->sink_type, 'webhook', 'a webhook sink');

        my $subscription = $events->subscriptions->create('twilio-perl-live-subscription',
          $sink->sid, [map { { type => $_ } } @types]);
        $undo->('the subscription', sub { $events->subscriptions($subscription->sid)->delete });
        is($subscription->sink_sid, $sink->sid, 'a subscription to it');

        my @subscribed =
          sort map { $_->type } $events->subscriptions($subscription->sid)->subscribed_events->read;
        is_deeply(\@subscribed, \@types, 'with both types');
        return;
      }
    );
  }
);

done_testing;

# Each check is a subtest that returns a reason to skip, or nothing. An error from Twilio fails
# that check alone, so one refused call doesn't hide the others.
sub live {
  my ($name, $code) = @_;
  return subtest $name => sub {
    my $skip;
    my $ok    = eval { $skip = $code->(); 1 };
    my $error = $@;
    if (!$ok) {
      fail('Twilio accepted the requests');
      diag(message($error));
      return;
    }
    plan skip_all => $skip if defined $skip;
    return;
  };
}

# $code gets a function to register how to delete each thing it creates. The deletes run newest
# first, also when $code dies, and each is a test, so a failed one is never silent.
sub with_cleanup {
  my ($code) = @_;
  my @deletes;
  my $result;
  my $ok = eval {
    $result = $code->(sub { push @deletes, [@_] });
    1;
  };
  my $error = $@;
  for my $delete (reverse @deletes) {
    my ($what, $undo) = @{$delete};
    my $deleted = eval { $undo->(); 1 };
    ok($deleted, "$what is deleted") or diag(message($@));
  }
  die $error if !$ok;    ## no critic (ErrorHandling::RequireCarping)
  return $result;
}

sub message {
  my ($error) = @_;
  return blessed($error) && $error->can('get_message') ? $error->get_message : $error;
}

sub status {
  my ($error) = @_;
  return blessed($error) && $error->can('get_status_code') ? $error->get_status_code : 0;
}

sub client {
  my ($username, $password, $options) = @_;
  my $transport = Local::RecordingClient->new;
  my $twilio    = Twilio::Rest::Client->new(
    $username,
    $password,
    {
      account_sid => $live{ACCOUNT_SID},
      http_client => $transport,
      environment => {},
      %{ $options // {} },
    }
  );
  return ($twilio, $transport);
}

# Only the method and URL are kept, never headers, so a log of a failure shows no credentials.
package Local::RecordingClient;

use parent -norequire, 'Twilio::Http::TinyClient';

sub send_request {
  my ($self, $request) = @_;
  push @{ $self->{seen} }, { method => $request->{method}, url => $request->{url} };
  return $self->SUPER::send_request($request);
}

sub requests {
  my ($self) = @_;
  return @{ $self->{seen} // [] };
}
