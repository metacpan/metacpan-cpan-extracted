#!perl -w

use Test'More skip_all => 'removed due to conflicts';

See the comments before the commented-out subroutine definitions in
lib/WWW/Scripter.pm.

use lib 't';
use WWW'Scripter;

use tests 12;
$w = new WWW'Scripter;
$w->get('about:blank');
is $w->status, "", 'status is blank by default';
is $w->defaultStatus, "", 'defaultStatus is blank by default';
is $w->status("37"), "", 'status returns "" on initial assignment';
is $w->defaultStatus("38"), "", 'defaultStatus returns "" on 1st assignm.';
is $w->status('foo'), '37', 'status returns old value on assignment';
is $w->defaultStatus('bar'),'38','defaultStatus rets. old val on assignm.';
is $w->status, 'foo', 'argless status returns assigned val';
is $w->defaultStatus, 'bar', 'argless defaultStatus returns assigned val.';
$w->get('data:text/html,');
is $w->status, '', 'status is lost when browsing';
is $w->defaultStatus, '', 'defaultStatus is lost when browsing';
$w->back;
is $w->status, "foo", 'status is restored when browsing back';
is $w->defaultStatus, "bar", 'defaultStatus is restored when going back';
