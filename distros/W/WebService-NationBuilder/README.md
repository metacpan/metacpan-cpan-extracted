# NAME

WebService::NationBuilder

# VERSION

version 0.0107

# SYNOPSIS

```perl
use WebService::NationBuilder;

my $nb = WebService::NationBuilder->new(
    access_token    => 'abc123',
    subdomain       => 'testing',
);

$nb->get_sites();
```

# DESCRIPTION

This module provides bindings for the [NationBuilder](http://www.nationbuilder.com) API.


# METHODS

*  [new](#new)
*  [get\_sites](#get_sites)
*  [get\_people](#get_people)
*  [get\_person](#get_person)
*  [match\_person](#match_person)
*  [create\_person](#create_person)
*  [update\_person](#update_person)
*  [push\_person](#push_person)
*  [delete\_person](#delete_person)
*  [get\_tags](#get_tags)
*  [get\_person\_tags](#get_person_tags)
*  [set\_tag](#set_tag)
*  [delete\_tag](#delete_tag)

## new

```perl
my $nb = WebService::NationBuilder->new(
    access_token    => $access_token,
    subdomain       => $subdomain,
    domain          => $domain,     # optional
    version         => $version,    # optional
    retries         => $retries,    # optional
);
```

Instantiates a new `WebService::NationBuilder` client object.

**Parameters:**

- `'access_token'`

    *Required*  
    A valid NationBuilder OAuth 2.0 access token for your nation.

- `'subdomain'`

    *Required*  
    The NationBuilder subdomain (slug) for your nation.

- `'domain'`

    *Optional*  
    The NationBuilder top-level domain to make API calls against.  
    Defaults to [nationbuilder.com](http://nationbuilder.com).

- `'version'`

    *Optional*  
    The NationBuilder API version to use.  
    Defaults to `v1`.

- `'retries'`

    *Optional*  
    The number of times to retry requests in cases when Balanced returns a 5xx response.  
    Defaults to `0`.

## get\_sites

Get information about the sites hosted by a nation.

**Request:**
```perl
get_sites({
    page        =>  1,
    per_page    =>  10,
});
```

**Response:**
```perl
[{
    id          => 1,
    name        => 'Foobar',
    slug        => 'foobar',
    domain      => 'foobarsoftwares.com',
},
{
    id          => 2,
    name        => 'Test Site',
    slug        => 'test',
    domain      => undef,
}]
```

## get\_people

Get a list of the people in a nation.

**Request:**
```perl
get_people({
    page        => 1,
    per_page    => 10,
});
```

**Response:**
```perl
[{
    id          => 1,
    email       => 'test@gmail.com'
    phone       => '415-123-4567',
    mobile      => '555-123-4567',
    first_name  => 'Firstname',
    last_name   => 'Lastname',
    created_at  => '2013-12-08T04:27:12-08:00',
    updated_at  => '2013-12-24T12:03:51-08:00',
    sex         => undef,
    twitter_id  => '123456789',
    primary_address => {
        address1        => undef,
        address2        => undef,
        zip             => undef,
        city            => 'San Francisco',
        state           => 'CA',
        country_code    => 'US',
        lat             => '37.7749295',
        lng             => '-122.4194155',
    }
}]
```

## get\_person

Get a full representation of the person with the provided `id`.

**Request:**
```perl
get_person(1);
```

**Response:**
```perl
{
    id          => 1,
    email       => 'test@gmail.com'
    phone       => '415-123-4567',
    mobile      => '555-123-4578',
    first_name  => 'Firstname',
    last_name   => 'Lastname',
    created_at  => '2013-12-08T04:27:12-08:00',
    updated_at  => '2013-12-24T12:03:51-08:00',
    sex         => undef,
    twitter_id  => '123456789',
    primary_address => {
        address1        => undef,
        address2        => undef,
        zip             => undef,
        city            => 'San Francisco',
        state           => 'CA',
        country_code    => 'US',
        lat             => '37.7749295',
        lng             => '-122.4194155',
    }
}
```

## match\_person

Get a full representation of the person with certain attributes.

**Request:**
```perl
match_person({
    email       => 'test@gmail.com',
    phone       => '415-123-4567',
    mobile      => '555-123-4567',
    first_name  => 'Firstname',
    last_name   => 'Lastname',
});
```

**Response:**
```perl
{
    id          => 1,
    email       => 'test@gmail.com'
    phone       => '415-123-4567',
    mobile      => '555-123-4578',
    first_name  => 'Firstname',
    last_name   => 'Lastname',
    created_at  => '2013-12-08T04:27:12-08:00',
    updated_at  => '2013-12-24T12:03:51-08:00',
    sex         => undef,
    twitter_id  => '123456789',
    primary_address => {
        address1        => undef,
        address2        => undef,
        zip             => undef,
        city            => 'San Francisco',
        state           => 'CA',
        country_code    => 'US',
        lat             => '37.7749295',
        lng             => '-122.4194155',
    }
}
```

## create\_person

Create a person with the provided data, and return a full representation of the person who was created.

**Request:**
```perl
create_person({
    email       => 'test@gmail.com',
    phone       => '415-123-4567',
    mobile      => '555-123-4567',
    first_name  => 'Firstname',
    last_name   => 'Lastname',
});
```

**Response:**
```perl
{
    id          => 1,
    email       => 'test@gmail.com'
    phone       => '415-123-4567',
    mobile      => '555-123-4578',
    first_name  => 'Firstname',
    last_name   => 'Lastname',
    created_at  => '2013-12-08T04:27:12-08:00',
    updated_at  => '2013-12-24T12:03:51-08:00',
    sex         => undef,
    twitter_id  => undef,
    primary_address => undef,
}
```

## update\_person

Update the person with the provided `id` to have the provided data, and return a full representation of the person who was updated.

**Request:**
```perl
update_person(1, {
    email       => 'test2@gmail.com',
    phone       => '123-456-7890',
    mobile      => '999-876-5432',
    first_name  => 'Firstname2',
    last_name   => 'Lastname2',
});
```

**Response:**
```perl
{
    id          => 1,
    email       => 'test2@gmail.com'
    phone       => '123-456-7890',
    mobile      => '999-876-5432',
    first_name  => 'Firstname2',
    last_name   => 'Lastname2',
    created_at  => '2013-12-08T04:27:12-08:00',
    updated_at  => '2013-12-24T12:03:51-08:00',
    sex         => undef,
    twitter_id  => undef,
    primary_address => undef,
}
```

## push\_person

Update a person matched by email address, or create a new person if no match is found, then return a full representation of the person who was created or updated.

**Request:**
```perl
push_person({
    email       => 'test2@gmail.com',
    sex         => 'M',
    first_name  => 'Firstname3',
    last_name   => 'Lastname3',
});
```

**Response:**
```perl
{
    id          => 1,
    email       => 'test2@gmail.com'
    phone       => '123-456-7890',
    mobile      => '999-876-5432',
    first_name  => 'Firstname3',
    last_name   => 'Lastname3',
    created_at  => '2013-12-08T04:27:12-08:00',
    updated_at  => '2013-12-24T12:03:51-08:00',
    sex         => 'M',
    twitter_id  => undef,
    primary_address => undef,
}
```

## delete\_person

Removes the person with the provided `id` from the nation.

**Request:**
```perl
delete_person(1);
```

**Response:**
```perl
1
```

## get\_tags

Get the tags that have been used before in a nation.

**Request:**
```perl
get_tags({
    page        => 1,
    per_page    => 10,
});
```

**Response:**
```perl
[{
    name    =>  'tag1',
},
{
    name    =>  'tag2',
}]
```

## get\_person\_tags

Gets a list of the tags for a given person with the provided `id`.

**Request:**
```perl
get_person_tags(1);
```

**Response:**
```perl
[{
    person_id   => 1,
    tag         => 'tag1',
},
{
    person_id   => 1,
    tag         => 'tag2',
}]
```

## set\_tag

Associates a tag to a given person with the provided `id`.

**Request:**
```perl
set_tag(1, 'tag3');
```

**Response:**
```perl
{
    person_id   => 1,
    tag         => 'tag3',
}
```

## delete\_tag

Removes a tag from a given person with the provided `id`.

**Request:**
```perl
delete_tag(1, 'tag3');
```

**Response:**
```perl
1
```

# AUTHORS

- Ali Anari <ali@anari.me>

# COPYRIGHT AND LICENSE

This software is copyright © 2014 by Crowdtilt, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
