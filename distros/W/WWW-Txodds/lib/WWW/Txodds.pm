package WWW::Txodds;

use 5.006;
use strict;
use warnings;

require HTTP::Request::Common;
require LWP::UserAgent;
require XML::LibXML::Simple;
require Carp;

our $VERSION = '0.69';
use constant DEBUG => $ENV{TXODDS_DEBUG} || 0;

sub new {
    my $class = shift;
    my $self  = {@_};

    $self->{ua} ||= LWP::UserAgent->new( agent => "TXOdds-agent/$VERSION" );
    $self->{xml} ||= XML::LibXML::Simple->new;
    bless $self, $class;
}

sub odds_feed {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/odds/xml.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ),
        ForceArray => 'bookmaker' );
}

sub results_feed {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/result/xml.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub htcs_feed {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/odds/htftcrs.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub average_feed {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/average/xml.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub antepost_feed {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/odds/ap.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub boid_states {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/boid_states.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub starting_times {
    my ( $self, %params ) = @_;
    my $url = 'http://txodds.com/feed/starting_times.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub moves {
    my ( $self, %params ) = @_;
    my $url = 'http://www.txodds.com/feed/moves/xml.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub sports {
    my $self    = shift;
    my $content = $self->get('http://xml2.txodds.com/feed/sports.php');
    my $data = $self->parse_xml( $content, ValueAttr => [ 'sport', 'name' ] );

    my %sports;
    foreach (@$data) {
        $sports{ $_->{id} } = $_->{name};
    }
    return %sports;
}

sub mgroups {
    my ( $self, %params ) = @_;
    my $content =
      $self->get( 'http://xml2.txodds.com/feed/mgroups.php', \%params );
    my $data =
      $self->parse_xml( $content, ValueAttr => [ 'mgroup', 'sportid' ] );
    my %mgroups;
    foreach (@$data) {
        $mgroups{ $_->{name} } = $_->{sportid};
    }
    return %mgroups;
}

sub odds_types {
    my $self    = shift;
    my $content = $self->get('http://xml2.txodds.com/feed/odds_types.php');
    my $data    = $self->parse_xml( $content, ValueAttr => ['type'] );
    unless (@_) {
        my %obj;
        foreach (@$data) {
            $obj{ $_->{ot} } = $_->{name};
        }
        return \%obj;
    }
    else { return $data; }
}

sub offer_amounts {
    my ( $self, %params ) = @_;
    my $content =
      $self->get( 'http://xml2.txodds.com/feed/offer_amounts.php', \%params );
    my $data = $self->parse_xml( $content, ValueAttr => ['offer'] );
    my %obj;
    if ( ref $data eq 'ARRAY' ) {
        foreach (@$data) { $obj{ $_->{boid} } = $_->{amount}; }
    }
    elsif ( ref $data eq 'HASH' ) {
        $obj{ $$data{boid} } = $$data{amount};
    }
    return \%obj;
}

sub ap_offer_amounts {
    my $self = shift;
    my $content =
      $self->get('http://xml2.txodds.com/feed/ap_offer_amounts.php');
    my $data = $self->parse_xml( $content, ValueAttr => ['offer'] );
    return $data;
}

sub deleted_ap_offers {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/deleted_ap_offers.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub countries {
    my $self    = shift;
    my $content = $self->get('http://xml2.txodds.com/feed/countries.php');
    my $data    = $self->parse_xml( $content, ValueAttr => ['country'] );
    return $data;
}

sub competitors {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/competitors.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ),
        ValueAttr => ['competitor'] );
}

sub deleted_peids {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/deleted_peids.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub deleted_boids {
    my ( $self, %params ) = @_;
    my $url = 'http://xml2.txodds.com/feed/deleted_boids.php';
    @params{ 'ident', 'passwd' } = get_ident_passwd();
    return $self->parse_xml( $self->get( $url, \%params ) );
}

sub groups {
    my ( $self, %params ) = @_;
    my $content =
      $self->get( 'http://xml2.txodds.com/feed/groups.php', \%params );
    my $data = $self->parse_xml( $content, ValueAttr => ['group'] );

    return $data;
}

sub books {
    my ( $self, %params ) = @_;
    my $content =
      $self->get( 'http://xml2.txodds.com/feed/books.php', \%params );
    my $data = $self->parse_xml( $content, ValueAttr => ['bookmaker'] );

    return $data;
}

sub xml_schema {
    my $self    = shift;
    my $content = $self->get('http://xml2.txodds.com/feed/odds/odds.xsd');
    return $content;
}

sub create_get_request {
    my ( $self, $url, $params ) = @_;

    $url = URI->new($url);
    $url->query_form(%$params);

    HTTP::Request::Common::GET($url);
}

sub get {
    my $self = shift;

    my $request = $self->create_get_request(@_);

    warn "GET>\n" if DEBUG;
    warn $request->as_string if DEBUG;

    my $response = $self->{ua}->request($request);

    warn "GET<\n" if DEBUG;

    return $response->decoded_content;
}

sub parse_xml {
    my ( $self, $xml_string, %options ) = @_;

    my $obj = $self->{xml}->XMLin( $xml_string, %options );

    Carp::croak( "Wrong responce: " . $xml_string ) unless $obj;

    return $obj;
}

sub get_ident_passwd {
    my $self = shift;
    Carp::croak(
        "ident & passwd of http://txodds.com API required for this action")
      unless ( $self->{ident} && $self->{passwd} );
    return $self->{ident}, $self->{passwd};
}

sub clean_obj {
    my ( $self, $BadObj ) = @_;
    my %sports  = $self->sports();
    my %mgroups = $self->mgroups();

    my $obj->{'timestamp'} = $BadObj->{'timestamp'};
    $obj->{time} = $BadObj->{'time'};
    $obj->{'time'} =~
s/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):\d{2}\+\d{2}:\d{2}/$4:$5 $3-$2-$1/;
    while ( my ( $MatchId, $MatchObj ) = each %{ $BadObj->{match} } ) {
        my $Home =
          $MatchObj->{hteam}->{ each %{ $MatchObj->{hteam} } }->{content};
        my $Away =
          $MatchObj->{ateam}->{ each %{ $MatchObj->{ateam} } }->{content};
        my $Group =
          $MatchObj->{group}->{ each %{ $MatchObj->{group} } }->{content};
        my $MatchTime = $MatchObj->{'time'};
        $MatchTime =~
s/(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):\d{2}\+\d{2}:\d{2}/$4:$5 $3-$2-$1/;
        my $Sport = $sports{ $mgroups{$1} } if $Group =~ m/^([A-Z]+).*/;
        $Group =~ s/^[A-Z]+ (.*)/$1/;

        %{ $obj->{sport}->{$Sport}->{$Group}->{"$Home - $Away"} } = (
            MatchTime => $MatchTime,
            Home      => $Home,
            Away      => $Away
        );

        while ( my ( $BookmakerName, $BookmakerObj ) =
            each %{ $MatchObj->{bookmaker} } )
        {
            while ( my ( $OfferId, $OfferObj ) =
                each %{ $BookmakerObj->{offer} } )
            {
                my $ot = $OfferObj->{ot};
                if (
                    $ot == 0
                    && (   $OfferObj->{odds}->[0]->{o1}
                        || $OfferObj->{odds}->[0]->{o2}
                        || $OfferObj->{odds}->[0]->{o3} )
                  )
                {
                    %{ $obj->{sport}->{$Sport}->{$Group}->{"$Home - $Away"}
                          ->{bookmaker}->{$BookmakerName}->{offer}->{$ot} } = (
                        1 => $OfferObj->{odds}->[0]->{o1},
                        x => $OfferObj->{odds}->[0]->{o2},
                        2 => $OfferObj->{odds}->[0]->{o3}
                          );
                }
            }
        }
    }
    return $obj;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Txodds - TXOdds.com API Perl interface.

=head1 VERSION

Version 0.68

=head1 SYNOPSIS

Working with http://txodds.com API.

    my $tx = WWW::Txodds->new(
        ident  => 'ident',
        passwd => 'password'
    );

=head1 SUBROUTINES/METHODS

=head2 new

Constructor.

    my $tx = WWW::Txodds->new(
        ident  => 'ident',
        passwd => 'password'
    );

=head2 odds_feed

This method work with Standard XML Feed and Full Service Feed odds.

The Full Service Feed provides the same request options as the standard feed but supports the 
following additional options.    
For more information see
Standard XML Feed and Full Service Feed description
in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>).

Usage:

    my $obj = $tx->odds_feed();
    or
    my $obj = $tx->odds_feed(%params);
    
%params is a HASH with API request options:

=head3 Sport - Master ID Groups

TXODDS provides a list of specific Master ID Groups to allow you to request just the content for
the sport and country that you require. For a full list of codes please see mgroups() or Appendix 2 - Master ID
group codes in PDF doc.

Usage:

    mgid => 'code1,code2,code3'

Example:

    my $obj = $tx->odds_feed(mgid => '1072');
    or
    my $obj = $tx->odds_feed(mgid => '1018,1022');

=head3 Sport - Master ID Groups by name

Usage:

    mgstr => 'name1,name2'

Example:

    my $obj = $tx->odds_feed(mgstr => 'FB%'); 
    # This will request all Master ID names that start with FB% (all socker)
    
    my $obj = $tx->odds_feed(mgid => 'FBENG,FBFRA');
    # English and France socker

=head3 Sport - Bookmakers

If you made the above requests you would have received all bookmakers quoted prices. For
popular events there can be well over a hundred bookmaker odds on the TXODDS XML Feed.
See books() for information about requesting bookmaker codes.

Usage:

    bid => 'code1,code2,code3'

Example:

    my $obj = $tx->odds_feed(bid => '17,42,110,126'); 
    # Only selected bookmakers

=head3 Sport - Odds type

The Odds Type parameter allows you to select single or multiple odds types. For example you may
only be interested in Asian Handicap odds for your chosen sport or league or you may wish to
process different odds types separately to keep your program code less complex.
See odds_types() for information about requesting offer codes.

Usage:

    ot => 'code1,code2,code3'

Example:

    my $obj = $tx->odds_feed(ot => '0,5'); 
    # Only three way and Asian Handicap odds (0 and 5)

=head3 Sport - League/Event - Minor ID Groups

pgid is for selecting groups such as Premier League-06 by giving group number as a parameter.
See groups() for information about requesting Minor ID group codes.

Usage:

    pgid => 'code1,code2,code3'

Example:

    my $obj = $tx->odds_feed(pgid => '2760,2761'); 
    # FBENG 2006 Premier League and Coca Cola Championship

=head3 Odds order

The TXODDS feed allows you also to specify which order of quoted odds you require for a
particular purpose. Please refer to the table below for a detailed explanation

Usage:

    all_odds => 'code'

Codes:

=over 4

=item 0

(first/last) You will receive both the first odds (oldest) and last odds ( youngest or most recent) quoted by the bookmaker(s);

=item 1 

(all) You will receive all odds quoted from the first odds (oldest) to the last odds (most recent) quoted by the bookmaker(s);

=item 2 

(last) You will receive the last odds ( youngest or most recent) quoted by the bookmaker(s);

=item 3 

(first) You will receive the first odds (oldest) quoted by the bookmaker(s);

=back

Example:

    my $obj = $tx->odds_feed(all_odds => 2);

=head3 Timed requests

When any request is made the returned XML document provides a timestamp at the top of the
feed which shows the current TXODDS feed server time for that request.
If you want to receive odds updates rather than refresh all the odds then you can store this value
and use it in your next request.

The timestamp is in standard Unix timestamp format
For more information please see http://en.wikipedia.org/wiki/Unix_time

Usage:

    last => 'timestamp'

Example:

    my $obj = $tx->odds_feed(last => '1215264420');
    # To request all changes after 1215264420 (19th May 2007 13:27:00)

=head3 Active Price

TXODDS selects and extracts bookmakers odds (scanning) by a variety of methods. Should the
bookmakers website or server be unable and therefore TXODDS cannot verify that the odds are
either the same or have changed during the current scanning process then those odds are flagged
as inactive.

The timestamp is in standard Unix timestamp format
For more information please see http://en.wikipedia.org/wiki/Unix_time

Usage:

    active => 0 # It will return the last odds from the master database regardless of age
    #or
    active => 1 # It will return only the odds that have been found during the last scan i.e. verified as the latest and most recent odds This option should be used if you require verifiable prices

Example:

    my $obj = $tx->odds_feed(active => 1);

=head3 Match ID

The peid option is for selecting a single match by its matchid attribute as a parameter.

Usage:

    peid => xxxxxxx

Example:

    my $obj = $tx->odds_feed(peid => 789701);

=head3 Bet Offer ID

The boid option is for selecting a single offer via the offer_id attribute as a parameter.

The default odds type is ot=0 ( Match Odds ). If the bet offer is not ot=o then you will also need to add the odds
type to the request.

    ot => 1

Usage:

    boid => 63087469

Example:

    my $obj = $tx->odds_feed(peid => 789701);

=head3 Team ID

The pid option is for selecting a single teams odds using the team id ( hteam or ateam id) attribute as a parameter.

Usage:

    pid => xxxx

Example:

    my $obj = $tx->odds_feed(pid => 1592);
    # This will return all odds for Birmingham City English Soccer team

=head3 Date search

The required date range to search

Usage:

    %options = (
        date => 'StartDate,EndDate'
    );

Example:

    date => '2007-06-01,2007-06-30',

The date parameter accepts also the following values:
    yesterday - Yesterdays results;
    today     - Todays results;
    tomorrow  - Tomorrows results;
    now       - Current time + 24 hours;
    next xxx  - Specific day i.e. where xxx is day e.g. Tuesday, Wednesday, etc.

Note: You can also do date arithmetic using the following operators: -+ day / month / year

Examples:

    date => 'today',
    date => 'today,tomorrow +1 day',
    date => 'now + 1 day',
    date => 'next saturday',
    date => '2009-3-24'

=head3 Day search

A simpler way to search uses the days option

    days => number
       
Use the &days= feature to separate full odds loads easily (and therefore cutting down on file sizes).
The xml days-parameter simplifies data loading. It now accepts the following format:

    days => 'n,r',

where: n is the starting day relative to the current date and r is range (in days) so for example.
If the r parameter is not specified it works like before.

Example:

    days => '0,1', # To return all of today’s odds
    days => '0,2', # To return odds for the next 2 days
    days => '1,1'  # To return tomorrow's odds
    days => '0,-1' # To return yesterday's odds
    days => '1'    # Today
    days => '3'    # Next 3 days
    days => '-1'   # Yesterday
    days => '-3'   # Last 3 days

=head3 Hours Search

Hours parameter - now you can request any upcoming info within an hour range.
To get all matches/odds for any given time range by using the date parameter. For example this
returns all soccer fixtures for the next 24 hours:

Example:

    date => 'now,now+24hour',
        
=head3 Fixtures & results

To choose between fixtures or final results you can use the result option
    
Usage: 

    %options = (
           result => code
    );

Codes:

    0 - FIXTURE (To request FIXTURES only);
    1 - RESULT (To request RESULTS only).

Example: 

    result => 0

=head3 Response

odds_feed function return a HASH object with data about matches, odds etc.
    
    {
        'timestamp' => '1316685278',
        'time' => '2011-09-22T09:54:38+00:00',
        'match' => {
            '1576137' => {
                'xsid' => '0',
                'bookmaker' => {
                    'BETDAQ' => {
                        'bid' => '109',
                        'offer' => {
                            '77732329' => {
                                'n' => '1',
                                'last_updated' => '2011-09-22T06:19:06+00:00',
                                'flags' => '0',
                                'ot' => '0',
                                'bmoid' => '2309781',
                                'odds' => [
                                    {
                                        'o2' => '0',
                                        'o1' => '0',
                                        'starting_time' => '2011-09-20T11:00:00+00:00',
                                        'time' => '2011-09-20T22:52:17+00:00',
                                        'o3' => '0',
                                        'i' => '0'
                                    }

                                    ...

                                ]
                            }

                            ...

                        }

                        ...

                    }
                },
                'group' => {
                    '8932' => {
                        'content' => 'GOLF Austrian Golf Open-11'
                    }
                },
                'hteam' => {
                    '25541' => {
                        'content' => 'Forsyth, Alastair'
                    }
                },
                'time' => '2011-09-22T06:20:00+00:00',
                'ateam' => {
                    '25949' => {
                        'content' => 'Drysdale, David'
                    }
                },
                'results' => '',
            }

            ...

        }
    }

=head3 Standart Feed and Full Service Feed XML document structure

Basic XML document structure

The basic TXODDS XML document is structurally rather simple. Each element may have multiple
sub-elements based upon your request.
The XML document is made up of the following six elements:

    * XML Declaration
    * Matches Container
    * Match Element
    * Bookmaker Element
    * Offer Element
    * Odds Element

These are all comprehensively described below.

The Full Service Feed XML document is an extension of the Standard Feed to provide the additional
information for fixtures, live scoring and final results information so please refer to the Standard XML
Feed description for the base structure details. In this section we will just document the additional
elements in the feed.
    
The XML document is made up of the following ten elements:

    * XML Declaration
    * Matches Container
    * Match Element
        o Bookmaker Element
        o Offer Element
        o Odds Element
        o Results Element
        o Result Element
        o Periods Element
        o Scorer Element
        
=head3 Odds XML Schema Definition (XSD)

Please see xml_schema function description

=head2 results_feed

Fixtures & Results Feed description can be read in PDF documentation

Usage:

    my $results = $tx->results_feed(%options);

Options:

=head3 Date search

The required date range to search

Usage: 
    
    %options = (
        date => 'StartDate,EndDate'
    );

Example:

    date => '2007-06-01,2007-06-30',

The date parameter accepts also the following values:
    yesterday - Yesterdays results;
    today     - Todays results;
    tomorrow  - Tomorrows results;
    now       - Current time + 24 hours;
    next xxx  - Specific day i.e. where xxx is day e.g. Tuesday, Wednesday, etc.

Note: You can also do date arithmetic using the following operators: -+ day / month / year

Examples:

    date => 'today',
    date => 'today,tomorrow +1 day',
    date => 'now + 1 day',
    date => 'next saturday',
    date => '2009-3-24'

=head3 Day search

A simpler way to search uses the days option

Usage:

    days => number
       
Use the &days= feature to separate full odds loads easily (and therefore cutting down on file sizes).
The xml days-parameter simplifies data loading. It now accepts the following format:

    days => 'n,r',

where: n is the starting day relative to the current date and r is range (in days) so for example.
If the r parameter is not specified it works like before.

Example:

    days => '0,1', # To return all of today’s odds
    days => '0,2', # To return odds for the next 2 days
    days => '1,1'  # To return tomorrow's odds
    days => '0,-1' # To return yesterday's odds
    days => '1'    # Today
    days => '3'    # Next 3 days
    days => '-1'   # Yesterday
    days => '-3'   # Last 3 days
    
=head3 Sport - Master ID Groups

TXODDS provides a list of specific Master ID Groups to allow you to request just the content for
the sport and country that you require. For a full list of codes please see mgroups() or Appendix 2 - Master ID
group codes in PDF doc.

Usage:

    mgid => 'code1,code2,code3'

Example:

    my $obj = $tx->odds_feed(mgid => '1072');
    or
    my $obj = $tx->odds_feed(mgid => '1018,1022');

=head3 Sport - Master ID Groups by name

Usage:

    mgstr => 'name1,name2'

Example:

    my $obj = $tx->odds_feed(mgstr => 'FB%');
    # This will request all Master ID names that start with FB% (all socker)
    
    my $obj = $tx->odds_feed(mgid => 'FBENG,FBFRA');
    # English and France socker

Results XML Schema Definition (XSD)

An XML Schema definition is available that describes the Results XML. This can be used by various
development tools to simplify code generation/testing/feed parsing.

http://xml2.txodds.com/feed/result/result.xsd

=head2 htcs_feed

Half-time & Correct Score feed (more info in PDF doc)

Usage:

    my $data = $tx->htcs_feed();

Requesting specific information

This feed can be searched using all the same request options as per the Standard feed.

=head2 average_feed

See the Average feed description in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>).

Usage:

    my $data = $tx->average_feed();

Options:

=over 4

League/Event - Minor ID Groups
The pgid is for selecting different groups such as Champions League -07 by giving the group number as a parameter.

    pgid => 'code1,code2,code3'

Bookmakers
If you made the above requests you would have received all bookmakers quoted prices. For popular events there can be well over a hundred bookmaker odds on the TXODDS XML Feed.

    bid => 'code1,code2,code3'

Match ID
The peid option is for selecting a single match by its matchid attribute as a parameter.

    peid => xxxx

Team ID
The pid option is for selecting a single teams odds using the team id ( hteam or ateam id) attribute as a parameter.

    pid => xxxxxxx

Average type
The how option returns one of two averages.
The default ( how=0 ) returns the current average as calculated based on all bookmakers ( or selected bookmakers )
The default ( how=1 ) returns the initial average and can be used to compare with the current average to see how prices have changed over time.

    how => code
    # O - Provides the current average price ( default );
    # 1 - Provides the initial average price;

Show bookmakers odds
The showbookdata option can be used to stop the display of the bookmakers odds ‘expectations’ element. If you simply want the averages and don’t want all the bookmakers odds then use this option for greater efficiency.

    showbookdata => code
    # O - Suppresses the bookmakers odds from being returned;
    # 1 - Provides the bookmakers odds as normal ( default );

=back

=head2 antepost_feed

A separate webservice provides outright lines for major Soccer leagues and events.

Usage:

    my $data = antepost_feed();

Options:

=over 4

League/Event - Minor ID Groups
The pgid is for selecting different groups such as Champions League -07 by giving the group number as a parameter.

    pgid => 'code1,code2,code3'

Bookmakers
If you made the above requests you would have received all bookmakers quoted prices. For popular events there can be well over a hundred bookmaker odds on the TXODDS XML Feed.

    bid => 'code1,code2,code3'

Odds order
The Antepost feed allows you also to specify which order of quoted odds you require for a particular purpose. Please refer to the table below for a detailed explanation

    all_odds => code1,code2,code3
    # 0 - (first/last) You will receive both the first odds (oldest) and last odds ( youngest or most recent) quoted by the bookmaker(s);
    # 1 - (all) You will receive all odds quoted from the first odds (oldest) to the last odds (most recent) quoted by the bookmaker(s);
    # 2 - (last) You will receive the last odds ( youngest or most recent) quoted by the bookmaker(s);
    # 3 - (first) You will receive the first odds (oldest) quoted by the bookmaker(s);

=back

=head2 boid_states

Tracking OTB (Off-the-board) Offers

For clients who want to know each offers current validity in real time we have created a new webservice specifically for this purpose.

There are two options within this webservice as follows:

    * type=change ( default );
    * type=update;

Offer state changes ( type=change)

This webservice provides details of offers ‘state changes’ i.e. an offer that currently cannot be verified is marked as ‘inactive’, and if subsequently it is re-verified it is then marked as ‘active’ again.
The reasons for offers becoming invalid are down to 2 main reasons:

    * the offer has been removed/taken down by the bookmaker (hence OTB);
    * we cannot establish a connection with the bookmakers and hence cannot read the odds;

Note: If all odds for a bookie are OTB, then most likely it's a connection/network problem.

In the XML odds element we already have the "flags=" and "last_updated" attributes which show if the offer is active or inactive for a particular offer and the time it was last verified. However, unless all offers are refreshed then this information is soon out of date, and refreshing all the offers each time is very inefficient.
As offers are verified frequently if we updated the offers element with this new data then you’d be getting all the data refreshed all the time, so we have built the OTB feed to provide this functionality in a much more efficient manner.

Active->Inactive->Active state changes

With this feed we you can monitor any offers that go from active->inactive and then inactive->active
The first request always returns just the header, and the timestamp.
Use the timestamp on your next request, in the same way as you would for odds updates.
You should check that the offer id exists in your database or application, and then updates it accordingly with the new "last_updated" and "flags" values.
Your database or application will now be fully up to date with which offers are verified as currently valid, so you can be assured that your applications and/or traders can use them wioth confidence.

Usage:

    my $data = $tx->boid_states(last => 1235383825);

Options:

=over 4

Offer last updated time ( type => 'update')
This webservice provides details of the time when each offer was last verified as correct.
As an example usage on the TXODDS website we have colours showing when offers where "last updated" or "verified as correct".

    my $data = $tx->boid_states( type => 'update', last => 1235383825 );

=back

Please note that as offers are verified every few seconds, to every few minutes depending on the bookmaker, so then there will naturally be a lot of data sent via this webservice.
You can then use the "last_updated" time to update your database/application using the bet offer Id (boid) and the "last_updated" , "last_changed" and "flags" values as appropriate.
Your database or application will now be fully up to date with the last time offers have been verified, or changed as currently valid, so you can be assured that your applications and/or traders can use them with confidence.

See the Tracking OTB (Off-the-board) Offers description in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>)

=head2 starting_times

Bookmakers Starting Times

This webservice provides details of the starting times of events as posted by individual online
bookmakers. It is very common for conflicting data to be posted by bookmakers in relation to the
starting time of events, therefore this service was created to allow customers to find make informed
choices when selecting the time they use for their own purposes.

If the request returns no data (i.e. no updates have been received) or it is invalid for some reason you will still
receive an XML document with valid XML Declaration and matches container as above but it will of course not
contain any data.

It is also a good idea to provide XML document verification in your processing code to ensure that the entire
document has arrived successfully and is not malformed due to any transmission errors.

Usage:

    my $data = $tx->starting_times();

This feed can be searched using the last timestamp to get changes for example every minute.
        
=head2 moves

This web service allows you to see which odds are moving and identifies trends you may want
to bring to the attention of your traders and/or show to your customers as an added value
service.

Usage:

    my $data = $tx->moves();

Options:

    spid - by sport id
        spid => 1

=head2 xml_schema

An XML Schema definition is available that describes the Odds XML. This can be used by various
development tools to simplify code generation/testing/feed parsing.

Usage:

    my $schema = $tx->xml_schema();

Response:

    This function returns XML Schema from http://xml2.txodds.com/feed/odds/odds.xsd.

=head2 sports

This service provides a complete list of sports used within the feeds.

Usage:

    my %sports = $tx->sports();

Response:

    {
        sportid => 'sport name',
        ...
    }

=head2 mgroups
    
This method request all master groups from http://xml2.txodds.com/feed/mgroups.php.
 
Usage:

    my %mgroups = $tx->mgroups();

Response:

    {
        name => 'sportid',
        ...
    }   

Options:

    active - (boolean) request only active master groups;
    spid - select by spid (sport identifier).

Example:

    my %mgroups = $tx->mgroups(
        active => 1,
        spid   => 1
    );
    # select only soccer active groups

=head2 odds_types

This method return all odds types. For more information see
Appendix 13 in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>).

Usage:

    my %types = $tx->odds_types();

Response:

    {
        '1' => 'money line',
        '0' => 'three way',
        '3' => 'points',
        '4' => 'totals',
        '5' => 'asian handicap'
        ...
    };

Options:

    any option will return full response
    
Example:

    my %types = $tx->odds_types('full');
    #return full response

Response:

    [
        {
            'sname' => '1x2',
            'name' => 'three way',
            'ot' => '0'
        },
        ...
    ]

=head2 offer_amounts

This servise is resersed for including exchange matched amounts for standard odds. For more information see
Appendix 12 in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>).

Usage:

    my %oa = $tx->offer_amounts(date => '2011-04-02');

Options:

    date:
        YYYY-MM-DD            - For a cpecific date;
        YYY-MM-DD, YYYY-MM-DD - For a cpecific date range;
        today                 - Just for today;
        today+7               - For today plus 7 days;
    spid (Sport Id):
        1 - soccer;
        2 - hockey;
        Please see sports() for all sport id codes;
    boid (Bet Offer Id):
        xxxxxxx - Single bet offer id;
        xxxxxxx, yyyyyyy, zzzzzzz - multiple bet offer id;

Response:

    {
        %boid% => %amount%,
        ...
    }

=head2 ap_offer_amounts

Antepost Exchange Mathed Amounts Servise. This servise is resersed for including exchange matched amounts.
For more information see Appendix 11 in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>).

Usage:

    my $oa = $tx->ap_offer_amounts();

Response:

    [
        {
            'amount' => %amount%,
            'bid'    => %BookmakerId%,
            'pgid'   => %pgid%
        }
        ...
    ]
    
    #or
    
    {
        'amount' => %amount%,
        'bid'    => %BookmakerId%,
        'pgid'   => %pgid%
    }
    
    if amount is single.
    
    %amount% - monetary value of amounts of matched bets on exchanges;
    %BookmakerId% - bookmaker (exchange) identify code;
    %pgid% - offer id code. This maps directly to the offer id specified in the offer element section.

=head2 deleted_ap_offers

This servise allows a search for deleted offers on Antepost feed.
An offer refers to market/bookie/team combination.
When an offer for team is no longer 'valid' the offer id is available
on this webservise ths providing a complete audit trail of what has been available. 

Usage:

    my $offers = $tx->deleted_ap_offers();

=head2 countries

Country codes

Usage:

    $countries = $tx->countries();

Response:

    [
        {
            'cc'   => 'IRI',
            'name' => 'Iran',
            'id'   => '361'
        }
    ]

=head2 competitors

Competitors webservice
This webservice provides a comprehensive list of team and players names used by the feed.
For more information see Appendix 6 in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>).

Usage:

    my $competitors = $tx->competitors();

Options:

    pid     - by participant id i.e. the unique competitor number;
    pgrp    - by participant group name a combination of the sport and country (or league for US Sports) e.g. fbjpn is football Japan;
    cid     - by country id all competitors or teams within a particular country;
    spid    - by sport id – every sport has a unique identifier;
    name    - by alias name selection – shows all competitors that include a particular string.

Response:

    [
        {
            'group' => 'fbeng',
            'name' => 'Liverpool',
            'id' => '2452'
        },
        {
            'group' => 'fbeng',
            'name' => 'Liverpool B',
            'id' => '7965'
        }
    ];

=head2 deleted_peids

When a match is longer ‘valid’ its id is available on this webservice.
For example when a match has finished then it may need to be removed from any monitoring
application or database.

For more information see Appendix 5 in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>).

Usage:

    my $peids = $tx->deleted_peids();

Options:

    last - select by timestamp;

Response:

    {
        'peid' => {
            '345819' => {
                'time' => '2008-02-13T06:57:48+00:00'
            },
            '345816' => {
                'time' => '2008-02-13T05:57:07+00:00'
            },
            '345810' => {
                'time' => '2008-02-13T00:57:48+00:00'
            },
        },
        'timestamp' => '1202887315',
        'time' => '2008-02-13T07:21:55+00:00'
    };

=head2 deleted_boids

When an extraction or verification of odds fails the unique odds id is available on this webservice.
For example if a bookmaker takes down their website for maintenance their odds are no longer
valid they may need to be removed from any monitoring application or database.

For more information see Appendix 4 in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>).

Usage:

    my $boids = $tx->deleted_boids();

Options:

    last - select by timestamp;

Response:

    {
        'timestamp' => '1202887171',
        'time' => '2008-02-13T07:19:31+00:00',
        'boid' => {
            '23674997' => {
                'time' => '2008-02-13T00:27:18+00:00'
            },
            '23674994' => {
                'time' => '2008-02-13T00:27:18+00:00'
            },
            '23675000' => {
                'time' => '2008-02-13T00:27:18+00:00'
            },
        }
    }

=head2 groups 

This method request league or event names. See Appendix 3 in PDF documentation (C<http://txodds.com/v2/0/services.xml.html>) for more info.

Usage:

    my $groups = $tx->groups();

Options:

    sid  - select by year / season:
        ...
        sid => '08,09'
        # To find the leagues or events starting in 2008 and 2009;
    mgid - Select by master group:
        ...
        mgid => 1027
        # To find the International soccer;

Example:

    my $groups = $tx->groups({sid => '08,09', mgid => 1027});

Response:

    [
        {
            'sid' => '08',
            'date2' => '2009-01-01 00:00:00',
            'date1' => '2007-01-05 00:00:00',
            'fullname' => 'FBINT UEFA U21 Championship-08',
            'name' => 'UEFA U21 Championship',
            'mgroup' => {
                'content' => 'FBINT',
                'id' => '1027'
            },
            'id' => '3220'
        },
        {
            'sid' => '08',
            'date2' => '2008-12-12 00:00:00',
            'date1' => '2008-01-01 00:00:00',
            'fullname' => 'FBINT Africa Cup of Nations-08',
            'name' => 'Africa Cup of Nations',
            'mgroup' => {
                'content' => 'FBINT',
                'id' => '1027'
            },
            'id' => '3690'
        },
        {
            'sid' => '08',
            'date2' => '2008-12-23 00:00:00',
            'date1' => '2008-01-01 00:00:00',
            'fullname' => 'FBINT Pan-Pacific Champions-08',
            'name' => 'Pan-Pacific Champions',
            'mgroup' => {
                'content' => 'FBINT',
                'id' => '1027'
            },
            'id' => '3751'
        },
        ...
    ]
    Where:
        id       - TXODDS group id code;
        mgroup   - master group. See mgroups();
        name     - league or event text name;
        sid      - season ID or year of the event / league;
        fullname - full description including the league / event name and the season / year information;
        date1    - start date for this event / league;
        date2    - end date for this event / league.

=head2 books

Bookmaker codes. More info in Appendix 3 of PDF documentation (C<http://txodds.com/v2/0/services.xml.html>.

Usage:

    my $bookmakers = $tx->books();

Options:

    active - request all active bookmakers:
        ...
        active => 1,
        ...
    ot     - the odds type to search for:
        ...
        ot => 5,
        # or
        ot => '3,4',

Response:

    [
        {
            'flags' => '19',
            'name' => 'Centrebet',
            'id' => '2'
        },
        {
            'flags' => '19',
            'name' => 'Admiral',
            'id' => '4'
        },
        {
            'flags' => '19',
            'name' => 'Expekt',
            'id' => '5'
        },
        ...
    ]

=head2 get

Send GET request and return response content.

Usage:

    my $data = $tx->get( $url, \%params );

Example:

    my $url = 'http://www.vasya.com/index.html'
    my %params = (
        user => 'vasya',
        pass => 'paswd',
        data => 'sometxt'
    );
    my $data = $tx->get( $url, \%params );
    # GET http://www.vasya.com/index.html?user=vasya&pass=passwd&data=sometxt

=head2 parse_xml

Usage:

    my $obj = $tx->parse_xml($xml_string, [Parser options]);

Options:

    Function is use XML::LibXML::Simple module. See options of parser in documentation of this module.

=head2 create_get_request

Method create GET request with URI. Used by get().

Usage:

    my $request = $tx->create_get_request( $url, \%params );

=head2 clean_obj

Method for clean "bad" API data object, returned odds_feed(): delete unnecessary nodes, add sport node etc.

Usage:

    my $BadObj = $tx->odds_feed();
    my $GoodObj = $tx->clean_obj($BadObj);

Response:

    {
        'timestamp' => '%Timestamp%',
        'time' => '%Time%',
        'sport' => {
            %SportName% => {
                %GroupName% => {
                    %MatchName% => {
                        'bookmaker' => {
                            %BookmakerName% => {
                                'offer' => {
                                    %OfferCode% => {
                                        '1' => %Odd%,
                                        'x' => %Odd%,
                                        '2' => %Odd%
                                    },
                                    ...
                                }
                            }
                            ...
                        },
                        'Home' => %HomeTeam%,
                        'MatchTime' => %MatchTime%,
                        'Away' => %AwayTeam%
                    },
                    ...
                },
                ...
            },
            ...
        },
    }

    Where:
        %Timestamp%      - Unix timestamp;
        %Time%           - Current time 'hh:mm dd-mm-yyyy' (13:04 22-09-2011);
        %SportName%      - Name of sport. See sports() method description;
        %GroupName%      - Group, League, Division, etc.;
        %MatchName%      - Name of match ('First comand\player' - 'Second comand\player');
        %BookmakerName%  - Name of bookmaker;
        %OfferCode%      - Offer code;
        %Odd%            - Odd factor;
        %HomeTeam%       - First comand, home comand, first player, or favorite etc.;
        %AwayTeam%       - Second comand, home comand, second player etc.

=head2 get_ident_passwd

Return ident and passwd

    my %params;
    @params{ 'ident', 'passwd' } = get_ident_passwd();

=head1 AUTHOR

"Alexander Babenko"
C<foxcool@cpan.org>
L<http://foxcool.ru>

=head1 CONTRIBUTORS
"Sergey Romanov"
L<https://github.com/sergeyromanov>

=head1 BUGS

Please report any bugs or feature requests to C<bug-txodds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW::Txodds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Txodds


You can also look for information at:

=over 4

=item * GitHub:

L<https://github.com/Foxcool/WWW-Txodds>

=item * API documentation PDF:

L<http://txodds.com/v2/0/services.xml.html>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW::Txodds>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW::Txodds>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW::Txodds>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW::Txodds/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 "Alexander Babenko".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
