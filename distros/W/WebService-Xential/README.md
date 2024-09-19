# methods

## new()

    my $xential = WebService::Xential->new(
      api_user => 'foo',
      api_key => 'foo',
      api_host => '127.0.0.1',
    );

## has\_api\_host()

Tells you if you have a custom API host defined

## whoami($session\_id)

Implements the whoami call from Xential

## logout($session\_id)

Implements the logout call from Xential

## impersonate($username, $user\_uuid, $session\_id)

Implements the impersonate call from Xential

## create\_ticket($xml, $options, $session\_id)

Implements the create\_ticket call from Xential

## start\_document($username, $user\_uuid, $session\_id)

Implements the start\_document call from Xential

## build\_document($username, $user\_uuid, $session\_id)

Implements the build\_document call from Xential

## api\_call($operation, $query, $content)

A wrapper around the [OpenAPI::Client::call](https://metacpan.org/pod/OpenAPI%3A%3AClient%3A%3Acall) function. Returns the JSON from
the endpoint.

# DESCRIPTION

# SYNOPSIS

# ATTRIBUTES

# METHODS
