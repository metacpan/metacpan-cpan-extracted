
use v5.38;
use Test::More;
use WebService::Akeneo::Transport;
use WebService::Akeneo::Config;
use Mojo::UserAgent;
use Mojo::Message::Response;

plan skip_all => 'Author test' unless $ENV{AUTHOR_TESTING};

{ package DummyAuth;
  use v5.38;
  our $refreshed = 0;
  sub new { bless {}, shift }
  sub refresh_if_needed { 1 }
  sub bearer { 'X' }
  sub refresh_token { $refreshed = 1; 1 }
}

my $t = WebService::Akeneo::Transport->new(
  config => WebService::Akeneo::Config->new(
    base_url      => 'https://example.test',
    client_id     => 'id',
    client_secret => 'sec',
    username      => 'u',
    password      => 'p',
  ),
  auth => DummyAuth->new,
);

my $ua = Mojo::UserAgent->new;

my $call = 0;
no warnings 'redefine';
*Mojo::UserAgent::start = sub ($self, $tx) {
  $call++;
  my $res = Mojo::Message::Response->new;
  if ($call == 1) {
    $res->code(401);
    $res->headers->content_type('application/json');
    $res->body('{"message":"expired"}');
  } else {
    $res->code(200);
    $res->headers->content_type('application/json');
    $res->body('{}');
  }
  $tx->res($res);
  return $tx;
};
use warnings;

$t->set_ua($ua);
my $out = $t->request('GET','/ping');

ok($DummyAuth::refreshed, 'auth.refresh_token called after 401');
ok(ref $out eq 'HASH', 'second attempt returned JSON hash');

done_testing;
