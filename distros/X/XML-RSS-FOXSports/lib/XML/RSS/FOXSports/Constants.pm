#=========================================================i======================
# Copyright (c) Brian Perez 2005. All rights reserved.
#--------------------------------------------------------------------------------
# This library is free software; you can redistribute it  
# and/or modify it under the same terms as Perl itself.
#================================================================================
package XML::RSS::FOXSports::Constants;

use strict;
use warnings;

use Exporter;

our (@ISA, $VERSION, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

@ISA     = qw(Exporter);
$VERSION = '0.01';

@EXPORT      = qw(); #-- no default exports
@EXPORT_OK   = qw(HEADLINE_BASE_URL
                  VIDEO_BASE_URL
                  MOST_WATCHED_URL
                  HEADLINE_FEED_URLS 
                  VIDEO_FEED_URLS 
                  FEED_TYPE_TO_ID
                  TEAM_TO_ID);
%EXPORT_TAGS = (
  all => [ @EXPORT, @EXPORT_OK ],
  ids => [ qw(
    FEED_TYPE_TO_ID 
    TEAM_TO_ID
  )],
  feed_urls  => [ qw(
    HEADLINE_FEED_URLS 
    VIDEO_FEED_URLS
  )],
  base_urls  => [ qw(
    HEADLINE_BASE_URL
    VIDEO_BASE_URL
    MOST_WATCHED_URL
  )],

);

use constant {
  HEADLINE_BASE_URL => 'http://msn.foxsports.com/feedout/syndicatedContent?categoryId=',
  VIDEO_BASE_URL    => 'http://rss.video.msn.com/s/us/rss.aspx?t=Fox%20Sports&p=33&',
  MOST_WATCHED_URL  => 'http://rss.video.msn.com/s/us/rss.aspx?t=hotVideo&c=topsports&title=%20MSN%20Video%20-%20sports&p=05',
};

use constant {
  TOP_NEWS_QUERY      => 'c=Top%20News&title=Fox%20Sports%20video%20-%20Top%20news',
  MLB_VIDEO_QUERY     => 'c=Baseball%20News&title=Fox%20Sports%20video%20-%20Baseball%20News',
  NFL_VIDEO_QUERY     => 'c=NFL%20News&title=Fox%20Sports%20video%20-%20NFL%20news',
  NCAA_FB_VIDEO_QUERY => 'c=College%20FB%20News&title=Fox%20Sports%20video%20-%20College%20FB%20News',
  NBA_VIDEO_QUERY     => 'c=NBA%20News&title=Fox%20Sports%20video%20-%20NBA%20news',
  NHL_VIDEO_QUERY     => 'c=Hockey%20News&title=Fox%20Sports%20video%20-%20Hockey%20news',
  NCAA_BK_VIDEO_QUERY => 'c=College%20BK%20News&title=Fox%20Sports%20video%20-%20College%20BK%20News',
  MORE_VIDEO_QUERY    => 'c=More%20Fox%20Sports&title=Fox%20Sports%20video%20-%20More%20Fox%20Sports%25',
};

#-- feed category ids
use constant FEED_TYPE_TO_ID => {
  HEADLINES   => 0,
  SOCCER      => 176,
  MLB         => 49,
  BASEBALL    => 49,
  NFL         => 5,
  NBA         => 73,
  NHL         => 142,
  NCAA_FB     => 24,
  NCAA_BK     => 99,
  NASCAR      => 167,
  GOLF        => 220,
  TENNIS      => 199,
  HORSERACING => 241,
  WNBA        => 90,
};

#-- headline feed urls
use constant HEADLINE_FEED_URLS => {
  HEADLINES   => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{HEADLINES},
  SOCCER      => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{SOCCER},
  MLB         => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{MLB},
  BASEBALL    => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{MLB},
  NFL         => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NFL},
  FOOTBALL    => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NFL},
  NBA         => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NBA},
  BASKETBALL  => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NBA},
  NHL         => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NHL},
  HOCKEY      => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NHL},
  NCAA_BK     => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NCAA_BK},
  NCAA_FB     => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NCAA_FB},
  NASCAR      => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NASCAR},
  GOLF        => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{GOLF},
  TENNIS      => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{TENNIS},
  WNBA        => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{WNBA},
  HORSERACING => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{HORSERACING},
  COLLEGE_FOOTBALL   => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NCAA_BK},
  COLLEGE_BASKETBALL => HEADLINE_BASE_URL . FEED_TYPE_TO_ID->{NCAA_FB},
};
                                                                                                                                                                                                                                                                                                                            
#-- video feed urls
use constant VIDEO_FEED_URLS => {
  MOST_WATCHED_VIDEO => MOST_WATCHED_URL,
  TOP_NEWS_VIDEO     => VIDEO_BASE_URL . TOP_NEWS_QUERY,
  MLB_VIDEO          => VIDEO_BASE_URL . MLB_VIDEO_QUERY,
  BASEBALL_VIDEO     => VIDEO_BASE_URL . MLB_VIDEO_QUERY,
  NFL_VIDEO          => VIDEO_BASE_URL . NFL_VIDEO_QUERY,
  FOOTBALL_VIDEO     => VIDEO_BASE_URL . NFL_VIDEO_QUERY,
  NBA_VIDEO          => VIDEO_BASE_URL . NBA_VIDEO_QUERY,
  BASKETBALL_VIDEO   => VIDEO_BASE_URL . NBA_VIDEO_QUERY,
  NHL_VIDEO          => VIDEO_BASE_URL . NHL_VIDEO_QUERY,
  HOCKEY_VIDEO       => VIDEO_BASE_URL . NHL_VIDEO_QUERY,
  NCAA_BK_VIDEO      => VIDEO_BASE_URL . NCAA_BK_VIDEO_QUERY,
  NCAA_FB_VIDEO      => VIDEO_BASE_URL . NCAA_FB_VIDEO_QUERY,
  MORE_VIDEO         => VIDEO_BASE_URL . MORE_VIDEO_QUERY,
  COLLEGE_FOOTBALL_VIDEO   => VIDEO_BASE_URL . NCAA_FB_VIDEO_QUERY,
  COLLEGE_BASKETBALL_VIDEO => VIDEO_BASE_URL . NCAA_BK_VIDEO_QUERY,
};

use constant TEAM_TO_ID => {
  MLS => {
    los_angeles    => 381,
    galaxy         => 381,
    dc_united      => 371,
    united         => 371, 
    columbus       => 376,
    crew           => 376,
    chicago        => 375,
    fire           => 375,
    san_jose       => 382,
    earthquakes    => 382,
    quakes         => 382,
    dallas         => 377,
    fc_dallas      => 377,
    rsl            => 2422,
    real_salt_lake => 2422,
    colorado       => 379,
    rapids         => 379,
    metrostars     => 374,
    metros         => 374,
    new_england    => 373,
    revolution     => 373,
    revs           => 373,
    kansas_city    => 380,
    wizards        => 380,
    chivas         => 3465,
    chivas_usa     => 3465,
  },
  MLB => {
    angels       => '71589',
    astros       => '71604',
    athletics    => '71597',
    blue_jays    => '71600',
    braves       => '71601',
    brewers      => '71594',
    cardinals    => '71610',
    cubs         => '71602',
    devil_rays   => '71616',
    diamondbacks => '71615',
    dodgers      => '71605',
    giants       => '71612',
    indians      => '71591',
    mariners     => '71598',
    marlins      => '71614',
    mets         => '71607',
    nationals    => '71606',
    orioles      => '71587',
    padres       => '71611',
    phillies     => '71608',
    pirates      => '71609',
    rangers      => '71599',
    red_sox      => '71588',
    reds         => '71603',
    rockies      => '71613',
    royals       => '71593',
    tigers       => '71592',
    twins        => '71595',
    white_sox    => '71590',
    yankees      => '71596',
  },
  NFL => {
    forty_niners => '67059',
    niners       => '67059',
    bears        => '67040',
    bengals      => '67041',
    bills        => '67039',
    broncos      => '67044',
    browns       => '67042',
    buccaneers   => '67061',
    cardinals    => '67066',
    chargers     => '67068',
    chiefs       => '67049',
    colts        => '67048',
    cowboys      => '67043',
    dolphins     => '67052',
    eagles       => '67058',
    falcons      => '67038',
    giants       => '67056',
    jaguars      => '67064',
    jets         => '67057',
    lions        => '67045',
    packers      => '67046',
    panthers     => '67063',
    patriots     => '67054',
    raiders      => '67050',
    rams         => '67051',
    ravens       => '67065',
    redskins     => '67062',
    saints       => '67055',
    seahawks     => '67060',
    steelers     => '67067',
    texans       => '67071',
    titans       => '67047',
    vikings      => '67053',
  },
NBA => { 
    sixers        => 71094,
    bobcats       => 71951,
    bucks         => 71089,
    bulls         => 71078,
    cavaliers     => 71079,
    celtics       => 71076,
    clippers      => 71086,
    grizzlies     => 71103,
    hawks         => 71075,
    heat          => 71088,
    hornets       => 71077,
    jazz          => 71100,
    kings         => 71097,
    knicks        => 71092,
    lakers        => 71087,
    magic         => 71093,
    mavericks     => 71080,
    nets          => 71091,
    nuggets       => 71081,
    pacers        => 71085,
    pistons       => 71082,
    raptors       => 71102,
    rockets       => 71084,
    spurs         => 71098,
    suns          => 71095,
    supersonics   => 71099,
    timberwolves  => 71090,
    trail_blazers => 71096,
    warriors      => 71083,
    wizards       => 71101,
  },
  NHL => {
    avalanche    => 66316,
    blackhawks   => 66303,
    blue_jackets => 66328,
    blues        => 66318,
    bruins       => 66300,
    canadiens    => 66309,
    canucks      => 66321,
    capitals     => 66322,
    coyotes      => 66323,
    devils       => 66310,
    flames       => 66302,
    flyers       => 66314,
    hurricanes   => 66306,
    islanders    => 66311,
    kings        => 66307,
    lightning    => 66319,
    maple_leafs  => 66320,
    mighty_ducks => 66324,
    oilers       => 66305,
    panthers     => 66325,
    penguins     => 66315,
    predators    => 66326,
    rangers      => 66312,
    red_wings    => 66304,
    sabres       => 66301,
    senators     => 66313,
    sharks       => 66317,
    stars        => 66308,
    thrashers    => 66327,
    wild         => 66329,
  },
};


1;


__END__


=head1 NAME

XML::RSS::FOXSports::Constants - Constants used by XML::RSS::FOXSports.

=head1 DESCRIPTION

Constant variable definitions used by XML::RSS::FOXSports

=head1 AUTHOR

Brian Perez <perez@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) Brian Perez 2005. All rights reserved.
This library is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=cut 


