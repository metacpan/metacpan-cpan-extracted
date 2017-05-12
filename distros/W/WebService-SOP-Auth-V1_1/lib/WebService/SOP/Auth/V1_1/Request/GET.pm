package WebService::SOP::Auth::V1_1::Request::GET;
use strict;
use warnings;
use Carp ();
use HTTP::Request::Common qw(GET);
use WebService::SOP::Auth::V1_1::Util qw(create_signature);

sub create_request {
    my ($class, $uri, $params, $app_secret) = @_;

    Carp::croak('Missing required parameter: time') if not $params->{time};
    Carp::croak('Missing app_secret') if not $app_secret;

    $uri->query_form({
        %$params,
        sig => create_signature($params, $app_secret),
    });
    GET $uri;
}

1;

__END__

=encoding utf-8

=head1 NAME

WebService::SOP::Auth::V1_1::Request::GET

=head1 DESCRIPTION

To create a valid L<HTTP::Request> object for given C<GET> request parameters.

=head1 METHODS

=head2 $class->create_request( $uri, $params, $app_secret )

Returns L<HTTP::Request> object for a GET request.
Request parameters including signature are gathered as GET parameters.

=head1 SEE ALSO

L<HTTP::Request>
L<WebService::SOP::Auth::V1_1>

=head1 LICENSE

Copyright (C) dataSpring, Inc.
Copyright (C) Research Panel Asia, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yoko.oyama [ at ] d8aspring.comE<gt>

=cut

