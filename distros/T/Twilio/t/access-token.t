use 5.016;
use warnings;
use utf8;

use JSON::PP ();
use Test::More;

# A fixed clock, set before the token class is compiled, so expiry can be checked exactly.
my $NOW = 1_700_000_000;

BEGIN {
  *CORE::GLOBAL::time = sub { return $NOW };
}

use Twilio::Json;
use Twilio::Jwt::AccessToken;
use Twilio::Jwt::Grants::ChatGrant;
use Twilio::Jwt::Grants::PlaybackGrant;
use Twilio::Jwt::Grants::SyncGrant;
use Twilio::Jwt::Grants::TaskRouterGrant;
use Twilio::Jwt::Grants::VideoGrant;
use Twilio::Jwt::Grants::VoiceGrant;
use Twilio::Jwt::JWT;

my $JWT     = 'Twilio::Jwt::JWT';
my $SECRET  = 'secret';
my $vectors = read_vectors('t/data/vectors-access-tokens.json');

subtest 'the same tokens as twilio-php' => sub {
  for my $case (@{ $vectors->{tokens} }) {
    my $token   = build($case)->to_jwt($case->{algorithm});
    my $payload = $JWT->decode($token, $SECRET);
    my $name    = $case->{description};

    is($payload->{jti}, "SKxxxx-$NOW",                 "$name: id");
    is($payload->{exp}, $NOW + ($case->{ttl} // 3600), "$name: expiry");
    delete @{$payload}{qw(jti exp)};

    is(canonical($payload),                 canonical($case->{payload}), "$name: content");
    is(canonical($JWT->get_header($token)), canonical($case->{header}),  "$name: header");
  }
};

subtest 'signatures match twilio-php' => sub {
  for my $case (@{ $vectors->{signatures} }) {
    my $signature = $JWT->sign($case->{message}, $case->{key}, $case->{algorithm});
    is($JWT->urlsafe_b64_encode($signature), $case->{expected}, $case->{algorithm});
  }
};

subtest 'URL-safe Base64 matches twilio-php' => sub {
  for my $case (@{ $vectors->{base64} }) {
    my $bytes = $case->{text};
    utf8::downgrade($bytes);

    is($JWT->urlsafe_b64_encode($bytes), $case->{expected}, "encoding '$case->{expected}'");
    is($JWT->urlsafe_b64_decode($case->{expected}), $bytes, "decoding '$case->{expected}'");
  }
};

subtest 'a forged token is refused' => sub {
  my $token = token()->to_jwt;
  my ($header, $payload, $signature) = split /[.]/, $token;

  my $forged = $JWT->urlsafe_b64_encode('{"sub":"someone else","grants":{}}');
  my $none   = $JWT->urlsafe_b64_encode('{"typ":"JWT","alg":"none"}');
  my $other  = $JWT->urlsafe_b64_encode('{"typ":"JWT","alg":"ES256"}');
  my $rsa    = $JWT->urlsafe_b64_encode('{"typ":"JWT","alg":"RS256"}');
  my $empty  = $JWT->urlsafe_b64_encode('{"typ":"JWT"}');

  my @cases = (
    ['another payload',         "$header.$forged.$signature", qr/Signature verification failed/],
    ['no signature',            "$header.$payload.",          qr/Signature verification failed/],
    ['a wrong signature',       "$header.$payload.abcd",      qr/Signature verification failed/],
    ['the none attack',         "$none.$forged.",             qr/Algorithm not supported/],
    ['the none attack, signed', "$none.$payload.$signature",  qr/Algorithm not supported/],
    ['another algorithm',       "$other.$payload.$signature", qr/Algorithm not supported/],
    [
      'RS256 with a secret',
      "$rsa.$payload.$signature",
      qr/RS256 needs (?:an RSA public key|the Perl module)/
    ],
    ['no algorithm',  "$empty.$payload.$signature",    qr/Empty algorithm/],
    ['two segments',  "$header.$payload",              qr/Wrong number of segments/],
    ['four segments', "$header.$payload.$signature.x", qr/Wrong number of segments/],
    ['not a token',   'nonsense',                      qr/Wrong number of segments/],
    ['bad JSON',      'abc.def.ghi',                   qr/Invalid segment encoding/],
    ['nothing',       undef,                           qr/Wrong number of segments/],
  );

  for my $case (@cases) {
    my ($name, $text, $expected) = @{$case};
    my $ok    = eval { $JWT->decode($text, $SECRET); 1 };
    my $error = $@;
    ok(!$ok, "$name: refused");
    like("$error", $expected, "$name: says why");
  }
};

subtest 'the wrong secret is refused' => sub {
  my $token = token()->to_jwt;

  my $ok    = eval { $JWT->decode($token, 'another'); 1 };
  my $error = $@;
  ok(!$ok, 'refused');
  like("$error", qr/Signature verification failed/, 'says why');

  $ok    = eval { $JWT->decode($token); 1 };
  $error = $@;
  ok(!$ok, 'no secret is refused');
  like("$error", qr/A key is needed/, 'says why');
};

subtest 'decoding without verifying' => sub {
  my $token = token()->to_jwt;

  is($JWT->decode($token, undef,   0)->{iss}, 'SKxxxx', 'it reads the payload');
  is($JWT->decode($token, 'wrong', 0)->{iss}, 'SKxxxx', 'whatever the key');
};

subtest 'encoding' => sub {
  my $token =
    $JWT->encode({ a => 1 }, $SECRET, undef, { cty => 'x', typ => 'other', alg => 'none' });

  is_deeply($JWT->get_header($token),      { typ => 'JWT', alg => 'HS256', cty => 'x' }, 'header');
  is_deeply($JWT->decode($token, $SECRET), { a   => 1 },                                 'payload');

  my $ok    = eval { $JWT->encode({}, $SECRET, 'none'); 1 };
  my $error = $@;
  ok(!$ok, 'an unknown algorithm is refused');
  like("$error", qr/Algorithm not supported/, 'says why');
};

subtest 'a secret with non-ASCII text' => sub {
  my $bytes = 'señal';
  utf8::encode($bytes);

  is($JWT->sign('m', 'señal'), $JWT->sign('m', $bytes), 'characters and bytes sign alike');
};

subtest 'the token object' => sub {
  my $token = token();

  is($token->set_identity('alice'), $token,  'set_identity returns the token');
  is($token->get_identity,          'alice', 'get_identity');
  is($token->set_nbf(5),            $token,  'set_nbf returns the token');
  is($token->get_nbf,               5,       'get_nbf');
  is($token->set_region('ie1'),     $token,  'set_region returns the token');
  is($token->get_region,            'ie1',   'get_region');

  my $grant = Twilio::Jwt::Grants::VideoGrant->new;
  is($token->add_grant($grant), $token, 'add_grant returns the token');

  is("$token", $token->to_jwt, 'a token converts to its text');
  ok($token, 'and is true');
  is($JWT->decode($token->to_jwt, $SECRET)->{nbf}, 5, 'nbf is a number in the token');
  like(payload_text($token), qr/"nbf":5\b/, 'and not text');
  like(payload_text($token), qr/"exp":\d+/, 'nor is exp');
};

subtest 'the grants' => sub {
  my @cases = (
    [
      'Twilio::Jwt::Grants::ChatGrant', 'chat',
      qw(service_sid endpoint_id deployment_role_sid push_credential_sid)
    ],
    [
      'Twilio::Jwt::Grants::SyncGrant', 'data_sync',
      qw(service_sid endpoint_id deployment_role_sid push_credential_sid)
    ],
    ['Twilio::Jwt::Grants::TaskRouterGrant', 'task_router', qw(workspace_sid worker_sid role)],
    ['Twilio::Jwt::Grants::VideoGrant',      'video',       qw(room)],
  );

  for my $case (@cases) {
    my ($class, $key, @fields) = @{$case};
    my $grant = $class->new;

    is($grant->get_grant_key, $key, "$class key");
    is_deeply($grant->get_payload, {}, 'empty at first');

    for my $field (@fields) {
      my ($getter, $setter) = ("get_$field", "set_$field");
      is($grant->$setter("v$field"), $grant,    "$setter returns the grant");
      is($grant->$getter,            "v$field", $getter);
    }
    is_deeply($grant->get_payload, { map { $_ => "v$_" } @fields }, 'the payload');
  }
};

subtest 'the voice grant' => sub {
  my $grant = Twilio::Jwt::Grants::VoiceGrant->new;

  is($grant->set_incoming_allow(1), $grant, 'a setter returns the grant');
  is($grant->get_incoming_allow,    1,      'allowed');

  is($grant->set_outgoing_application('AP1', { a => 1 }), $grant, 'with parameters');
  is($grant->get_outgoing_application_sid,                'AP1',  'application');
  is_deeply($grant->get_outgoing_application_params, { a => 1 }, 'parameters');

  $grant->set_outgoing_application_sid('AP2');
  $grant->set_push_credential_sid('CR1');
  $grant->set_endpoint_id('E1');
  is($grant->get_push_credential_sid,      'CR1', 'push credential');
  is($grant->get_endpoint_id,              'E1',  'endpoint');
  is($grant->get_outgoing_application_sid, 'AP2', 'application alone');

  like(Twilio::Json::encode($grant->get_payload), qr/"allow":true/, 'allow is a JSON boolean');

  $grant->set_outgoing_application('AP3', {});
  unlike(Twilio::Json::encode($grant->get_payload), qr/params/, 'empty parameters are left out');
};

subtest 'the playback grant' => sub {
  my $grant = Twilio::Jwt::Grants::PlaybackGrant->new;

  is($grant->get_grant_key, 'player', 'key');
  is_deeply($grant->get_payload, {}, 'empty at first');
  is($grant->set_grant({ a => 1 }), $grant, 'set_grant returns the grant');
  is_deeply($grant->get_grant,   { a => 1 }, 'get_grant');
  is_deeply($grant->get_payload, { a => 1 }, 'the payload');
};

subtest 'a custom claim cannot replace the claims that identify the token' => sub {
  my $token = token();
  $token->add_claim(find => 'me');
  $token->add_claim($_   => 'redefined') for qw(sub iss jti exp grants);
  my $payload = $JWT->decode($token->to_jwt, $SECRET);

  is($payload->{find}, 'me',        'a new claim is added');
  is($payload->{sub},  'ACxxxx',    'sub stays the account, as in twilio-php');
  is($payload->{iss},  'SKxxxx',    'iss stays the key');
  is($payload->{exp},  $NOW + 3600, 'exp stays');
  like($payload->{jti}, qr/\ASKxxxx-/, 'jti stays');
  is_deeply($payload->{grants}, {}, 'grants stay');
};

# twilio-python's test_add_grant_validates_grant.
subtest 'add_grant refuses what is not a grant' => sub {
  my @cases = (
    ['text',         'GrantRootAccess',                 qr/not 'GrantRootAccess'/],
    ['a class name', 'Twilio::Jwt::Grants::VideoGrant', qr/not 'Twilio::Jwt::Grants::VideoGrant'/],
    ['a hash',       { video => {} },                   qr/not HASH/],
    ['another object', bless({}, 'Local::NotAGrant'),   qr/not Local::NotAGrant/],
    ['undef',          undef,                           qr/not undef/],
  );

  for my $case (@cases) {
    my ($name, $grant, $pattern) = @{$case};
    my $token = token();
    my $ok    = eval { $token->add_grant($grant); 1 };
    my $error = $@;

    ok(!$ok, "$name: refused");
    like($error, qr/add_grant takes a grant object/, "$name: says why");
    like($error, $pattern,                           "$name: names what it got");
    is_deeply($JWT->decode($token->to_jwt, $SECRET)->{grants}, {}, "$name: the token still works");
  }
};

subtest 'a grant must name itself' => sub {
  require Twilio::Jwt::Grants::Grant;
  my $grant = Twilio::Jwt::Grants::Grant->new;

  my $ok    = eval { $grant->get_grant_key; 1 };
  my $error = $@;
  ok(!$ok, 'it dies');
  like($error, qr/must implement get_grant_key/, 'says why');
};

done_testing;

sub token {
  return Twilio::Jwt::AccessToken->new('ACxxxx', 'SKxxxx', $SECRET);
}

sub build {
  my ($case) = @_;

  my $token = Twilio::Jwt::AccessToken->new('ACxxxx', 'SKxxxx', $SECRET, $case->{ttl},
    $case->{identity}, $case->{region});
  $token->set_nbf($case->{nbf}) if defined $case->{nbf};

  my %claims = %{ $case->{claims} // {} };
  $token->add_claim($_, $claims{$_}) for sort keys %claims;

  for my $definition (@{ $case->{grants} // [] }) {
    my $grant = "Twilio::Jwt::Grants::$definition->{class}"->new;
    for my $call (@{ $definition->{calls} }) {
      my ($method, @arguments) = @{$call};
      $grant->$method(@arguments);
    }
    $token->add_grant($grant);
  }
  return $token;
}

sub payload_text {
  my ($token) = @_;
  my (undef, $payload) = split /[.]/, $token->to_jwt;
  return $JWT->urlsafe_b64_decode($payload);
}

# The tokens may decode through different JSON modules, so they are compared as text.
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
