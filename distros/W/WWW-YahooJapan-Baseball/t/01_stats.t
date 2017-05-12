use strict;
use Test::More 0.98;
use Data::Dumper;

use WWW::YahooJapan::Baseball::Parser;

subtest 'parsing stats' => sub {
  my $html = `gzip -cd t/stats.gz`;
  my %stats = WWW::YahooJapan::Baseball::Parser::parse_game_stats_page(html => $html, uri => 'http://baseball.yahoo.co.jp/npb/game/2015100102/stats');
  my $l55 = shift @{$stats{fielders}};
  is($l55->{statuses}->{ba}, '.359');
  like($l55->{player}->{name}, qr/秋山/);
};

done_testing;
