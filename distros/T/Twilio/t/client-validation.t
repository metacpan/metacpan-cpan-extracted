use 5.016;
use warnings;

use Digest::SHA qw(sha256_hex);
use Test::More;

use Twilio::Jwt::JWT;
use Twilio::Jwt::Validation::ClientValidationJwt;

my $CLASS = 'Twilio::Jwt::Validation::ClientValidationJwt';
my $DATA  = 't/data/client-validation';

# twilio-python's test_client_validation.py, case by case: the canonical request is checked
# by its hash, and two cases against hashes Twilio's side is known to accept.
my $BODY         = 'me=letop&you=leworst';
my @PYTHON_CASES = (
  {
    name    => 'basic',
    payload => {
      query_string => 'q1=v1',
      all_headers  => { head => 'toe', headera => 'vala', headerb => 'valb' },
      body         => $BODY,
    },
    lines => ['q1=v1', 'headera:vala', 'headerb:valb', q{}, 'headera;headerb', sha256_hex($BODY)],
  },
  {
    name    => 'complex',
    payload => {
      query_string => 'q1=v1&q2=v2&a=b',
      all_headers  => { head => 'toe', Headerb => 'valb', yeezy => 'weezy' },
      body         => $BODY,
    },
    lines => ['a=b&q1=v1&q2=v2', 'headerb:valb', q{}, 'headera;headerb', sha256_hex($BODY)],
  },
  {
    name    => 'no query string',
    payload => {
      query_string => q{},
      all_headers  => { head => 'toe', Headerb => 'valb', yeezy => 'weezy' },
      body         => $BODY,
    },
    lines => [q{}, 'headerb:valb', q{}, 'headera;headerb', sha256_hex($BODY)],
  },
  {
    name    => 'no request body',
    payload => {
      query_string => 'q1=v1',
      all_headers  => { head => 'toe', headera => 'vala', headerb => 'valb' },
      body         => q{},
    },
    lines => ['q1=v1', 'headera:vala', 'headerb:valb', q{}, 'headera;headerb', q{}],
  },
  {
    name    => 'header names in lower case',
    payload => {
      query_string => 'q1=v1',
      all_headers  => { head => 'toe', Headera => 'vala', Headerb => 'valb' },
      body         => $BODY,
    },
    lines => ['q1=v1', 'headera:vala', 'headerb:valb', q{}, 'headera;headerb', sha256_hex($BODY)],
  },
  {
    name    => 'no headers',
    payload => { query_string => 'q1=v1', all_headers => {}, body => $BODY },
    lines   => ['q1=v1', q{}, 'headera;headerb', sha256_hex($BODY)],
  },
);

subtest "twilio-python's canonical requests" => sub {
  for my $case (@PYTHON_CASES) {
    my $jwt = jwt(
      {
        method         => 'GET',
        path           => 'https://api.twilio.com/',
        signed_headers => [qw(headerb headera)],
        %{ $case->{payload} },
      }
    );
    my $expected = join "\n", 'GET', 'https://api.twilio.com/', @{ $case->{lines} };
    is($jwt->canonical_request, $expected, "$case->{name}: the canonical request");

    my $claims = $jwt->get_payload;
    is($claims->{hrh}, 'headera;headerb',     "$case->{name}: hrh");
    is($claims->{rqh}, sha256_hex($expected), "$case->{name}: rqh");
  }
};

subtest 'hashes known to be right' => sub {
  my %headers = (authorization => 'foobar', host => 'api.twilio.com');
  my $get     = jwt(
    {
      method       => 'GET',
      path         => '/Messages',
      query_string => 'PageSize=5&Limit=10',
      all_headers  => {%headers},
      body         => 'foobar',
    }
  );
  is($get->get_payload->{hrh}, 'authorization;host', 'the default signed headers');
  is(
    $get->get_payload->{rqh},
    '4dc9b67bed579647914587b0e22a1c65c1641d8674797cd82de65e766cce5f80',
    'a GET'
  );

  my $post = jwt(
    {
      method       => 'POST',
      path         => '/Messages',
      query_string => q{},
      all_headers  => {%headers},
      body         => 'testbody',
    }
  );
  is(
    $post->get_payload->{rqh},
    'bd792c967c20d546c738b94068f5f72758a10d26c12979677501e1eefe58c65a',
    'a POST'
  );
};

subtest 'the claims' => sub {
  my $claims = jwt({ method => 'GET', path => '/Messages' })->get_payload(1_000_000);
  is($claims->{iss}, 'SK123',   'iss is the API key');
  is($claims->{sub}, 'AC123',   'sub is the account');
  is($claims->{nbf}, 1_000_000, 'nbf is now');
  is($claims->{exp}, 1_000_300, 'it lasts five minutes');
};

subtest 'a header given as a list' => sub {
  my $jwt = jwt(
    {
      method         => 'GET',
      path           => '/',
      all_headers    => { Host => [qw(b a)] },
      signed_headers => ['host'],
    }
  );
  like($jwt->canonical_request, qr/^host:a,b$/m, 'sorted and joined with commas');
};

subtest 'what is required' => sub {
  my @given = ('AC123', 'SK123', 'CR123', 'key', {});
  my @names = qw(account_sid api_key_sid credential_sid private_key);
  for my $index (0 .. $#names) {
    my @arguments = @given;
    $arguments[$index] = undef;
    my $ok = eval { $CLASS->new(@arguments); 1 };
    ok(!$ok, "without $names[$index]");
    like($@, qr/\A\Q$names[$index]\E is required/, "$names[$index]: the reason");
  }
  my $ok = eval { $CLASS->new(@given[0 .. 3], 'GET /'); 1 };
  ok(!$ok, 'without a request as a hash');
};

subtest 'RS256 without its module' => sub {
  local @INC =
    (sub { die "blocked for this test\n" if $_[1] eq 'Crypt/OpenSSL/RSA.pm'; return }, @INC);
  plan skip_all => 'Crypt::OpenSSL::RSA is already loaded' if $INC{'Crypt/OpenSSL/RSA.pm'};

  my $ok = eval { Twilio::Jwt::JWT->sign('x', slurp('test-private-key.pem'), 'RS256'); 1 };
  ok(!$ok, 'it dies');
  like($@, qr/RS256 needs the Perl module Crypt::OpenSSL::RSA/, 'and names the module');
};

SKIP: {
  skip 'RS256 needs Crypt::OpenSSL::RSA', 4 if !eval { require Crypt::OpenSSL::RSA; 1 };

  my $private = slurp('test-private-key.pem');
  my $public  = slurp('test-public-key.pem');

  subtest 'RS256 signatures match openssl' => sub {
    my $expected = slurp('openssl-rs256-signature.txt') =~ s/\s+\z//r;
    my $signed   = Twilio::Jwt::JWT->sign('header.payload', $private, 'RS256');
    is(Twilio::Jwt::JWT->urlsafe_b64_encode($signed), $expected, 'with a PKCS#8 key');

    my $pkcs1 = Crypt::OpenSSL::RSA->new_private_key($private)->get_private_key_string;
    like($pkcs1, qr/\A-----BEGIN RSA PRIVATE KEY-----/, 'the same key in PKCS#1 form');
    is(
      Twilio::Jwt::JWT->urlsafe_b64_encode(
        Twilio::Jwt::JWT->sign('header.payload', $pkcs1, 'RS256')
      ),
      $expected,
      'with a PKCS#1 key'
    );
  };

  subtest 'a client validation token' => sub {
    my $jwt = jwt(
      {
        method       => 'GET',
        path         => '/Messages',
        query_string => 'PageSize=5&Limit=10',
        all_headers  => { authorization => 'foobar', host => 'api.twilio.com' },
        body         => 'foobar',
      },
      $private
    );
    my $token = $jwt->to_jwt;

    is_deeply(
      Twilio::Jwt::JWT->get_header($token),
      { alg => 'RS256', typ => 'JWT', cty => 'twilio-pkrv;v=1', kid => 'CR123' },
      'the header, as twilio-python writes it'
    );
    my $claims = Twilio::Jwt::JWT->decode($token, $public);
    is($claims->{rqh}, '4dc9b67bed579647914587b0e22a1c65c1641d8674797cd82de65e766cce5f80', 'rqh');
    is($claims->{hrh}, 'authorization;host',                                               'hrh');
    is($claims->{iss}, 'SK123',                                                            'iss');
    is($claims->{sub}, 'AC123',                                                            'sub');
    ok($claims->{exp} >= time && $claims->{exp} <= time + 300, 'exp within five minutes');
  };

  subtest 'RS256 tokens that must not verify' => sub {
    my $token = Twilio::Jwt::JWT->encode({ sub => 'me' }, $private, 'RS256');
    my ($header, $payload, $signature) = split /[.]/, $token;

    my $changed = join q{.}, $header, Twilio::Jwt::JWT->urlsafe_b64_encode('{"sub":"you"}'),
      $signature;
    like(
      error_of(sub { Twilio::Jwt::JWT->decode($changed, $public) }),
      qr/Signature verification failed/,
      'a changed payload'
    );

    my $other = Crypt::OpenSSL::RSA->generate_key(2048)->get_public_key_x509_string;
    like(
      error_of(sub { Twilio::Jwt::JWT->decode($token, $other) }),
      qr/Signature verification failed/,
      'another public key'
    );

    my $forged = Twilio::Jwt::JWT->encode({ sub => 'me' }, 'any secret', 'HS256');
    like(
      error_of(sub { Twilio::Jwt::JWT->decode($forged, $public) }),
      qr/takes a shared secret, not a key in PEM form/,
      'HS256 with the public key as secret'
    );

    like(
      error_of(sub { Twilio::Jwt::JWT->sign('x', 'not a key', 'RS256') }),
      qr/RS256 needs an RSA private key in PEM form/,
      'signing with what is not a key'
    );
  };

  subtest 'HS256 keeps working' => sub {
    my $token = Twilio::Jwt::JWT->encode({ sub => 'me' }, 'secret');
    is(Twilio::Jwt::JWT->decode($token, 'secret')->{sub}, 'me', 'a round trip');
  };
}

done_testing;

sub jwt {
  my ($payload, $key) = @_;
  return $CLASS->new('AC123', 'SK123', 'CR123', $key // 'secret', $payload);
}

# The error, or nothing when the code did not die.
sub error_of {
  my ($code) = @_;
  my $ok = eval { $code->(); 1 };
  return $ok ? undef : "$@";
}

sub slurp {
  my ($name) = @_;
  open my $handle, '<:raw', "$DATA/$name" or die "$DATA/$name: $!";    ## no critic (ErrorHandling::RequireCarping)
  my $content = do { local $/ = undef; <$handle> };
  close $handle or die "$DATA/$name: $!";                              ## no critic (ErrorHandling::RequireCarping)
  return $content;
}
