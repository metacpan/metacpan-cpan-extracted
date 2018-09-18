package WWW::OAuth::Request;

use URI;
use WWW::OAuth::Util 'form_urldecode';

use Role::Tiny;

our $VERSION = '1.000';

requires 'method', 'url', 'content', 'content_is_form', 'header', 'request_with';

sub query_pairs { [map { utf8::decode $_; $_ } URI->new(shift->url)->query_form] }

sub body_pairs { form_urldecode shift->content }

1;

=head1 NAME

WWW::OAuth::Request - HTTP Request container role

=head1 SYNOPSIS

  use Role::Tiny::With;
  with 'WWW::OAuth::Request';

=head1 DESCRIPTION

L<WWW::OAuth::Request> is a L<Role::Tiny> role that provides a consistent
interface to L<WWW::OAuth> for parsing and authenticating requests. See
L<WWW::OAuth/"HTTP REQUEST CONTAINERS"> for specifics.

=head1 METHODS

L<WWW::OAuth::Request> implements or requires the following methods.

=head2 body_pairs

 my $pairs = $req->body_pairs;

Return body parameters from C<application/x-www-form-urlencoded> L</"content">
as an even-sized arrayref of keys and values.

=head2 content

 my $content = $req->content;
 $req        = $req->content('foo=1&baz=2');

Set or return request content. Must be implemented to compose role.

=head2 content_is_form

 my $bool = $req->content_is_form;

Check whether content is single-part and content type is
C<application/x-www-form-urlencoded>. Must be implemented to compose role.

=head2 header

 my $header = $req->header('Content-Type');
 $req       = $req->header('Content-Type' => 'application/x-www-form-urlencoded');

Set or return a request header. Multiple values can be set by passing an array
reference as the value, and multi-value headers are joined on C<, > when
returned. Must be implemented to compose role.

=head2 method

 my $method = $req->method;
 $req       = $req->method('GET');

Set or return request method. Must be implemented to compose role.

=head2 query_pairs

 my $pairs = $req->query_pairs;

Return query parameters from L</"url"> as an even-sized arrayref of keys and
values.

=head2 request_with

 my $res = $req->request_with($ua);

Send request using passed user-agent object, and return response. Must be
implemented to compose role.

=head2 url

 my $url = $req->url;
 $req    = $req->url('http://example.com/api/');

Set or return request URL. Must be implemented to compose role.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<HTTP::Request>, L<Mojo::Message::Request>
