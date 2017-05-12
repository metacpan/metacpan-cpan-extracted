package WebAPI::HTTP::Throwable::Role::JSONBody;
$WebAPI::HTTP::Throwable::Role::JSONBody::VERSION = '0.004002';
use Moo::Role;

sub body { return shift->message }

sub body_headers {
    my ($self, $body) = @_;

    return [
        'Content-Type'   => 'application/json',
        'Content-Length' => length $body,
    ];
}

sub as_string { return shift->body }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::HTTP::Throwable::Role::JSONBody

=head1 VERSION

version 0.004002

=head1 OVERVIEW

When an HTTP::Throwable exception uses this role, its PSGI response
will have a C<application/json> content type and will send the
C<message> attribute as the response body.  C<message> should be a
valid JSON string.

=head1 NAME

WebAPI::HTTP::Throwable::Role::JSONBody - an exception with a JSON body

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
