use Test::More tests => 133;
use strict;
use warnings;
use Time::Duration::pt;

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
  
is( later(   0), 'agora');
is( later(   2), '2 segundos depois');
is( later(  -2), '2 segundos antes');
is( earlier( 0), 'agora');
is( earlier( 2), '2 segundos antes');
is( earlier(-2), '2 segundos depois');
  
is( ago(      0), 'agora');
is( ago(      2), '2 segundos atrás');
is( ago(     -2), 'daqui a 2 segundos');
is( from_now( 0), 'agora');
is( from_now( 2), 'daqui a 2 segundos');
is( from_now(-2), '2 segundos atrás');

 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Advanced tests...

my $v;  #scratch var

$v = 0;
is(later(       $v   ), 'agora');
is(later(       $v, 3), 'agora');
is(later_exact( $v   ), 'agora');

$v = 1;
is(later(       $v   ), '1 segundo depois');
is(later(       $v, 3), '1 segundo depois');
is(later_exact( $v   ), '1 segundo depois');

$v = 30;
is(later(       $v   ), '30 segundos depois');
is(later(       $v, 3), '30 segundos depois');
is(later_exact( $v   ), '30 segundos depois');

$v = 46;
is(later(       $v   ), '46 segundos depois');
is(later(       $v, 3), '46 segundos depois');
is(later_exact( $v   ), '46 segundos depois');

$v = 59;
is(later(       $v   ), '59 segundos depois');
is(later(       $v, 3), '59 segundos depois');
is(later_exact( $v   ), '59 segundos depois');

$v = 61;
is(later(       $v   ), '1 minuto e 1 segundo depois');
is(later(       $v, 3), '1 minuto e 1 segundo depois');
is(later_exact( $v   ), '1 minuto e 1 segundo depois');

$v = 3599;
is(later(       $v   ), '59 minutos e 59 segundos depois');
is(later(       $v, 3), '59 minutos e 59 segundos depois');
is(later_exact( $v   ), '59 minutos e 59 segundos depois');

$v = 3600;
is(later(       $v   ), '1 hora depois');
is(later(       $v, 3), '1 hora depois');
is(later_exact( $v   ), '1 hora depois');

$v = 3601;
is(later(       $v   ), '1 hora e 1 segundo depois');
is(later(       $v, 3), '1 hora e 1 segundo depois');
is(later_exact( $v   ), '1 hora e 1 segundo depois');

$v = 3630;
is(later(       $v   ), '1 hora e 30 segundos depois');
is(later(       $v, 3), '1 hora e 30 segundos depois');
is(later_exact( $v   ), '1 hora e 30 segundos depois');

$v = 3800;
is(later(       $v   ), '1 hora e 3 minutos depois');
is(later(       $v, 3), '1 hora, 3 minutos, e 20 segundos depois');
is(later_exact( $v   ), '1 hora, 3 minutos, e 20 segundos depois');

$v = 3820;
is(later(       $v   ), '1 hora e 4 minutos depois');
is(later(       $v, 3), '1 hora, 3 minutos, e 40 segundos depois');
is(later_exact( $v   ), '1 hora, 3 minutos, e 40 segundos depois');

$v = $DAY + - $HOUR + -28;
is(later(       $v   ), '23 horas depois');
is(later(       $v, 3), '22 horas, 59 minutos, e 32 segundos depois');
is(later_exact( $v   ), '22 horas, 59 minutos, e 32 segundos depois');

$v = $DAY + - $HOUR + $MINUTE;
is(later(       $v   ), '23 horas e 1 minuto depois');
is(later(       $v, 3), '23 horas e 1 minuto depois');
is(later_exact( $v   ), '23 horas e 1 minuto depois');

$v = $DAY + - $HOUR + 29 * $MINUTE + 1;
is(later(       $v   ), '23 horas e 29 minutos depois');
is(later(       $v, 3), '23 horas, 29 minutos, e 1 segundo depois');
is(later_exact( $v   ), '23 horas, 29 minutos, e 1 segundo depois');

$v = $DAY + - $HOUR + 29 * $MINUTE + 31;
is(later(       $v   ), '23 horas e 30 minutos depois');
is(later(       $v, 3), '23 horas, 29 minutos, e 31 segundos depois');
is(later_exact( $v   ), '23 horas, 29 minutos, e 31 segundos depois');

$v = $DAY + - $HOUR + 30 * $MINUTE + 31;
is(later(       $v   ), '23 horas e 31 minutos depois');
is(later(       $v, 3), '23 horas, 30 minutos, e 31 segundos depois');
is(later_exact( $v   ), '23 horas, 30 minutos, e 31 segundos depois');

$v = $DAY + - $HOUR + -28 + $YEAR;
is(later(       $v   ), '1 ano e 23 horas depois');
is(later(       $v, 3), '1 ano e 23 horas depois');
is(later_exact( $v   ), '1 ano, 22 horas, 59 minutos, e 32 segundos depois');

$v = $DAY + - $HOUR + $MINUTE + $YEAR;
is(later(       $v   ), '1 ano e 23 horas depois');
is(later(       $v, 3), '1 ano, 23 horas, e 1 minuto depois');
is(later_exact( $v   ), '1 ano, 23 horas, e 1 minuto depois');

$v = $DAY + - $HOUR + 29 * $MINUTE + 1 + $YEAR;
is(later(       $v   ), '1 ano e 23 horas depois');
is(later(       $v, 3), '1 ano, 23 horas, e 29 minutos depois');
is(later_exact( $v   ), '1 ano, 23 horas, 29 minutos, e 1 segundo depois');

$v = $DAY + - $HOUR + 29 * $MINUTE + 31 + $YEAR;
is(later(       $v   ), '1 ano e 23 horas depois');
is(later(       $v, 3), '1 ano, 23 horas, e 30 minutos depois');
is(later_exact( $v   ), '1 ano, 23 horas, 29 minutos, e 31 segundos depois');

$v = $YEAR + 2 * $HOUR + -1;
is(later(       $v   ), '1 ano e 2 horas depois');
is(later(       $v, 3), '1 ano e 2 horas depois');
is(later_exact( $v   ), '1 ano, 1 hora, 59 minutos, e 59 segundos depois');

$v = $YEAR + 2 * $HOUR + 59;
is(later(       $v   ), '1 ano e 2 horas depois');
is(later(       $v, 3), '1 ano, 2 horas, e 59 segundos depois');
is(later_exact( $v   ), '1 ano, 2 horas, e 59 segundos depois');

$v = $YEAR + $DAY + 2 * $HOUR + -1;
is(later(       $v   ), '1 ano e 1 dia depois');
is(later(       $v, 3), '1 ano, 1 dia, e 2 horas depois');
is(later_exact( $v   ), '1 ano, 1 dia, 1 hora, 59 minutos, e 59 segundos depois');

$v = $YEAR + $DAY + 2 * $HOUR + 59;
is(later(       $v   ), '1 ano e 1 dia depois');
is(later(       $v, 3), '1 ano, 1 dia, e 2 horas depois');
is(later_exact( $v   ), '1 ano, 1 dia, 2 horas, e 59 segundos depois');

$v = $YEAR + - $DAY + - 1;
is(later(       $v   ), '364 dias depois');
is(later(       $v, 3), '364 dias depois');
is(later_exact( $v   ), '363 dias, 23 horas, 59 minutos, e 59 segundos depois');

$v = $YEAR + - 1;
is(later(       $v   ), '1 ano depois');
is(later(       $v, 3), '1 ano depois');
is(later_exact( $v   ), '364 dias, 23 horas, 59 minutos, e 59 segundos depois');



# And an advanced one to put duration thru its paces...
$v = $YEAR + $DAY + 2 * $HOUR + 59;
is(duration(       $v   ), '1 ano e 1 dia');
is(duration(       $v, 3), '1 ano, 1 dia, e 2 horas');
is(duration_exact( $v   ), '1 ano, 1 dia, 2 horas, e 59 segundos');
is(duration(      -$v   ), '1 ano e 1 dia');
is(duration(      -$v, 3), '1 ano, 1 dia, e 2 horas');
is(duration_exact(-$v   ), '1 ano, 1 dia, 2 horas, e 59 segundos');


#~~~~~~~~
# Some tests of concise() ...

is( concise duration(   0), '0s');
is( concise duration(   1), '1s');
is( concise duration(  -1), '1s');
is( concise duration(   2), '2s');
is( concise duration(  -2), '2s');
  
is( concise later(   0), 'agora');
is( concise later(   2), '2s depois');
is( concise later(  -2), '2s antes');
is( concise earlier( 0), 'agora');
is( concise earlier( 2), '2s antes');
is( concise earlier(-2), '2s depois');
  
is( concise ago(      0), 'agora');
is( concise ago(      2), '2s atrás');
is( concise ago(     -2), 'daqui a 2s');
is( concise from_now( 0), 'agora');
is( concise from_now( 2), 'daqui a 2s');
is( concise from_now(-2), '2s atrás');

$v = $YEAR + $DAY + 2 * $HOUR + -1;
is(concise later(       $v   ), '1a1d depois');
is(concise later(       $v, 3), '1a1d2h depois');
is(concise later_exact( $v   ), '1a1d1h59m59s depois');

$v = $YEAR + $DAY + 2 * $HOUR + 59;
is(concise later(       $v   ), '1a1d depois');
is(concise later(       $v, 3), '1a1d2h depois');
is(concise later_exact( $v   ), '1a1d2h59s depois');

$v = $YEAR + - $DAY + - 1;
is(concise later(       $v   ), '364d depois');
is(concise later(       $v, 3), '364d depois');
is(concise later_exact( $v   ), '363d23h59m59s depois');

$v = $YEAR + - 1;
is(concise later(       $v   ), '1a depois');
is(concise later(       $v, 3), '1a depois');
is(concise later_exact( $v   ), '364d23h59m59s depois');

# That's it.
