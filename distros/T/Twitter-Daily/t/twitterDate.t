
use strict;
use warnings;

use Test::More tests => 29;
use Twitter::Date;
use Error qw(:try);
use Twitter::NoDateError;

my $date = Twitter::Date->new('Thu Dec 09 19:50:41 +0000 2010');

is( $date->getSeconds(), 41, 'Seconds' );
is( $date->getMinutes(), 50, 'Minutes' );
is( $date->getHour(), 19, 'Hour' );

is( $date->getDay(), 9, 'Day' );
is( $date->getMonth(), 12, 'Month' );
is( $date->getYear(), 2010, 'Year' );

is( $date->getTimeZone(), 0 , "Timezone");

ok ( $date->eq($date), "Every date is equals to itself" );
ok ( ! $date->lt($date), "Every date is NOT less than itself" );
ok ( ! $date->gt($date), "Every date is NOT grater than  itself" );
ok ( $date->cmp($date) == 0 , "Every date is equals to itself (cmp)" );

my $date2 = Twitter::Date->new('Thu Dec 09 20:50:41 +0000 2010');

ok ( $date2->eq($date2), "Every date is equals to itself" );
ok ( ! $date2->lt($date2), "Every date is NOT less than itself" );
ok ( ! $date2->gt($date2), "Every date is NOT grater than  itself" );
ok ( $date2->cmp($date2) == 0 , "Every date is equals to itself (cmp)" );

ok ( $date->lt($date2), "Lower than comparison" );
ok ( ! $date->gt($date2), "Grater than comparison" );
ok ( ! $date->eq($date2), "Equals to comparison" );
ok ( $date->cmp($date2) == -1 , "Lower than comparison (cmp)" );
ok ( $date2->cmp($date) == 1 , "Greater than comparison (cmp)" );

my $date3 = Twitter::Date->new('Thu Dec 09 18:50:41 +0000 2010');

ok ( $date3->eq($date3), "Every date is equals to itself" );
ok ( ! $date3->lt($date3), "Every date is NOT less than itself" );
ok ( ! $date3->gt($date3), "Every date is NOT grater than  itself" );
ok ( $date3->cmp($date3) == 0 , "Every date is equals to itself (cmp)" );

ok ( ! $date->lt($date3), "Greater than comparison" );
ok ( $date->gt($date3), "Grater than comparison" );
ok ( ! $date->eq($date3), "Equals to comparison" );
ok ( $date->cmp($date3) == 1 , "Greater than comparison (cmp)" );
ok ( $date3->cmp($date) == -1 , "Lower than comparison (cmp)" );

