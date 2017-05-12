#!perl -w

# Modified version of WWW::Mechanize::Plugin::DOM’s dom.t
# Tests are gradually being moved from here into other files. More
# recently, this has become the dumping ground for miscellaneous tests.

use strict; use warnings;
use lib 't';
use Test::More;

use utf8;

use Scalar::Util 1.09 'refaddr';
use URI;
use URI::file;
use WWW::Scripter;

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

use tests 4; # interface for callback routines
for my $lang ('default', qr//) {
	my $test_name = ref $lang ? 'with re' : $lang;
	my @result;
	my $event_triggered;

	my $m = new WWW::Scripter;
	$m->script_handler($lang => new ScriptHandler
		sub {
				push @result, "script",
				  map ref eq "URI::file" ? $_ : ref||$_, @_
		},
		sub {
				push @result, "event",
				 map ref eq "URI::file" ? $_ : ref||$_, @_;
				sub { ++ $event_triggered }
		}
	);
	my $uri = URI::file->new_abs( 't/dom-callbacks.html' );
	my $script_uri = URI::file->new_abs( 't/dom-test-script' );
	$m->get($uri);
	is_deeply \@result, [
		script =>
			'WWW::Scripter',
			"<!--\nthis is a short script\n-->",
			"$uri",
			 3,
			 1, # not normative; it just has to be true
		script =>
			'WWW::Scripter',
			"This is an external script.\n",
			"$script_uri",
			 1,
			 0, # not normative; it just has to be false
		event =>
			'WWW::Scripter',
			'HTML::DOM::Element::A',
			'click',
			'bar',
			"$uri",
			 8,
		event =>
			'WWW::Scripter',
			'HTML::DOM::Element::A',
			'click',
			'baz',
			"$uri",
			 9,
	], "callbacks ($test_name)"
	 or require Data'Dumper,
	    diag Data'Dumper'Dumper(\@result);
	$m->document->getElementsByTagName('a')->[0]->
		trigger_event('click');
	is $event_triggered,1, "event handlers ($test_name)";
}

use tests 1; # Make sure the presence of a callback routine does not cause
             # <meta> tags to warn that have no http-equiv attribute.
{
	my $m = new WWW::Scripter;
	$m->script_handler(default => new ScriptHandler
		sub {},
		sub {}
	);
	my $uri = data_url '<meta>';
	my $w;
	local $SIG{__WARN__} = sub { $w = shift };
	$m->get($uri);
	is $w,undef,
	 "<meta> tags w/o http-equiv warn not when script handlers exist";
}

use tests 2; # charset
{     
	(my $m = new WWW::Scripter);
	$m->get(URI::file->new_abs( 't/dom-charset.html' ));
	is $m->document->title,
		'Ce mai faceţ?', 'charset';
	local $^W;
	$m->get(URI::file->new_abs( 't/dom-charset2.html' ));
	is $m->document->title,
		'Αὐτὴ ἡ σελίδα χρησιμοποιεῖ «UTF-8»', 'charset 2';
}

use tests 2; # get_text_content with different charsets
{            # (bug in 0.002 [Mech plugin])
	(my $m = new WWW::Scripter);
	$m->get(URI::file->new_abs( 't/dom-charset.html' ));
	like $m->content(format=>'text'), qr/Ce mai face\376\?/,
		 'get_text_content';
	local $^W;
	$m->get(URI::file->new_abs( 't/dom-charset2.html' ));
	my $qr = qr/
		\316\221\341\275\220\317\204\341\275\264\302\240\341
		\274\241[ ]\317\203\316\265\316\273\341\275\267\316\264\316
		\261[ ]\317\207\317\201\316\267\317\203\316\271\316\274\316
		\277\317\200\316\277\316\271\316\265\341\277\226[ ]\302\253
		UTF-8\302\273/x;
	like $m->content(format=>'text'), $qr,
		 'get_text_content on subsequent page';
}

use tests 9; # scripts_enabled
{
	my $script_src;
	my $event;

	my $m = new WWW::Scripter;
	$m->script_handler(
			default => new ScriptHandler sub {
				$script_src = $_[1]
			}, sub {
				my $e = "@_[2,3]"; # event name & attr val
				sub { $event = $e }
			}
	);
	ok $m->scripts_enabled, 'scripts enabled by default';

	my $url = data_url(<<'END');
		<HTML><head><title>oetneotne</title></head>
		<body onclick="do stough">
		<script>this is a script</script>
END
	$m->scripts_enabled(0);
	$m->get($url);
	is $script_src, undef, 'disabling scripts works';
	$m->get($url);
	is $script_src, undef, 'the disabled settings survives a ->get';
	$m->scripts_enabled(1);
	$m->document->body->trigger_event('click');
	is $event, undef,
	  'disabling scripts stops event handlers from being registered';
	$m->get($url);
	is $script_src, 'this is a script', 're-enabling scripts works';
	$m->document->body->click;
	is $event, 'click do stough',
		'  and re-enables attr event handler registration as well';
	$event=undef;
	$m->scripts_enabled(0);
	$m->document->body->trigger_event('click');
	is $event, undef,
	   'disabling scripts disabled event handlers already registered';
	$m->scripts_enabled(1);
	$m->document->body->trigger_event('click');
	is $event, 'click do stough',
	' & re-enabling them re-enables event handlers already registered';

	$m->scripts_enabled(0);
	$m->onfoo(sub{$event = 42});
	$m->trigger_event('foo');
	isn't $event, 42,
	  'window event handlers are not called when scripts are off';
}

use tests 3; # dom_enabled
{
	my $m = new WWW::Scripter;
	ok $m->dom_enabled(0), 'DOM enabled by default';

	$m->get('data:text/html,123');
	ok !$m->document, 'dom_enabled'
	 or diag $m->document->URL;
	is $m->content, '123', 'content works when !dom_enabled';
}

use tests 1; # DOM tree ->charset
{
	my $m = new WWW::Scripter;
	my $url = data_url <<'END';
		<title>A page</title><p>
END
	$url->media_type("text/html;charset=iso-8859-7");
	$m->get($url);

	is $m->document->charset, 'iso-8859-7',
		'the plugin sets the DOM tree\'s charset attribute';
}

use tests 1; # get_content and !doctype
{
	my $m = new WWW::Scripter;
	my $url = data_url <<'END';
		<!doctype html public "-//W3C//DTD HTML 4.01//EN">
		<title>A page</title><p>
END
	$m->get($url);

	like $m->content, qr/^<!doctype/,
		'get_content includes the doctype (if there was one)';
}

use tests 1; # re-use of document objects when browsing history
{
 my $w = new WWW::Scripter;
 $w->get("about:blank");
 my @refaddrs = refaddr $w->document;
 $w->get("data:text/html,foo");
 push @refaddrs, refaddr $w->document;
 $w->back;
 push @refaddrs, refaddr $w->document;
 like join('-',@refaddrs), qr/^(\d+)-(?!\1)\d+-\1\z/,
  'going back reuses the same document object';
}

use tests 4; # about:blank before browsing
{
 my $w = new WWW::Scripter;
 is $w->uri, "about:blank",
  "about:blank uri before browsing";
 is $w->ct, "text/html", "ct before browsing";
 is $w->response->content, "", "content before browsing";
 ok $w->document,, "document before browsing";
}

use tests 2; # clone
{
 my $w = new WWW::Scripter;
 my $clone = clone $w;
 ok eval{
   ()= # non-void context
      $clone->class_info
   ; 1}, 'class_info on a clone no longer dies in non-void context';
 is_deeply [eval{$clone->class_info}], [$w->class_info],
  'class_info gets copied over';
}

use tests 1; # no doc object for non-HTML
{
 my $w = new WWW::Scripter;
 (my $url = <<"") =~ s/\s+//;   # URL stolen from URI::data
           data:image/gif;base64,R0lGODdhIAAgAIAAAAAAAPj8+CwAAAAAI
           AAgAAAClYyPqcu9AJyCjtIKc5w5xP14xgeO2tlY3nWcajmZZdeJcG
           Kxrmimms1KMTa1Wg8UROx4MNUq1HrycMjHT9b6xKxaFLM6VRKzI+p
           KS9XtXpcbdun6uWVxJXA8pNPkdkkxhxc21LZHFOgD2KMoQXa2KMWI
           JtnE2KizVUkYJVZZ1nczBxXlFopZBtoJ2diXGdNUymmJdFMAADs=

 get $w $url;
 ok !$w->document, 'no doc object for non-HTML';
}

use tests 1; # DOES
ok new WWW'Scripter ->DOES(WWW'Scripter::),'DOES';

use tests 1; # screen
isa_ok new WWW'Scripter->screen, 'WWW::Scripter::Screen', 'screen';

use tests 1; # %WindowInterface
ok exists $WWW::Scripter'WindowInterface{history};
