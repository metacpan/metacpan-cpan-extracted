#!perl -w

use lib 't';

use HTML'DOM 0.03; # for the onload/unonload test
use URI::file;
use WWW'Scripter;

sub data_url {
	my $u = new URI 'data:';
	$u->media_type('text/html');
	$u->data(shift);
	$u
}

{ package ScriptHandler;
  sub new { shift; bless [@_] }
  sub eval { my $self = shift; $self->[0](@_) }
  sub event2sub { my $self = shift; $self->[1](@_) }
}

use tests 5; # on(un)load
{
	my $events = '';
	my $target;
	(my $m = new WWW::Scripter)
	 ->script_handler(
			default => new ScriptHandler sub {}, sub {
				my $code = $_[3];
				sub {
				 $events .= $code; $target = shift->target
				}
			}
	);
	$m->get(URI::file->new_abs( 't/dom-onload.html' ));
	is $events, 'onlode', '<body onload=...';
	(my $doc = $m->document)->title('dom-onload modified');
	is $target, $doc, 'target of load event';
	$doc->addEventListener(
	 'onload', sub { $events = "This should never happen." }
	);
	$m->get(new_abs URI'file 't/blank.html');
	is $events, 'onlodeunlode', 'unload';
	$m->document->title("blank modified");
	$m->get('about:blank');
	$m->back;
	is $m->title, "blank modified",
	 'absence of onunload causes documents to persist';
	$m->back;
	is $m->title, "",
	 'presence of onunload causes documents to be discarded';
}

use tests 1; # window as part of event dispatch chain
{
	my $m = new WWW::Scripter;
	$m->get('data:text/html,');
	my $targets;
	$m                           ->onfoo(sub { $targets .= '-w' });
	$m->document                 ->onfoo(sub { $targets .= '-d' });
	$m->document->documentElement->onfoo(sub { $targets .= '-h' });
	$m->document->body      ->addEventListener( foo=>
	        sub { $targets .= '-b' });
	$m                      ->addEventListener( foo=>
		sub { $targets .= '-w(c)' },1);
	$m->document            ->addEventListener( foo=>
		sub { $targets .= '-d(c)' }, 1);
	$m->document->firstChild->addEventListener( foo=>
		sub { $targets .= '-h(c)' }, 1);
	$m->document->body      ->addEventListener( foo=>
		sub { $targets .= '-b(c)' }, 1);
	$m->document->body->trigger_event('foo');
	is $targets, '-w(c)-d(c)-h(c)-b-h-d-w',
		'window as part of the event dispatch chain';
}

use tests 1; # click events on links
{
	my $m = new WWW::Scripter ;
	my $other_url = data_url <<'END';
		<title>The other page</title><p>
END
	$m->get(data_url(<<END));
		<HTML><head><title>oetneotne</title></head>
		<a href="$other_url">click me </a>
END
	$m->document->links->[0]->click;
	is $m->document->title, 'The other page',
		'a click event on a link goes to the other page';
}

use tests 1; # call_with and event targets
{ package Function;
  sub call_with { ${$_[0]} = $_[1] } # record event target
  sub target_passed { ${+shift} }
  sub new { bless \my $x }
}
{
 my $function = new Function;
 (my $m = new WWW::Scripter)->onload($function);
 $m->trigger_event('load');
 is $function->target_passed, $m,
  'target passed to a window event handler with a call_with method';
  # My attempt at using separate ‘internal-only’ WWW::Scripter::EventTarget
  # objects  (for different sets of event listeners for each  page)  back-
  # fired. That’s what this test is for. This was fixed in version 0.009.
}

use tests 1; # event2sub that leaves stuff in $@
{
	my $w;
	(my $m = new WWW::Scripter onwarn => sub { $w = shift })
	 ->script_handler(
			default => new ScriptHandler sub {}, sub {
				$@ = "strit"
			}
	);
	$m->get("data:text/html,<body onload='plile'>");
	is $w, 'strit', 'event2sub $@ messages turn into warnings';
}
