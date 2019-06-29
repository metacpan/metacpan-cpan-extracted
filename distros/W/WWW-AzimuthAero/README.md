# NAME

WWW::AzimuthAero - Parser for https://azimuth.aero/

# VERSION

version 0.31

# SYNOPSIS

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

# DESCRIPTION

This module provides a parser for [https://azimuth.aero/](https://azimuth.aero/)

Module can be useful for creating price monitoring services and flexible travel planners

Module uses [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) as user agent and  [Mojo::DOM](https://metacpan.org/pod/Mojo::DOM) + [JavaScript::V8](https://metacpan.org/pod/JavaScript::V8) as DOM parser

# INSTALLATION NOTES

Since this module depends on [JavaScript::V8](https://metacpan.org/pod/JavaScript::V8) you need to install libv8-3.14.5 libv8-3.14-dev on your system

# FOR DEVELOPERS

How to generate DOM samples for unit tests after git clone: 

    $ perl -Ilib -e "use WWW::AzimuthAero::Mock; WWW::AzimuthAero::Mock->generate()"

See [WWW::AzimuthAero::Mock](https://metacpan.org/pod/WWW::AzimuthAero::Mock) and [Mojo::UserAgent::Mockable](https://metacpan.org/pod/Mojo::UserAgent::Mockable) for more details

## API endpoints

urls that modules uses:

[https://booking.azimuth.aero/](https://booking.azimuth.aero/) (for fetching route map and initialize session)

[https://azimuth.aero/ru/flights?from=ROV&to=LED](https://azimuth.aero/ru/flights?from=ROV&to=LED) (for fetching schedule)

[https://booking.azimuth.aero/!/ROV/LED/19.06.2019/1-0-0/](https://booking.azimuth.aero/!/ROV/LED/19.06.2019/1-0-0/) (for fetching prices)

# TO-DO

\+ implement find\_transits at ["get\_lowest\_fares" in WWW::AzimuthAero](https://metacpan.org/pod/WWW::AzimuthAero#get_lowest_fares)

\+ implement check\_tickets at ["get" in WWW::AzimuthAero](https://metacpan.org/pod/WWW::AzimuthAero#get)

# MAIN METHODS

## new

    use WWW::AzimuthAero;
    my $az = Azimuth->new();
    # or my $az = Azimuth->new(ua_str => 'yandex-travel');

## get

Checks for flight between two cities on selected date. 

Cities are specified as IATA codes.

    $az->get( from => 'ROV', to => 'LED', date => '04.06.2019' );
    $az->get( from => 'ROV', to => 'LED', date => '04.06.2019', check_tickets => 1 );

You can also set adults params, from 1 to 9, and check\_tickets (auto check with adults from 9 to 1)

Those params may be convenient for monitoring tickets availability.

WARN: check\_tickets is not implemented yet

Return ARRAYref with [WWW::AzimuthAero::Flight](https://metacpan.org/pod/WWW::AzimuthAero::Flight) objects or hash with error like 

    { 'error' => 'No flights found' }

There could be two flights between same cities in same day 
so for unification this method always returns ARRAYref even if array contains one item

## route\_map  

Return [WWW::AzimuthAero::RouteMap](https://metacpan.org/pod/WWW::AzimuthAero::RouteMap) object

    perl -Ilib -MWWW::AzimuthAero -MData::Dumper::AutoEncode -e 'my $x = WWW::AzimuthAero->new->route_map; warn eDumper $x;'

## get\_schedule\_dates

Get schedule by requested direction

    $az->get_schedule_dates( from => 'ROV', to => 'KLF' );
    
    $az->get_schedule_dates( from => 'ROV', to => 'PKV', max => '20.06.2019' ); # will start search from today
    
    $az->get_schedule_dates( from => 'ROV', to => 'PKV', min => '16.06.2019', max => '20.06.2019' );

Return list of available dates in `'%d.%m.%Y'` format

Always return dates from today

Method is useful for minimize amount of API requests

If no available\_to property set (like at [https://azimuth.aero/ru/flights?from=ROV&to=PKV](https://azimuth.aero/ru/flights?from=ROV&to=PKV) ) 
will check for 2 months forward and return all dates in range

# HELPER METHODS

Useful for making CLI utilites

## possible\_fares

Return names of div.td\_fare CSS classes which contain prices

Current:

    qw/legkiy vygodnyy optimalnyy svobodnyy komfort/;

## find\_no\_schedule

Return hash with routes with no available schedule, presumably all transit routes.

## get\_fares\_schedule

Get fares schedule between selected cities. Cities are specified as IATA codes.

my @flights = $az->get\_fares\_schedule(
    from         => 'ROV',
    to           => 'LED',
    min          => '25.06.2019',
    max          => '30.06.2019',
    progress\_bar => 1,
    print\_immediately => 1,
    print\_table => 1
);

Returned list of [WWW::AzimuthAero::Flight](https://metacpan.org/pod/WWW::AzimuthAero::Flight) objects sorted by date, ascending

Params: 

from

to

min

max

progress\_bar - will print on STDOUT progress bar like 

    ROV->LED : 25.06.2019->30.06.2019
    1/3
    2/3
    3/3

print\_immediately - will print on STDOUT flight data immediately with progress bar like

    ROV->LED : 25.06.2019->30.06.2019
    1/3
    27.06.2019 10:00 07:20 A4 203 ROV LED
    2/3
    28.06.2019 10:00 07:20 A4 203 ROV LED
    3/3
    29.06.2019 09:50 07:10 A4 203 ROV LED

print\_table - will print on STDOUT result table like

## get\_lowest\_fares

Wrapper for ["get\_fares\_schedule" in WWW::AzimuthAero](https://metacpan.org/pod/WWW::AzimuthAero#get_fares_schedule)

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

# AUTHOR

Pavel Serikov <pavelsr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Pavel Serikov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
