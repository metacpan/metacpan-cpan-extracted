#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

plan skip_all => "DateTime needed" unless eval { require DateTime };

{
    package Sim::Date;

    use strict;
    use warnings;

    require DateTime;
    use Test::Sims;

    make_rand year  => [1800..2100];

    sub sim_datetime {
        my %args = @_;

        my $year = $args{year} || rand_year();
        my $date = DateTime->new( year => $year );

        my $days_in_year = $date->is_leap_year ? 366 : 365;
        my $secs = rand( $days_in_year * 24 * 60 * 60 );
        $date->add( seconds => $secs );

        $date->set( %args );

        return $date;
    }

    export_sims();
}


{
    package Foo;

    use Test::More;
    Sim::Date->import();

    my $date = sim_datetime();

    cmp_ok $date->year, ">=", 1800;
    cmp_ok $date->year, "<=", 2101;

    $date = sim_datetime(
        year   => 2008,
        second => 23,
    );

    is $date->year, 2008;
    is $date->second, 23;
    note $date;

    $date = sim_datetime(
        month   => 8
    );

    is $date->month, 8;
    note $date;
}


done_testing();
