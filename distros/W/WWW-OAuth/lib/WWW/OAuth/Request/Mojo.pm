package WWW::OAuth::Request::Mojo;

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
	return $self->request->url->to_string unless @_;
	require Mojo::URL;
	$self->request->url(Mojo::URL->new(shift));
	return $self;
}

sub content {
	my $self = shift;
	return $self->request->body unless @_;
	$self->request->body(shift);
	return $self;
}

sub content_is_form {
	my $self = shift;
	return 0 if $self->request->content->is_multipart;
	my $content_type = $self->request->headers->content_type;
	return 0 unless defined $content_type and $content_type =~ m!application/x-www-form-urlencoded!i;
	return 1;
}

sub query_pairs { shift->request->query_params->pairs }

sub body_pairs { require Mojo::Parameters; Mojo::Parameters->new(shift->request->body)->pairs }

sub header {
	my $self = shift;
	my $name = shift;
	croak 'No header to set/retrieve' unless defined $name;
	return $self->request->headers->header($name) unless @_;
	my @values = ref $_[0] eq 'ARRAY' ? @{$_[0]} : $_[0];
	$self->request->headers->header($name => @values);
	return $self;
}

sub request_with {
	my ($self, $ua, $cb) = @_;
	croak 'Unknown user-agent object' unless blessed $ua and $ua->isa('Mojo::UserAgent');
	return $ua->start($self->_build_tx($ua), $cb);
}

sub request_with_p {
	my ($self, $ua) = @_;
	croak 'Unknown user-agent object' unless blessed $ua and $ua->isa('Mojo::UserAgent');
	my $has_promises = do { local $@; eval { require Mojolicious; Mojolicious->VERSION('7.54'); 1 } };
	croak 'Mojolicious 7.54 required for request_with_p' unless $has_promises;
	return $ua->start_p($self->_build_tx($ua));
}

sub _build_tx {
	my ($self, $ua) = @_;
	return $ua->build_tx($self->method, $self->url, $self->request->headers->to_hash, $self->content);
}

1;

=head1 NAME

WWW::OAuth::Request::Mojo - HTTP Request container for Mojo::Message::Request

=head1 SYNOPSIS

 my $req = WWW::OAuth::Request::Mojo->new(request => $mojo_request);
 my $ua = Mojo::UserAgent->new;
 my $tx = $req->request_with($ua);
 $req->request_with_p($ua)->then(sub {
   my $tx = shift;
 });

=head1 DESCRIPTION

L<WWW::OAuth::Request::Mojo> is a request container for L<WWW::OAuth> that
wraps a L<Mojo::Message::Request> object, which is used by L<Mojo::UserAgent>.
It performs the role L<WWW::OAuth::Request>.

=head1 ATTRIBUTES

L<WWW::OAuth::Request::Mojo> implements the following attributes.

=head2 request

 my $mojo_request = $req->request;
 $req             = $req->request($mojo_request);

L<Mojo::Message::Request> object to authenticate.

=head1 METHODS

L<WWW::OAuth::Request::Mojo> composes all methods from L<WWW::OAuth::Request>,
and implements the following new ones.

=head2 body_pairs

 my $pairs = $req->body_pairs;

Return body parameters from L</"request"> as an even-sized arrayref of keys and
values.

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
 $req       = $req->header(Authorization => 'foo bar');

Set or return a request header from L</"request">.

=head2 method

 my $method = $req->method;
 $req       = $req->method('GET');

Set or return request method from L</"request">.

=head2 query_pairs

 my $pairs = $req->query_pairs;

Return query parameters from L</"request"> as an even-sized arrayref of keys
and values.

=head2 request_with

 my $tx = $req->request_with($ua);
 $req->request_with($ua, sub {
   my ($ua, $tx) = @_;
   ...
 });

Run request with passed L<Mojo::UserAgent> user-agent object, and return
L<Mojo::Transaction> object, as in L<Mojo::UserAgent/"start">. A callback can
be passed to perform the request non-blocking.

=head2 request_with_p

 my $p = $req->request_with_p($ua)->then(sub {
   my $tx = shift;
   ...
 });

Run non-blocking request with passed L<Mojo::UserAgent> user-agent object, and
return a L<Mojo::Promise> which will be resolved with the successful
transaction or rejected on a connection error, as in
L<Mojo::UserAgent/"start_p">.

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

L<Mojo::UserAgent>
