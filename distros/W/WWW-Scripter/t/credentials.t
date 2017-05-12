#!perl

# This test script may seem redundant, but we need to make sure our ver-
# sion-juggling is working correctly. (And, after all, these tests *were*
# failing in version 0.001.)

use warnings; no warnings qw 'utf8 parenthesis';
use strict;
use Test::More;
use lib 't';

{
	package FakeProtocol;
	use LWP::Protocol;
	our @ISA = LWP::Protocol::;

	LWP'Protocol'implementor http => __PACKAGE__;

	sub request {
		my($self, $request, $proxy, $arg) = @_;
	
		my $h = new HTTP::Headers;
		header $h 'Content-Type', 'text/html';
		header $h 'WWW-Authenticate', 'basic realm="foo"';
		my($u,$p) = $request->authorization_basic;
		my $can_pass = defined $u && defined $p &&
		         ( $u eq 'yuzer' and $p eq reverse $u );
		my $response = new HTTP::Response
			$can_pass
			? (200, "hokkhe", $h)
			: (401, "Hugo's there", $h);
		my $src =
			$can_pass
			? '<title>Wellcum</title><h1>'.
			  $request->authorization_basic .'</h1>'
			: '<title>401 Forbidden</title><h1>Fivebidden</h1>'
			;

		my $done;
		$self->collect($arg, $response, sub {
			\($done++ ? '' : $src)
		});
	}
	
}

use tests 3;

use WWW::Scripter;
my $w = new WWW::Scripter;

$w->credentials('istodoulos','nominifur');
my $r = $w->get('http://etetete/3');
is $r->code, 401,
 'make sure the following tests actually test something';

$w->credentials('yuzer','rezuy');
$r = $w->get('http://etetete/1');
is $r->code, 200, '2-arg overridden credentials';
like $w->content, qr/>yuzer:rezuy</, 'name & pw make their way through';
