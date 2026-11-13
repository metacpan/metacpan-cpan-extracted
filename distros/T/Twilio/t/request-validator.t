use 5.016;
use warnings;
use utf8;

use JSON::PP ();
use Test::More;

use Twilio::Security::RequestValidator;

my $CLASS   = 'Twilio::Security::RequestValidator';
my $vectors = read_vectors('t/data/vectors-request-validator.json');
my $checker = $CLASS->new($vectors->{token});

subtest 'signatures match twilio-php' => sub {
  for my $case (@{ $vectors->{signatures} }) {
    is($checker->compute_signature($case->{url}, $case->{data}, $case->{algorithm}),
      $case->{expected}, $case->{description});
  }
};

subtest 'validation matches twilio-php' => sub {
  for my $case (@{ $vectors->{validations} }) {
    my $valid =
      $checker->validate($case->{signature}, $case->{url}, $case->{data} // {}, $case->{algorithm});
    is($valid, $case->{expected} ? 1 : 0, $case->{description});
  }
};

subtest 'body hashes match twilio-php' => sub {
  for my $case (@{ $vectors->{bodies} }) {
    is($CLASS->compute_body_hash($case->{body}), $case->{expected}, $case->{description});
  }
};

subtest 'validation of a body matches twilio-php' => sub {
  for my $case (@{ $vectors->{body_validations} }) {
    my $valid = $checker->validate($case->{signature}, $case->{url}, $case->{body});
    is($valid, $case->{expected} ? 1 : 0, $case->{description});
  }
};

subtest 'the settings header matches twilio-php' => sub {
  for my $case (@{ $vectors->{settings_headers} }) {
    is($CLASS->get_signature_algorithm($case->{header}), $case->{expected}, "'$case->{header}'");
  }
  is($CLASS->get_signature_algorithm(undef), 'HMAC_SHA1', 'no header');
};

subtest 'a body needs a hash in the URL' => sub {
  my $url       = 'https://a.test/x?foo=1';
  my $signature = $checker->compute_signature($url);

  is($checker->validate($signature, $url, '{"a":1}'), 0, 'refused');

  my $no_query = 'https://a.test/x';
  is($checker->validate($checker->compute_signature($no_query), $no_query, 'body'), 0, 'no query');
};

subtest 'a body with a right hash and a wrong signature' => sub {
  my $url = 'https://a.test/x?bodySHA256=' . $CLASS->compute_body_hash('body');

  is($checker->validate('wrong', $url, 'body'), 0, 'refused');
};

subtest 'data can be left out' => sub {
  my $url = 'https://a.test/x';
  is($checker->validate($checker->compute_signature($url), $url), 1, 'no data');
};

subtest 'text as characters or as bytes' => sub {
  my $characters = 'código';
  my $bytes      = $characters;
  utf8::encode($bytes);

  is(
    $checker->compute_signature('https://a.test/x', { Body => $characters }),
    $checker->compute_signature('https://a.test/x', { Body => $bytes }),
    'the same signature'
  );
  is($CLASS->compute_body_hash($characters), $CLASS->compute_body_hash($bytes), 'the same hash');
};

subtest 'a token with non-ASCII text' => sub {
  my $characters = $CLASS->new('señal');
  my $bytes      = $CLASS->new(encoded('señal'));

  is(
    $characters->compute_signature('https://a.test/x'),
    $bytes->compute_signature('https://a.test/x'),
    'the same signature'
  );
};

subtest 'values sort as text' => sub {

  # PHP compares numeric strings as numbers here, and Python as text.
  my %numbers = (Id => ['9', '10']);
  my $text    = $checker->compute_signature('https://a.test/x', \%numbers);

  is($text, sign('https://a.test/xId10Id9'), 'by the text of the value');
};

subtest 'a missing value' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  is(
    $checker->compute_signature('https://a.test/x', { A => undef }),
    $checker->compute_signature('https://a.test/x', { A => q{} }),
    'the same as an empty one'
  );
  is_deeply(\@warnings, [], 'and no warning');
};

subtest 'the last hash in the URL counts' => sub {
  my $hash = $CLASS->compute_body_hash('body');

  my $later   = "https://a.test/x?bodySHA256=wrong&bodySHA256=$hash";
  my $earlier = "https://a.test/x?bodySHA256=$hash&bodySHA256=wrong";

  is($checker->validate($checker->compute_signature($later), $later, 'body'), 1,
    'as in twilio-php');
  is($checker->validate($checker->compute_signature($earlier), $earlier, 'body'),
    0, 'and not the first');
};

subtest 'compare' => sub {
  is($CLASS->compare('abc',  'abc'),  1, 'the same');
  is($CLASS->compare('abc',  'abd'),  0, 'the last differs');
  is($CLASS->compare('abc',  'xbc'),  0, 'the first differs');
  is($CLASS->compare('abc',  'abcd'), 0, 'longer');
  is($CLASS->compare('abcd', 'abc'),  0, 'shorter');
  is($CLASS->compare(q{},    q{}),    0, 'empty strings are not a match');
  is($CLASS->compare(undef,  'abc'),  0, 'nothing first');
  is($CLASS->compare('abc',  undef),  0, 'nothing second');
  is($CLASS->compare(undef,  undef),  0, 'nothing at all');
};

subtest 'a request with no signature is refused' => sub {
  my $url = 'https://a.test/x';

  is($checker->validate(undef, $url), 0, 'undefined');
  is($checker->validate(q{},   $url), 0, 'empty');
};

subtest 'an algorithm this library does not know' => sub {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  is($checker->validate('anything', 'https://a.test/x', {}, 'HMAC_MD5'), 0, 'validate refuses it');
  is(scalar @warnings,                                                   1, 'and warns');
  like($warnings[0], qr/Unsupported webhook signature algorithm 'HMAC_MD5'/, 'naming it');

  my $ok    = eval { $checker->compute_signature('https://a.test/x', {}, 'HMAC_MD5'); 1 };
  my $error = $@;
  ok(!$ok, 'compute_signature dies');
  isa_ok($error, 'Twilio::Exceptions::TwilioException');
};

subtest 'unusual URLs' => sub {
  my @cases = (
    ['an IPv6 host',         'https://[::1]/x',   'https://[::1]:443/x'],
    ['an upper case scheme', 'HTTPS://a.test/x',  'HTTPS://a.test:443/x'],
    ['an unknown scheme',    'ftp://a.test/x',    'ftp://a.test:80/x'],
    ['an empty port',        'https://a.test:/x', 'https://a.test:443/x'],
  );

  for my $case (@cases) {
    my ($name, $url, $with_port) = @{$case};
    is($checker->validate($checker->compute_signature($with_port), $url), 1, $name);
  }

  my $odd = 'not a url';
  is($checker->validate($checker->compute_signature($odd), $odd), 1, 'not a URL at all');
};

subtest 'the names of headers and algorithms' => sub {
  is($CLASS->SIGNATURE_HEADER,          'X-Twilio-Signature',                   'signature');
  is($CLASS->SIGNATURE_SETTINGS_HEADER, 'X-Twilio-Webhooks-Signature-Settings', 'settings');
  is($CLASS->HMAC_SHA1,                 'HMAC_SHA1',                            'SHA-1');
  is($CLASS->HMAC_SHA256,               'HMAC_SHA256',                          'SHA-256');
};

done_testing;

sub sign {
  my ($text) = @_;
  require Digest::SHA;
  require MIME::Base64;
  return MIME::Base64::encode_base64(Digest::SHA::hmac_sha1($text, $vectors->{token}), q{});
}

sub encoded {
  my ($text) = @_;
  utf8::encode($text);
  return $text;
}

sub read_vectors {
  my ($file) = @_;

  open my $handle, '<:raw', $file or die "Cannot read $file: $!\n";
  my $content = do { local $/ = undef; <$handle> };
  close $handle or die "Cannot read $file: $!\n";
  return JSON::PP->new->utf8->decode($content);
}
