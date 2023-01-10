package WebService::DS::SOP::Auth::V1_1::Request::PUT_JSON;
use strict;
use warnings;
use Carp ();
use JSON::XS qw(encode_json);
use HTTP::Request::Common qw(PUT);
use WebService::DS::SOP::Auth::V1_1::Util qw(create_signature);

sub create_request {
    my ($class, $uri, $params, $app_secret) = @_;

    Carp::croak('Missing required parameter: time') if not $params->{time};
    Carp::croak('Missing app_secret') if not $app_secret;

    my $content = encode_json($params);
    my $sig = create_signature($content, $app_secret);

    my $req = PUT $uri, Content => $content;
    $req->headers->header('content-type' => 'application/json');
    $req->headers->header('x-sop-sig'    => $sig);
    $req;
}

1;

__END__

=encoding utf-8

=head1 NAME

WebService::DS::SOP::Auth::V1_1::Request::PUT_JSON

=head1 DESCRIPTION

To create a valid L<HTTP::Request> object for C<PUT> request with content type C<application/json>.

=head1 FUNCTIONS

=head2 $class->create_request( URI $uri, Hash $params, Str $app_secret ) returns HTTP::Request

Returns L<HTTP::Request> object for a PUT request with content-type C<application/json>,
with signature in header C<X-Sop-Sig>.

=head1 LICENSE

Copyright (C) dataSpring, Inc.
Copyright (C) Research Panel Asia, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yoko.oyama [ at ] d8aspring.comE<gt>

=cut

