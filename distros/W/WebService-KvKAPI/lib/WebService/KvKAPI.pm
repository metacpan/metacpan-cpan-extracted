use utf8;
package WebService::KvKAPI;

our $VERSION = '0.101';

# ABSTRACT: Query the Dutch Chamber of Commerence (KvK) API
#
# This code has an EUPL license. Please see the LICENSE file in this repo for
# more information.

use v5.26;
use Object::Pad;

class WebService::KvKAPI;
use WebService::KvKAPI::Search;
use WebService::KvKAPI::BasicProfile;
use WebService::KvKAPI::LocationProfile;

has $api_key   :param = undef;
has $api_host  :param :accessor = undef;
has $spoof     :param = 0;

# We need https://rt.cpan.org/Public/Bug/Display.html?id=140712 for delegation
has $basic_profile;
has $location_profile;
has $search;

ADJUST {
    $search = WebService::KvKAPI::Search->new(
        api_key => $api_key,
        spoof   => $spoof,
        $self->has_api_host ? (api_host => $api_host) : (),
    );
    $location_profile = WebService::KvKAPI::LocationProfile->new(
        api_key => $api_key,
        spoof   => $spoof,
        $self->has_api_host ? (api_host => $api_host) : (),
    );
    $basic_profile = WebService::KvKAPI::BasicProfile->new(
        api_key => $api_key,
        spoof   => $spoof,
        $self->has_api_host ? (api_host => $api_host) : (),
    );

}

method has_api_host {
    return $api_host ? 1 : 0;
}

method search {
    return $search->search(@_);
}

method get_location_profile {
    return $location_profile->get_location_profile(@_);
}

method get_basic_profile {
    return $basic_profile->get_basic_profile(@_);

}

method get_owner {
    return $basic_profile->get_owner(@_);
}

method get_main_location {
    return $basic_profile->get_main_location(@_);
}

method get_locations {
    return $basic_profile->get_locations(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::KvKAPI - Query the Dutch Chamber of Commerence (KvK) API

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WebService::KvKAPI;
    my $api = WebService::KvKAPI->new(
        api_key => 'foobar',
        # optional
        api_host => 'foo.bar', # send the request to a different host
        spoof => 1, # enable spoof mode, uses the test api of the KvK

    );

    $api->search(%args);
    $api->get_location_profile($location_number);
    $api->get_basic_profile($kvk_number);
    $api->get_owner($kvk_number);
    $api->get_main_location($kvk_number);
    $api->get_locations($kvk_number);

=head1 DESCRIPTION

Query the KvK API via their OpenAPI definition.

=head1 ATTRIBUTES

=head2 api_key

The KvK API key. You can request one at L<https://developers.kvk.nl/>.

=head2 client

An L<OpenAPI::Client> object. Build for you.

=head2 api_host

Optional API host to allow overriding the default host C<api.kvk.nl>.

=head1 METHODS

=head2 has_api_host

Check if you have an API host set or if you use the default. Publicly available
for those who need it.

=head2 search

See L<WebService::KvKAPI::Search/search> for more information.

=head2 get_basic_profile

See L<WebService::KvKAPI::BasicProfile/get_basic_profile> for more information.

=head2 get_owner

See L<WebService::KvKAPI::BasicProfile/get_owner> for more information.

=head2 get_main_location

See L<WebService::KvKAPI::BasicProfile/get_main_location> for more information.

=head2 get_locations

See L<WebService::KvKAPI::BasicProfile/get_locations> for more information.

=head2 get_location_profile

See L<WebService::KvKAPI::LocationProfile/get_location_profile> for more information.

=head1 SSL certificates

The KvK now uses private root certificates, please be aware of this. See the
L<KvK developer portal|https://developers.kvk.nl> for more information about
this.

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
