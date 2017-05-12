# NAME

WWW::JSON - Make working with JSON Web API's as painless as possible

# SYNOPSIS

    use WWW::JSON;

    my $wj = WWW::JSON->new(
        base_url => 'http://api.metacpan.org/v0?fields=name,distribution&size=1',
        post_body_format           => 'JSON',
        default_response_transform => sub { shift->{hits}{hits}[0]{fields} },
    );

    my $get = $wj->get(
        '/release/_search',
        {
            q      => 'author:ANTIPASTA',
            filter => 'status:latest',
        }
    );

    warn "DISTRIBUTION: " . $get->res->{distribution} if $get->success;

# DESCRIPTION

WWW::JSON is an easy interface to any modern web API that returns JSON.

It tries to make working with these API's as intuitive as possible.

# ABSTRACT

When using abstracted web API libraries I often ran into issues where bugs in the library interfere with proper api interactions, or features  are added to the API that the library doesn't support.

In these cases the additional abstraction winds up making life more difficult.

Abstracted libraries do offer benefits.

    -Auth is taken care of for you.
    -Cuts out boilerplate
    -Don't have to think about HTTP status, JSON, or parameter serialization

I wanted just enough abstraction to get the above benefits, but no more.

Thus, WWW::JSON was born. Perl + Web + JSON - tears

## FEATURES

\-Light on dependencies

\-Don't repeat yourself

    -Set a url that all requests will be relative to
    -Set query params included on all requests
    -Set body params included on all requests that contain a POST body
    -URL paths support primitive templating
    -Transform the response of all API requests. Useful if an API returns data in a silly structure.

\-Work with APIs that require different parameter serialization

    - Serialized post bodys (Facebook, Foursquare)
    - JSON-ified post bodys (Github, Google+)

\-Role-based Authentication

    -Basic
    -OAuth 1.0a
    -OAuth2
    -New roles can easily be created for other auth schemes

\-Avoids boilerplate

    -Don't have to worry about going from JSON => perl and back
    -Handles HTTP and JSON decode errors gracefully

\-Templating
    Can put templates in url paths

    Use template toolkit style brackets in url. Populate a template variable in the second parameter's
    hashref by prefixing it with a dash(-). Example:
        $wj->get('/users/[% user_id %]/status, { page => 3, -user_id => 456 });

# PARAMETERS

## base\_url

The root url that all requests will be relative to.

Any query parameters included in the base\_url will be added to every request made to the api

Alternatively, an array ref consisting of the base\_url and a hashref of query parameters can be passed like so:

base\_url => \[ 'http://google.com', { key1 => 'val1', key2 => 'val2'} \]

## body\_params

Parameters that will be added to every non-GET request made by WWW::JSON.

## post\_body\_format

How to serialize the post body.

'serialized' - Normal post body serialization (this is the default)

'JSON' - JSONify the post body. Used by API's like github and google plus

## default\_response\_transform

Many API's have a lot of boilerplate around their json responses.

For example lets say every request's meaningful payload is included inside the first array index of a hash key called 'data'.

Instead of having to do $res->{data}->\[0\]->{key1}, you can specify default\_response\_transform as sub { shift->{data}->\[0\] } 

Then in your responses you can get at key1 directly by just doing $res->{key1}

NOTE: This transform only occurs if no HTTP errors or decoding errors occurred. If we get back an HTTP error status it seems more useful to get back the entire decoded JSON blob

## authentication

Accepts a single key value pair, where the key is the name of a WWW::JSON::Role::Authentication role and the value is a hashref containing the data the role needs to perform the authentication.

Supported authentication schemes:

OAuth1 => {
    consumer\_key    => 'somekey',
    consumer\_secret => 'somesecret',
    token           => 'sometoken',
    token\_secret    => 'sometokensecret'
  }

Basic => { username => 'antipasta', password => 'hunter2' }

OAuth2 => Net::OAuth2::AccessToken->new( ... )

New roles can be created to support different types of authentication. Documentation on this will be fleshed out at a later time.

## ua\_options

Options that can be passed when initializing the useragent. For example { timeout => 5 }. See LWP::UserAgent for possibilities.

# METHODS

## get

$wj->get($path,$params)

Performs a GET request to the relative path $path. $params is a hashref of url query parameters.

## post

$wj->post($path,$params)

Performs a POST request. $params is a hashref of parameters to be passed to the post body

## put

$wj->put($path,$params)

Performs a PUT request. $params is a hashref of parameters to be passed to the post body

## delete

$wj->delete($path,$params)

Performs a DELETE request. $params is a hashref of parameters to be passed to the post body

## req

$wj->req($method,$path,$params)

Performs an HTTP request of type $method. $params is a hashref of parameters to be passed to the post body

## body\_param

Add/Update a single body param

# LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Joe Papperello <antipasta@cpan.org>

# SEE ALSO

\-Net::OAuth2 - For making OAuth2 signed requests with WWW::JSON

\-App::Adenosine - Using this on the command line definitely served as some inspiration for WWW::JSON.

\-Net::HTTP::Spore - I found this while researching other modules in this space. It's still a bit abstracted from the actual web request for my taste, but it's obvious the author created it out of some of the same above frustrations and it looks useful.
