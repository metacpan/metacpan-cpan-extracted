package WWW::Tracking::Data::Plugin::Headers;

use strict;
use warnings;

our $VERSION = '0.05';

use WWW::Tracking::Data;

1;

package WWW::Tracking::Data;

use Carp::Clan 'croak';
use CGI::Cookie;

sub from_headers {
	my $class = shift;
	my $args = shift || {};
	
	my $headers = $args->{'headers'}
		or croak 'headers is mandatory argument';
	my $request_uri = $args->{'request_uri'}
		or croak 'request_uri is mandatory argument';
	my $remote_ip = $args->{'remote_ip'}
		or croak 'remote_ip is mandatory argument';
	my $visitor_id = $args->{'visitor_id'};
	my $visitor_cookie_name = $args->{'visitor_cookie_name'} || '__vcid';
	
	unless ($visitor_id) {
		my $cookies_header = $headers->header('Cookie');
		my %cookies = CGI::Cookie->parse($cookies_header);
		$visitor_id = $cookies{$visitor_cookie_name}->value
			if $cookies{$visitor_cookie_name};
	}
	
	return $class->new(
		hostname           => $headers->header('Host') || undef,
		request_uri        => $request_uri,
		remote_ip          => $remote_ip,
		user_agent         => $headers->user_agent || undef,
		referer            => $headers->referer || undef,
		browser_language   => $headers->header('Accept-Language') || undef,
		encoding           => $headers->header('Accept-Charset') || undef,
		visitor_id         => $visitor_id,
	);
}

1;


__END__

=head1 NAME

WWW::Tracking::Data::Plugin::Headers - create C<WWW::Tracking::Data> object from http headers

=head1 SYNOPSIS

	
	my $wt = WWW::Tracking->new->from(
		'headers' => {
			'headers'     => $req->headers,
			'request_uri' => $req->uri,
			'remote_ip'   => $req->address,
			'visitor_cookie_name' => '__vcid',
		},
	);	

=head1 DESCRIPTION

Parses http headers and generate L<WWW::Tracking::Data> object from it.

=cut
