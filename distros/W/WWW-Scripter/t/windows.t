#!perl -w

use lib 't';
use WWW'Scripter'WindowGroup;

# Avoid network & disk activity when playing with HTTP and file URLs:
use LWP'Protocol;
{
 package __;
 @ISA = LWP'Protocol;
 LWP'Protocol'implementor $'_ => __ for <http file>;
 sub request {
  my($self,undef,undef,$arg) = @'_;
  my $response = new HTTP::Response 200, 'OK', [
   Content_Length=>0,
   Content_Type  =>'text/html',
  ];

  $self->collect($arg, $response, sub {\''});
 }
}


$g = new WWW'Scripter'WindowGroup;

use tests 13; # WindowGroup’s methods
$w = $g->active_window;
isa_ok $w, 'WWW::Scripter';
is $g->windows, 1, 'number of windows initially';
is_deeply [$g->windows], [$w],'windows method in list context';
is $w->window_group, $g, 'window group of the first window';
$w->scripts_enabled(0);
$w2 = $g->new_window;
isa_ok $w2, 'WWW::Scripter', 'second window';
is join("-",$g->windows),"$w2-$w", 'new windows appear in front';
is $w2->window_group, $g, 'window group of the new_window window';
ok !$w2->scripts_enabled, 'new window is a clone of the frontmost';
$g->detach($w2);
is join("-",$g->windows), $w, 'detach';
is $w2->window_group, undef, 'detach resets window_group';
$g->attach($w2);
is join("-",$g->windows),"$w2-$w", 'attach';
$w3 = $g->new_window;
$g->bring_to_front($w2);
is join("-",$g->windows), "$w2-$w3-$w", 'bring_to_front';
$g = new WWW'Scripter'WindowGroup empty => 1;
is $g->windows, 0, 'empty option to constructor';


# Scripter’s methods:

use tests 4; # window_group
$w = new WWW'Scripter;
is $w->window_group, undef, 'Scripter->window_group is undef at first';
is $w->window_group($g), undef, 'retval of window_group when setting';
is $w->window_group(qr//), $g,
 'retval of window_group when setting is the previous value';
$w->window_group($g);
is $w->window_group, $g, 'window_group after assignment';

use tests 4; # blur
$g->attach($w);
$g->attach($w2);
$g->attach($w3);
is +()=$w3->blur, 0, 'no retval from blur';
is join("-",$g->windows), "$w2-$w3-$w", 'effect of blur';
$w3->blur;
is join("-",$g->windows), "$w2-$w3-$w",
 'blur has no effect if the blurree is not in front';
$g->detach($w2);
$g->detach($w3);
$w->blur;
is join("-",$g->windows), "$w",
 'blur has no effect if there is only one window';

use tests 4; # close
$g->attach($w3);
$g->attach($w2);
is +()=$w->close, 0, 'no retval from close';
is join("-",$g->windows), "$w2-$w3", 'close detaches the window';
is $w->window_group, undef, 'setting its window_group to undef';
$w->get("about:blank");
$w->get("data:text/html,");
$w->close;
is $w->uri, 'about:blank', 'close goes back in single-window mode';

use tests 4; # focus
$g->attach($w);
is +()=$w2->focus, 0, 'no retval from focus';
is join("-",$g->windows), "$w2-$w-$w3", 'effect of focus (2nd window)';
$w2->focus;
is join("-",$g->windows), "$w2-$w-$w3", 'effect of focus (active window)';
$w3->focus;
is join("-",$g->windows), "$w3-$w2-$w", 'effect of focus (last window)';

use tests 20; # open
$w->close();
$w->get("data:text/html,");
$len = $w->history->length;
is $w->open("data:text/html,dring"), $w,
 '$w->open returns $w in single-window mode';
is $w->uri, 'data:text/html,dring',
 '$w->open in single-window mode fetches the url in the same window';
is $w->history->length, $len+1, 'single-window open adds to history';
$w->back;
$w->open;
is $w->uri, 'about:blank', 'open with no args uses about:blank';
$w->get('data:text/html,');
is $w->history->length, $len+1,
 'open with no args creates an ‘unbrowsed’ history entry';
$w->back; $w->open(undef);
is $w->uri, 'about:blank', 'open with undef URL uses about:blank';
$w->get('data:text/html,');
is $w->history->length, $len+1,
 'open with undef URL creates an ‘unbrowsed’ history entry';
$w->back; $w->open('');
is $w->uri, 'about:blank', 'open with empty string URL uses about:blank';
$w->get('data:text/html,');
is $w->history->length, $len+1,
 'open with empty string creates an ‘unbrowsed’ history entry';
$w->back; $w->open('about:blank');
$w->get('data:text/html,');
is $w->history->length, $len+2,
 'open with about:blank creates an normal history entry';
$w->get("file:///cteck");
$w->open("dwon");
is $w->uri, "file:///dwon", 'opened URL is relative to the opener';
$w->get("data:text/html,<iframe name=smext>");
$frame = $w->frames->[0];
$w->open("file:///swed",'smext');
is $frame->uri, 'file:///swed', 'open with target';
$w->get('file:///prit');
$w->get('file:///frile');
$w->open('file:///quew','_top',undef,1);
$w->back;
is $w->uri, 'file:///prit', 'open with true replace arg';
$g->detach($_) for $g->windows;
$g->attach($w); # Switch to multi mode
$neww = $w->open("file:///plor");
is $neww->uri, 'file:///plor', 'uri of new window created by open()';
is join("-",$g->windows),"$neww-$w",
 'open() adds a new window to the group';
isn't $neww, $w, 'the new window is not just the same window again';
$w->get('data:text/html,<base target=skit>');
isn't $w->open, $w, 'open ignores <base target>';
$neww->close;
$w->get('data:text/html,<base href="http://skit.com/">');
$neww = $w->open('froon');
is $neww->uri, 'http://skit.com/froon', 'open respects <base href>';
$neww->close;
# These next two tests are commented out because no browser actually imple-
# ments these the way HTML 5 says too,  and HTML 5 is still in a state of
# flux.  Right now we follow Safari 4 and Firefox 3.5.  Any attempt  to
# develop the code further at this point would likely turn out to be a
# waste of time.
#$w->get("file:///");
#get{$neww = $w->open}'gile';
#is uri $neww, "file:///gile", 'origin of new window is its opener';
#$neww->close;
#$neww = $w->open;
#$w->get('http://smew/');
#$neww->get('pror');
#is uri $neww, 'file:///pror',
# 'origin of new window stays the same when the opener changes origin';
#$neww->close;
$neww = $w->open('','lat');
$neww->get("data:text/html,");
$w->open('','lat');
is $neww->uri, 'data:text/html,',
 'open with empty string does not navigate an existing window';
$w->open(undef,'lat');
is $neww->uri, 'data:text/html,',
 'open with undef does not navigate an existing window';
