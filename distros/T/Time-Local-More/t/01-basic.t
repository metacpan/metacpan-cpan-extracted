#!perl

use strict;
use warnings;
use Test::More 0.98;

use Time::Local::More qw(
                       time_startofminute_local
                       time_startofminute_utc
                       localtime_startofminute
                       gmtime_startofminute

                       time_startofhour_local
                       time_startofhour_utc
                       localtime_startofhour
                       gmtime_startofhour

                       time_startofday_local
                       time_startofday_utc
                       localtime_startofday
                       gmtime_startofday

                       time_startofsaturday_local
                       time_startofsaturday_utc
                       localtime_startofsaturday
                       gmtime_startofsaturday

                       time_startofsunday_local
                       time_startofsunday_utc
                       localtime_startofsunday
                       gmtime_startofsunday

                       time_startofmonday_local
                       time_startofmonday_utc
                       localtime_startofmonday
                       gmtime_startofmonday

                       time_startofmonth_local
                       time_startofmonth_utc
                       localtime_startofmonth
                       gmtime_startofmonth

                       time_startoflastdayofmonth_local
                       time_startoflastdayofmonth_utc
                       localtime_startoflastdayofmonth
                       gmtime_startoflastdayofmonth

                       time_startoflastdayoflastmonth_local
                       time_startoflastdayoflastmonth_utc
                       localtime_startoflastdayoflastmonth
                       gmtime_startoflastdayoflastmonth

                       time_startofyear_local
                       time_startofyear_utc
                       localtime_startofyear
                       gmtime_startofyear
                    );

my $epoch1 = 1623894635; # Thu Jun 17 08:50:35 2021 Asia/Jakarta = Thu Jun 17 01:50:35 2021 UTC

subtest all => sub {
    local $ENV{TZ} = "Asia/Jakarta";
    # startofminute
    is_deeply(time_startofminute_local($epoch1), $epoch1-35);
    is_deeply(time_startofminute_utc($epoch1), $epoch1-35);
    is_deeply([localtime_startofminute($epoch1)], [0,50,8,17,5,121,4,167,0]);
    is_deeply(scalar localtime_startofminute($epoch1), "Thu Jun 17 08:50:00 2021");
    is_deeply([gmtime_startofminute($epoch1)], [0,50,1,17,5,121,4,167,0]);
    is_deeply(scalar gmtime_startofminute($epoch1), "Thu Jun 17 01:50:00 2021");

    # startofhour
    is_deeply(time_startofhour_local($epoch1), $epoch1-50*60-35);
    is_deeply(time_startofhour_utc($epoch1), $epoch1-50*60-35);
    is_deeply([localtime_startofhour($epoch1)], [0,0,8,17,5,121,4,167,0]);
    is_deeply(scalar localtime_startofhour($epoch1), "Thu Jun 17 08:00:00 2021");
    is_deeply([gmtime_startofhour($epoch1)], [0,0,1,17,5,121,4,167,0]);
    is_deeply(scalar gmtime_startofhour($epoch1), "Thu Jun 17 01:00:00 2021");

    # startofday
    is_deeply(time_startofday_local($epoch1), $epoch1-8*3600-50*60-35);
    is_deeply(time_startofday_utc($epoch1), $epoch1-1*3600-50*60-35);
    is_deeply([localtime_startofday($epoch1)], [0,0,0,17,5,121,4,167,0]);
    is_deeply(scalar localtime_startofday($epoch1), "Thu Jun 17 00:00:00 2021");
    is_deeply([gmtime_startofday($epoch1)], [0,0,0,17,5,121,4,167,0]);
    is_deeply(scalar gmtime_startofday($epoch1), "Thu Jun 17 00:00:00 2021");

    # startofsaturday
    is_deeply(time_startofsaturday_local($epoch1), $epoch1-5*86400-8*3600-50*60-35);
    is_deeply(time_startofsaturday_utc($epoch1), $epoch1-5*86400-1*3600-50*60-35);
    is_deeply([localtime_startofsaturday($epoch1)], [0,0,0,12,5,121,6,162,0]);
    is_deeply(scalar localtime_startofsaturday($epoch1), "Sat Jun 12 00:00:00 2021");
    is_deeply([gmtime_startofsaturday($epoch1)], [0,0,0,12,5,121,6,162,0]);
    is_deeply(scalar gmtime_startofsaturday($epoch1), "Sat Jun 12 00:00:00 2021");

    # startofsunday
    is_deeply(time_startofsunday_local($epoch1), $epoch1-4*86400-8*3600-50*60-35);
    is_deeply(time_startofsunday_utc($epoch1), $epoch1-4*86400-1*3600-50*60-35);
    is_deeply([localtime_startofsunday($epoch1)], [0,0,0,13,5,121,0,163,0]);
    is_deeply(scalar localtime_startofsunday($epoch1), "Sun Jun 13 00:00:00 2021");
    is_deeply([gmtime_startofsunday($epoch1)], [0,0,0,13,5,121,0,163,0]);
    is_deeply(scalar gmtime_startofsunday($epoch1), "Sun Jun 13 00:00:00 2021");

    # startofmonday
    is_deeply(time_startofmonday_local($epoch1), $epoch1-3*86400-8*3600-50*60-35);
    is_deeply(time_startofmonday_utc($epoch1), $epoch1-3*86400-1*3600-50*60-35);
    is_deeply([localtime_startofmonday($epoch1)], [0,0,0,14,5,121,1,164,0]);
    is_deeply(scalar localtime_startofmonday($epoch1), "Mon Jun 14 00:00:00 2021");
    is_deeply([gmtime_startofmonday($epoch1)], [0,0,0,14,5,121,1,164,0]);
    is_deeply(scalar gmtime_startofmonday($epoch1), "Mon Jun 14 00:00:00 2021");

    # startofmonth
    is_deeply(time_startofmonth_local($epoch1), $epoch1-16*86400-8*3600-50*60-35);
    is_deeply(time_startofmonth_utc($epoch1), $epoch1-16*86400-1*3600-50*60-35);
    is_deeply([localtime_startofmonth($epoch1)], [0,0,0,1,5,121,2,151,0]);
    is_deeply(scalar localtime_startofmonth($epoch1), "Tue Jun  1 00:00:00 2021");
    is_deeply([gmtime_startofmonth($epoch1)], [0,0,0,1,5,121,2,151,0]);
    is_deeply(scalar gmtime_startofmonth($epoch1), "Tue Jun  1 00:00:00 2021");

    # startoflastdayofmonth
    is_deeply(time_startoflastdayofmonth_local($epoch1), $epoch1+13*86400-8*3600-50*60-35);
    is_deeply(time_startoflastdayofmonth_utc($epoch1), $epoch1+13*86400-1*3600-50*60-35);
    is_deeply([localtime_startoflastdayofmonth($epoch1)], [0,0,0,30,5,121,3,180,0]);
    is_deeply(scalar localtime_startoflastdayofmonth($epoch1), "Wed Jun 30 00:00:00 2021");
    is_deeply([gmtime_startoflastdayofmonth($epoch1)], [0,0,0,30,5,121,3,180,0]);
    is_deeply(scalar gmtime_startoflastdayofmonth($epoch1), "Wed Jun 30 00:00:00 2021");

    # startoflastdayoflastmonth
    is_deeply(time_startoflastdayoflastmonth_local($epoch1), $epoch1-17*86400-8*3600-50*60-35);
    is_deeply(time_startoflastdayoflastmonth_utc($epoch1), $epoch1-17*86400-1*3600-50*60-35);
    is_deeply([localtime_startoflastdayoflastmonth($epoch1)], [0,0,0,31,4,121,1,150,0]);
    is_deeply(scalar localtime_startoflastdayoflastmonth($epoch1), "Mon May 31 00:00:00 2021");
    is_deeply([gmtime_startoflastdayoflastmonth($epoch1)], [0,0,0,31,4,121,1,150,0]);
    is_deeply(scalar gmtime_startoflastdayoflastmonth($epoch1), "Mon May 31 00:00:00 2021");

    # startofyear
    is_deeply(time_startofyear_local($epoch1), $epoch1-167*86400-8*3600-50*60-35);
    is_deeply(time_startofyear_utc($epoch1), $epoch1-167*86400-1*3600-50*60-35);
    is_deeply([localtime_startofyear($epoch1)], [0,0,0,1,0,121,5,0,0]);
    is_deeply(scalar localtime_startofyear($epoch1), "Fri Jan  1 00:00:00 2021");
    is_deeply([gmtime_startofyear($epoch1)], [0,0,0,1,0,121,5,0,0]);
    is_deeply(scalar gmtime_startofyear($epoch1), "Fri Jan  1 00:00:00 2021");
};

DONE_TESTING:
done_testing;
