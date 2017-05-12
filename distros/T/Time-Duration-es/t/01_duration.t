use Test::More tests => 7;
use Time::Duration::es;

is duration(120), "2 minutos";
is duration(121), "2 minutos y 1 segundo";

is ago(3600), "hace 1 hora";
is ago(-3600), "en 1 hora";
is ago(3601), "hace 1 hora y 1 segundo";
is ago(-3660), "en 1 hora y 1 minuto";

is ago(3661, 3), "hace 1 hora, 1 minuto, y 1 segundo";

# need more tests!

