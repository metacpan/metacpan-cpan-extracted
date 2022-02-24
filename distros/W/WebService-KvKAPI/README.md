# DESCRIPTION

Query the KvK API via their OpenAPI definition.

# SYNOPSIS

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

# ATTRIBUTES

## api\_key

The KvK API key. You can request one at [https://developers.kvk.nl/](https://developers.kvk.nl/).

## client

An [OpenAPI::Client](https://metacpan.org/pod/OpenAPI%3A%3AClient) object. Build for you.

## api\_host

Optional API host to allow overriding the default host `api.kvk.nl`.

# METHODS

## has\_api\_host

Check if you have an API host set or if you use the default. Publicly available
for those who need it.

## search

See ["search" in WebService::KvKAPI::Search](https://metacpan.org/pod/WebService%3A%3AKvKAPI%3A%3ASearch#search) for more information.

## get\_basic\_profile

See ["get\_basic\_profile" in WebService::KvKAPI::BasicProfile](https://metacpan.org/pod/WebService%3A%3AKvKAPI%3A%3ABasicProfile#get_basic_profile) for more information.

## get\_owner

See ["get\_owner" in WebService::KvKAPI::BasicProfile](https://metacpan.org/pod/WebService%3A%3AKvKAPI%3A%3ABasicProfile#get_owner) for more information.

## get\_main\_location

See ["get\_main\_location" in WebService::KvKAPI::BasicProfile](https://metacpan.org/pod/WebService%3A%3AKvKAPI%3A%3ABasicProfile#get_main_location) for more information.

## get\_locations

See ["get\_locations" in WebService::KvKAPI::BasicProfile](https://metacpan.org/pod/WebService%3A%3AKvKAPI%3A%3ABasicProfile#get_locations) for more information.

## get\_location\_profile

See ["get\_location\_profile" in WebService::KvKAPI::LocationProfile](https://metacpan.org/pod/WebService%3A%3AKvKAPI%3A%3ALocationProfile#get_location_profile) for more information.

# SSL certificates

The KvK now uses private root certificates, please be aware of this. See the
[KvK developer portal](https://developers.kvk.nl) for more information about
this.
