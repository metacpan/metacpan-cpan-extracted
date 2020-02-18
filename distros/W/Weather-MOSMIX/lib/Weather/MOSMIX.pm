package Weather::MOSMIX;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use DBI;
use JSON;
use DBD::SQLite 1.56; # some virtual table bugfixes
use Weather::MOSMIX::Weathercodes 'mosmix_weathercode';
use Storable 'dclone';
use Time::Piece;
use Encode 'encode', 'decode';

our $VERSION = '0.02';

=head1 NAME

Weather::MOSMIX - Reader for MOSMIX weather forecast files

=head1 SYNOPSIS

=cut

with 'MooX::Role::DBIConnection';

our $TIMESTAMP = '%Y-%m-%dT%H:%M:%S';

has 'json' => (
    is => 'lazy',
    default => sub {
		JSON->new()
	},
);

# Convert an array into an SQLite virtual table
# This should move into its own module/role, maybe
sub as_dbh( $table_name, $rows, $colnames=[keys %{ $rows->[0]}]) {
    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:',undef,undef,{AutoCommit => 1, RaiseError => 1,PrintError => 0});
    $dbh->sqlite_create_module(perl => "DBD::SQLite::VirtualTable::PerlData");

    $colnames = join ",", @$colnames;
    our $table_000;
    local $table_000 = $rows;
    my $tablevar = __PACKAGE__ . '::table_000';
    my $sql = qq(CREATE VIRTUAL TABLE "$table_name" USING perl($colnames, hashrefs="$tablevar"););
    $dbh->do($sql);

    return $dbh
}

sub forecast( $self, %options ) {
    my $cos_lat_sq = cos( $options{ latitude } ) ^ 2;
    my $res =
    $self->dbh->selectall_arrayref(<<'SQL', { Slice => {}}, $options{latitude}, $options{latitude}, $options{longitude},$options{longitude}, $cos_lat_sq);
        select *,
              ((l.latitude - ?)*(l.latitude - ?))
            + ((l.longitude - ?)*(l.longitude - ?)*?) as distance
            from forecast_location l
            join forecast f on l.name = f.name
            order by distance asc, expiry desc
            limit 1
SQL
    for (@$res) {
        $_->{forecasts} = $self->json->decode($_->{forecasts})
    };
    $res->[0]
};

sub forecast_dbh( $self, %options ) {
    my $res = $self->forecast( %options );
    # Convert from UTC to CET. This happens to work because my machines
    # are located within CET ...
    my $time = Time::Piece->strptime( $res->{issuetime}, $TIMESTAMP.'Z' );
    $time = $time->_mktime( $time->epoch, 1 );
    $time->tzoffset(2*3600); # at least until October ...

    #for my $i ($offset..$offset+$count-1) {
    #    my $c = $weathercode->{values}->[ $i ];
    #    if( length $c ) {
    #        my $v = sprintf '%02d', 0+$c;
    #        push @{ $weather }, {
    #            timestamp   => $time->new(),
    #            description => mosmix_weathercode($v),
    #        };
    #        $time += 3600;

    # zip ww and TTT to AoH
    my $hour_ofs;
    my @rows = map {
        my $ts = $time->new;
        $time += 3600;

        my $res = +{
            $res->{forecasts}->[0]->{type} => $res->{forecasts}->[0]->{values}->[$_],
            $res->{forecasts}->[1]->{type} => $res->{forecasts}->[1]->{values}->[$_],
            timestamp                      => $ts->strftime($TIMESTAMP),
            date                           => $ts->strftime('%Y-%m-%d'),
            hour                           => $ts->strftime('%H'),
            hour_ofs                       => $hour_ofs++,
            weekday                        => $ts->strftime('%a'),
            description                    => $res->{description},
            issuetime                      => $res->{issuetime}
        };
        my $descr = mosmix_weathercode($res->{ww}, 'emoji');
        $res->{emoji} = encode('UTF-8', $descr);
        length $res->{TTT} ? $res : ()
    } 0..$#{$res->{forecasts}->[0]->{values}};
    return as_dbh( 'forecast', \@rows )
}

sub format_forecast_range_concise {
    my( $ts, $temp, $weathercode, $offset, $count ) = @_;

    my ($min, $max) = (1000,0);
    for my $f (grep { length $_ } @{ $temp->{values} }[$offset..$offset+$count-1]) {
        if( $f < $min ) {
            $min = $f;
        };
        if( $f > $max ) {
            $max = $f;
        };
    };

    $max -= 273.15;
    $min -= 273.15;

    my $weather = [];

    my %forecast = (
        date    => $ts->new(),
        weather => $weather,
        min     => $min,
        max     => $max,
    );

    my $time = $ts->new();
    $time->tzoffset(2*3600); # at least until October ...
    # Do the min/max for the 4 6-hour windows
    # Find the "representative" weather code for each window
    # This should be done in SQL instead of hacking Perl code for this
    my %count;
    # with range as (
    #     select * from perldata
    #     where rownum() between ? and ?
    # )
    # select min(temp) as mintemp over ()
    # , max(temp) as maxtemp over ()
    # from range
    for my $i ($offset..$offset+$count-1) {
        my $c = $weathercode->{values}->[ $i ];
        if( length $c ) {
            my $v = sprintf '%02d', 0+$c;
            $count{ $v }++;
            $time += 3600;
        };
    };

    # Use the prevalent weather ...
    my ($prevalent_weather) = (sort { $count{$a} cmp $count{$a} } keys %count )[0];
    push @{ $weather }, {
        timestamp   => $ts->new(),
        description => mosmix_weathercode($prevalent_weather),
    };

    return \%forecast
}

sub format_forecast_day_concise( $ts, $temp, $weathercode, $offset, $count ) {

    # with range as (
    #     select * from perldata
    # )
    # , minmax as (
    #     select min(temp) as mintemp over (partition by offset / 6)
    #     , max(temp) as maxtemp over (partition by offset / 6)
    #     , weathercode
    # select
    #     lead(min,0) lead(max,0), lead(weathercode,0)
    #     lead(min,1) lead(max,1), lead(weathercode,1)
    #     lead(min,2) lead(max,2), lead(weathercode,2)
    #     lead(min,3) lead(max,3), lead(weathercode,3)
    # from range
    my @res;
    for (1..4) {
        push @res, format_forecast_range_concise( $ts, $temp, $weathercode, $offset, 6 );
        $offset += 6;
    };
    # put all of the information into a single line:
    # location / ts / 3-9        / 10-15     / 16-21     / 22-2
    # location / ts / min/max/w / min/max/w / min/max/w / min/max/w
};

sub format_forecast_day {
    my( $self, $ts, $temp, $weathercode, $offset, $count ) = @_;

    my ($min, $max) = (1000,0);
    for my $f (grep { length $_ } @{ $temp->{values} }[$offset..$offset+$count-1]) {
        if( $f < $min ) {
            $min = $f;
        };
        if( $f > $max ) {
            $max = $f;
        };
    };

    $max -= 273.15;
    $min -= 273.15;

    my $weather = [];
    my %forecast = (
        date    => $ts->new(),
        weather => $weather,
        min     => $min,
        max     => $max,
    );

    my $time = $ts->new();
    $time->tzoffset(2*3600); # at least until October ...
    for my $i ($offset..$offset+$count-1) {
        my $c = $weathercode->{values}->[ $i ];
        if( length $c ) {
            my $v = sprintf '%02d', 0+$c;
            push @{ $weather }, {
                timestamp   => $time->new(),
                description => mosmix_weathercode($v),
            };
            $time += 3600;
        };
    };

    return \%forecast,
};

sub format_forecast_dbh( $self, $dbh, $interval, $offset=0 ) {
# We need some offset for the first set, which will not contain the full
# six (or whatever) hours
    my $sql = <<SQL;
    with
      partitioned as (
        select
                 round((hour_ofs*1.0)/$interval -0.5) as part
               , (hour_ofs*1.0)/$interval as weather_partition
               , $interval    as size
               , *
          from forecast
    )
    , minmax as (
        select
                max(TTT) over (partition by part) as maxtemp
              , min(TTT) over (partition by part) as mintemp
              , row_number() over (partition by part order by timestamp) as row
              --, min(weather_partition) over (partition by part) as use_this
              -- , date
              -- , timestamp -- TZ-adjusted
              , *
        from partitioned
    )
    select
          'active' as status
        , *
    from minmax
    where row = 1
    order by timestamp
SQL

    my $res = $dbh->selectall_arrayref($sql, { Slice => {} });

    # Now, add dummy data for slots we don't have
    # this would likely be parts of the day that have already passed
    while( $res->[0]->{hour} > $offset+$interval) {
        my $new = dclone( $res->[0]);
        $new->{hour}-= $interval;
        $new->{status} = 'past';
        unshift @$res, $new;
    };

    for( @$res ) {
        if( exists $_->{emoji}) {
            $_->{emoji} = decode('UTF-8', $_->{emoji});
        }
    }

    # fix up the data we have
    # $time->tzoffset(2*3600); # at least until October ...
    #for my $i ($offset..$offset+$count-1) {
    #    my $c = $weathercode->{values}->[ $i ];
    #    if( length $c ) {
    #        my $v = sprintf '%02d', 0+$c;
    #        push @{ $weather }, {
    #            timestamp   => $time->new(),
    #            description => mosmix_weathercode($v),
    #        };
    #        $time += 3600;
    #    };
    #};

    return $res;
};

sub format_forecast( $self, $f ) {
    my $loc = $f->{description};
    (my $temp) = grep{ $_->{type} eq 'TTT' } @{ $f->{forecasts}};
    (my $weathercode) = grep{ $_->{type} eq 'ww' } @{ $f->{forecasts}};

    # Convert from UTC to CET. This happens to work because my machines
    # are located within CET ...
    my $time = Time::Piece->strptime( $f->{issuetime}, '%Y-%m-%dT%H:%M:%SZ' );
    $time = $time->_mktime( $time->epoch, 1 );

    # Find where today ends, and add a linebreak, resp. move to the next array ...
    my @forecasts;
    my %weather = (
        #today    => $weath,
        #tomorrow => [],
        #tomnext  => [],
        days     => \@forecasts,
    );
    my %sequence = (
        today    => 'tomorrow',
        tomorrow => 'tomnext',
    );

    my $count = 0;
    my $today = $time->truncate(to => 'day');
    my $start = $time->new();
    my $offset = $start->hour;
    my $slot = 'today';

    while( $offset < @{$weathercode->{values}} ) {
        $time += 3600;
        $count++;
        if( $time->truncate( to => 'day' ) != $today ) {
            push @forecasts, $self->format_forecast_day( $start, $temp, $weathercode, $offset, $count );
            $offset += $count;
            $count = 0;
            if( defined $slot ) {
                #print "$slot ($today) -> $sequence{ $slot } ($time)\n";
                $slot = $sequence{ $slot };
            };
            $today = $time->truncate( to => 'day' );
            $start = $today;
        };
    };

    $weather{ today }    = $forecasts[0];
    $weather{ tomorrow } = $forecasts[1];
    $weather{ tomnext }  = $forecasts[2];

    return {
        issuetime => $f->{issuetime},
        location  => $loc,
        weather   => \%weather,
    }
}

sub formatted_forecast( $self, %options ) {
    my $f = $self->forecast( %options );
    $self->format_forecast( $f )
}

=head2 C<< $mosmix->locations >>

Lists all locations with their names and longitude/latitude. If a longitude
/ latitude pair is passed in, the list is ordered by the distance from
that position.

=cut

sub locations( $self, %options ) {
    my $order_by = 'description asc';
    if(     exists $options{ longitude }
        and exists $options{ latitude } ) {
        $order_by = 'distance asc';
    } else {
        $options{ latitude } = 0;
    };
    my $cos_lat_sq = cos( $options{ latitude } ) ^ 2;
    my $res =
    $self->dbh->selectall_arrayref(<<SQL, { Slice => {}}, $options{latitude}, $options{latitude}, $options{longitude},$options{longitude}, $cos_lat_sq);
        select
            description
          , latitude
          , longitude
          ,   ((l.latitude - ?)*(l.latitude - ?))
            + ((l.longitude - ?)*(l.longitude - ?)*?) as distance
            from forecast_location l
            order by $order_by
SQL
    $res
};

=head1 SETUP

=over 4

=item 1

Install the module

=item 2

Create a directory for the database

    mkdir ~/weather ; cd ~/weather

=item 3

Create the database

    mosmix-import.pl --create

=item 4

Set up a cron job to fetch the MOSMIX forecast

    01 6,12,18,0 * * * cd /home/corion/weather; mosmix-import.pl
    15 6,12,18,0 * * * cd /home/corion/weather; mosmix-purge.pl

=item 5

Query the current forecast

    cd /home/corion/weather; mosmix-query.pl

=back

=head1 SEE ALSO

German Weather Service

L<https://opendata.dwd.de/weather/>

L<https://opendata.dwd.de/weather/local_forecasts/mos/MOSMIX_S/all_stations/kml/>

Other Weather APIs

L<https://openweathermap.org/api> - international, signup required

L<https://www.weatherbit.io/api> - international, signup required

L<https://developer.accuweather.com/> - international, signup required

L<https://darksky.net/dev> - paid, international, signup required

L<http://api.weather2020.com/> - international, signup required

Overview of Open Data

L<https://index.okfn.org/place/de/weather/>
L<https://index.okfn.org/place/us/weather/>
L<https://index.okfn.org/place/lv/weather/>
L<https://index.okfn.org/place/cy/weather/>

Cyprus forecast

L<http://www.moa.gov.cy/moa/ms/ms.nsf/DMLforecast_general_gr/DMLforecast_general_gr?opendocument>

=head2 Icons

L<https://github.com/zagortenay333/Tempestacons>

L<https://thenounproject.com/search/?q=weather>

L<https://undraw.co/search>

L<https://coreui.io/icons/>

=cut

1;
=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/weather-mosmix>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Weather-MOSMIX>
or via mail to L<www-Weather-MOSMIX@rt.cpan.org|mailto:Weather-MOSMIX@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2019-2020 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
