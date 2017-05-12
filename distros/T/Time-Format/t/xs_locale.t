#!/perl -I..

# Test locale changing

use strict;
use Test::More tests => 9;

BEGIN { use_ok 'Time::Format', '%time' }

my $posix_bad;
my $lc_time;
BEGIN
{
    $posix_bad = eval ('require POSIX; 1')? 0 : 1;
    unless ($posix_bad)
    {
        $lc_time = POSIX::LC_TIME();
        *setlocale = \&POSIX::setlocale;
    }
    delete $INC{'POSIX.pm'};
    %POSIX:: = ();
}
my $tl_notok;
BEGIN {$tl_notok = eval ('use Time::Local; 1')? 0 : 1}

SKIP:
{
    skip 'POSIX not available', 8        if $posix_bad;
    skip 'Time::Local not available', 8  if $tl_notok;
    skip 'XS version not available', 8   if !defined $Time::Format_XS::VERSION;

    my $t = timelocal(9, 58, 13, 5, 5, 103);    # June 5, 2003 at 1:58:09 pm

    my $en_ok = setlocale($lc_time, 'en_US');
    $en_ok ||=  setlocale($lc_time, 'C');
    SKIP:
    {
        skip 'No English locale', 2  unless $en_ok;
        is $time{'Mon',$t},     'Jun'         => 'English month';
        is $time{'Day',$t},     'Thu'         => 'English day';
    }

    my $fr_ok = setlocale($lc_time, 'fr_FR');
    SKIP:
    {
        skip 'No French locale', 2 unless $fr_ok;
        is $time{'month',$t},   'juin'      => 'Mois français';
        is $time{'weekday',$t}, 'jeudi'     => 'Jour de la semaine français';
    }

    my $de_ok = setlocale($lc_time, 'de_DE');
    SKIP:
    {
        skip 'No German locale', 2 unless $de_ok;
        is $time{'month',$t},   'juni'         => 'Deutscher Monat';
        is $time{'weekday',$t}, 'donnerstag'   => 'Deutscher Wochentag';
    }

    my $es_ok = setlocale($lc_time, 'es_ES');
    SKIP:
    {
        skip 'No Spanish locale', 2 unless $es_ok;
        is $time{'month',$t},   'junio'      => 'Mes español';
        is $time{'weekday',$t}, 'jueves'     => 'Día español de la semana';
    }
}
