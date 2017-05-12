use Test::More tests=>4;
use Cache::FileCache;
BEGIN {
  use_ok qw(WWW::Mechanize::Plugin::Cache);
}
use WWW::Mechanize::Pluggable;

system 'rm -rf t/testcache';

my $cache = Cache::FileCache->new({cache_root=>'t/testcache'});
my $mech = WWW::Mechanize::Pluggable->new(
  autocheck  => 0,
  cookie_jar => undef,
  cache=>$cache
);

$mech->get("http://yahoo.com");
ok $mech->success, "the webpage";

my $other_mech =  WWW::Mechanize::Pluggable->new(
  autocheck  => 0,
  cookie_jar => undef,
  cache=>$cache
);

$other_mech->get("http://yahoo.com");
ok $other_mech->success, "the webpage reloaded";

is $mech->content, $other_mech->content, "same (from cache)";

system 'rm -rf t/testcache';
