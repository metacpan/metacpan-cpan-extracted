package WWW::OAuth::Request::Basic;

use strict;
use warnings;
use Class::Tiny::Chained 'method', 'url', 'content', { headers => sub { {} } };

use Carp 'croak';
use List::Util 'first';
use Scalar::Util 'blessed';
use WWW::OAuth::Util 'form_urlencode';

use Role::Tiny::With;
with 'WWW::OAuth::Request';

our $VERSION = '1.000';

sub content_is_form {
	my $self = shift;
	my $content_type = $self->header('Content-Type');
	return 0 unless defined $content_type and $content_type =~ m!application/x-www-form-urlencoded!i;
	return 1;
}

sub header {
	my $self = shift;
	my $name = shift;
	croak 'No header to set/retrieve' unless defined $name;
	my $headers = $self->headers;
	unless (@_) {
		# workaround for TEMP bug in first/lc
		my @names = keys %$headers;
		my $key = first { lc $_ eq lc $name } @names;
		return undef unless defined $key;
		my @values = ref $headers->{$key} eq 'ARRAY' ? @{$headers->{$key}} : $headers->{$key};
		return join ', ', grep { defined } @values;
	}
	my $value = shift;
	my @existing = grep { lc $_ eq lc $name } keys %$headers;
	delete @$headers{@existing} if @existing;
	$headers->{$name} = $value;
	return $self;
}

sub set_form {
	my ($self, $form) = @_;
	$self->header('Content-Type' => 'application/x-www-form-urlencoded');
	$self->content(form_urlencode $form);
	return $self;
}

sub request_with {
	my ($self, $ua) = @_;
	croak 'Unknown user-agent object' unless blessed $ua and $ua->isa('HTTP::Tiny');
	return $ua->request($self->method, $self->url, { headers => $self->headers, content => $self->content });
}

1;

=head1 NAME

WWW::OAuth::Request::Basic - HTTP Request container for HTTP::Tiny

=head1 SYNOPSIS

 my $req = WWW::OAuth::Request::Basic->new(method => 'POST', url => $url, content => $content);
 $req->request_with(HTTP::Tiny->new);

=head1 DESCRIPTION

L<WWW::OAuth::Request::Basic> is a request container for L<WWW::OAuth> that
stores the request parameters directly, for use with user-agents that do not
use request objects like L<HTTP::Tiny>. It performs the role
L<WWW::OAuth::Request>.

=head1 ATTRIBUTES

L<WWW::OAuth::Request::Basic> implements the following attributes.

=head2 content

 my $content = $req->content;
 $req        = $req->content('foo=1&bar=2');

Request content string.

=head2 headers

 my $headers = $req->headers;
 $req        = $req->headers({});

Hashref of request headers. Must be updated carefully as headers are
case-insensitive. Values can be array references to specify multi-value
headers.

=head2 method

 my $method = $req->method;
 $req       = $req->method('GET');

Request method.

=head2 url

 my $url = $req->url;
 $req    = $req->url('http://example.com/api/');

Request URL.

=head1 METHODS

L<WWW::OAuth::Request::Basic> composes all methods from L<WWW::OAuth::Request>,
and implements the following new ones.

=head2 content_is_form

 my $bool = $req->content_is_form;

Check whether L</"headers"> contains a C<Content-Type> header set to
C<application/x-www-form-urlencoded>.

=head2 header

 my $header = $req->header('Content-Type');
 $req       = $req->header(Authorization => 'Basic foobar');

Set or return a request header in L</"headers">.

=head2 set_form

 $req = $req->set_form({foo => 'bar'});

Convenience method to set L</"content"> to a urlencoded form. Equivalent to:

 use WWW::OAuth::Util 'form_urlencode';
 $req->header('Content-Type' => 'application/x-www-form-urlencoded');
 $req->content(form_urlencode $form);

=head2 request_with

 my $res = $req->request_with(HTTP::Tiny->new);

Run request with passed L<HTTP::Tiny> user-agent object, and return response
hashref, as in L<HTTP::Tiny/"request">.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<HTTP::Tiny>
