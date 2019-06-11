package WWW::AzimuthAero;
$WWW::AzimuthAero::VERSION = '0.1';

# ABSTRACT: Parser for https://azimuth.aero/


use strict;
use warnings;
use utf8;
use feature 'say';
use Carp;

use Mojo::DOM;
use Mojo::UserAgent;

use WWW::AzimuthAero::Utils qw(:all);
use WWW::AzimuthAero::RouteMap;

use Data::Dumper;
use Data::Dumper::AutoEncode;


sub new {
    my ( $self, $ua ) = @_;
    $ua = Mojo::UserAgent->new() unless defined $ua;

    # get cookies, otheerwise will be 403 error
    my $req = $ua->get('https://booking.azimuth.aero/');

    # get route map
    my $route_map = $req->res->dom->find('script')
      ->grep( sub { $_->text =~ /\/\/ Route map/ } )->first->text;
    $route_map = extract_js_glob_var( $route_map, 'data.routes' );

    bless {
        ua        => $ua,
        route_map => WWW::AzimuthAero::RouteMap->new($route_map)
    }, $self;
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
            push @dates, get_dates_from_dows(%$interval);
        }
        return sort_dates(@dates);
    }
    else {
        carp "No schedule available between "
          . $params{from} . " and "
          . $params{to}
          . ", url : $url"
          if $params{v};
        return get_dates_from_range( min => $params{min}, max => $params{max} );
    }
}


# assume that aray is already sorted by lowest price

sub print_flights {
    my ( $self, @flights ) = @_;
    my $str;

    for my $f (@flights) {

        my $transfer_time = $f->{has_stops} ? $f->{flight_duration} : '';

        $str .=
            $f->{fares}{lowest} . "\t"
          . $f->{date} . "\t"
          . $f->{from} . '->'
          . $f->{to}
          . $transfer_time
          . "\n                                                                                                                                                                                                                          ";
    }

    return $str;
}

sub _get_fares {
    my ( $self, $dom ) = @_;
    my $fares          = {};
    my @possible_fares = qw/legkiy vygodnyy optimalnyy svobodnyy/;

    for my $class (@possible_fares) {
        my $tdom =
          $dom->at( 'div.td_fare.' . $class . ' span.sf-price__value.rub' );
        if ($tdom) {
            my $f = $tdom->text;
            $f =~ s/\D+//g;
            $fares->{$class} = $f;

            # $fares->{lowest} = $f if ( $f < $fares->{lowest} );
        }
    }

    $fares->{lowest} = 99999;
    for my $fare ( values %$fares ) {
        $fares->{lowest} = $fare if ( $fare < $fares->{lowest} );
    }

    return $fares;
}

# leave only digits and :
sub _fix_time {
    my ( $self, $time ) = @_;
    $time =~ s/(?![\d:]).//g;
    $time =~ s/[\r\n\t]//g;
    return $time;
}

sub _get_flight_data {
    my ( $self, $dom ) = @_;

    # div.ts-flight_summary
    my %stops_data;
    if ( my $stops = $dom->at('div.ts-flight__duration div.ts-flight__stops') )
    {
        if ( $stops->text =~ /пересадк/ ) {
            $stops_data{has_stops} = 1;
            $stops_data{flight_duration} =
              $dom->at('div.ts-flight__duration div.ts-flight__dur')->text;
            $stops_data{flight_duration} =~ s/[\r\n\t]//g;
            $stops_data{flight_duration} =~ s/^\s+//;
            $stops_data{flight_duration} =~ s/\s+$//;
        }
    }

    return {
        arrival => $self->_fix_time(
            $dom->at('div.ts-flight__arrival div.ts-flight__time')->text
        ),
        departure => $self->_fix_time(
            $dom->at('div.ts-flight__deparure div.ts-flight__time')->text
        ),
        %stops_data
    };
}


sub get {
    my ( $self, %params ) = @_;

    confess "from is not defined" unless defined $params{from};
    confess "to is not defined"   unless defined $params{to};
    confess "date is not defined" unless defined $params{date};

    my $url =
        'https://booking.azimuth.aero/!/'
      . $params{from} . '/'
      . $params{to} . '/'
      . $params{date}
      . '/1-0-0/';
    my $req        = $self->{ua}->get($url);
    my $target_dom = $req->res->dom->at('div.sf-day__content');

    if ( ref($target_dom) eq 'Mojo::DOM' ) {

        my @res;

        for my $flight_dom ( $target_dom->find('div.sf-flight-block')->each ) {

            my $fhash = {
                flight => $self->_get_flight_data($flight_dom),
                fares  => $self->_get_fares($flight_dom),
                %params
            };

            push @res, $fhash;

        }

        return \@res;

    }
    else {
        return { error => 'No flights found' };
    }
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

    for my $i ( 0 .. $#available_dates ) {

        my $date_str = $available_dates[$i];
        say $params{from} . '->'
          . $params{to} . ' : '
          . ( $i + 1 ) . '/'
          . scalar @available_dates
          if $params{progress_bar};

        my $flights = $self->get(
            from => $params{from},
            to   => $params{to},
            date => $date_str
        );

        #warn Dumper $flights;
        $self->print_flights(@$flights) if $params{print_immediately};

        push @fares, @$flights
          if ( ref($flights) eq 'ARRAY' );
    }

# say scalar @fares . ' days of direct flights with available tickets found' if $params{progress_bar};

    return sort { $a->{date} cmp $b->{date} } @fares;
}


# TO-DO: confess if max_date < now

sub get_lowest_fares {
    my ( $self, %params ) = @_;

    my @fares = $self->get_fares_schedule(%params);

    if ( $params{check_neighbors} ) {

        my @from_neighbors =
          $self->route_map->get_neighbor_airports_iata( $params{from} );
        my @to_neighbors =
          $self->route_map->get_neighbor_airports_iata( $params{to} );

# say 'Will check neighbor airports also : '.join("\t",@from_neighbors,@to_neighbors) if ($params{progress_bar});
        say '== neighbours : ' . join( " ", @from_neighbors, @to_neighbors );

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

    return sort { $a->{fares}{lowest} <=> $b->{fares}{lowest} } @fares;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AzimuthAero - Parser for https://azimuth.aero/

=head1 VERSION

version 0.1

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

This module provides a parser for https://azimuth.aero/

Module can be useful for creating price monitoring services and flexible travel planners

Module uses L<Mojo::UserAgent> as user agent and  L<Mojo::DOM> + L<JavaScript::V8> as DOM parser

=head1 FOR DEVELOPERS

How to generate DOM samples for unit tests after git clone: 

    $ perl -Ilib -e "use WWW::AzimuthAero::Mock; WWW::AzimuthAero::Mock->generate()"

See L<WWW::AzimuthAero::Mock> and L<Mojo::UserAgent::Mockable> for more details

=head1 TO-DO

implement find_transits

Checking more than 1 transfer

L<WWW::AzimuthAero/get_fares_schedule> get requests debug stat

=head1 new

    use WWW::AzimuthAero;
    my $az = Azimuth->new();

=head1 route_map  

Return L<WWW::AzimuthAero::RouteMap> object

    perl -Ilib -MWWW::AzimuthAero -MData::Dumper::AutoEncode -e 'my $x = WWW::AzimuthAero->new->route_map->raw; warn eDumper $x;'

=head1 get_schedule_dates

Get schedule by requested direction

    $az->get_schedule_dates( from => 'ROV', to => 'KLF' );
    
    $az->get_schedule_dates( from => 'ROV', to => 'PKV', max => '20.06.2019' ); # will start search from today
    
    $az->get_schedule_dates( from => 'ROV', to => 'PKV', min => '16.06.2019', max => '20.06.2019' );

Return list of available dates in '%d.%m.%Y' format

Method is useful for minimize amount of API requests

If no available_to property set (like at https://azimuth.aero/ru/flights?from=ROV&to=PKV ) will return all dates in range

=head1 print_flights

    my @x = $az->get_lowest_fares( from => 'ROV', to => 'MOW', max => '16.06.2019', progress_bar => 1 );
    $az->print_flights(@x);

=head1 get

Checks for flight between two cities on selected date. 

Cities are specified as IATA codes.

    $az->get( from => 'ROV', to => 'LED', date => '04.06.2019' );

Return ARRAYref with flights data of hash with error like 

    { 'error' => 'No flights found' }

Example output 

    [
        {
            'date' => '16.06.2019',
            'fares' => { 'lowest' => '5620', 'svobodnyy' => '5620' },
            'to' => 'KLF',
            'from' => 'ROV',
            'flight' => { 'arrival' => '11:35', 'departure' => '10:00' }
        },from is not defined
        ...
    ];

Example of output if flight has transfers :

[
      {
        'date' => '12.06.2019',
        'fares' => {
                     'lowest' => '6930',
                     'optimalnyy' => '8430',
                     'svobodnyy' => '16360',
                     'vygodnyy' => '6930'
                   },
        'to' => 'PKV',
        'flight' => {
                      'flight_duration' => '5ч 35м',
                      'has_stops' => 1,
                      'departure' => '07:45',
                      'arrival' => '13:20'
                    },
        'from' => 'ROV'
      }
    ];

( flight property will have has_stops option )

=head1 get_fares_schedule

Get fares schedule between selected cities. Cities are specified as IATA codes.

Returned data is sorted by date, ascending

    $az->get_lowest_fares(
        from         => 'ROV',
        to           => 'LED',
        min          => '7.06.2019',
        max          => '15.06.2019',
        progress_bar => 1,
    );

=head1 get_lowest_fares

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
        # max_edges     => 2    # hardcoded cow
    );

=head1 AUTHOR

Pavel Serikov <pavelsr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
