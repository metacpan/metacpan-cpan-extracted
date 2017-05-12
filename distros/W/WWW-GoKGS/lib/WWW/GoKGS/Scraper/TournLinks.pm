package WWW::GoKGS::Scraper::TournLinks;
use strict;
use warnings;
use Exporter qw/import/;
use WWW::GoKGS::Scraper::Declare;
use WWW::GoKGS::Scraper::Filters qw/datetime/;

our @EXPORT = qw( __build_tourn_links );

sub __build_tourn_links {
    my $self = shift;

    my @start_time = (
        sub {
            my $time = m/ will start at (.*)$/ && $1;
            $time ||= m/\(([^\-]+) -/ && $1;
            $time =~ tr/\x{a0}/ / if $time;
            $time;
        },
        \&datetime,
    );

    my @end_time = (
        sub {
            my $time = m/- ([^)]+)\)$/ && $1;
            $time =~ tr/\x{a0}/ / if $time;
            $time;
        },
        \&datetime,
    );

    my %entrants = (
        sort_by => [ 'TEXT', sub { s/^By // } ],
        uri => '@href',
    );

    my $round = scraper {
        process '.', 'round' => [ 'TEXT', sub { m/^Round (\d+) / && $1 } ],
                     'start_time' => [ 'TEXT', @start_time ];
        process 'a', 'end_time' => [ 'TEXT', @end_time ],
                     'uri' => '@href';
    };

    scraper {
        process '//ul[1]//li/a', 'entrants[]' => \%entrants;
        process '//ul[2]//li', 'rounds[]' => $round;
    };
}

1;
