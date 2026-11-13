use 5.016;
use warnings;

use Digest::SHA qw(sha256_hex);
use Test::More;

use Twilio::Rest::Client;

plan skip_all => 'Signing needs Crypt::OpenSSL::RSA' if !eval { require Crypt::OpenSSL::RSA; 1 };

require Twilio::Http::ValidationClient;
require Twilio::Jwt::JWT;

my $DATA    = 't/data/client-validation';
my $PRIVATE = slurp('test-private-key.pem');
my $PUBLIC  = slurp('test-public-key.pem');
my %OPTIONS = (
  account_sid    => 'ACxx',
  api_key_sid    => 'SKxx',
  credential_sid => 'CRxx',
  private_key    => $PRIVATE,
);

subtest 'a create is signed' => sub {
  my ($client, $tiny) = client();
  $client->messages->create('+15558675309', { from => '+15017250604', body => 'Hello' });

  my ($sent) = $tiny->sent;
  my $token = header($sent, 'Twilio-Client-Validation');
  ok($token, 'the header is sent');

  is_deeply(
    Twilio::Jwt::JWT->get_header($token),
    { alg => 'RS256', typ => 'JWT', cty => 'twilio-pkrv;v=1', kid => 'CRxx' },
    'its header names the credential'
  );
  my $claims = Twilio::Jwt::JWT->decode($token, $PUBLIC);
  is($claims->{iss}, 'SKxx',               'issued by the API key');
  is($claims->{sub}, 'ACxx',               'for the account');
  is($claims->{hrh}, 'authorization;host', 'covering Authorization and Host');

  # Built here from what went out, not with the class under test.
  my $canonical = join "\n", 'POST', '/2010-04-01/Accounts/ACxx/Messages.json', q{},
    'authorization:' . header($sent, 'Authorization'), 'host:api.twilio.com', q{},
    'authorization;host',
    sha256_hex($sent->{content});
  is($claims->{rqh}, sha256_hex($canonical), 'the request as it was sent');
  like(header($sent, 'Authorization'), qr/\ABasic /, 'with the API key credentials');
};

subtest 'a read signs its sorted query' => sub {
  my ($client, $tiny) = client();
  $tiny->answer(200, '{"messages":[],"next_page_uri":null}');
  $client->messages->read({ to => '+15558675309', from => '+15017250604' }, 5);

  my ($sent) = $tiny->sent;
  like($sent->{url}, qr/[?]From=%2B15017250604&PageSize=5&To=%2B15558675309\z/, 'the query');
  my $canonical = join "\n", 'GET', '/2010-04-01/Accounts/ACxx/Messages.json',
    'From=%2B15017250604&PageSize=5&To=%2B15558675309',
    'authorization:' . header($sent, 'Authorization'), 'host:api.twilio.com', q{},
    'authorization;host', q{};
  my $claims = Twilio::Jwt::JWT->decode(header($sent, 'Twilio-Client-Validation'), $PUBLIC);
  is($claims->{rqh}, sha256_hex($canonical), 'no body, an empty hash');
};

subtest 'every request gets its own token' => sub {
  my ($client, $tiny) = client();
  $tiny->answer(200, '{"sid":"SM1"}');
  $client->messages('SM1')->fetch;
  $client->messages('SM2')->fetch;

  my @tokens = map { header($_, 'Twilio-Client-Validation') } $tiny->sent;
  isnt($tokens[0], $tokens[1], 'different requests, different tokens');
};

subtest 'a Host header from the caller is not signed' => sub {
  my $http = Twilio::Http::ValidationClient->new({%OPTIONS});
  my $request =
    { method => 'GET', url => 'https://api.twilio.com/x', headers => { Host => 'evil.test' } };
  my $claims    = Twilio::Jwt::JWT->decode($http->validation_token($request), $PUBLIC);
  my $canonical = join "\n", 'GET', '/x', q{}, 'host:api.twilio.com', q{}, 'authorization;host',
    q{};
  is($claims->{rqh}, sha256_hex($canonical), 'the host of the URL is');
};

subtest 'what is required' => sub {
  for my $name (sort keys %OPTIONS) {
    my %options = %OPTIONS;
    delete $options{$name};
    my $ok = eval { Twilio::Http::ValidationClient->new(\%options); 1 };
    ok(!$ok, "without $name");
    isa_ok($@, 'Twilio::Exceptions::ConfigurationException', "$name: the error");
  }

  my $ok =
    eval { Twilio::Http::ValidationClient->new({ %OPTIONS, private_key => 'not a key' }); 1 };
  ok(!$ok, 'a key that cannot sign fails at once');
  like($@, qr/RS256 needs an RSA private key in PEM form/, 'and says why');
};

done_testing;

sub client {
  my $tiny   = Local::Tiny->new;
  my $http   = Twilio::Http::ValidationClient->new({ %OPTIONS, http_tiny => $tiny });
  my $client = Twilio::Rest::Client->new('SKxx', 'secret',
    { account_sid => 'ACxx', http_client => $http, environment => {} });
  return ($client, $tiny);
}

sub header {
  my ($request, $name) = @_;
  my ($key) = grep { lc eq lc $name } keys %{ $request->{headers} };
  return defined $key ? $request->{headers}{$key} : undef;
}

sub slurp {
  my ($name) = @_;
  open my $handle, '<:raw', "$DATA/$name" or die "$DATA/$name: $!";    ## no critic (ErrorHandling::RequireCarping)
  my $content = do { local $/ = undef; <$handle> };
  close $handle or die "$DATA/$name: $!";                              ## no critic (ErrorHandling::RequireCarping)
  return $content;
}

# Stands in for HTTP::Tiny, keeping what would have gone out.
package Local::Tiny;

sub new     { return bless { sent => [], answer => [201, '{"sid":"SM1"}'] }, shift }
sub timeout { return }

sub answer {
  my ($self, $status, $content) = @_;
  $self->{answer} = [$status, $content];
  return;
}

sub request {
  my ($self, $method, $url, $arguments) = @_;
  push @{ $self->{sent} }, { method => $method, url => $url, %{$arguments} };
  return { status => $self->{answer}[0], content => $self->{answer}[1], headers => {} };
}

sub sent { return @{ $_[0]{sent} } }
