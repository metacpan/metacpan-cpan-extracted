package WWW::OAuth::Request::HTTP_Request;

use strict;
use warnings;
use Class::Tiny::Chained 'request';

use Carp 'croak';
use Scalar::Util 'blessed';

use Role::Tiny::With;
with 'WWW::OAuth::Request';

our $VERSION = '1.000';

sub method {
	my $self = shift;
	return $self->request->method unless @_;
	$self->request->method(shift);
	return $self;
}

sub url {
	my $self = shift;
	return $self->request->uri->as_string unless @_;
	$self->request->uri(shift);
	return $self;
}

sub content {
	my $self = shift;
	return $self->request->content unless @_;
	$self->request->content(shift);
	return $self;
}

sub content_is_form {
	my $self = shift;
	my @parts = $self->request->parts;
	return 0 if @parts;
	my $content_type = $self->request->headers->content_type;
	return 0 unless defined $content_type and $content_type =~ m!application/x-www-form-urlencoded!i;
	return 1;
}

sub header {
	my $self = shift;
	my $name = shift;
	croak 'No header to set/retrieve' unless defined $name;
	return scalar $self->request->header($name) unless @_;
	$self->request->header($name => shift);
	return $self;
}

sub request_with {
	my ($self, $ua) = @_;
	croak 'Invalid user-agent object' unless blessed $ua;
	if ($ua->isa('LWP::UserAgent') or $ua->isa('HTTP::Thin')) {
		return $ua->request($self->request);
	} elsif ($ua->isa('Net::Async::HTTP')) {
		return $ua->do_request(request => $self->request);
	} else {
		my $class = blessed $ua;
		croak "Unknown user-agent class $class";
	}
}

1;

=head1 NAME

WWW::OAuth::Request::HTTP_Request - HTTP Request container for HTTP::Request

=head1 SYNOPSIS

 my $req = WWW::OAuth::Request::HTTP_Request->new(request => $http_request);
 $req->request_with(LWP::UserAgent->new);

=head1 DESCRIPTION

L<WWW::OAuth::Request::HTTP_Request> is a request container for L<WWW::OAuth>
that wraps a L<HTTP::Request> object, which can be used by several user-agents
like L<LWP::UserAgent>, L<HTTP::Thin>, and L<Net::Async::HTTP>. It performs the
role L<WWW::OAuth::Request>.

=head1 ATTRIBUTES

L<WWW::OAuth::Request::HTTP_Request> implements the following attributes.

=head2 request

 my $http_request = $req->request;
 $req             = $req->request(HTTP::Request->new(GET => $url));

L<HTTP::Request> object to authenticate.

=head1 METHODS

L<WWW::OAuth::Request::HTTP_Request> composes all methods from
L<WWW::OAuth::Request>, and implements the following new ones.

=head2 content

 my $content = $req->content;
 $req        = $req->content('foo=1&bar=2');

Set or return request content from L</"request">.

=head2 content_is_form

 my $bool = $req->content_is_form;

Check whether L</"request"> has single-part content and a C<Content-Type>
header of C<application/x-www-form-urlencoded>.

=head2 header

 my $header = $req->header('Content-Type');
 $req       = $req->header(Authorization => 'Basic foobar');

Set or return a request header from L</"request">.

=head2 method

 my $method = $req->method;
 $req       = $req->method('GET');

Set or return request method from L</"request">.

=head2 request_with

 $http_response = $req->request_with(LWP::UserAgent->new);

Run request with passed user-agent object, and return L<HTTP::Response> object.
User-agent may be L<LWP::UserAgent>, L<HTTP::Thin>, or L<Net::Async::HTTP>. If
run with L<Net::Async::HTTP>, the return value is a L<Future> yielding the
L<HTTP::Response> object as in L<< "do_request" in Net::Async::HTTP|Net::Async::HTTP/"$response = $http->do_request( %args )->get" >>.

=head2 url

 my $url = $req->url;
 $req    = $req->url('http://example.com/api/');

Set or return request URL from L</"request">.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<LWP::UserAgent>, L<HTTP::Thin>, L<Net::Async::HTTP>
