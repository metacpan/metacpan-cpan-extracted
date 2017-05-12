#!perl -w

use lib 't';

use WWW'Scripter;
$w = new WWW'Scripter;

use tests 3;
ok $w->can($_), $_ for < scroll scrollTo scrollBy >;
