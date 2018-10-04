package Twitter::API::Context;
# ABSTRACT: Encapsulated state for a request/response
$Twitter::API::Context::VERSION = '1.0005';
use Moo;
use namespace::clean;

has [ qw/http_method args headers extra_args/ ] => (
    is => 'ro',
);

for my $attr ( qw/url result http_response http_request/ ) {
    has $attr => (
        writer => "set_$attr",
        is     => 'ro',
    );
}

has options => (
    is      => 'ro',
    default => sub { {} },
);

sub get_option { $_[0]->options->{$_[1]}         }
sub has_option { exists $_[0]->options->{$_[1]}  }
sub set_option { $_[0]->options->{$_[1]} = $_[2] }
sub delete_option { delete $_[0]->options->{$_[1]} }

# private method
my $limit = sub {
    my ( $self, $which ) = @_;

    my $res = $self->http_response;
    $res->header("X-Rate-Limit-$which");
};

sub rate_limit           { shift->$limit('Limit') }
sub rate_limit_remaining { shift->$limit('Remaining') }
sub rate_limit_reset     { shift->$limit('Reset') }

sub set_header {
    my ( $self, $header, $value ) = @_;

    $self->headers->{$header} = $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Twitter::API::Context - Encapsulated state for a request/response

=head1 VERSION

version 1.0005

=head1 SYNOPSIS

    my ( $r, $c ) = $client->verify_credentials;

    say sprintf '%d verify_credentials calls remaining unitl %s',
        $c->rate_limit_remaining,
        scalar localtime $c->rate_limit_reset;

    # output:
    74 verify_credentials_calls remaining until Sat Dec  3 22:05:41 2016

=head1 DESCRIPTION

The state for every API call is stored in a context object. It is automatically
created when a request is initiated and is returned to the caller as the second
value in list context. The context includes the L<HTTP::Request> and
L<HTTP::Response> objects, a reference to the API return data, and accessor for
rate limit information.

A reference to the context is also included in a L<Twitter::API::Error>
exception.

=head1 METHODS

=head2 http_request

Returns the L<HTTP::Request> object for the API call.

=head2 http_response

Returns the L<HTTP::Response> object for the API call.

=head2 result

Returns the result data for the API call.

=head2 rate_limit

Every API endpoint has a rate limit. This method returns the rate limit for the
endpoint of the API call. See
L<https://developer.twitter.com/en/docs/basics/rate-limiting> for details.

=head2 rate_limit_remaining

Returns the number of API calls remaining for the endpoint in the current rate limit window.

=head2 rate_limit_reset

Returns the time of the next rate limit window in UTC epoch seconds.

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2018 by Marc Mims.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
