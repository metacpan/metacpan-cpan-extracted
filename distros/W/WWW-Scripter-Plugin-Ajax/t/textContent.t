#!perl

# This script tests the little hack we added to _xml_stuff.pm to add
# textContent to XML::DOM::Lite.

use strict; use warnings;
use lib 't';
use Test::More;

use utf8;
use WWW::Scripter;
use WWW::Scripter::Plugin::JavaScript 0.002; # new init interface
use HTTP::Headers;
use HTTP::Response;

our %SRC;

# For faking HTTP requests; this gets the source code from the global %SRC
# hash, using the "$method $url" as the key. Each element of the hash
# is an array ref containing (0) the Content-Type and (1) text that is to
# become the body of the response or a coderef.
no warnings 'redefine';
{
	package FakeProtocol;
	use LWP::Protocol;
	our @ISA = LWP::Protocol::;

	LWP'Protocol'implementor $_ => __PACKAGE__ for qw/ http file /;

	sub _create_response_object {
		my $request = shift;

		my $src_ary =
			$'SRC{join ' ',method $request,$request->uri};
		my $h = new HTTP::Headers;
		header $h 'Content-Type', $$src_ary[0] if $src_ary;
		my $r = new HTTP::Response
			$src_ary
				? (200, 'Okey dokes')
				: (404, 'Knot found'),
			$h;
		$r, $src_ary && ref $$src_ary[1]
			? $$src_ary[1]->($request)
			: $$src_ary[1];

	}

	sub request {
		my($self, $request, $proxy, $arg) = @_;
	
		          # This weird syntax ensures it can be overridden:
		my($response,$src) =
			(\&{'_create_response_object'})->($request);

		my $done;
		defined $src or $src = "";
		$self->collect($arg, $response, sub {
			\($done++ ? '' : "$src")
			      # LWP has a heart attack without those quotes
		});
	}
	
}

$SRC{'GET http://foo.com/blank'}=['text/html',''];
$SRC{'GET http://foo.com/xml'}=['text/xml',<<XML];
<?xml version="1.0"?>
<root>This <item1>is<item2> a </item2>sentenc</item1>e.</root>
XML


my $m = new WWW::Scripter;
$m->use_plugin('Ajax' => init => sub {
	for my $js_plugin(shift->plugin('JavaScript')){
		$js_plugin->new_function($_ => \&$_)
			for qw 'ok is diag pass fail unlike like';
	}
});


#----------------------------------------------------------------#
use tests 3; # The Tests

$m->get('http://foo.com/blank');
$m->eval('
  with(new XMLHttpRequest)
   open("GET", "http://foo.com/xml", false),
   send(null),
   is(responseXML.documentElement.textContent, "This is a sentence."),
   responseXML.documentElement.textContent="feef1ef0efum",
   is(
     responseXML.documentElement.childNodes.length, 1,
    "length of childNodes after assignment to textContent"
   ),
   is(responseXML.documentElement.childNodes[0].nodeValue, "feef1ef0efum",
      "value assigned to new text node by textContent")
');
