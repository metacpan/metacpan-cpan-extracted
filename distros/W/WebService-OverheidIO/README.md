# SYNOPSIS

    package WebService::OverheidIO::Foo;
    use Moose;
    extends 'WebService::OverheidIO';

    # You must implement the following builders:
    # _build_type
    # _build_fieldnames
    # _build_queryfields

# DESCRIPTION

[Overheid.IO](https://overheid.io) is a open data initiative to expose
data the Dutch government exposes via a JSON API. This is a Perl
implemenation for talking to that JSON API.

# ATTRIBUTES

## ua

An [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object

## base\_uri

The base URI of the Overheid.IO, lazy loaded.

## max\_query\_size

The max query size, defaults to 30.

## key

The required Overheid.IO API key.

## type

The type of Overheid.IO api

## fieldnames

The names of the fields which the Overheid.IO will respond with

## queryfields

The names of the fields which will be used to query on

# METHODS

## search

Search OverheidIO by a search term, you can apply additional filters for zipcodes and such

    $overheidio->search(
        "Mintlab",
        filter => {
            postcode => '1051JL',
        }
    );

# SEE ALSO

- [WebService::OverheidIO::KvK](https://metacpan.org/pod/WebService::OverheidIO::KvK)

    Chamber of commerce data

- [WebService::OverheidIO::BAG](https://metacpan.org/pod/WebService::OverheidIO::BAG)

    BAG stands for Basis Administratie Gebouwen. This is basicly a huge
    address table.
