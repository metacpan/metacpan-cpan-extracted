package Web::App::Session::Cookie;
# $Id: Cookie.pm,v 1.1 2009/03/29 10:12:26 apla Exp $

use strict;

use CGI::Cookie;

use Digest::MD5;

use Web::App;

use Class::Easy;

sub detected_session {
	my $pack   = shift;
	my $entity = shift;
	
	my $app = Web::App->app;
	
	my $request = $app->request;
	my $session = $app->session;
	
	my $cookies = CGI::Cookie->fetch;
	
	my $cookie  = $cookies->{$entity};
	
	return unless defined $cookie;
	
	debug "cookie value is: '$cookie'";
	
	if ($session->no_parse_cookie) {
		return $cookie->value;
	}
	
	my ($user, $expires, $hash) = split (':', $cookie->value);
	
	my $chunk  = "$user:$expires";
	my $digest_string = $session->salt.$chunk;
	
	
	if (Digest::MD5::md5_hex ($digest_string) eq $hash and time < hex $expires) {
		debug "user is: '$user'";
		return $user, $expires, $hash;
	} else {
		debug "hash for '$digest_string': received '$hash', but waiting for: ",
			Digest::MD5::md5_hex ($digest_string), ", session expired";
		$session->expired (1);
		return $user, $expires, $hash;
	}
	
}

sub save {
	my $class   = shift;
	my $entity  = shift;
	my @session = @_;
	
	my $app     = Web::App->app;
	my $request = $app->request;
	my $session = $app->session;
	
	my $expires  = time + 60*60; # one hour
	my $hex_expires = sprintf '%x', $expires; 
	
	my $session_id = $session[0];
	
	# now we encrypt cookie
	my $chunk  = "$session_id:$hex_expires";
	my $digest_string = $session->salt.$chunk;
	
	my $cookie = CGI::Cookie->new (
		-name  => $entity,
		-value => $chunk.':'.Digest::MD5::md5_hex ($digest_string),
		-expires => '+10y',
	);
	
	$app->response->headers->header ('Set-Cookie' => $cookie);

}

sub remove {
	my $class   = shift;
	my $entity  = shift;
	
	my $app     = Web::App->app;
	
	my $cookie = CGI::Cookie->new (
		-name  => $entity,
		-value => '',
		-expires => '-10y',
	);
	
	$app->response->headers->header ('Set-Cookie' => $cookie);

}


1;