BEGIN {
  $ENV{TZ} = "GMT";
}

use strict;
use warnings;

use Test::MockTime qw/:all/;
use Test::More tests => 4080;
use Time::Piece::MySQL;
use Time::Piece::Over24;

my $t    = localtime;
my $base = localtime->from_mysql_datetime("2010-12-31 00:00:00");
my $TIME_DIFFERENCE = 0 * 3600;

my $time = 0;
while ( $time < 86400 * 2 ) {
    my $day = int( $time / 86400 );

    #parse time test
    my $check_time = sprintf( "%02d:%02d:%02d",
        24 * $day + $base->hour,
        $base->min, $base->sec );
    my $over = $t->over24_time($check_time);
    $over->over24_offset("00:00:00");

    is $over->hms, $base->hms, sprintf( "over24_time parse %s", $check_time );
    $over = $t->from_over24_time($check_time);
    is $over->hms, $base->hms,
      sprintf( "from_over24_time parse %s", $check_time );

    is $over->over24_time, $check_time,
      sprintf( "over24_time output %s", $check_time );

    #parse datetime test
    my $check_datetime = sprintf(
        "2010-12-31 %02d:%02d:%02d",
        24 * $day + $base->hour,
        $base->min, $base->sec
    );
    $over = $t->over24_datetime($check_datetime);
    is $over->datetime, $base->datetime,
      sprintf( "over24_datetime parse %s", $check_datetime );
    $over = $t->from_over24_datetime($check_datetime);
    is $over->datetime, $base->datetime,
      sprintf( "from_over24_datetime parse %s", $check_datetime );

    #output time test
    is $over->over24_time, $check_time,
      sprintf( "over24_time output %s at %s", $check_time, $check_datetime );

    #output datetime test
    is $over->over24_datetime, $check_datetime,
      sprintf( "over24_datetime output %s", $check_datetime );

    #offset test
    $over->over24_offset("05:00:00");
    my $check_year = $base->year;
    if ( $base->year == 2011 && $base->hour < 5 ) {
        $check_year -= 1;
    }
    is $over->over24_year, $check_year, "over24_year output at offset 05:00:00";

    my $check_mon = $base->mon;
    if ( $base->year == 2011 && $base->mon == 1 && $base->hour < 5 ) {
        $check_mon = 12;
    }
    is $over->over24_mon, $check_mon, "over24_mon output at offset 05:00:00";

    my $check_day = $base->mday;
    if ( $base->hour < 5 ) {
        $check_day -= 1;
        $check_day ||= 31;
    }
    is $over->over24_mday, $check_day, "over24_mday output at offset 05:00:00";

    my $check_hour = $base->hour;
    if ( $base->hour < 5 ) {
        $check_hour += 24;
    }
    is $over->over24_hour, $check_hour, "over24_hour output at offset 05:00:00";

    $over->over24_offset("00:00:00");
    my $start        = localtime->from_mysql_datetime("2010-12-31 23:00:00");
    my $end          = localtime->from_mysql_datetime("2011-01-01 02:00:00");
    my $check_during = ( $start <= $base && $base <= $end ) ? 1 : undef;
    is $over->is_during( "2010-12-31 23:00:00", "2010-12-31 26:00:00", $base ),
      $check_during, "is_during datetime";

    my $over24_end = localtime->from_over24("2010-12-31 26:00:00");
    $check_during = ( $start <= $base && $base <= $end ) ? 1 : undef;
    is $over->is_during( $start, $over24_end, $base ), $check_during,
      "is_during time piece";

    set_fixed_time( ( $base - $TIME_DIFFERENCE )->datetime . 'Z' );
    my $mock_base = localtime;
    $check_during = ( $start <= $mock_base && $mock_base <= $end ) ? 1 : undef;
    is $over->is_during( $start, $end ), $check_during, "is_during now";
    restore_time;

    $base += 600;
    $time += 600;
}

#old test
my $over = $t->from_over24_datetime("2009-09-15 26:00:00");
is $over->datetime, "2009-09-16T02:00:00", "datetiem from_over24_datetime";
is $over->over24_datetime, "2009-09-15 26:00:00",
  "over24_datetime from_over24_datetime";
$over->over24_offset("01:00:00");
is $over->datetime, "2009-09-16T02:00:00", "datetiem from_over24_datetime";
is $over->over24_datetime, "2009-09-16 02:00:00",
  "over24_datetime from_over24_datetime";
$over->over24_offset("00:00:00");

my $offset_test = $t->strptime( "2009-01-01 02:00:00", "%Y-%m-%d %H:%M:%S" );

my $offset = $offset_test->over24_offset;
is $offset, "00:00:00", "over24_offset output";

my $datetime = $offset_test->over24;
is $datetime, "2009-01-01 02:00:00", "over24";

my $year = $offset_test->over24_year;
is $year, "2009", "over24_year";

my $mon = $offset_test->over24_mon;
is $mon, "1", "over24_mon at offset 00:00";

my $mday = $offset_test->over24_mday;
is $mday, "1", "over24_mday at offset 00:00";

my $hour = $offset_test->over24_hour;
is $hour, "2", "over24_hour at offset 00:00";

$time = $offset_test->over24_time;
is $time, "02:00:00", "over24_time at offset 00:00";

$datetime = $offset_test->over24_datetime;
is $datetime, "2009-01-01 02:00:00", "over24_time at offset 00:00";

$offset = $offset_test->over24_offset("03:00:00");
is $offset, "03:00:00", "change offset 03:00:00";

$datetime = $offset_test->over24;
is $datetime, "2008-12-31 26:00:00", "over24_time at offset 03:00";

$year = $offset_test->over24_year;
is $year, "2008", "year in offset";

$mon = $offset_test->over24_mon;
is $mon, "12", "mon in offset";

$mday = $offset_test->over24_mday;
is $mday, "31", "mday in offset";

$hour = $offset_test->over24_hour;
is $hour, "26", "hour in offset";

$time = $offset_test->over24_time;
is $time, "26:00:00", "time in offset";

$datetime = $offset_test->over24_datetime;
is $datetime, "2008-12-31 26:00:00", "datetime in offset";

#is_during test
my $flg = $t->is_during( "01:00", "11:00", "23:59" );
is $flg, undef, "is_during [01:00 - 11:00] at 23:59";

$flg = $t->is_during( "01:00", "11:00", "01:00" );
is $flg, 1, "is_during [01:00 - 11:00] at 00:00";

$flg = $t->is_during( "01:00", "11:00", "01:01" );
is $flg, 1, "is_during [01:00 - 11:00] at 01:01";

$flg = $t->is_during( "01:00", "11:00", "11:00" );
is $flg, 1, "is_during [01:00 - 11:00] at 11:00";

$flg = $t->is_during( "01:00", "11:00", "11:01" );
is $flg, undef, "is_during [01:00 - 11:00] at 11:01";

$flg = $t->is_during( "23:00", "27:00", "22:59" );
is $flg, undef, "is_during [23:00 - 27:00] at 22:59";

$flg = $t->is_during( "23:00", "27:00", "23:00" );
is $flg, 1, "is_during [23:00 - 27:00] at 23:00";

$flg = $t->is_during( "23:00", "27:00", "23:01" );
is $flg, 1, "is_during [23:00 - 27:00] at 23:01";

$flg = $t->is_during( "23:00", "27:00", "27:00" );
is $flg, 1, "is_during [23:00 - 27:00] at 27:00";

$flg = $t->is_during( "23:00", "27:00", "27:01" );
is $flg, undef, "is_during [23:00 - 27:00] at 27:01";

$flg = $t->is_during(
    "2011-06-01 01:00:00",
    "2011-06-01 11:00:00",
    "2011-06-01 00:59:59"
);
is $flg, undef,
"is_during [2011-06-01 01:00:00 - 2011-06-01 11:00:00] at 2011-06-01 00:59:59";

$flg = $t->is_during(
    "2011-06-01 01:00:00",
    "2011-06-01 11:00:00",
    "2011-06-01 01:00:00"
);
is $flg, 1,
"is_during [2011-06-01 01:00:00 - 2011-06-01 11:00:00] at 2011-06-01 01:00:00";

$flg = $t->is_during(
    "2011-06-01 01:00:00",
    "2011-06-01 11:00:00",
    "2011-06-01 01:00:01"
);
is $flg, 1,
"is_during [2011-06-01 01:00:00 - 2011-06-01 11:00:00] at 2011-06-01 01:00:01";

$flg = $t->is_during(
    "2011-06-01 01:00:00",
    "2011-06-01 11:00:00",
    "2011-06-01 11:00:00"
);
is $flg, 1,
"is_during [2011-06-01 01:00:00 - 2011-06-01 11:00:00] at 2011-06-01 11:00:00";

$flg = $t->is_during(
    "2011-06-01 01:00:00",
    "2011-06-01 11:00:00",
    "2011-06-01 11:00:01"
);
is $flg, undef,
"is_during [2011-06-01 01:00:00 - 2011-06-01 11:00:00] at 2011-06-01 11:00:01";

$flg = $t->is_during(
    "2011-06-01 23:00:00",
    "2011-06-01 27:00:00",
    "2011-06-01 22:59:59"
);
is $flg, undef,
"is_during [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 22:59:59";

$flg = $t->is_during(
    "2011-06-01 23:00:00",
    "2011-06-01 27:00:00",
    "2011-06-01 23:00:00"
);
is $flg, 1,
"is_during [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 23:00:00";

$flg = $t->is_during(
    "2011-06-01 23:00:00",
    "2011-06-01 27:00:00",
    "2011-06-01 23:00:01"
);
is $flg, 1,
"is_during [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 23:00:01";

$flg = $t->is_during(
    "2011-06-01 23:00:00",
    "2011-06-01 27:00:00",
    "2011-06-01 27:00:00"
);
is $flg, 1,
"is_during [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 27:00:00";

$flg = $t->is_during(
    "2011-06-01 23:00:00",
    "2011-06-01 27:00:00",
    "2011-06-01 27:00:01"
);
is $flg, undef,
"is_during [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 27:00:01";

$flg = $t->is_during(
    "2011-06-01 23:00:00",
    "2011-06-01 27:00:00",
    "2011-06-02 00:00:00"
);
is $flg, 1,
"is_during [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-02 00:00:00";

$flg = $t->is_during(
    "2011-06-01 23:00:00",
    "2011-06-01 27:00:00",
    "2011-06-02 03:00:00"
);
is $flg, 1,
"is_during [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-02 03:00:00";

$flg = $t->is_during(
    "2011-06-01 23:00:00",
    "2011-06-01 27:00:00",
    "2011-06-02 03:00:01"
);
is $flg, undef,
"is_during [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-02 03:00:01";

my $t1 = $t->from_mysql_datetime("2011-06-01 23:00:00");
my $t2 = $t->from_over24_datetime("2011-06-01 27:00:00");

$flg = $t->is_during( $t1, $t2, "2011-06-01 22:59:59" );
is $flg, undef,
"is_during [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 22:59:59";

$flg = $t->is_during( $t1, $t2, "2011-06-01 23:00:00" );
is $flg, 1,
"is_during timepiece [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 23:00:00";

$flg = $t->is_during( $t1, $t2, "2011-06-01 23:00:01" );
is $flg, 1,
"is_during timepiece [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 23:00:01";

$flg = $t->is_during( $t1, $t2, "2011-06-01 27:00:00" );
is $flg, 1,
"is_during timepiece [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 27:00:00";

$flg = $t->is_during( $t1, $t2, "2011-06-01 27:00:01" );
is $flg, undef,
"is_during timepiece [2011-06-01 23:00:00 - 2011-06-01 27:00:00] at 2011-06-01 27:00:01";

1;
