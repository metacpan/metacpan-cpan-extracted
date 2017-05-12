#!perl -w

use lib 't';
use WWW'Scripter'WindowGroup;
use HTML'DOM'Element'Form 0.039; # submitting to a data: URL

$g = new WWW'Scripter'WindowGroup;
$w = $g->active_window;
$s = new WWW'Scripter; # single window

use tests 4; # _blank
$w->get('data:text/html,glin<a href="data:text/html,skow" target=_blank>');
$w->follow_link(n => 1);
like $w->uri, qr\^data:text/html,glin\,
 '_blank leaves the uri of the original window alone';
is $g->windows, 2, '_blank opens a new window';
is $g->active_window->uri, 'data:text/html,skow',
 'the new window has the link’s URL';
$s->get('data:text/html,<a href="data:text/html," target=_blank>');
$s->follow_link(n => 1);
is $s->uri, 'data:text/html,', '_blank in single-window mode';
# Clean up:
$g->detach($_) for $g->windows;
$g->attach($w);

use tests 1; # _self
$w->get(
 'data:text/html,'
 .'<base target=_blank>'
 .'<a href="data:text/html," target=_self>'
);
$w->follow_link(n => 1);
is $w->uri, 'data:text/html,', '_self';

require Carp'Heavy;
use tests 2; # _parent
$w->get(
  q|data:text/html,<iframe src="|
 . q|data:text/html,<iframe src='|
 .  q|data:text/html,<a href=%2522data:text/html,%2522 target=_parent>|
 . q|'>|
 .q|">|
);
$w->frames->[0]->frames->[0]->follow_link(n => 1);
is $w->frames->[0]->uri, 'data:text/html,', '_parent';
$w->get('about:blank');
$w->open("data:text/html,", "_parent");
is $w->uri, 'data:text/html,', '_parent of top window is itself';

use tests 1; # _top
$w->get(
  q|data:text/html,|
 .q|<iframe src="|
 . q|data:text/html,<iframe src=%2522|
 .  q|data:text/html,<a href='data:text/html,jat' target=_top>|
 . q|%2522>|
 .q|">|
);
$w->frames->[0]->frames->[0]->follow_link(n => 1);
like uri $w, qr rjatr, '_top';

use tests 15; # named targets
$w->get(
  q|data:text/html,<iframe src="|
 . q|data:text/html,<iframe name=crelp>|
 .q|"></iframe><a target=crelp href="data:text/html,">|
);
$w->follow_link(n=>2);
is $w->frames->[0]->frames->[0]->uri, 'data:text/html,',
 'named subframe as target';
$w->frames->[0]->get('about:blank');
$w->follow_link(n=>2);
is $g->windows, 2, 'named target opening a new window';
$neww = $g->active_window;
is $neww->uri, 'data:text/html,',
 'uri of new window created by named target';
for($w->document->links->[0]) {
 $_->href("data:text/html,czeen");
 $_->click;
}
like $neww->uri, qr 'czeen', 'named target uses existing new window';
$w->reload; # We should now have our crelp iframe back
$w->follow_link(n=>2);
is $w->frames->[0]->frames->[0]->uri, 'data:text/html,',
 'named subframe takes precedence over new window';
$w->get('about:blank');
$w->open("",'crelp');
is $g->windows, 3,
 'window names are not retained when the main window is browsed';
$w->back;
$w->open("about:blank",'crelp');
is $neww->uri ,'about:blank', 'but are restored when browsing back';
$neww->close;
$newneww = $w->open("",'crelp');
isn't $newneww, $neww, 'closed windows are not reused';
$w->get(
  q|data:text/html,<iframe name=gnare src="|
 . q|data:text/html,<iframe>|
 .q|">|
);
$w->frames->[0]->frames->[0]->open("about:blank","gnare");
is $w->frames->[0]->uri, 'about:blank', 'named parent frames';
$w->get( q|data:text/html,<iframe name=dwing></iframe><iframe>| );
$w->frames->[1]->open("data:text/html,", "dwing");
is $w->frames->[0]->uri, 'data:text/html,', 'named sibling frame';
$w->get(
  q|data:text/html,<iframe name=dreck></iframe><iframe src="|
 . q|data:text/html,<iframe>|
 .q|">|
);
$w->frames->[1]->frames->[0]->open("data:text/html,", 'dreck');
is $w->frames->[0]->uri, 'data:text/html,', 'named anepsic frame';
$s->open("","fon");
is $s->uri, 'about:blank', 'named target in single-window mode';
$s->get("data:text/html,<iframe name=fon>");
$s->open("data:text/html,","fon");
is $s->frames->[0]->uri, 'data:text/html,',
 'named subframe in single-window mode';
$s->get("data:text/html,<iframe>");
$s->frames->[0]->open("","gnin");
is $s->uri, 'about:blank',
 'simulated new blank window in single-win. mode is the top-level window';
$s->back;
$s->frames->[0]->open("data:text/html,","smow");
is $s->uri, 'data:text/html,',
 'simulated new window with URL in single-win. mode is top-level window';

use tests 1; # <base target>
$w->clear_history(1);;
$w->get(
  "data:text/html,"
 ."<base href=thed>" # to confuse it
 ."<base target=snext>"
 ."<a href='data:text/html,'></a><iframe name=snext>"
);
$w->follow_link(n=>1);
is $w->frames->[0]->uri, 'data:text/html,', '<base target>';

use tests 4; # form targets
$s->get('data:text/html,<form target=foo><iframe name=foo>');
$s->submit;
like $s->frames->[0]->uri, qr/^data:/, 'form target';
reload $s;
()=$s->submit;
like $s->frames->[0]->uri, qr/^data:/,
 'form target (submit in non-void context)';
# Now try it with the click method.
reload $s;
$s->submit;
like $s->frames->[0]->uri, qr/^data:/, 'form target (click method)';
reload $s;
()=$s->submit;
like $s->frames->[0]->uri, qr/^data:/,
 'form target (click in non-void context)';

