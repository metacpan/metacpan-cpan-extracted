#!perl -w

use lib 't';
use WWW'Scripter;

use tests 4;

use Scalar::Util 'weaken';

$w = new WWW'Scripter;
$res = $w->res;
undef $w;
weaken $res;
is $res, undef, 'no circular references between response and doc';

$w = new WWW'Scripter;
$w->get('text/html,<title></title><style>b{b:b}<table><tr><td></table>');
weaken $w;
is $w, undef, 'no circular references keeping the window alive';

$w = new WWW'Scripter;
$w->frames;
$doc = $w->document;
weaken $w;
weaken $doc;
is $w, undef, '->frames creates no circular refs keeping the win alive';
is $doc, undef, '->frames creates no circular refs keeping the doc alive';

