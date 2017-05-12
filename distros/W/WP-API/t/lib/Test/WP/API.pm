package Test::WP::API;

use strict;
use warnings;

use Exporter qw( import );

our @EXPORT = qw( format_datetime_value );

sub format_datetime_value {
    my $dt = shift;

    return $dt->datetime() . q{ } . $dt->time_zone_long_name();
}

1;
