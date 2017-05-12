#!perl -w

# This file deals with things specific to <script> elements.

use strict; use warnings;
use lib 't';

use utf8;

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

use tests 1; # warnings caused by script tags and event handlers
{            # with no language
	my $warnings = 0;
	local $SIG{__WARN__} = sub { ++$warnings;};

	my $m = new WWW::Scripter;
	$m->script_handler(
			'foo' => qr//
	);
	$m->get(URI::file->new_abs( 't/dom-no-lang.html' ));
	is $warnings, 0, 'absence of a script language causes no warnings';
}

use tests 3; # script encodings
{
	my $script_content;
	(my $m = new WWW::Scripter)
	 ->script_handler( default => new ScriptHandler sub {
			$script_content = $_[1];
		}) ;

	my $script_url = data_url "\xfe\xfd";
	$script_url->media_type(
		'application/javascript;charset=iso-8859-7'
	);
	my $html_url = data_url <<"END";
		<title>A page</title><script src='$script_url'></script><p>
END
	$m->get($html_url);
	is $script_content, 'ώύ', 'script encoding in the HTTP headers';

	$script_url->media_type('application/javascript');
	$html_url = data_url <<"END";
		<title>A page</title>
			<script src='$script_url'></script><p>
END
	$html_url->media_type('text/html;charset=iso-8859-5');
	$m->get($html_url);
	is $script_content, 'ў§',
		'script encoding inferred from the HTML page';

	$html_url = data_url <<"END";
		<title>A page</title>
		  <script charset=iso-8859-4 src='$script_url'></script><p>
END
	$m->get($html_url);
	is $script_content, 'ūũ',
		'script encoding from explicit charset param';
}

use tests 1; # gzipped scripts
{
	package ProtocolThatAlwaysReturnsTheSameThing;
	use LWP::Protocol;
	our @ISA = LWP::Protocol::;

	LWP'Protocol'implementor $_ => __PACKAGE__ for qw/ test /;

	sub request {
		my($self, $request, $proxy, $arg) = @_;
	
		my $h = new HTTP::Headers;
		$h->header('Content-Encoding', 'gzip');
		my $zhello = join '', map chr hex, qw[
		 1f 8b 08 00 02 5b 09 49 00 03 cb 48 cd c9 c9 07 00 86 a6
		 10 36 05 00 00 00
		];
		new HTTP::Response 200, 'OK', $h, $zhello
	}
}
{
 my $output;
 (my $m = new WWW::Scripter)
  ->script_handler( default => new ScriptHandler sub { $output = $_[1] } );
 $m->get(data_url '<script src="test://foo/"></script>');
 is $output, 'hello', 'gzipped scripts';
}

use tests 1; # appendChild(<script>) shouldn’t warn (fixed in 0.009)
{
 use HTML::DOM::EventTarget 0.034; # This test also triggers bugs in
 my @w;                            # EventTarget 0.033 and earlier.
 local $SIG{__WARN__} = sub { diag("oteheuot");push @w, shift };
 (my $w = new WWW::Scripter)->script_handler(
  default => new ScriptHandler sub {}
 );
 $w->get('about:blank');
 my $doc = $w->document;
 my $script = $doc->createElement('script');
 $script->appendChild($doc->createTextNode('shext'));
 $doc->body->appendChild($script);
 is "@w", "", 'no warnings for generated inline script elements';
}                        # where ‘inline’ means lacking an src attribute

use tests 1; # empty script element
{
 (my $w = new WWW::Scripter)->script_handler(
  default => new ScriptHandler sub {}
 );
 ok eval { $w->get('data:text/html,<script></script>'); 1},
  '<script></script> does not cause errors';
  # the combination of a script without an src attribute and no content
  # caused this to die prior to version 0.009
}

use tests 1; # scripts served as text/html (fixed in 0.010)
{
 my $called;
 (my $w = new WWW::Scripter)->script_handler(
  default => new ScriptHandler
   sub {}, # script handler
   sub { ++$called } # event2sub -- this should never be called
 );
 $w->get(
  'data:text/html,'
   . '<script src="data:text/html,/*<a onclick=crile>*/"></script>'
 );
 ok !$called, 'scripts served as text/html are not dommified';
}

use tests 1; # Can scripts see forms with the Mech interface?
{
 my $form;
 (my $m = new WWW::Scripter)
  ->script_handler(default => new ScriptHandler sub {
    $form = ($_[0]->forms)[0]
   }, sub {});
 $m->get(data_url '<form><script>grat</script>');
 is $form, $m->document->forms->[0],
  'Scripts can see forms with the mech interface.';
}


use tests 1; # script errors
{
	my $w;
	(my $m = new WWW::Scripter onwarn => sub { $w = shift })
	 ->script_handler(
			default => new ScriptHandler sub {
				$@ = "tew"
			}, sub {} 
	);
	$m->get("data:text/html,<script>sphat</script>");
	is $w, 'tew', 'script errors turn into warnings';
}

use tests 1; # Referrer header when fetching a script
{
	package ProtocolThatReturnsReferrer;
	use LWP::Protocol;
	our @ISA = LWP::Protocol::;

	LWP'Protocol'implementor $_ => __PACKAGE__ for qw/ referrer /;

	sub request {
		my($self, $request, $proxy, $arg) = @_;
		new HTTP::Response 200, 'OK', undef, $request->referer
	}
}
{
 my $output;
 (my $m = new WWW::Scripter)
  ->script_handler( default => new ScriptHandler sub { $output = $_[1] } );
 $m->get(my $u = data_url '<script src="referrer://foo/"></script>');
 is $output, $u, 'referrer sent with script requests';
}
