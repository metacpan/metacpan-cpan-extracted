[![Build Status](https://travis-ci.org/kianmeng/webservice-swapi.svg?branch=master)](https://travis-ci.org/kianmeng/webservice-swapi)
# NAME

Webservice::Swapi - A Perl module to interface with the Star Wars API
(swapi.co) webservice.

# SYNOPSIS

    use Webservice::Swapi;

    $swapi = Webservice::Swapi->new;

    # Get information of all available resources
    my $resources = $swapi->resources();

    # View the JSON schema for people resource
    my $schema = $swapi->schema('people');

    # Searching
    my $results = $swapi->search('people', 'solo');

    # Get resource item
    my $item = $swapi->get_object('films', '1');

# DESCRIPTION

Webservice::Swapi is a Perl client helper library for the Star Wars API (swapi.co).

# DEVELOPMENT

Source repo at [https://github.com/kianmeng/webservice-swapi](https://github.com/kianmeng/webservice-swapi).

If you have Docker installed, you can build your Docker container for this
project.

    $ docker build -t webservice-swapi-0.1.0 .
    $ docker run -it -v $(pwd):/root webservice-swapi-0.1.0 bash

To setup the development environment and run the test using Carton.

    $ carton install
    $ export PERL5LIB=$(pwd)/local/lib/perl5/

To enable Perl::Critic test cases, enable the flag.

    $ TEST_CRITIC=1 carton exec -- prove -Ilib -lv t

To use Minilla instead. This will update the README.md file from the source.

    $ cpanm Minilla
    $ minil build
    $ minil test
    $ FAKE_RELEASE=1 minil release # testing
    $ minil release # actual

# LICENSE

Copyright 2017 (C) Kian-Meng, Ang.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kian-Meng, Ang <kianmeng@users.noreply.github.com>
