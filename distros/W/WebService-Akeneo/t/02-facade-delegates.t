
use v5.38;
use Test::More;
use WebService::Akeneo;
use WebService::Akeneo::Config;

my $ak = WebService::Akeneo->new(
  config => WebService::Akeneo::Config->new(
    base_url      => 'https://example.test',
    client_id     => 'id',
    client_secret => 'sec',
    username      => 'u',
    password      => 'p',
  )
);

ok($ak->can('categories'), 'categories accessor exists');
ok($ak->categories->can('upsert_ndjson'), 'resource method upsert_ndjson exists');
done_testing;
