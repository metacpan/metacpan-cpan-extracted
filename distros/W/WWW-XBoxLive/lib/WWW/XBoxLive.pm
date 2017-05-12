use strict;
use warnings;

package WWW::XBoxLive;
{
  $WWW::XBoxLive::VERSION = '1.123160';
}

# ABSTRACT: Get XBox Live Gamercard information

use WWW::XBoxLive::Gamercard;
use WWW::XBoxLive::Game;

use LWP::Simple              ();
use HTML::TreeBuilder::XPath ();

# the gamercard url
use constant GAMERCARD_URL => 'http://gamercard.xbox.com/%s/%s.card';

# if a user has this avatar, they are not a user
use constant INVALID_AVATAR =>
  'http://image.xboxlive.com//global/t.FFFE07D1/tile/0/20000';


sub new {
    my $class = shift;
    my $args  = shift || {};
    my $self  = {};

    bless( $self, $class );

    $self->{region} = $args->{region} || 'en-US';

    return $self;
}


sub get_gamercard {
    my ( $this, $gamertag ) = @_;

    # get the html
    my $html =
      LWP::Simple::get( sprintf( GAMERCARD_URL, $this->{region}, $gamertag ) );

    # parse
    my $gamercard = $this->_parse_gamercard($html);

    return $gamercard;
}

# parse the HTML
sub _parse_gamercard {
    my ( $this, $html ) = @_;

    # generate HTML tree
    my $tree = HTML::TreeBuilder::XPath->new_from_content($html);

    # get the gamertag
    my $gamertag = _trimWhitespace( $tree->findvalue('//title') );

    # is valid? If not, then skip everything else
    my $gamerpic = $tree->findvalue('//img[@id="Gamerpic"]/@src');
    if ( $gamerpic eq INVALID_AVATAR ) {
        return WWW::XBoxLive::Gamercard->new(
            gamertag => $gamertag,
            is_valid => 0,
        );
    }

    my $bio = _trimWhitespace( $tree->findvalue('//div[@id="Bio"]') );
    my $gamerscore =
      _trimWhitespace( $tree->findvalue('//div[@id="Gamerscore"]') );
    my $motto    = _trimWhitespace( $tree->findvalue('//div[@id="Motto"]') );
    my $location = _trimWhitespace( $tree->findvalue('//div[@id="Location"]') );
    my $name     = _trimWhitespace( $tree->findvalue('//div[@id="Name"]') );
    my $profile_link = $tree->findvalue('//a[@id="Gamertag"]/@href');

    # guess account status
    my $account_status = 'unknown';
    if ( $tree->exists('//body/div[@class=~ /Gold/]') ) {
        $account_status = 'gold';
    }
    elsif ( $tree->exists('//body/div[@class=~ /Silver/]') ) {
        $account_status = 'silver';
    }

    # find gender
    my $gender = 'unknown';
    if ( $tree->exists('//body/div[@class=~ /Male/]') ) {
        $gender = 'male';
    }
    elsif ( $tree->exists('//body/div[@class=~ /Female/]') ) {
        $gender = 'female';
    }

    # count the reputation stars
    my @reputation_stars =
      $tree->findnodes('//div[@class="RepContainer"]/div[@class="Star Full"]');
    my $reputation = scalar @reputation_stars;

    # games
    my @recent_games;
    my $i = 1;
    while (
        my $title = $tree->findvalue(
            '//ol[@id="PlayedGames"]/li[' . $i . ']/a/span[@class="Title"]'
        )
      )
    {
        my $last_played =
          $tree->findvalue( '//ol[@id="PlayedGames"]/li[' 
              . $i
              . ']/a/span[@class="LastPlayed"]' );
        my $earned_gamerscore =
          $tree->findvalue( '//ol[@id="PlayedGames"]/li[' 
              . $i
              . ']/a/span[@class="EarnedGamerscore"]' );
        my $available_gamerscore =
          $tree->findvalue( '//ol[@id="PlayedGames"]/li[' 
              . $i
              . ']/a/span[@class="AvailableGamerscore"]' );
        my $earned_achievements =
          $tree->findvalue( '//ol[@id="PlayedGames"]/li[' 
              . $i
              . ']/a/span[@class="EarnedAchievements"]' );
        my $available_achievements =
          $tree->findvalue( '//ol[@id="PlayedGames"]/li[' 
              . $i
              . ']/a/span[@class="AvailableAchievements"]' );
        my $percentage_complete =
          $tree->findvalue( '//ol[@id="PlayedGames"]/li[' 
              . $i
              . ']/a/span[@class="PercentageComplete"]' );

        my $game = WWW::XBoxLive::Game->new(
            available_achievements => $available_achievements,
            available_gamerscore   => $available_gamerscore,
            earned_achievements    => $earned_achievements,
            earned_gamerscore      => $earned_gamerscore,
            last_played            => $last_played,
            percentage_complete    => $percentage_complete,
            title                  => $title,
        );

        push @recent_games, $game;
        $i++;
    }

    # to ensure we do not have memory leaks
    $tree->delete;

    # create new gamercard
    my $gamercard = WWW::XBoxLive::Gamercard->new(
        account_status => $account_status,
        bio            => $bio,
        gamerscore     => $gamerscore,
        gamertag       => $gamertag,
        gender         => $gender,
        is_valid       => 1,
        location       => $location,
        motto          => $motto,
        name           => $name,
        profile_link   => $profile_link,
        recent_games   => \@recent_games,
        reputation     => $reputation,
    );

    return $gamercard;
}

# trims whitespace from a string
sub _trimWhitespace {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

1;


__END__
=pod

=head1 NAME

WWW::XBoxLive - Get XBox Live Gamercard information

=head1 VERSION

version 1.123160

=head1 SYNOPSIS

  my $xbox_live = WWW::XBoxLive->new();

  my $gamercard = $xbox_live->get('BrazenStraw3');

  say $gamercard->name;
  say $gamercard->bio;

  for my $game (@{ $gamercard->recent_games }){
    say $game->title;
    say $game->last_played;
  }

=head1 DESCRIPTION

This is a module to get and parse an XBox Live Gamercard (i.e. L<http://gamercard.xbox.com/en-US/BrazenStraw3.card>).

=head1 METHODS

=head2 new(region => 'en-US')

Create a new WWW::XBoxLive object. Optionally takes a region argument, which defaults to 'en-US'.

=head2 get_gamercard( $gamertag )

Get a gamercard. Returns an L<WWW::XBoxLive::Gamercard> object.

=head1 SEE ALSO

=over 4

=item *

L<WWW::XBoxLive::Gamercard>

=item *

L<WWW::XBoxLive::Game>

=back

=head1 CREDITS

Jason Clemons wrote a PHP version, which helped me write this version. It is available at L<https://github.com/JBlaze/Xbox-Gamercard-Data>.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

