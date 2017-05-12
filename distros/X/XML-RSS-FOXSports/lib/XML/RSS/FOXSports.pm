#=========================================================i======================
# Copyright (c) Brian Perez 2005. All rights reserved.
#--------------------------------------------------------------------------------
# This library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#================================================================================
package XML::RSS::FOXSports;

use 5.006;
use strict;
use warnings;

use XML::RSS::Parser;
use base qw(XML::RSS::Parser);

use Carp;
use LWP::UserAgent;
use XML::RSS::FOXSports::Constants qw(:feed_urls HEADLINE_BASE_URL TEAM_TO_ID);

our $VERSION = '0.02';

my $ua = LWP::UserAgent->new();
   $ua->agent('XML::RSS::FOXSports/'.$VERSION);

my $DEBUG = 0;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %opts  = @_;
  my $self  = $class->SUPER::new();
  $self->_set_fsutil unless $opts{NoUtil};
  $self->_set_fsmeta if $opts{Meta};
  $self->_set_debug  if $opts{Debug};
  return $self;
}

#-- AUTOLOAD ------
#-- used for method proxies
sub AUTOLOAD {
  our $AUTOLOAD;
  my ($method, $feed);
  ($method = $AUTOLOAD) =~ s/.*:://;
  warn "[dbg] method called: $method" if $DEBUG;
  die "$method is not a currently supported method" unless $method =~ /^parse_/;
  $feed = uc ((split('_', $method, 2))[1]);
  #-- headlines ----
  if (defined HEADLINE_FEED_URLS->{$feed}) {
    {
      no strict 'refs';
      *{$AUTOLOAD} =
        sub {
          my ($rss_xml, $message) = $_[0]->_get_rss_feed(HEADLINE_FEED_URLS->{$feed});
          croak "rss xml feed is empty with message $message" unless defined $rss_xml;
          $_[0]->_save_meta_data($feed, HEADLINE_FEED_URLS->{$feed}) if $_[0]->{_fsmeta};
          #-- for xml::rss::parser 4.0 compatibility
          return $_[0]->SUPER::parse_string($rss_xml) if $_[0]->SUPER::can('parse_string');
          return $_[0]->SUPER::parse($rss_xml);
        };
      goto &{$AUTOLOAD};
    }
  }
  #-- video ----
  elsif (defined VIDEO_FEED_URLS->{$feed}) {
    {
      no strict 'refs';
      *{$AUTOLOAD} =
        sub {
          my ($rss_xml, $message) = $_[0]->_get_rss_feed(VIDEO_FEED_URLS->{$feed});
          croak "rss xml feed is empty with message $message" unless defined $rss_xml;
          $_[0]->_save_meta_data($feed, VIDEO_FEED_URLS->{$feed}) if $_[0]->{_fsmeta};
          #-- for xml::rss::parser 4.0 compatibility
          return $_[0]->SUPER::parse_string($rss_xml) if $_[0]->SUPER::can('parse_string');
          return $_[0]->SUPER::parse($rss_xml);
        };
      goto &{$AUTOLOAD};
    }
  } #-- specific team (e.g., Giants, 49ers, Galaxy)
  elsif ($feed =~ /_TEAM$/) {
    my ($league, $ext) = split('_', $feed, 2);
    if (defined TEAM_TO_ID->{$league}) {
      croak 'sports team was not found, perhaps you forgot to supply one.' unless defined $_[1];
      {
        no strict 'refs';
        *{$AUTOLOAD} =
          sub {
            my $url = HEADLINE_BASE_URL . TEAM_TO_ID->{$league}->{lc $_[1]};
            my ($rss_xml, $message) = $_[0]->_get_rss_feed($url);
            croak "rss xml feed is empty with message $message" unless defined $rss_xml;
            $_[0]->_save_meta_data($league.'_'.lc $_[1], $url) if $_[0]->{_fsmeta};
            #-- for xml::rss::parser 4.0 compatibility
            return $_[0]->SUPER::parse_string($rss_xml) if $_[0]->SUPER::can('parse_string');
            return $_[0]->SUPER::parse($rss_xml);
          };
        goto &{$AUTOLOAD};
      }
    }
  }
  else {
    die "$method is not a currently supported method";
  }
}

#-- parse_team ------
sub parse_team {
  warn "[dbg] (parse_team) league:$_[1] team:$_[2]" if $DEBUG;
  TEAM_TO_ID->{uc $_[1]}           or die "the league $_[1] is not currently available";
  TEAM_TO_ID->{uc $_[1]}{lc $_[2]} or die "the team $_[2] is not currently available";
  my $sub = join('','parse_', $_[1], '_team');
  warn "[dbg] (parse_team) sub:$sub" if $DEBUG;
  $_[0]->$sub($_[2]);
}


#-- util methods ------
sub http_timeout     { $_[1] ? $ua->timeout($_[1]) : $ua->timeout }
sub last_parsed_url  { $_[0]->{_fsmeta}{last_parsed_url}  or ''   }
sub last_parsed_feed { $_[0]->{_fsmeta}{last_parsed_feed} or ''   }
sub parsed_feed      { $_[0]->{_fsmeta}{parsed_feeds}     or {}   }

sub get_feed_url {
  $_[0]->{_fsutil}
    ? $_[0]->{_fsutil}->get_feed_url($_[1])
    : $_[0]->_na;
}

sub get_feed_urls {
  $_[0]->{_fsutil}
    ? $_[0]->{_fsutil}->get_feed_urls
    : $_[0]->_na;
}

sub get_available_feeds {
  $_[0]->{_fsutil}
    ? $_[0]->{_fsutil}->get_available_feeds
    : $_[0]->_na;
}

sub get_available_teams {
  $_[0]->{_fsutil}
    ? $_[0]->{_fsutil}->get_available_teams
    : $_[0]->_na;
}

sub get_available_leagues {
  $_[0]->{_fsutil}
    ? $_[0]->{_fsutil}->get_available_leagues
    : $_[0]->_na;
}

sub get_available_headline_feeds {
  $_[0]->{_fsutil}
    ? $_[0]->{_fsutil}->get_available_headline_feeds
    : $_[0]->_na;
}

sub get_available_video_feeds {
  $_[0]->{_fsutil}
    ? $_[0]->{_fsutil}->get_available_video_feeds
    : $_[0]->_na;
}

sub get_available_leagues_teams  {
  $_[0]->{_fsutil}
    ? $_[0]->{_fsutil}->get_available_leagues_teams
    : $_[0]->_na;
}

sub debug { $_[1] ? $_[0]->_set_debug($_[1]) : $DEBUG }

sub DESTROY {
  my $self = shift;
  delete $self->{_fsutil};
  delete $self->{_fsmeta};
  #$self->SUPER::DESTROY;
}


#== PRIVATE METHODS ===================================

sub _get_rss_feed {
  my $res = $ua->get($_[1]);
  warn "[dbg] url requested: $_[1]" if $DEBUG;
  warn "[dbg] status line: $res->status_line" if $DEBUG;
  return $res->content, undef if $res->is_success;
  return undef, $res->status_line;
}

#-- avoid clashes
sub _set_fsutil {
  use XML::RSS::FOXSports::Utils;
  $_[0]->{_fsutil} = XML::RSS::FOXSports::Utils->new();
}

sub _set_fsmeta {
  $_[0]->{_fsmeta} = {
    last_parsed_feed => '',
    last_parsed_url  => '',
    parsed_feeds     => {},
  };
}

sub _na { "not available" }

sub _set_debug { $DEBUG = $_[1] || 1; }

sub _save_meta_data {
  $_[0]->{_fsmeta}{last_parsed_feed} = $_[1];
  $_[0]->{_fsmeta}{last_parsed_url}  = $_[2];
  $_[0]->{_fsmeta}{parsed_feeds}{$_[1]}++;
}


1;


__END__


=head1 NAME

XML::RSS::FOXSports - An XML::RSS::Parser subclass for parsing Foxsports.com RSS feeds.

=head1 SYNOPSIS

=head2 USING XML::RSS::Parser VERSION 2.15

  #!/usr/bin/perl -w

  use strict;
  use XML::RSS::FOXSports;

  my $fsp = new XML::RSS::FOXSports;
  my $soc_feed = $fsp->parse_soccer;
  my $mlb_feed = $fsp->parse_mlb;

  print "item count: ", $soc_feed->item_count()."\n\n";
  foreach my $i ( $soc_feed->items ) {
    map { print $_->name.": ".$_->value."\n" } $i->children;
    print "\n";
  }

  #-- retrieve values for attribution
  my $img = $mlb_feed->image();
  print $img->children('title')->value, "\n";
  print $img->children('url')->value,   "\n";
  print $img->children('link')->value,  "\n";
  print $img->children('width')->value, "\n";
  print $img->children('height')->value,"\n";

  my @leagues = $fsp->get_available_leagues
  my @teams   = $fsp->get_available_teams

=head2 USING XML::RSS::Parser VERSION 4.0

  #!/usr/bin/perl -w

  use strict;
  use XML::RSS::FOXSports;

  my $fsp = XML::RSS::FOXSports->new;
  my $glxy_feed = $fsp->parse_mls_team('galaxy');

  #-- output some values
  my $glxy_title = $glxy_feed->query('/channel/title');
  print $glxy_title->text_content,"\n";
  print $glxy_feed->item_count,   "\n";

  foreach my $i ( $glxy_feed->query('//item') ) {
    my $node = $i->query('title');
    print ' ', $node->text_content, "\n";
  }

=head1 ABSTRACT

XML::RSS::FOXSports is an XML::RSS::Parser subclass providing an object oriented interface
to FOXSports.com RSS 2.0 feeds.

=head1 DESCRIPTION

XML::RSS::FOXSports provides retrieval and parsing functionality for FOXSports.com's RSS 2.0 feeds.
It is a subclass of Timothy Appnel's L<XML::RSS::Parser>. This module has an object oriented interface and creates
a hidden HTTP client with L<LWP::UserAgent> for feed retrieval. Each XML::RSS::FOXSports parser
object encapsulates its own L<XML::RSS::FOXSports::Utils> object unless the C<NoUtil> option
is passed to the constructor method.

The naming conventions used in this module (e.g., method and team names) have followed those
from FOXSports.com's website as closely as possible. However, some method and team names
have additional alternatives or mnemonics where it seems intuitive.

Excepting the team parsing methods, all parsing methods name the feed they are retrieving.
For example the parse_soccer and parse_mlb methods parse the Soccer and MLB feeds respectively.

=head1 CAVEATS

=head2 XML::RSS::Parser VERSIONS

This module was originally written for and used with XML::RSS::Parser Version 2.15.
It has been modified for compatibility with XML::RSS::Parser Version 4.0
and has worked successfully with both versions. However, be aware that it
was intended for use with Version 2.15 and testing with version 4.0 has
been relatively limited.

=head2 FOXSPORTS.COM RSS FEED USAGE

FOXSports.com requires attribution for use of their content.

From FOXSports.com website:
"The feeds are free of charge to use for individuals and non-profit
organizations for non-commercial use. Attribution (included in each feed)
is required."

Please see the FOXSports.com RSS website for terms of use:
L<http://msn.foxsports.com/story/2005035>

=head1 METHODS

The following methods are provided in this package in addition
to those inherited from XML::RSS::Parser.

All parse_* methods retrieve the named RSS feed over HTTP, parse the feed,
and return a XML::RSS::Parser::Feed object. A die is thrown if a parse error occurs.

=over 4

=item new([NoUtil => 1])

Constructor method. The folowing options are allowed.

=item * NoUtil

Prevents creation of the XML::RSS::FOXSports::Utils object.
Access to its methods via a XML::RSS::FOXSports parser object
will not be available. See Below.

=back

=head2 HEADLINE FEEDS

These methods retrieve and parse the named RSS headline feed data.

=over 4

=item parse_soccer

=item parse_mlb

parse_baseball is an equivalant mnemonic

=item parse_headlines

=item parse_nfl

parse_football is an equivalant mnemonic

=item parse_ncaa_fb

parse_college_football is an equivalant mnemonic

=item parse_nba

parse_basketball is an equivalant mnemonic

=item parse_nhl

parse_hockey is an equivalant mnemonic

=item parse_ncaa_bk

parse_college_basketball is an equivalant mnemonic

=item parse_nascar

=item parse_golf

=item parse_tennis

=item parse_horseracing

=item parse_wnba

=back

=head2 VIDEO FEED PARSING METHODS

These methods retrieve and parse the named RSS video feed data.

=over 4

=item parse_most_watched_video

=item parse_top_news_video

=item parse_mlb_video

parse_baseball_video is an equivalant mnemonic

=item parse_nfl_video

parse_football_video is an equivalant mnemonic

=item parse_ncaa_fb_video

parse_college_football_video is an equivalant mnemonic

=item parse_nba_video

parse_basketball_video is an equivalant mnemonic

=item parse_nhl_video

parse_hockey_video is an equivalant mnemonic

=item parse_ncaa_bk_video

parse_college_basketball_video is an equivalant mnemonic

=item parse_more_video

=back

=head2 TEAM FEED PARSING METHODS

These methods retrieve and parse the RSS feed for a given sports team.
See the README file for the list of available league and team values.
Also see below

=over 4

=item parse_team($league, $team)

$league can be one of MLS, SOCCER, MLB, NFL, NBA, or NHL.
$team must be an existing team name within the given $league.
See the README file for the complete list of available team values.
Also see below.

=item parse_mls_team($team)

=item parse_mlb_team($team)

=item parse_nfl_team($team)

=item parse_nba_team($team)

=item parse_nhl_team($team)

=back

=head2 UTILITY METHODS

=over 4

=item http_timeout

Returns the current timeout value of the wrapped HTTP client requesting the RSS feed.

=item http_timeout($seconds)

Sets the timeout value of the wrapped HTTP client requesting the RSS feed.

=back

=head3 PROVIDED BY XML::RSS::FOXSports::Utils

These methods will not be available if the C<NoUtil> option
is passed to the constructor method.

=over 4

=item get_available_feeds

Returns a list of all headline and video feed names this package parses

=item get_available_headline_feeds

Returns a list of headline feed names this package parses

=item get_available_video_feeds

Returns a list of video feed names this package parses

=item get_available_leagues

Returns a list of league names that can be passed to the parse_team method

=item get_available_teams

Returns a list of all team names that can be passed to the parse_team method

=item get_available_leagues_teams

Returns a hash reference of teams names indexed by league name

=item get_feed_url($feed_name)

Returns the url of the named feed

=item get_feed_urls

Returns the urls for headline and video feeds

=back

=head2 LEAGUE AND TEAM OPTIONS FOR TEAM METHODS

The following league and team options are currently provided.

Usage example:
C<my $giants_feed = $fsp-E<gt>parse_team('MLB', 'giants');>

  MLS
    los_angeles      dc_united     columbus
    chicago          san_jose      fc_dallas
    real_salt_lake   colorado      metrostars
    new_england      kansas_city   chivas_usa

  MLB
    angels    astros      athletics   blue_jays    braves
    brewers   cardinals   cubs        devil_rays   diamondbacks
    dodgers   giants      indians     mariners     marlins
    mets      nationals   orioles     padres       phillies
    pirates   rangers     red_sox     reds         rockies
    royals    tigers      twins       white_sox    yankees

  NFL
    forty_niners   bears        bengals     bills      broncos
    browns         buccaneers   cardinals   chargers   chiefs
    colts          cowboys      dolphins    eagles     falcons
    giants         jaguars      jets        lions      packers
    panthers       patriots     raiders     rams       ravens
    redskins       saints       seahawks    steelers   texans
    titans         vikings

  NBA
    sixers        bobcats        bucks           bulls      cavaliers
    celtics       clippers       grizzlies       hawks      heat
    hornets       jazz           kings           knicks     lakers
    magic         mavericks      nets            nuggets    pacers
    pistons       raptors        rockets         spurs      suns
    supersonics   timberwolves   trail_blazers   warriors   wizards

  NHL
    avalanche   blackhawks    blue_jackets   blues       bruins
    canadiens   canucks       capitals       coyotes     devils
    flames      flyers        hurricanes     islanders   kings
    lightning   maple_leafs   mighty_ducks   oilers      panthers
    penguins    predators     rangers        red wings   sabres
    senators    sharks        stars          thrashers   wild


=head1 DEPENDENCIES

L<XML::Parser> L<XML::RSS::Parser> 2.15 L<Class::XPath>

=head1 SEE ALSO

L<XML::RSS::Parser::Element>, L<XML::RSS::Parser::Feed>,
L<XML::SAX>, L<XML::Elemental>, L<Class::ErrorHandler>

=head1 AUTHOR

Brian Perez <perez@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) Brian Perez 2005. All rights reserved.
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut




