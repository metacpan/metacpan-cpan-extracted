package WebService::SmartyStreets;
$WebService::SmartyStreets::VERSION = '0.0105';
use Moo;
with 'WebService::Client';

# VERSION

use aliased 'WebService::SmartyStreets::Exception::AddressNotFound';
use aliased 'WebService::SmartyStreets::Exception::AddressMissingInformation';

use Method::Signatures;
use URI;

has auth_id    => ( is => 'ro', required => 1 );
has auth_token => ( is => 'ro', required => 1 );

has '+base_url' => (
    default => sub {
        my $self = shift;
        my $uri = URI->new('https://api.smartystreets.com/street-address');
        $uri->query_form(
            'auth-id'    => $self->auth_id,
            'auth-token' => $self->auth_token,
        );
        return $uri->as_string;
    },
);

method verify_address(
    Str :$street!,
    Str :$street2 = '',
    Str :$city!,
    Str :$state!,
    Str :$zipcode = '',
    Int :$candidates = 2
) {
    my $results = $self->post($self->base_url, [{
        street     => $street,
        street2    => $street2,
        city       => $city,
        state      => $state,
        zipcode    => $zipcode,
        candidates => $candidates,
    }]);

    AddressNotFound->throw unless $results and @$results;
    AddressMissingInformation->throw if @$results == 1
        and $results->[0]{analysis}{dpv_match_code} eq 'D';

    return [
        map {{
            street  => $_->{delivery_line_1},
            (street2 => $_->{delivery_line_2}) x!! $_->{delivery_line_2},
            city    => $_->{components}{city_name},
            state   => $_->{components}{state_abbreviation},
            zipcode => $_->{components}{zipcode} . '-' . $_->{components}{plus4_code},
        }} @$results
    ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::SmartyStreets

=head1 VERSION

version 0.0105

=head1 SYNOPSIS

    use WebService::SmartyStreets;

    my $ss = WebService::SmartyStreets->new(
        auth_id     => 'abc123',
        auth_token  => 'zyx456',
    );

    $ss->verify_address(...);

=head1 DESCRIPTION

This module provides bindings for the
L<SmartyStreets|http://smartystreets.com/products/liveaddress-api> API.

=for markdown [![Build Status](https://travis-ci.org/aanari/WebService-SmartyStreets.svg?branch=master)](https://travis-ci.org/aanari/WebService-SmartyStreets)

=head1 METHODS

=head2 new

Instantiates a new WebService::SmartyStreets client object.

    my $ss = WebService::SmartyStreets->new(
        auth_id    => $auth_id,
        auth_token => $auth_token,
        timeout    => $retries,    # optional
        retries    => $retries,    # optional
    );

B<Parameters>

=over 4

=item - C<auth_id>

I<Required>E<10> E<8>

A valid SmartyStreets auth id for your account.

=item - C<auth_token>

I<Required>E<10> E<8>

A valid SmartyStreets auth token for your account.

=item - C<timeout>

I<Optional>E<10> E<8>

The number of seconds to wait per request until timing out.  Defaults to C<10>.

=item - C<retries>

I<Optional>E<10> E<8>

The number of times to retry requests in cases when SmartyStreets returns a 5xx response.  Defaults to C<0>.

=back

=head2 verify_address

Validates an address given.

B<Request:>

    verify_address(
        street  => '370 Townsend St',
        city    => 'San Francisco',
        state   => 'CA',
        zipcode => '94107',
    );

B<Response:>

    [{
        street   => '370 Townsend St',
        city     => 'San Francisco',
        state    => 'CA',
        zipcode  => '94107-1607',
    }]

B<Exceptions:>

=over 4

=item - C<WebService::SmartyStreets::Exception::AddressNotFound>

Address Not Found.

=item - C<WebService::SmartyStreets::Exception::AddressMissingInformation>

The address you entered was found but more information is needed to match to a specific address.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/WebService-SmartyStreets/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 CONTRIBUTOR

=for stopwords Naveed Massjouni

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ali Anari.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
