
use v5.38;
use Test::More;

my @modules = qw(
  WebService::Akeneo
  WebService::Akeneo::Config
  WebService::Akeneo::Auth
  WebService::Akeneo::Transport
  WebService::Akeneo::Paginator
  WebService::Akeneo::Resource::Categories
  WebService::Akeneo::Resource::Products
  WebService::Akeneo::HTTPError
);

for my $m (@modules) {
  use_ok($m) or diag "cannot load $m";
}

done_testing;
