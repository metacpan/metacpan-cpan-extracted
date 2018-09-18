package WWW::OAuth::Util;

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use Module::Runtime 'require_module';
use Role::Tiny ();
use Scalar::Util 'blessed';
use WWW::Form::UrlEncoded 'build_urlencoded_utf8', 'parse_urlencoded_arrayref';

our $VERSION = '1.000';

our @EXPORT_OK = qw(form_urlencode form_urldecode oauth_request);

sub form_urldecode {
	my $string = shift;
	return [] unless defined $string;
	my $form = parse_urlencoded_arrayref $string;
	utf8::decode $_ for @$form;
	return $form;
}

sub form_urlencode {
	my $form = shift;
	if (ref $form eq 'ARRAY') {
		croak 'Form to urlencode must be even-sized' if @$form % 2;
	} elsif (ref $form eq 'HASH') {
		$form = [map { ($_ => $form->{$_}) } sort keys %$form];
	} else {
		croak 'Form to urlencode must be hash or array reference';
	}
	return build_urlencoded_utf8 $form, '&';
}

sub oauth_request {
	my $class = ref $_[0] ? undef : shift;
	my $proto = shift;
	my %args;
	if (blessed $proto) { # Request object
		return $proto if Role::Tiny::does_role($proto, 'WWW::OAuth::Request'); # already in container
		unless (defined $class) {
			if ($proto->isa('HTTP::Request')) {
				$class = 'HTTP_Request';
			} elsif ($proto->isa('Mojo::Message::Request')) {
				$class = 'Mojo';
			} else {
				$class = blessed $proto;
				$class =~ s/::/_/g;
			}
		}
		%args = (request => $proto);
	} elsif (ref $proto eq 'HASH') { # Hashref
		$class = 'Basic' unless defined $class;
		%args = %$proto;
	} else {
		croak 'No request or request parameters passed';
	}
	
	$class = "WWW::OAuth::Request::$class" unless $class =~ /::/;
	require_module $class;
	croak "Class $class does not perform the role WWW::OAuth::Request"
		unless Role::Tiny::does_role($class, 'WWW::OAuth::Request');
	
	return $class->new(%args);
}

1;

=head1 NAME

WWW::OAuth::Util - Utility functions for WWW::OAuth

=head1 SYNOPSIS

 use WWW::OAuth::Util 'form_urldecode', 'form_urlencode';
 my $body_string = form_urlencode({foo => 'a b c', bar => [1, 2, 3]});
 # bar=1&bar=2&bar=3&foo=a+b+c
 my $ordered_pairs = form_urldecode($body_string);
 # ['bar', '1', 'bar', '2', 'bar', '3', 'foo', 'a b c']
 
 use WWW::OAuth::Util 'oauth_request';
 my $container = oauth_request($http_request);

=head1 DESCRIPTION

L<WWW::OAuth::Util> contains utility functions for use with L<WWW::OAuth>. All
functions are exportable on demand.

=head1 FUNCTIONS

=head2 form_urldecode

 my $param_pairs = form_urldecode($body_string);

Decodes an C<application/x-www-form-urlencoded> string and returns an
even-sized arrayref of key-value pairs. Order is preserved and repeated keys
are not combined.

=head2 form_urlencode

 my $body_string = form_urlencode([foo => 2, bar => 'baz', foo => 1]);
 # foo=2&bar=baz&foo=1
 my $body_string = form_urlencode({foo => [2, 1], bar => 'baz'});
 # bar=baz&foo=2&foo=1

Converts a hash or array reference into an C<application/x-www-form-urlencoded>
string suitable for a query string or request body. If a value is an array
reference, the key is repeated with each value. Order is preserved if
parameters are passed in an array reference; the parameters are sorted by key
for consistency if passed in a hash reference.

=head2 oauth_request

 my $container = oauth_request($http_request);
 my $container = oauth_request({ method => 'GET', url => $url });
 my $container = oauth_request(Basic => { method => 'POST', url => $url, content => $content });

Constructs an HTTP request container performing the L<WWW::OAuth::Request>
role. The input should be a recognized request object or hashref of arguments
optionally preceded by a container class name. The class name is appended to
C<WWW::OAuth::Request::> if it does not contain C<::>. Currently,
L<HTTP::Request> and L<Mojo::Message::Request> objects are recognized, and
hashrefs are used to construct a L<WWW::OAuth::Request::Basic> object if no
container class is specified.

 # Longer forms to construct WWW::OAuth::Request::HTTP_Request
 my $container = oauth_request(HTTP_Request => $http_request);
 my $container = oauth_request(HTTP_Request => { request => $http_request });

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<URI>, L<URL Living Standard|https://url.spec.whatwg.org/#application/x-www-form-urlencoded>
