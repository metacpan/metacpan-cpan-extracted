# NAME

WWW::YahooJapan::Baseball - Fetches Yahoo Japan's baseball stats

# SYNOPSIS

    use WWW::YahooJapan::Baseball;
    use Data::Dumper;

    my $client = WWW::YahooJapan::Baseball->new(date => '20151001', league => 'NpbPl');
    for my $game ($client->games) {
      my %stats = $game->player_stats;
      print Dumper \%stats;
    }

# DESCRIPTION

WWW::YahooJapan::Baseball provides a way to fetch Japanese baseball stats via Yahoo Japan's baseball service.

# LICENSE

Copyright (C) Shun Takebayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shun Takebayashi <shun@takebayashi.asia>
