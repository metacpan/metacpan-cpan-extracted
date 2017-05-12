# NAME

WebService::TeamCity - Client for the TeamCity REST API

# VERSION

version 0.03

# SYNOPSIS

    use WebService::TeamCity;

    my $client = WebService::TeamCity->new(
        scheme   => 'https',
        host     => 'tc.example.com',
        port     => 8123,
        user     => 'tc-user',
        password => 'tc-password',
    );

    my $projects = $client->projects;
    for my $project ( @{$projects} ) {
        say $project->id;
        for my $build_type ( @{ $project->build_types } ) {
            say $build_type->id;
        }
    }

    my $projects = $client->projects;
    for my $project ( @{$projects} ) {
        ...;
    }

# DESCRIPTION

This distribution provides a client for the TeamCity REST API.

Currently, this client targets the TeamCity 9.1 release exclusively. It is
also quite incomplete and only supports read operations. Pull requests are
very welcome!

The entry point for the API is this module, `WebService::TeamCity`. Once you
have an object of that class, you can use it to get at various other objects
provided by the API.

# INSTABILITY WARNING

This distribution is still in its early days and its API may change without
warning in future releases.

# API

This module provides the top-level client for the API.

## WebService::TeamCity->new(...)

This method takes named parameters to construct a new TeamCity client.

- scheme

    The URL scheme to use. This defaults to `http`.

- host

    The host to connect to. Required.

- port

    The port to connect to. By default, this just uses whatever the scheme
    normally uses.

- user

    The username to use for authentication. Required.

- password

    The password to use for authentication. Required.

- ua

    An instance of [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent). You can pass one in for testing and
    debugging purposes.

## $client->projects(...)

Returns an array reference of [WebService::TeamCity::Entity::Project](https://metacpan.org/pod/WebService::TeamCity::Entity::Project)
objects. This contains all the projects defined on the TeamCity server.

You can pass arguments as key/value pairs to limit the projects returned:

- id => Str

    Only return projects matching this id.

- name => Str

    Only return projects matching this name.

## $client->build\_types

Returns an array reference of [WebService::TeamCity::Entity::BuildType](https://metacpan.org/pod/WebService::TeamCity::Entity::BuildType)
objects. This contains all the build types defined on the TeamCity server.

You can pass arguments as key/value pairs to limit the build types returned:

- affected\_project => { ... }

    Only return build types which affect the specified project. Projects can be
    specified as defined for the `projects` method. This includes sub-projects of
    the specified project.

- id => Str

    Only return build types matching this id.

- name => Str

    Only return build types matching this name.

- paused => Bool

    Only return build types which are or are not paused.

- project => { ... }

    Only return build types which affect the specified project. Projects can be
    specified as defined for the `projects` method. This only includes the
    project itself, not its sub-projects.

- template => { ... }

    Only return build types which use the specified template. The template is
    defined the same way as a build type, but you cannot include a `template` key
    for the template spec too.

- template\_flag => Bool

    Only return build types which are or are not templates.

## $client->builds

Returns a [WebService::TeamCity::Iterator](https://metacpan.org/pod/WebService::TeamCity::Iterator) which returns
[WebService::TeamCity::Entity::Build](https://metacpan.org/pod/WebService::TeamCity::Entity::Build) objects.

You can pass arguments as key/value pairs to limit the projects returned:

- affected\_project => { ... }

    Only return builds which affect the specified project. Projects can be
    specified as defined for the `projects` method. This includes sub-projects of
    the specified project.

- agent\_name => Str

    Only return builds which used the specified agent.

- branch => Str

    Only return builds which were built against the specified branch.

- build\_type => { ... }

    Only return builds which were built using the specific build type. Build types
    can be specified as defined for the `build_types` method.

- canceled => Bool

    Only returns builds which were or were not canceled.

- failed\_to\_start => Bool

    Only returns builds which did or did not fail to start.

- id => Str

    Only return builds matching this id.

- lookup\_limit => Int

    Only search the most recent N builds for a matching build.

- name => Str

    Only return builds matching this name.

- number => Str

    Only return builds matching this number.

- personal => Bool

    Only returns builds which are or are not marked as personal builds.

- pinned => Bool

    Only returns builds which are or are not pinned.

- project => { ... }

    Only return builds which affect the specified project. Projects can be
    specified as defined for the `projects` method. This only includes the
    project itself, not its sub-projects.

- running => Bool

    Only returns builds which are or are not running.

- since\_date => DateTime

    Only returns builds started on or after the specified datetime.

- status => Str

    Only returns builds with the specified status. This can be one of `SUCCESS`,
    `FAILURE`, or `ERROR`.

- tags => \[ ... \]

    Only returns builds which match _all_ of the specified tags. Tags are given
    as strings.

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Dave Rolsky <drolsky@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
