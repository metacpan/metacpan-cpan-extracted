#!perl

use lib 't';
use warnings;
no warnings qw 'utf8 parenthesis regexp once qw bareword syntax';

use Test::More;
use URI;
use WWW::Scripter;

sub data_url {
	my $u = new URI 'data:';
	$u->media_type('text/html');
	$u->data(shift);
	$u
}

use tests 5; # submit (overridden in version 0.006)
{
	my $m = new WWW::Scripter;
	my $url = data_url '<form action="about:blank">';
	$m->get($url);
	my $called;
	$m->current_form->addEventListener( submit => my $eh = sub {
		++$called; shift->preventDefault
	} );
	is $m->submit, undef,
	 'submit returns undef when the event is cancelled';
	$m->submit; # make sure it works in void context, too
	is $called, 2, 'onsubmit was called';
	is $m->uri, $url, 'event handlers can cancel $mech->submit';
	$m->current_form->removeEventListener(submit => $eh);
	is $m->submit, $m->response, 'submit returns the response object';
	like $m->uri, qr/^about:blank\b/, '& submit went to another page';
}

use tests 5; # click (overridden in version 0.011)
{
	my $m = new WWW::Scripter;
	my $url = data_url '<form action="about:blank">';
	$m->get($url);
	my $called;
	$m->current_form->addEventListener( submit => my $eh = sub {
		++$called; shift->preventDefault
	} );
	is $m->click, undef,
	 'click returns undef when the event is cancelled';
	$m->click; # make sure it works in void context, too
	is $called, 2, 'onsubmit was called (click method)';
	is $m->uri, $url, 'event handlers can cancel $mech->click';
	$m->current_form->removeEventListener(submit => $eh);
	is $m->click, $m->response, 'click returns the response object';
	like $m->uri, qr/^about:blank\b/, '& click went to another page';
}
