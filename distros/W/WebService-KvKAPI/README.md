# DESCRIPTION

Query the KvK API via their OpenAPI definition.

# SYNOPSIS

    use WebService::KvKAPI;
    my $api = WebService::KvKAPI->new(
        api_key => 'foobar',
    );

    $api->search();
    $api->search_all();
    $api->search_max();

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

## api\_call

Directly do an API call towards the KvK API. Returns the JSON datastructure as
an `HashRef`.

## profile

Retreive detailed information of one company. Dies when the company cannot be
found. Make sure to call ["search" in WebService::KvKAPI](https://metacpan.org/pod/WebService%3A%3AKvKAPI#search) first in case you don't
want to die.

## search

Search the KVK, only retrieves the first 10 entries.

    my $results = $self->search(kvkNumber => 12345678, ...);
    foreach (@$results) {
        ...;
    }

## search\_all

Search the KVK, retreives ALL entries. Potentially a very expensive call
(money wise). Don't lookup the Albert Heijn KvK number, do more specific
searches

    my $results = $self->search_all(kvkNumber => 12345678, ...);
    foreach (@$results) {
        ...;
    }

## search\_max

Search the KVK, retreives a maximum of X results up the the nearest 10, eg 15
as a max returns 20 items.

    my $results = $self->search_max(15, kvkNumber => 12345678, ...);
    foreach (@$results) {
        ...;
    }

## mangle\_params

Helper function to always have the correct syntax for the kvkNumber and
branchNumber. Publicly available for if you want to do calls yourself via
["api\_call" in WebService::KvKAPI](https://metacpan.org/pod/WebService%3A%3AKvKAPI#api_call)

# SEE ALSO

The KvK also has test endpoints. While they are supported via the direct
`api_call` method, you can instantiate a model that works only in
spoofmode: [WebService::KvKAPI::Spoof](https://metacpan.org/pod/WebService%3A%3AKvKAPI%3A%3ASpoof)
