package WebService::PayPal::PaymentsAdvanced::Error::Role::HasHTTPResponse;

use Moo::Role;

our $VERSION = '0.000021';

use Types::Standard qw( InstanceOf Int );
use Types::URI qw( Uri );

has http_status => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has http_response => (
    is       => 'ro',
    isa      => InstanceOf ['HTTP::Response'],
    required => 1,
);

has request_uri => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

1;

=pod

=head1 NAME

WebService::PayPal::PaymentsAdvanced::Error::Role::HasHTTPResponse - Role which provides attributes for an error in an HTTP response.

=head1 VERSION

version 0.000021

=head1 METHODS

The C<< $error->message() >>, and C<< $error->stack_trace() >> methods are
inherited from L<Throwable::Error>.

=head2 http_response

Returns the L<HTTP::Response> object which was returned when attempting to GET
the hosted form.

=head2 http_status

Returns the HTTP status code for the response.

=head2 request_uri

The URI of the request that caused the HTTP error.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
#ABSTRACT: Role which provides attributes for an error in an HTTP response.

