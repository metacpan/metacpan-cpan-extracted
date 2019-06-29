package WWW::AzimuthAero;
$WWW::AzimuthAero::VERSION = '0.31';

# ABSTRACT: Parser for https://azimuth.aero/


use strict;
use warnings;
use utf8;
use feature 'say';
use Carp;
use List::Util qw/min/;

use Mojo::DOM;
use Mojo::UserAgent;

use WWW::AzimuthAero::Utils qw(:all);
use WWW::AzimuthAero::RouteMap;
use WWW::AzimuthAero::Flight;

use Data::Dumper;
use Data::Dumper::AutoEncode;


sub new {
    my ( $self, %params ) = @_;
    $params{ua_obj} = Mojo::UserAgent->new() unless defined $params{ua_obj};
    $params{ua_str} =
'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.109 Safari/537.36'
      unless defined $params{ua_str};
    $params{ua_obj}->transactor->name( $params{ua_str} );

    # get cookies, otheerwise will be 403 error
    my $req = $params{ua_obj}->get('https://booking.azimuth.aero/');

    # get route map
    my $route_map = $req->res->dom->find('script')
      ->grep( sub { $_->text =~ /\/\/ Route map/ } )->first->text;
    $route_map = extract_js_glob_var( $route_map, 'data.routes' );

    bless {
        ua        => $params{ua_obj},
        route_map => WWW::AzimuthAero::RouteMap->new($route_map)
    }, $self;
}


sub get {
    my ( $self, %params ) = @_;

    confess "from is not defined" unless defined $params{from};
    confess "to is not defined"   unless defined $params{to};
    confess "date is not defined" unless defined $params{date};
    confess "date is not defined" unless defined $params{date};

    $params{adults} = 1 unless defined $params{adults};
    confess "adults > 9"
      if ( defined $params{adults} && ( $params{adults} > 9 ) );

    my $url =
        'https://booking.azimuth.aero/!/'
      . $params{from} . '/'
      . $params{to} . '/'
      . $params{date} . '/'
      . $params{adults} . '-0-0/';
    my $req        = $self->{ua}->get($url);
    my $target_dom = $req->res->dom->at('div.sf-day__content');

    if ( ref($target_dom) eq 'Mojo::DOM' ) {

        my @res;

        for my $flight_dom ( $target_dom->find('div.sf-flight-block')->each ) {

            my $flight = WWW::AzimuthAero::Flight->new(
                from_city   => $params{from},
                to_city     => $params{to},
                flight_date => $params{date}
            );

            my $stops_css =
              $flight_dom->at('div.ts-flight__duration div.ts-flight__stops');

            if ($stops_css) {
                if ( $stops_css->text =~ /пересадк/ ) {
                    $flight->has_stops(1);

                    warn "Dur: "
                      . fix_html_string $flight_dom->at(
                        'div.ts-flight__duration div.ts-flight__dur')->text;

                    $flight->trip_duration(
                        fix_html_string $flight_dom->at(
                            'div.ts-flight__duration div.ts-flight__dur')->text
                    );
                }
            }

            $flight->arrival_time(
                fix_html_string $flight_dom->at(
                    'div.ts-flight__arrival div.ts-flight__time')->text );

            $flight->departure_time(
                fix_html_string $flight_dom->at(
                    'div.ts-flight__deparure div.ts-flight__time')->text
            );

            $flight->flight_num(
                fix_html_string $flight_dom->at('div.ts-flight__num')->text );

            my $fares = {};
            for my $class ( $self->possible_fares() ) {
                my $tdom = $flight_dom->at(
                    'div.td_fare.' . $class . ' span.sf-price__value.rub' );
                if ($tdom) {
                    my $f = $tdom->text;
                    $f =~ s/\D+//g;    # remove all non-digits
                    $fares->{$class} = $f;
                }
            }

            $fares->{lowest} = min values %$fares;
            $flight->fares($fares);
            push @res, $flight;

        }

        return \@res;

    }

    # return die
    else {
        return { error => 'No flights found' };
    }
}


sub route_map {
    return shift->{route_map};
}


# ENDPOINT LIKE: https://azimuth.aero/ru/flights?from=ROV&to=ASF

sub get_schedule_dates {
    my ( $self, %params ) = @_;

    confess "from is not defined" unless defined $params{from};
    confess "to is not defined"   unless defined $params{to};

    my $url =
        'https://azimuth.aero/ru/flights?from='
      . $params{from} . '&to='
      . $params{to};
    my $res = $self->{ua}->get($url)->res->json;

    if ( ref( $res->{available_to} ) eq 'ARRAY' ) {

        my @dates;
        for my $interval ( @{ $res->{available_to} } ) {

            # warn "Interval : ".Dumper $interval;
            # $interval->{min}
            # $interval->{max}
            # $interval->{days}
            push @dates,
              get_dates_from_dows(%$interval)
              ;    # to-do : check min_date and max_date
        }

        # sort dates again for keeping sequence of interval
        return sort_dates(@dates);
    }
    else {
        carp "No schedule available between "
          . $params{from} . " and "
          . $params{to}
          . ", url : $url, most likely is transit route"
          if $params{v};

        return get_dates_from_range( min => $params{min}, max => $params{max} )
          ;    # to-do : check max_date
    }
}


sub possible_fares {
    return qw/legkiy vygodnyy optimalnyy svobodnyy komfort/;
}


sub find_no_schedule {
    my ( $self, %params ) = @_;

    my $iata_map = $self->route_map->route_map_iata;

    my %res = ();
    my $i;
    while ( my ( $from, $cities ) = each(%$iata_map) ) {
        for my $to (@$cities) {
            my $url =
              'https://azimuth.aero/ru/flights?from=' . $from . '&to=' . $to;
            my $res = $self->{ua}->get($url)->res->json;
            say $i;
            $res{$from} = $to if ( ref( $res->{available_to} ) ne 'ARRAY' );
            $i++;
        }
    }

    return %res;
}


sub get_fares_schedule {
    my ( $self, %params ) = @_;

    my @available_dates = $self->get_schedule_dates(%params);

    # filter schedule dates from now to max
    @available_dates = filter_dates(
        \@available_dates,
        max => $params{max},
        min => $params{min}
    );

    # warn "Dates : ".Dumper @available_dates;

    my @fares;

# say scalar @available_dates . ' days will be checked' if $params{progress_bar};

    say $params{from} . '->'
      . $params{to} . ' : '
      . $params{min} . '->'
      . $params{max}
      if $params{progress_bar};
    for my $i ( 0 .. $#available_dates ) {

        my $date_str = $available_dates[$i];

        say '' . ( $i + 1 ) . '/' . scalar @available_dates
          if $params{progress_bar};

        my $flights = $self->get(
            from => $params{from},
            to   => $params{to},
            date => $date_str
        );

        if ( ref($flights) eq 'ARRAY' ) {    # not error
            if ( $params{print_immediately} ) {
                say $_->as_string( order => [qw/flight_date/] ) for (@$flights);
            }
            push @fares, @$flights;
        }
    }

    if ( $params{print_table} ) {
        say $_->as_string( order => [qw/flight_date/], separator => "\t" )
          for (@fares);
    }

# say scalar @fares . ' days of direct flights with available tickets found' if $params{progress_bar};

    return sort { $a->flight_date cmp $b->flight_date } @fares;
}


sub get_lowest_fares {
    my ( $self, %params ) = @_;

    my @fares = $self->get_fares_schedule(%params);

    if ( $params{check_neighbors} ) {

        my @from_neighbors =
          $self->route_map->get_neighbor_airports_iata( $params{from} );
        my @to_neighbors =
          $self->route_map->get_neighbor_airports_iata( $params{to} );

# say 'Will check neighbor airports also : '.join("\t",@from_neighbors,@to_neighbors) if ($params{progress_bar});
# say '== neighbours : ' . join( " ", @from_neighbors, @to_neighbors );

        for my $from2 (@from_neighbors) {

            # warn "from 2 : ".$from2;
            push @fares,
              $self->get_fares_schedule(
                from         => $from2,
                to           => $params{to},
                min          => $params{min},
                max          => $params{max},
                progress_bar => $params{progress_bar},
              );
        }

        for my $to2 (@to_neighbors) {
            push @fares,
              $self->get_fares_schedule(
                from         => $params{from},
                to           => $to2,
                min          => $params{min},
                max          => $params{max},
                progress_bar => $params{progress_bar},
              );
        }

    }

    if ( $params{find_transits} ) {

        my $routes = $self->route_map->transfer_routes(
            from => $params{from},
            to   => $params{to}
        );

        # [ [ 'ROV', 'MOW', 'LED' ], [ 'ROV', 'KRR', 'LED' ] ]
        # to
        # [  { from => 'ROV', via => 'MOW', to => 'LED' }, ... ]
        my @flights = iata_pairwise($routes);

        # process transit flights
        # for my $x (@flights) {
        #     push @fares, $self->get_fares_schedule_transit(
        #         from         => $x->{from},
        #         via          => $x->{via},
        #         via          => $x->{to},
        #         min          => $params{min},
        #         max          => $params{max},
        #         progress_bar => $params{progress_bar},
        #         max_delay_days  => $params{max_delay_days}
        #     );
        # }

    }

    return sort { $a->fares->{lowest} <=> $b->fares->{lowest} } @fares;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AzimuthAero - Parser for https://azimuth.aero/

=head1 VERSION

version 0.31

=head1 SYNOPSIS

    use WWW::AzimuthAero;
    my $az = WWW::AzimuthAero->new();
    
    $az->get_schedule_dates( from => 'ROV', to => 'KLF' );
    
    $az->get( from => 'ROV', to => 'LED', date => '14.06.2019' );
    
    $az->get_lowest_fares( from => 'ROV', to => 'LED', max => '14.08.2019' );
    
    $az->print_flights(
        $az->get_lowest_fares(
            from          => 'ROV',
            to            => 'LED',
            max           => '14.08.2019',
            progress_bar => 1
        )
    )

Outside:

    perl -Ilib -MData::Dumper -MWWW::AzimuthAero -e 'my $x = WWW::AzimuthAero->new->route_map->transfer_routes; warn Dumper $x;'

=head1 DESCRIPTION

This module provides a parser for L<https://azimuth.aero/>

Module can be useful for creating price monitoring services and flexible travel planners

Module uses L<Mojo::UserAgent> as user agent and  L<Mojo::DOM> + L<JavaScript::V8> as DOM parser

=head1 INSTALLATION NOTES

Since this module depends on L<JavaScript::V8> you need to install libv8-3.14.5 libv8-3.14-dev on your system

=head1 FOR DEVELOPERS

How to generate DOM samples for unit tests after git clone: 

    $ perl -Ilib -e "use WWW::AzimuthAero::Mock; WWW::AzimuthAero::Mock->generate()"

See L<WWW::AzimuthAero::Mock> and L<Mojo::UserAgent::Mockable> for more details

=head2 API endpoints

urls that modules uses:

L<https://booking.azimuth.aero/> (for fetching route map and initialize session)

L<https://azimuth.aero/ru/flights?from=ROV&to=LED> (for fetching schedule)

L<https://booking.azimuth.aero/!/ROV/LED/19.06.2019/1-0-0/> (for fetching prices)

=head1 TO-DO

+ implement find_transits at L<WWW::AzimuthAero/get_lowest_fares>

+ implement check_tickets at L<WWW::AzimuthAero/get>

=head1 MAIN METHODS

=head2 new

    use WWW::AzimuthAero;
    my $az = Azimuth->new();
    # or my $az = Azimuth->new(ua_str => 'yandex-travel');

=head2 get

Checks for flight between two cities on selected date. 

Cities are specified as IATA codes.

    $az->get( from => 'ROV', to => 'LED', date => '04.06.2019' );
    $az->get( from => 'ROV', to => 'LED', date => '04.06.2019', check_tickets => 1 );

You can also set adults params, from 1 to 9, and check_tickets (auto check with adults from 9 to 1)

Those params may be convenient for monitoring tickets availability.

WARN: check_tickets is not implemented yet

Return ARRAYref with L<WWW::AzimuthAero::Flight> objects or hash with error like 

    { 'error' => 'No flights found' }

There could be two flights between same cities in same day 
so for unification this method always returns ARRAYref even if array contains one item

=head2 route_map  

Return L<WWW::AzimuthAero::RouteMap> object

    perl -Ilib -MWWW::AzimuthAero -MData::Dumper::AutoEncode -e 'my $x = WWW::AzimuthAero->new->route_map; warn eDumper $x;'

=head2 get_schedule_dates

Get schedule by requested direction

    $az->get_schedule_dates( from => 'ROV', to => 'KLF' );
    
    $az->get_schedule_dates( from => 'ROV', to => 'PKV', max => '20.06.2019' ); # will start search from today
    
    $az->get_schedule_dates( from => 'ROV', to => 'PKV', min => '16.06.2019', max => '20.06.2019' );

Return list of available dates in C<'%d.%m.%Y'> format

Always return dates from today

Method is useful for minimize amount of API requests

If no available_to property set (like at L<https://azimuth.aero/ru/flights?from=ROV&to=PKV> ) 
will check for 2 months forward and return all dates in range

=head1 HELPER METHODS

Useful for making CLI utilites

=head2 possible_fares

Return names of div.td_fare CSS classes which contain prices

Current:

    qw/legkiy vygodnyy optimalnyy svobodnyy komfort/;

=head2 find_no_schedule

Return hash with routes with no available schedule, presumably all transit routes.

=head2 get_fares_schedule

Get fares schedule between selected cities. Cities are specified as IATA codes.

my @flights = $az->get_fares_schedule(
    from         => 'ROV',
    to           => 'LED',
    min          => '25.06.2019',
    max          => '30.06.2019',
    progress_bar => 1,
    print_immediately => 1,
    print_table => 1
);

Returned list of L<WWW::AzimuthAero::Flight> objects sorted by date, ascending

Params: 

from

to

min

max

progress_bar - will print on STDOUT progress bar like 

    ROV->LED : 25.06.2019->30.06.2019
    1/3
    2/3
    3/3

print_immediately - will print on STDOUT flight data immediately with progress bar like

    ROV->LED : 25.06.2019->30.06.2019
    1/3
    27.06.2019 10:00 07:20 A4 203 ROV LED
    2/3
    28.06.2019 10:00 07:20 A4 203 ROV LED
    3/3
    29.06.2019 09:50 07:10 A4 203 ROV LED

print_table - will print on STDOUT result table like

=head2 get_lowest_fares

Wrapper for L<WWW::AzimuthAero/get_fares_schedule>

Main difference that it sort flights by price and can also checks neighbor airports

Get lowest fares between selected cities. Cities are specified as IATA codes.

    $az->get_lowest_fares(
        from            => 'ROV',
        to              => 'LED',
        min        => '7.06.2019',
        max        => '15.06.2019',
        progress_bar  => 1,
        check_neighbors => 1,   # will check PKV instead LED and KLG instead of MOW
        find_transits   => 1,   # will find transit cities that are not mentioned by azimuth
        max_delay_days  => 1,   
        # max_edges     => 2    # TO-DO, hardcoded for now
    );

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
