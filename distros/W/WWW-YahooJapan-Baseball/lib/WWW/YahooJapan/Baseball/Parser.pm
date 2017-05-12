package WWW::YahooJapan::Baseball::Parser;

use utf8;

use Web::Scraper;

sub parse_games_page {
  my $date = shift;
  my $league = shift;
  my %params = @_;
  my $day_scraper = scraper {
    process_first '//*[@id="gm_sch"]/div[contains(@class, "' . $league . '")]', 'league_name' => 'TEXT';
    process '//*[@id="gm_sch"]/div[contains(@class, "' . $league . '")]/following-sibling::div[position() <= 2 and contains(@class, "NpbScoreBg")]//a[starts-with(@href, "/npb/game/' . $date . '") and not(contains(@href, "/top"))]', 'uris[]' => '@href';
  };
  my $res = $day_scraper->scrape(defined $params{html} ? ($params{html}, $params{uri}) : $params{uri});
  my %league_names = (
    NpbPl => 'パ･リーグ',
    NpbCl => 'セ･リーグ',
    NpbIl => '交流戦'
  );
  if ($res->{league_name} eq $league_names{$league}) {
    return @{$res->{uris}};
  }
  else {
    return ();
  }
}

sub parse_game_player_batting_row {
  my $cells = shift;
  my $stats = {};

  my %position_table = (
    '投' => 'p',
    '捕' => 'c',
    '一' => '1b',
    '二' => '2b',
    '三' => '3b',
    '遊' => 'ss',
    '左' => 'lf',
    '中' => 'cf',
    '右' => 'rf',
    '指' => 'dh',
    '打' => 'ph',
    '走' => 'pr'
  );
  my @positions = ();
  my $pos_rep = shift @$cells;
  if ($pos_rep =~ /^\((.*)\)$/) {
    my $i = 0;
    for my $p (split //, $1) {
      push(@positions, {
          position => $position_table{$p},
          is_starting => $i++ > 0 ? 0 : 1
      });
    }
  }
  else {
    for my $p (split //, $pos_rep) {
      push(@positions, {
          position => $position_table{$p},
          is_starting => 0
      });
    }
  }
  $stats->{positions} = \@positions;

  my $player_name = shift @$cells;

  $stats->{statuses} = {};
  for my $status (qw(ba)) {
    $stats->{statuses}->{$status} = shift @$cells;
  }

  $stats->{results} = {};
  for my $result (qw(ab r h rbi k bb_hbp sh_sf sb e hr)) {
    $stats->{results}->{$result} = 0 + shift @$cells;
  }

  my $abi = 1;
  $stats->{at_bats_by_innings} = {};
  for my $bat (@$cells) {
    $stats->{at_bats_by_innings}->{$abi++} = $bat ne '' ? [$bat] : [];
  }
  return $player_name, $stats;
}

sub parse_game_player_pitching_row {
  my $cells = shift;
  my $stats = {};

  my $wls_rep = shift @$cells;
  if ($wls_rep eq '○') {
    $stats->{wls} = 'w';
  }
  elsif ($wls_rep eq '●') {
    $stats->{wls} = 'l';
  }
  elsif ($wls_rep eq 'S') {
    $stats->{wls} = 's';
  }
  else {
    $stats->{wls} = '';
  }

  my $player_name = shift @$cells;

  $stats->{statuses} = {};
  for my $status (qw(era)) {
    $stats->{statuses}->{$status} = shift @$cells;
  }

  $stats->{results} = {};
  for my $result (qw(pi at pit h hr k bb_hbp r er)) {
    $stats->{results}->{$result} = 0 + shift @$cells;
  }

  return $player_name, $stats;
}

sub parse_game_stats_page {
  my %params = @_;
  my $stats_scraper = scraper {
    process '//*[@id="st_batth" or @id="st_battv"]//tr', 'batting_lines[]' => scraper {
      process '//td', 'cells[]' => 'TEXT';
      process_first '//a[contains(@href, "/npb/player")]', 'player_uri' => '@href';
    };
    process '//*[@id="st_pith" or @id="st_pitv"]//tr', 'pitching_lines[]' => scraper {
      process '//td', 'cells[]' => 'TEXT';
      process_first '//a[contains(@href, "/npb/player")]', 'player_uri' => '@href';
    };
  };
  my $res = $stats_scraper->scrape(defined $params{html} ? ($params{html}, $params{uri}) : $params{uri});
  my @fielders = ();
  for my $line (@{$res->{batting_lines}}) {
    my $cells = $line->{cells};
    unless ($cells and $line->{player_uri}) {
      next;
    }
    my ($player_name, $player_stats) = WWW::YahooJapan::Baseball::Parser::parse_game_player_batting_row($cells);
    $player_stats->{player} = {
      name => $player_name,
      uri => $line->{player_uri},
      $line->{player_uri}->query_form
    };
    push(@fielders, $player_stats);
  }
  my @pitchers = ();
  for my $line (@{$res->{pitching_lines}}) {
    my $cells = $line->{cells};
    unless ($cells and $line->{player_uri}) {
      next;
    }
    my ($player_name, $player_stats) = WWW::YahooJapan::Baseball::Parser::parse_game_player_pitching_row($cells);
    $player_stats->{player} = {
      name => $player_name,
      uri => $line->{player_uri},
      $line->{player_uri}->query_form
    };
    push(@pitchers, $player_stats);
  }
  ('fielders' => \@fielders, 'pitchers' => \@pitchers);
}

1;
