#!perl -w

use lib 't';
use WWW'Scripter;

use tests 3;
$w = new WWW'Scripter;
is $w->title("foo"), '','retval of title when setting initially';
is $w->document->title,'foo', 'setting the title works';
is $w->title, 'foo', 'retval of title with no argument';
