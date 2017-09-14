use Test::More;
use WebService::NextEpisode;
use Test::RequiresInternet ('next-episode.net' => 80);
plan tests => 1;
diag "Online check possible";

my $content = WebService::NextEpisode::of("Better Call Saul");

ok $content;
