package WebService::Client::Response;
use Moo;

our $VERSION = '1.0001'; # VERSION

use JSON::MaybeXS ();

has res => (
    is => 'ro',
    isa => sub {
        die 'res must be a HTTP::Response object'
            unless shift->isa('HTTP::Response');
    },
    required => 1,
    handles => [qw(
        code
        content
        decoded_content
        is_error
        is_success
        status_line
    )],
);

has json => (
    is      => 'ro',
    lazy    => 1,
    default => sub { JSON::MaybeXS->new() },
);

sub data {
    my ($self) = @_;
    return $self->json->decode($self->decoded_content);
}

sub ok {
    my ($self) = @_;
    return $self->is_success;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Client::Response

=head1 VERSION

version 1.0001

=head1 AUTHOR

Naveed Massjouni <naveed@vt.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
