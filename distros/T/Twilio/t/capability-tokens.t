use 5.016;
use warnings;
use utf8;

use JSON::PP ();
use Test::More;

# A fixed clock, set before the token classes are compiled, so expiry can be checked exactly.
my $NOW = 1_700_000_000;

BEGIN {
  *CORE::GLOBAL::time = sub { return $NOW };
}

use Twilio::Json;
use Twilio::Jwt::Client::ScopeURI;
use Twilio::Jwt::ClientToken;
use Twilio::Jwt::JWT;
use Twilio::Jwt::TaskRouter::CapabilityToken;
use Twilio::Jwt::TaskRouter::Policy;
use Twilio::Jwt::TaskRouter::TaskQueueCapability;
use Twilio::Jwt::TaskRouter::WorkerCapability;
use Twilio::Jwt::TaskRouter::WorkspaceCapability;

my $JWT     = 'Twilio::Jwt::JWT';
my $SCOPE   = 'Twilio::Jwt::Client::ScopeURI';
my $CLIENT  = 'Twilio::Jwt::ClientToken';
my $SECRET  = 'foobar';
my $vectors = read_vectors('t/data/vectors-capability-tokens.json');

subtest 'client tokens match twilio-php' => sub {
  for my $case (@{ $vectors->{client} }) {
    my $capability = $CLIENT->new('AC123', $SECRET);
    run_calls($capability, $case->{calls});

    check_token($capability->generate_token($case->{ttl}), $case);
  }
};

subtest 'TaskRouter tokens match twilio-php' => sub {
  for my $case (@{ $vectors->{task_router} }) {
    my $class = "Twilio::Jwt::TaskRouter::$case->{class}";
    my @ids   = ('AC123', $SECRET, 'WS456', defined $case->{channel} ? $case->{channel} : ());

    my $capability = $class->new(@ids, $case->{base_url}, $case->{base_ws_url});
    run_calls($capability, $case->{calls});

    check_token($capability->generate_token($case->{ttl}, $case->{extra}), $case);
  }
};

subtest 'policies match twilio-php' => sub {
  for my $case (@{ $vectors->{policies} }) {
    my $policy = Twilio::Jwt::TaskRouter::Policy->new(@{$case}{qw(url method query post allow)});
    $policy->add_query_filter($case->{add_query}) if $case->{add_query};
    $policy->add_post_filter($case->{add_post})   if $case->{add_post};

    is(canonical($policy->to_hash), canonical($case->{expected}), $case->{description});
  }
};

subtest 'a scope in text and back' => sub {
  my $scope = $SCOPE->new('client', 'incoming', { clientName => 'me', zone => 'a b' });
  is($scope->to_string, 'scope:client:incoming?clientName=me&zone=a+b', 'names sorted');

  my $parsed = $SCOPE->parse($scope->to_string);
  is($parsed->get_service,   'client',   'service');
  is($parsed->get_privilege, 'incoming', 'privilege');
  is_deeply($parsed->get_params, { clientName => 'me', zone => 'a b' }, 'parameters');
  is($parsed->to_string, $scope->to_string, 'the same text');
};

subtest 'a scope with no parameters' => sub {
  my $scope = $SCOPE->parse('scope:stream:subscribe');

  is($scope->to_string, 'scope:stream:subscribe', 'no query');
  is_deeply($scope->get_params, {}, 'no parameters');
};

subtest 'a parameter with no value' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $scope = $SCOPE->parse('scope:a:b?empty=&none');

  is_deeply($scope->get_params, { empty => q{}, none => q{} }, 'empty');
  is_deeply(\@warnings,         [],                            'no warnings');
};

subtest 'a value with an equals sign' => sub {
  is($SCOPE->parse('scope:a:b?x=1=2')->get_params->{x}, '1=2', 'it is kept whole');
};

subtest 'a scope that is not one' => sub {
  my @cases = (
    ['another scheme',  'other:a:b', qr/Not a scope URI/],
    ['nothing',         undef,       qr/Not a scope URI/],
    ['no privilege',    'scope:a',   qr/Not enough parts/],
    ['empty privilege', 'scope:a:',  qr/Not enough parts/],
  );

  for my $case (@cases) {
    my ($name, $text, $expected) = @{$case};
    my $ok    = eval { $SCOPE->parse($text); 1 };
    my $error = $@;
    ok(!$ok, "$name: refused");
    like("$error", $expected, "$name: says why");
  }
};

subtest 'add_param' => sub {
  my $scope = $SCOPE->new('a', 'b', [[one => 1], [two => 2]]);

  is($scope->add_param(three => 3), $scope, 'it returns the scope');
  $scope->add_param(one => 9);
  is($scope->to_string, 'scope:a:b?two=2&three=3&one=9', 'pairs keep their order');
};

subtest 'build_query' => sub {
  is($SCOPE->build_query({}),                     q{},        'an empty hash');
  is($SCOPE->build_query(undef),                  q{},        'nothing');
  is($SCOPE->build_query([[b => 1], [a => 2]]),   'b=1&a=2',  'pairs keep their order');
  is($SCOPE->build_query({ b => 1, a => 2 }),     'a=2&b=1',  'a hash is sorted');
  is($SCOPE->build_query({ a => "\x{f3}" }),      'a=%C3%B3', 'characters are UTF-8');
  is($SCOPE->build_query({ a => "\xc3\xb3" }),    'a=%C3%B3', 'UTF-8 stays as it is');
  is($SCOPE->build_query({ a => undef, b => 1 }), 'b=1',      'undefined values are skipped');
};

subtest 'text comes back as characters' => sub {
  my $scope = $SCOPE->parse('scope:a:b?name=Jos%C3%A9');

  is($scope->get_params->{name}, "Jos\x{e9}",                'decoded');
  is($scope->to_string,          'scope:a:b?name=Jos%C3%A9', 'and encoded again');
};

subtest 'the name of a client' => sub {
  for my $case (['a space', 'a b'], ['a dash', 'a-b'], ['an accent', "jos\x{e9}"]) {
    my ($name, $client) = @{$case};
    my $ok    = eval { $CLIENT->new('AC1', $SECRET)->allow_client_incoming($client); 1 };
    my $error = $@;
    ok(!$ok, "$name: refused");
    like("$error", qr/Only alphanumeric/, "$name: says why");
  }

  my $ok    = eval { $CLIENT->new('AC1', $SECRET)->allow_client_incoming(q{}); 1 };
  my $error = $@;
  ok(!$ok, 'empty: refused');
  like("$error", qr/zero length/, 'empty: says why');
};

subtest 'a capability token defaults to an hour' => sub {
  my $token = $CLIENT->new('AC1', $SECRET)->generate_token;
  is($JWT->decode($token, $SECRET)->{exp}, $NOW + 3600, 'client');

  my $worker = Twilio::Jwt::TaskRouter::WorkspaceCapability->new('AC1', $SECRET, 'WS1');
  is($JWT->decode($worker->generate_token, $SECRET)->{exp}, $NOW + 3600, 'TaskRouter');
};

subtest 'SIDs are checked' => sub {
  my @cases = (
    ['the account',   ['XX1', $SECRET, 'WS1', 'WK1'], qr/Invalid AccountSid provided: XX1/],
    ['no account',    [undef, $SECRET, 'WS1', 'WK1'], qr/Invalid AccountSid/],
    ['the workspace', ['AC1', $SECRET, 'XX1', 'WK1'], qr/Invalid WorkspaceSid provided: XX1/],
    ['no workspace',  ['AC1', $SECRET, undef, 'WK1'], qr/Invalid WorkspaceSid/],
    ['the channel',   ['AC1', $SECRET, 'WS1', 'XX1'], qr/Invalid ChannelId provided: XX1/],
    ['no channel',    ['AC1', $SECRET, 'WS1', undef], qr/ChannelId not provided/],
  );

  for my $case (@cases) {
    my ($name, $arguments, $expected) = @{$case};
    my $ok    = eval { Twilio::Jwt::TaskRouter::CapabilityToken->new(@{$arguments}); 1 };
    my $error = $@;
    ok(!$ok, "$name: refused");
    like("$error", $expected, "$name: says why");
  }
};

subtest 'a resource URL can be given' => sub {
  my $capability =
    Twilio::Jwt::TaskRouter::CapabilityToken->new('AC1', $SECRET, 'WS1', 'WS1',
    'https://a.test/own');
  $capability->allow_updates;

  my $policies = $JWT->decode($capability->generate_token, $SECRET)->{policies};
  is($policies->[2]{url}, 'https://a.test/own', 'it can be read');
  is($policies->[3]{url}, 'https://a.test/own', 'and used');
};

subtest 'a given resource URL is not worked out again' => sub {
  my $worked_out = 0;
  local *Twilio::Jwt::TaskRouter::CapabilityToken::setup_resource = sub { $worked_out++; return };

  Twilio::Jwt::TaskRouter::CapabilityToken->new('AC1', $SECRET, 'WS1', 'WS1', 'https://a.test/own');
  is($worked_out, 0, 'with one');

  Twilio::Jwt::TaskRouter::CapabilityToken->new('AC1', $SECRET, 'WS1', 'WS1');
  is($worked_out, 1, 'without one');
};

subtest 'adding a policy' => sub {
  my $capability = Twilio::Jwt::TaskRouter::WorkspaceCapability->new('AC1', $SECRET, 'WS1');

  my $policy = $capability->add_policy_deconstructed('https://a.test', 'GET', {}, {}, 0);
  isa_ok($policy, 'Twilio::Jwt::TaskRouter::Policy');

  my $policies = $JWT->decode($capability->generate_token, $SECRET)->{policies};
  ok(!$policies->[-1]{allow}, 'it denies');

  my $default = $capability->add_policy_deconstructed('https://a.test', 'GET');
  is(canonical($default->to_hash->{query_filter}), '{}', 'filters left out are empty');
  is(canonical($default->to_hash->{post_filter}),  '{}', 'both of them');
};

subtest 'a policy allows unless told otherwise' => sub {
  my $policy = Twilio::Jwt::TaskRouter::Policy->new('https://a.test', 'GET');

  like(Twilio::Json::encode($policy->to_hash), qr/"allow":true/, 'a JSON boolean');
};

done_testing;

sub run_calls {
  my ($object, $calls) = @_;

  for my $call (@{$calls}) {
    my ($method, @arguments) = @{$call};
    $object->$method(@arguments);
  }
  return;
}

sub check_token {
  my ($token, $case) = @_;

  my $name    = $case->{description};
  my $payload = $JWT->decode($token, $SECRET);
  is($payload->{exp}, $NOW + ($case->{ttl} // 3600), "$name: expiry");
  delete $payload->{exp};

  is(canonical($payload),                 canonical($case->{payload}), "$name: content");
  is(canonical($JWT->get_header($token)), canonical($case->{header}),  "$name: header");
  return;
}

# Decoded values can come from different JSON modules, so they are compared as text.
sub canonical {
  my ($value) = @_;
  return Twilio::Json::encode($value);
}

sub read_vectors {
  my ($file) = @_;

  open my $handle, '<:raw', $file or die "Cannot read $file: $!\n";
  my $content = do { local $/ = undef; <$handle> };
  close $handle or die "Cannot read $file: $!\n";
  return JSON::PP->new->utf8->decode($content);
}
