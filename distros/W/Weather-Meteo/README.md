# NAME

Weather::Meteo - Interface to [https://open-meteo.com](https://open-meteo.com) for historical weather data

# VERSION

Version 0.05

# SYNOPSIS

      use Weather::Meteo;

      my $meteo = Weather::Meteo->new();
      my $weather = $meteo->weather({ latitude => 0.1, longitude => 0.2, date => '2022-12-25' });

# DESCRIPTION

Weather::Meteo provides an interface to open-meteo.com
for historical weather data from 1940.

# METHODS

## new

    my $meteo = Weather::Meteo->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $meteo = Weather::Meteo->new(ua => $ua);

    my $weather = $meteo->weather({ latitude => 51.34, longitude => 1.42, date => '2022-12-25' });
    my @snowfall = @{$weather->{'hourly'}->{'snowfall'}};

    print 'Number of cms of snow: ', $snowfall[1], "\n";

## weather

    use Geo::Location::Point;

    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    # Print snowfall at 1AM on Christmas morning in Ramsgate
    $weather = $meteo->weather($ramsgate, '2022-12-25');
    @snowfall = @{$weather->{'hourly'}->{'snowfall'}};

    print 'Number of cms of snow: ', $snowfall[1], "\n";

## ua

Accessor method to get and set UserAgent object used internally. You
can call _env\_proxy_ for example, to get the proxy information from
environment variables:

    $meteo->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle('open-meteo.com' => 1);
    $meteo->ua($ua);

# AUTHOR

Nigel Horne, `<njh@bandsman.co.uk>`

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at [https://open-meteo.com](https://open-meteo.com).

# BUGS

# SEE ALSO

Open Meteo API: [https://open-meteo.com/en/docs#api\_form](https://open-meteo.com/en/docs#api_form)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Weather::Meteo

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/release/Weather-Meteo](https://metacpan.org/release/Weather-Meteo)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Weather-Meteo](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Weather-Meteo)

- CPANTS

    [http://cpants.cpanauthors.org/dist/Weather-Meteo](http://cpants.cpanauthors.org/dist/Weather-Meteo)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Weather-Meteo](http://matrix.cpantesters.org/?dist=Weather-Meteo)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Weather-Meteo](http://deps.cpantesters.org/?module=Weather-Meteo)

# LICENSE AND COPYRIGHT

Copyright 2023 Nigel Horne.

This program is released under the following licence: GPL2
