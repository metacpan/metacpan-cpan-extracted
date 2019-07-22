#!/perl
# -*- coding: utf-8; -*-     (for Emacs)

# Test locale changing

use 5.006;
use strict;
use utf8;
use Test::More tests => 9;
use FindBin;
use lib $FindBin::Bin;


## ----------------------------------------------------------------------------------
## Test for availability of certain modules.
my $tl_ok;
BEGIN { $tl_ok = eval ('use Time::Local; 1') }
my $posix_ok;
my $lc_time;
BEGIN
{
    $posix_ok = eval ('require POSIX; 1');
    if ($posix_ok)
    {
        $lc_time = POSIX::LC_TIME();
        *setlocale = \&POSIX::setlocale;
    }
}


## ----------------------------------------------------------------------------------
## Load our module.

BEGIN { use_ok 'Time::Format', '%time' }


## ----------------------------------------------------------------------------------
## Locale setting is not supported under openbsd
my $lc_supported = 1;
$lc_supported = 0  if $^O eq 'openbsd';


## ----------------------------------------------------------------------------------
## Begin tests.

SKIP:
{
    skip 'POSIX not available',       8  unless $posix_ok;
    skip 'Time::Local not available', 8  unless $tl_ok;
    skip 'Locale not supported',      8  unless $lc_supported;
    skip 'XS version not available',  8  unless defined $Time::Format_XS::VERSION;

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
