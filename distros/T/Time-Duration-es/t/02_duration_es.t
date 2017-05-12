use Test::More tests => 133;
use strict;
use warnings;
use Time::Duration::es;

# this module is entirely based in segundos
my $MINUTE =   60;
my $HOUR   =   60 * $MINUTE;
my $DAY    =   24 * $HOUR;
my $YEAR   =  365 * $DAY;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Basic tests...

is( duration(0), '0 segundos');
is( duration(   1), '1 segundo');
is( duration(  -1), '1 segundo');
is( duration(   2), '2 segundos');
is( duration(  -2), '2 segundos');

is( later(   0), 'al momento');
is( later(   2), '2 segundos después');
is( later(  -2), '2 segundos antes');
is( earlier( 0), 'al momento');
is( earlier( 2), '2 segundos antes');
is( earlier(-2), '2 segundos después');

is( ago(      0), 'ahora');
is( ago(      2), 'hace 2 segundos');
is( ago(     -2), 'en 2 segundos');
is( from_now( 0), 'ahora');
is( from_now( 2), 'en 2 segundos');
is( from_now(-2), 'hace 2 segundos');

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Advanced tests...

my $v;  #scratch var

$v = 0;
is(later(       $v   ), 'al momento');
is(later(       $v, 3), 'al momento');
is(later_exact( $v   ), 'al momento');

$v = 1;
is(later(       $v   ), '1 segundo después');
is(later(       $v, 3), '1 segundo después');
is(later_exact( $v   ), '1 segundo después');

$v = 30;
is(later(       $v   ), '30 segundos después');
is(later(       $v, 3), '30 segundos después');
is(later_exact( $v   ), '30 segundos después');

$v = 46;
is(later(       $v   ), '46 segundos después');
is(later(       $v, 3), '46 segundos después');
is(later_exact( $v   ), '46 segundos después');

$v = 59;
is(later(       $v   ), '59 segundos después');
is(later(       $v, 3), '59 segundos después');
is(later_exact( $v   ), '59 segundos después');

$v = 61;
is(later(       $v   ), '1 minuto y 1 segundo después');
is(later(       $v, 3), '1 minuto y 1 segundo después');
is(later_exact( $v   ), '1 minuto y 1 segundo después');

$v = 3599;
is(later(       $v   ), '59 minutos y 59 segundos después');
is(later(       $v, 3), '59 minutos y 59 segundos después');
is(later_exact( $v   ), '59 minutos y 59 segundos después');

$v = 3600;
is(later(       $v   ), '1 hora después');
is(later(       $v, 3), '1 hora después');
is(later_exact( $v   ), '1 hora después');

$v = 3601;
is(later(       $v   ), '1 hora y 1 segundo después');
is(later(       $v, 3), '1 hora y 1 segundo después');
is(later_exact( $v   ), '1 hora y 1 segundo después');

$v = 3630;
is(later(       $v   ), '1 hora y 30 segundos después');
is(later(       $v, 3), '1 hora y 30 segundos después');
is(later_exact( $v   ), '1 hora y 30 segundos después');

$v = 3800;
is(later(       $v   ), '1 hora y 3 minutos después');
is(later(       $v, 3), '1 hora, 3 minutos, y 20 segundos después');
is(later_exact( $v   ), '1 hora, 3 minutos, y 20 segundos después');

$v = 3820;
is(later(       $v   ), '1 hora y 4 minutos después');
is(later(       $v, 3), '1 hora, 3 minutos, y 40 segundos después');
is(later_exact( $v   ), '1 hora, 3 minutos, y 40 segundos después');

$v = $DAY + - $HOUR + -28;
is(later(       $v   ), '23 horas después');
is(later(       $v, 3), '22 horas, 59 minutos, y 32 segundos después');
is(later_exact( $v   ), '22 horas, 59 minutos, y 32 segundos después');

$v = $DAY + - $HOUR + $MINUTE;
is(later(       $v   ), '23 horas y 1 minuto después');
is(later(       $v, 3), '23 horas y 1 minuto después');
is(later_exact( $v   ), '23 horas y 1 minuto después');

$v = $DAY + - $HOUR + 29 * $MINUTE + 1;
is(later(       $v   ), '23 horas y 29 minutos después');
is(later(       $v, 3), '23 horas, 29 minutos, y 1 segundo después');
is(later_exact( $v   ), '23 horas, 29 minutos, y 1 segundo después');

$v = $DAY + - $HOUR + 29 * $MINUTE + 31;
is(later(       $v   ), '23 horas y 30 minutos después');
is(later(       $v, 3), '23 horas, 29 minutos, y 31 segundos después');
is(later_exact( $v   ), '23 horas, 29 minutos, y 31 segundos después');

$v = $DAY + - $HOUR + 30 * $MINUTE + 31;
is(later(       $v   ), '23 horas y 31 minutos después');
is(later(       $v, 3), '23 horas, 30 minutos, y 31 segundos después');
is(later_exact( $v   ), '23 horas, 30 minutos, y 31 segundos después');

$v = $DAY + - $HOUR + -28 + $YEAR;
is(later(       $v   ), '1 año y 23 horas después');
is(later(       $v, 3), '1 año y 23 horas después');
is(later_exact( $v   ), '1 año, 22 horas, 59 minutos, y 32 segundos después');

$v = $DAY + - $HOUR + $MINUTE + $YEAR;
is(later(       $v   ), '1 año y 23 horas después');
is(later(       $v, 3), '1 año, 23 horas, y 1 minuto después');
is(later_exact( $v   ), '1 año, 23 horas, y 1 minuto después');

$v = $DAY + - $HOUR + 29 * $MINUTE + 1 + $YEAR;
is(later(       $v   ), '1 año y 23 horas después');
is(later(       $v, 3), '1 año, 23 horas, y 29 minutos después');
is(later_exact( $v   ), '1 año, 23 horas, 29 minutos, y 1 segundo después');

$v = $DAY + - $HOUR + 29 * $MINUTE + 31 + $YEAR;
is(later(       $v   ), '1 año y 23 horas después');
is(later(       $v, 3), '1 año, 23 horas, y 30 minutos después');
is(later_exact( $v   ), '1 año, 23 horas, 29 minutos, y 31 segundos después');

$v = $YEAR + 2 * $HOUR + -1;
is(later(       $v   ), '1 año y 2 horas después');
is(later(       $v, 3), '1 año y 2 horas después');
is(later_exact( $v   ), '1 año, 1 hora, 59 minutos, y 59 segundos después');

$v = $YEAR + 2 * $HOUR + 59;
is(later(       $v   ), '1 año y 2 horas después');
is(later(       $v, 3), '1 año, 2 horas, y 59 segundos después');
is(later_exact( $v   ), '1 año, 2 horas, y 59 segundos después');

$v = $YEAR + $DAY + 2 * $HOUR + -1;
is(later(       $v   ), '1 año y 1 día después');
is(later(       $v, 3), '1 año, 1 día, y 2 horas después');
is(later_exact( $v   ), '1 año, 1 día, 1 hora, 59 minutos, y 59 segundos después');

$v = $YEAR + $DAY + 2 * $HOUR + 59;
is(later(       $v   ), '1 año y 1 día después');
is(later(       $v, 3), '1 año, 1 día, y 2 horas después');
is(later_exact( $v   ), '1 año, 1 día, 2 horas, y 59 segundos después');

$v = $YEAR + - $DAY + - 1;
is(later(       $v   ), '364 días después');
is(later(       $v, 3), '364 días después');
is(later_exact( $v   ), '363 días, 23 horas, 59 minutos, y 59 segundos después');

$v = $YEAR + - 1;
is(later(       $v   ), '1 año después');
is(later(       $v, 3), '1 año después');
is(later_exact( $v   ), '364 días, 23 horas, 59 minutos, y 59 segundos después');



# And an advanced one to put duration thru its paces...
$v = $YEAR + $DAY + 2 * $HOUR + 59;
is(duration(       $v   ), '1 año y 1 día');
is(duration(       $v, 3), '1 año, 1 día, y 2 horas');
is(duration_exact( $v   ), '1 año, 1 día, 2 horas, y 59 segundos');
is(duration(      -$v   ), '1 año y 1 día');
is(duration(      -$v, 3), '1 año, 1 día, y 2 horas');
is(duration_exact(-$v   ), '1 año, 1 día, 2 horas, y 59 segundos');


#~~~~~~~~
# Some tests of concise() ...

is( concise duration(   0), '0s');
is( concise duration(   1), '1s');
is( concise duration(  -1), '1s');
is( concise duration(   2), '2s');
is( concise duration(  -2), '2s');

is( concise later(   0), 'al momento');
is( concise later(   2), '2s después');
is( concise later(  -2), '2s antes');
is( concise earlier( 0), 'al momento');
is( concise earlier( 2), '2s antes');
is( concise earlier(-2), '2s después');

is( concise ago(      0), 'ahora');
is( concise ago(      2), 'hace 2s');
is( concise ago(     -2), 'en 2s');
is( concise from_now( 0), 'ahora');
is( concise from_now( 2), 'en 2s');
is( concise from_now(-2), 'hace 2s');

$v = $YEAR + $DAY + 2 * $HOUR + -1;
is(concise later(       $v   ), '1a1d después');
is(concise later(       $v, 3), '1a1d2h después');
is(concise later_exact( $v   ), '1a1d1h59m59s después');

$v = $YEAR + $DAY + 2 * $HOUR + 59;
is(concise later(       $v   ), '1a1d después');
is(concise later(       $v, 3), '1a1d2h después');
is(concise later_exact( $v   ), '1a1d2h59s después');

$v = $YEAR + - $DAY + - 1;
is(concise later(       $v   ), '364d después');
is(concise later(       $v, 3), '364d después');
is(concise later_exact( $v   ), '363d23h59m59s después');

$v = $YEAR + - 1;
is(concise later(       $v   ), '1a después');
is(concise later(       $v, 3), '1a después');
is(concise later_exact( $v   ), '364d23h59m59s después');

# That's it.
