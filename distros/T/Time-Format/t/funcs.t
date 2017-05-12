#!/perl -I..

use strict;
use Test::More tests => 18;

BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(%time time_format time_strftime time_manip) }
my $tl_notok;
BEGIN { $tl_notok = eval ('use Time::Local; 1')? 0 : 1 }
my $posix_bad;
BEGIN {
    $posix_bad = eval ('use POSIX (); 1')? 0 : 1;
    delete $INC{'POSIX.pm'};
    %POSIX:: = ();
}
my $manip_bad;
my $manip_notz;
BEGIN {
    $manip_bad = eval('use Date::Manip (); 1')? 0 : 1;
    unless ($manip_bad)
    {
        # If Date::Manip can't determine the time zone, it'll bomb out of the tests.
        $manip_notz = eval ('Date::Manip::Date_TimeZone (); 1')? 0 : 1;
    }
    delete $INC{'Date/Manip.pm'};
    %Date::Manip:: = ();
}

# Get day/month names in current locale
my ($Thursday, $Thu, $June, $Jun);
unless (eval
    {
        require I18N::Langinfo;
        I18N::Langinfo->import(qw(langinfo DAY_3 MON_12 DAY_5 ABDAY_5 MON_6 ABMON_6));
        ($Thursday, $Thu, $June, $Jun) = map ucfirst lc langinfo($_), (DAY_5(), ABDAY_5(), MON_6(), ABMON_6());
        1;
    })
{
    ($Thursday, $Thu, $June, $Jun) = qw(Thursday Thu June Jun);
}

SKIP:
{
    skip 'Time::Local not available', 17  if $tl_notok;
    my $t = timelocal(9, 58, 13, 5, 5, 103);    # June 5, 2003 at 1:58:09 pm
    $t .= '.987654321';

    # time_format tests (5)
    is time_format('yyyymmdd',$t),  '20030605'       => 'month: mm';
    is time_format('hhmmss',$t),    '135809'         => 'm minute: 1';
    is time_format('MONTH',$t),     uc $June         => 'uc month name';
    is time_format('weekday',$t),   lc $Thursday     => 'lc weekday';
    is time_format('yyyymmdd'),     $time{yyyymmdd}  => 'time_format equals %time';

    # time_strftime tests (6)
    SKIP:
    {
        skip 'POSIX not available', 6  if $posix_bad;

        # Be sure to use ONLY ansi standard strftime codes here,
        # otherwise the tests will fail on somebody's system somewhere.

        is time_strftime('%d',$t),      '05'        => 'day of month';
        is time_strftime('%m',$t),      '06'        => 'Month number';
        is time_strftime('%M',$t),      '58'        => 'minute';
        is time_strftime('%H',$t),      '13'        => 'hour';
        is time_strftime('%Y',$t),      '2003'      => 'year';
        is time_strftime('%M'),     $time{'mm{in}'} => 'time_strftime equals %time';
    }

    # time_manip tests (6)
    SKIP:
    {
        skip 'Date::Manip not available',             6 if $manip_bad;
        skip 'Date::Manip cannot determine timezone', 6 if $manip_notz;
        my $m = 'first thursday in june 2003';
        is time_manip('%Y',$m),      '2003'      => 'year';
        is time_manip('%d',$m),      '05'        => 'day of month';
        is time_manip('%D',$m),      '06/05/03'  => '%D';
        is time_manip('%e',$m),      ' 5'        => 'spaced day';
        is time_manip('%H',$m),      '00'        => 'hour';
        is time_manip('%H'),     $time{'hh'}     => 'time_manip equals %time';
    }
}
