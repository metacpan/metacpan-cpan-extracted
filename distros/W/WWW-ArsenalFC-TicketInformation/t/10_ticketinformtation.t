#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Deep;

use FindBin qw($Bin);

BEGIN { use_ok('WWW::ArsenalFC::TicketInformation'); }

use aliased 'WWW::ArsenalFC::TicketInformation::Match';
use aliased 'WWW::ArsenalFC::TicketInformation::Match::Availability';
use aliased 'WWW::ArsenalFC::TicketInformation::Category';

my $ticket_info = new_ok('WWW::ArsenalFC::TicketInformation');

my $html = open_html("$Bin/resources/buy-tickets-16-08-2012.htm");
$ticket_info->{tree} = HTML::TreeBuilder::XPath->new_from_content($html);
$ticket_info->fetch();

subtest 'Categories' => sub {
    plan tests => 1;
    my $actual = $ticket_info->categories;

    my @expected = (
        Category->new(
            category    => 'C',
            date_string => 'Saturday, August 18',
            opposition  => 'Sunderland',
        ),
        Category->new(
            category    => 'C',
            date_string => 'Saturday September 15',
            opposition  => 'Southampton',
        ),
        Category->new(
            category    => 'A',
            date_string => 'Saturday, September 29',
            opposition  => 'Chelsea',
        ),
        Category->new(
            category    => 'B',
            date_string => 'Saturday, October 27',
            opposition  => 'Queen\'s Park Rangers',
        ),
        Category->new(
            category    => 'B',
            date_string => 'Saturday, November 10',
            opposition  => 'Fulham',
        ),
        Category->new(
            category    => 'A',
            date_string => 'Saturday, November 17',
            opposition  => 'Tottenham Hotspur',
        ),
        Category->new(
            category    => 'C',
            date_string => 'Saturday, December 1',
            opposition  => 'Swansea City',
        ),
        Category->new(
            category    => 'C',
            date_string => 'Saturday, December 8',
            opposition  => 'West Bromwich Albion',
        ),
        Category->new(
            category    => 'B',
            date_string => 'Wednesday, December 26',
            opposition  => 'West Ham United',
        ),
        Category->new(
            category    => 'B',
            date_string => 'Saturday, December 29',
            opposition  => 'Newcastle United',
        ),
    );

    cmp_deeply( $actual, \@expected );
};

subtest 'Matches' => sub {
    plan tests => 1;
    my $actual = $ticket_info->matches;

    my @expected = (
        Match->new(
            competition     => 'Barclays Premier League',
            datetime_string => 'Saturday, August 18, 2012, 15:00',
            fixture         => 'Arsenal vs Sunderland',
            hospitality     => 1,
            is_soldout      => 0,
            can_exchange    => 1,
            category        => 'C',
        ),
        Match->new(
            competition     => 'Barclays Under-21 Premier League',
            datetime_string => 'Monday, August 20, 2012, 19:00',
            fixture         => 'Arsenal vs Bolton',
            hospitality     => 1,
            is_soldout      => 0,
            can_exchange    => 0,
            availability    => [
                Availability->new(
                    type        => Availability->FOR_SALE,
                    memberships => [ Availability->GENERAL_SALE ]
                )
            ],
        ),
        Match->new(
            competition     => 'Barclays Under-21 Premier League',
            datetime_string => 'Saturday, August 25, 2012, 14:00',
            fixture         => 'Arsenal vs Blackburn',
            hospitality     => 1,
            is_soldout      => 0,
            can_exchange    => 0,
            availability    => [
                Availability->new(
                    type        => Availability->FOR_SALE,
                    memberships => [ Availability->GENERAL_SALE ]
                )
            ],
        ),
        Match->new(
            competition     => 'Barclays Premier League',
            datetime_string => 'Sunday, August 26, 2012, 13:30',
            fixture         => 'Stoke City vs Arsenal',
            hospitality     => 0,
            is_soldout      => 1,
            can_exchange    => 0,
        ),
        Match->new(
            competition     => 'Barclays Premier League',
            datetime_string => 'Sunday, September 2, 2012, 13:30',
            fixture         => 'Liverpool vs Arsenal',
            hospitality     => 0,
            is_soldout      => 1,
            can_exchange    => 0,
        ),
        Match->new(
            competition     => 'Barclays Premier League',
            datetime_string => 'Saturday, September 15, 2012, 15:00',
            fixture         => 'Arsenal vs Southampton',
            hospitality     => 1,
            is_soldout      => 0,
            can_exchange    => 0,
            category        => 'C',
            availability    => [
                Availability->new(
                    type        => Availability->FOR_SALE,
                    memberships => [ Availability->SILVER ]
                ),
                Availability->new(
                    type        => Availability->SCHEDULED,
                    memberships => [ Availability->RED ],
                    date        => '20-08-2012'
                )
            ],
        ),
        Match->new(
            competition     => 'Barclays Premier League',
            datetime_string => 'Sunday, September 23, 2012, 16:00',
            fixture         => 'Manchester City vs Arsenal',
            hospitality     => 0,
            is_soldout      => 0,
            can_exchange    => 0,
            availability    => [
                Availability->new(
                    type        => Availability->SCHEDULED,
                    memberships => [
                        Availability->PLATINUM_GOLD, Availability->TRAVEL_CLUB
                    ],
                    date => '24-08-2012'
                )
            ],
        ),
        Match->new(
            competition     => 'Barclays Premier League',
            datetime_string => 'Saturday, September 29, 2012, 12:45',
            fixture         => 'Arsenal vs Chelsea',
            hospitality     => 1,
            is_soldout      => 0,
            can_exchange    => 0,
            category        => 'A',
            availability    => [
                Availability->new(
                    type        => Availability->SCHEDULED,
                    memberships => [ Availability->SILVER ],
                    date        => '23-08-2012'
                ),
                Availability->new(
                    type        => Availability->SCHEDULED,
                    memberships => [ Availability->RED ],
                    date        => '30-08-2012'
                )
            ],
        ),
        Match->new(
            competition     => 'Barclays Premier League',
            datetime_string => 'Saturday, October 27, 2012, 15:00',
            fixture         => 'Arsenal vs QPR',
            hospitality     => 1,
            is_soldout      => 0,
            can_exchange    => 0,

#category => 'C', # stored as QPR in one table and Queens Park Rangers in the other...
            availability => [
                Availability->new(
                    type        => Availability->SCHEDULED,
                    memberships => [ Availability->SILVER ],
                    date        => '28-08-2012'
                ),
                Availability->new(
                    type        => Availability->SCHEDULED,
                    memberships => [ Availability->RED ],
                    date        => '27-09-2012'
                )
            ],
        ),
    );

    cmp_deeply( $actual, \@expected );
};

sub open_html {
    my ($file) = @_;

    open( my $fh, '<:encoding(UTF-8)', $file )
      or die $!;
    my $hold = $/;
    undef $/;
    my $html = <$fh>;
    $/ = $hold;

    return $html;
}
