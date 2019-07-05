use strict;
use warnings;
use Test2::V0;
use Time::FFI::tm;

my @tm_members = qw(tm_sec tm_min tm_hour tm_mday tm_mon tm_year tm_wday tm_yday tm_isdst);

my $tm = Time::FFI::tm->new;
is $tm, object { call $_ => 0 for @tm_members }, 'base tm struct';

my $time = time;
my @localtime = CORE::localtime $time;

$tm = Time::FFI::tm->new(map { ($tm_members[$_] => $localtime[$_]) } 0..$#tm_members);
is $tm, object { call $tm_members[$_] => $localtime[$_] for 0..$#tm_members }, 'populated tm struct';

$tm = Time::FFI::tm->from_list(@localtime);
is $tm, object { call $tm_members[$_] => $localtime[$_] for 0..$#tm_members }, 'populated tm struct from list';

is [$tm->to_list], \@localtime, 'tm struct to list';

done_testing;
