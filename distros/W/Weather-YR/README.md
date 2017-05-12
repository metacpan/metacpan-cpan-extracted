# NAME

Weather::YR - Object-oriented interface to Yr.no's weather service.

# VERSION

Version 0.38.

# SYNOPSIS

    use Weather::YR;
    use DateTime::TimeZone;

    my $yr = Weather::YR->new(
        lat => 63.590833,
        lon => 10.741389,
        tz  => DateTime::TimeZone->new( name => 'Europe/Oslo' ),
    );

    foreach my $day ( @{$yr->location_forecast->days} ) {
        say $day->date . ':';
        say ' ' x 4 . 'Temperature = ' . $day->temperature->celsius;

        foreach my $dp ( @{$day->datapoints} ) {
            say ' ' x 4 . 'Wind direction: ' . $dp->wind_direction->name;
        }
    }

    # If you are interested in the weather right now (*):

    my $now = $yr->location_forecast->now;

    say "It's " . $now->temperature->celsius . "C outside.";
    say "Weather status: " . $now->precipitation->symbol->text;

    # (*) "Right now" is actually lying, as the data from Yr is always
    #     a _forecast_, ie. what the weather will be like. The now()
    #     method simply picks the closest data point in time.

# DESCRIPTION

This is an object-oriented interface to Yr.no's free weather service located at
[https://api.met.no/](https://api.met.no/).

# METHODS

## location\_forecast

Returns a [Weather::YR::LocationForecast](https://metacpan.org/pod/Weather::YR::LocationForecast) instance.

# TODO

- Improve the documentation.
- Add more tests.
- Add support for more of Yr.no's APIs.
- Translate wind speed names/descriptions.

# BUGS

Please report any bugs or feature requests via the web interface at
[https://rt.cpan.org/Public/Dist/Display.html?Name=Weather-YR](https://rt.cpan.org/Public/Dist/Display.html?Name=Weather-YR), or via
the github interface at [https://github.com/toreau/Weather-YR/issues](https://github.com/toreau/Weather-YR/issues).

# AUTHORS

- Tore Aursand, 2014-2016, `toreau@gmail.com`
- Knut-Olav Hoven, 2008-2014, `knut-olav@hoven.ws`

# LICENSE AND COPYRIGHT

Copyright 2014-2016, ABC Startsiden.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
