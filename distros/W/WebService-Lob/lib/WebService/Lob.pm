package WebService::Lob;
$WebService::Lob::VERSION = '0.0107';
use Moo;
with 'WebService::Client';

# VERSION

use aliased 'WebService::Lob::Exception::AddressNotFound';
use aliased 'WebService::Lob::Exception::AddressMissingInformation';

use Method::Signatures;

has '+base_url'   => ( default => 'https://api.lob.com/v1' );
has api_key       => ( is => 'ro', required => 1           );
has states_uri    => ( is => 'ro', default => '/states'    );
has countries_uri => ( is => 'ro', default => '/countries' );
has verify_uri    => ( is => 'ro', default => '/verify'    );

method BUILD(...) {
    $self->ua->credentials('api.lob.com:443', '', $self->api_key, '');
}

method get_states {
    my $result = $self->get($self->states_uri);
    return $result->{data} if $result;
}

method get_countries {
    my $result = $self->get($self->countries_uri);
    return $result->{data} if $result;
}

method verify_address(
    Str :$address_line1,
    Str :$address_line2 = '',
    Str :$address_city,
    Str :$address_state,
    Str :$address_zip,
    Str :$address_country
) {
    my $result = $self->post($self->verify_uri, {
        address_line1   => $address_line1,
        address_line2   => $address_line2,
        address_city    => $address_city,
        address_state   => $address_state,
        address_zip     => $address_zip,
        address_country => $address_country,
    });

    AddressNotFound->throw unless $result;
    AddressMissingInformation->throw( message => $result->{message} )
        if $result->{message};
    return $result->{address};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Lob

=head1 VERSION

version 0.0107

=head1 SYNOPSIS

    use WebService::Lob;

    my $lob = WebService::Lob->new( api_key => 'abc123' );

    $lob->get_countries();

=head1 DESCRIPTION

This module provides bindings for the
L<Lob|https://www.lob.com/docs> API.

=for markdown [![Build Status](https://travis-ci.org/aanari/WebService-Lob.svg?branch=master)](https://travis-ci.org/aanari/WebService-Lob)

=head1 METHODS

=head2 new

Instantiates a new WebService::Lob client object.

    my $lob = WebService::Lob->new(
        api_key  => $api_key,
        base_url => $domain,     # optional
        timeout  => $retries,    # optional
        retries  => $retries,    # optional
    );

B<Parameters>

=over 4

=item - C<api_key>

I<Required>E<10> E<8>

A valid Lob api key for your account.

=item - C<base_url>

I<Optional>E<10> E<8>

The Lob base url to make API calls against.  Defaults to L<https://api.lob.com|https://api.lob.com>.

=item - C<timeout>

I<Optional>E<10> E<8>

The number of seconds to wait per request until timing out.  Defaults to C<10>.

=item - C<retries>

I<Optional>E<10> E<8>

The number of times to retry requests in cases when Lob returns a 5xx response.  Defaults to C<0>.

=back

=head2 get_states

Returns a list of all US states.

B<Request:>

    get_states();

B<Response:>

    [{
        name       => 'Alabama',
        short_name => 'AL',
        object     => 'state',
    },
    {
        name       => 'Alaska',
        short_name => 'AK',
        object     => 'state',
    },
    ...
    {
        name       => 'Wisconsin',
        short_name => 'WI',
        object     => 'state',
    },
    {
        name       => 'Wyoming',
        short_name => 'WY',
        object     => 'state',
    }]

=head2 get_countries

Returns a list of all currently supported countries.

B<Request:>

    get_countries();

B<Response:>

    [{
        name       => 'United States',
        short_name => 'US',
        object     => 'country',
    },
    {
        name       => 'Afghanistan',
        short_name => 'AF',
        object     => 'country',
    },
    ...
    {
        name       => 'Zambia',
        short_name => 'ZM',
        object     => 'country',
    },
    {
        name       => 'Zimbabwe',
        short_name => 'ZW',
        object     => 'country',
    }]

=head2 verify_address

Validates an address given.

B<Request:>

    verify_address(
        address_line1   => '370 Townsend St',
        address_city    => 'San Francisco',
        address_state   => 'CA',
        address_zip     => '94107',
        address_country => 'US',
    );

B<Response:>

    {
        object          => 'address',
        address_line1   => '370 TOWNSEND ST',
        address_line2   => '',
        address_city    => 'SAN FRANCISCO',
        address_state   => 'CA',
        address_zip     => '94107-1607',
        address_country => 'US',
    }

B<Exceptions:>

=over 4

=item - C<WebService::Lob::Exception::AddressNotFound>

Address Not Found.

=item - C<WebService::Lob::Exception::AddressMissingInformation>

The address you entered was found but more information is needed to match to a specific address.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/aanari/WebService-Lob/issues

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
