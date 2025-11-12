
use v5.38;
use Test::More;
use WebService::Akeneo::Transport;
use WebService::Akeneo::Config;
use WebService::Akeneo::Paginator;
use Mojo::UserAgent;
use Mojo::Message::Response;

plan skip_all => 'Author test' unless $ENV{AUTHOR_TESTING};

{ package DummyAuth; use v5.38; sub new { bless {}, shift } sub refresh_if_needed { 1 } sub bearer { 'X' } }

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

my $page = 0;
no warnings 'redefine';
*Mojo::UserAgent::start = sub ($self, $tx) {
  $page++;
  my $res = Mojo::Message::Response->new;
  $res->headers->content_type('application/json');
  if ($page == 1) {
    $res->code(200);
    $res->body('{"_embedded":{"items":[{"id":1},{"id":2}]},"_links":{"next":{"href":"https://example.test/api/rest/v1/foo?page=2&limit=2"}}}');
  } else {
    $res->code(200);
    $res->body('{"_embedded":{"items":[{"id":3}]}}');
  }
  $tx->res($res);
  return $tx;
};
use warnings;

$t->set_ua($ua);

my $p = WebService::Akeneo::Paginator->new( transport => $t );
my $all = $p->collect('/foo', limit => 2);

is_deeply($all, [ {id=>1},{id=>2},{id=>3} ], 'collected items from paginated _links.next');
done_testing;
