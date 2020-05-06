# NAME

WebService::PivotalTracker - Perl library for the Pivotal Tracker REST API

# VERSION

version 0.12

# SYNOPSIS

    my $pt =  WebService::PivotalTracker->new(
        token => '...',
    );
    my $story = $pt->story( story_id => 1234 );
    my $me = $pt->me;

    for my $label ( $story->labels ) { }

    for my $comment ( $story->comments ) { }

# DESCRIPTION

**This is fairly alpha software. The API is likely to change in breaking ways
in the future.**

This module provides a Perl interface to the [REST API
V5](https://www.pivotaltracker.com/help/api/rest/v5) for [Pivotal
Tracker](https://www.pivotaltracker.com/). You will need to refer to the [REST
API docs](https://www.pivotaltracker.com/help/api/rest/v5) for some details, as
this documentation does not reproduce the details of every attribute available
for a resource.

This class, `WebService::PivotalTracker`, provides the main entry point for
all API calls.

# METHODS

All web requests which return anything other than a success status result in a
call to `die` with a simple string error message. This will probably change
to something more useful in the future.

This class provides the following methods:

## WebService::PivotalTracker->new(...)

This creates a new object of this class. It accepts the following arguments:

- token

    An MD5 access token for Pivotal Tracker. May be provided as a string or
    something that stringifies to the token.

    This is required.

- base\_uri

    The base URI against which all requests will be made. This defaults to
    `https://www.pivotaltracker.com/services/v5`.

## $pt->projects

This method returns an array reference of
[WebService::PivotalTracker::Project](https://metacpan.org/pod/WebService%3A%3APivotalTracker%3A%3AProject) objects, one for each project to which
the token provides access.

## $pt->project\_stories\_where(...)

This method accepts the following arguments:

- story\_id

    The id of the project you are querying.

    This is required.

- filter

    A search filter. This is the same syntax as you would use in the PT
    application for searching. See
    [https://www.pivotaltracker.com/help/articles/advanced\_search/](https://www.pivotaltracker.com/help/articles/advanced_search/) for details.

## $pt->story(...)

This method returns a single [WebService::PivotalTracker::Story](https://metacpan.org/pod/WebService%3A%3APivotalTracker%3A%3AStory) object, if
one exists for the given id.

This method accepts the following arguments:

- story\_id

    The id of the story you are querying.

    This is required.

## $pt->create\_story(...)

This creates a new story. This method accepts every attribute of a
[WebService::PivotalTracker::Story](https://metacpan.org/pod/WebService%3A%3APivotalTracker%3A%3AStory) object. The `project_id` and `name`
parameters are required.

It also accepts two additional optional parameters:

- before\_id

    A story ID before which this story should be added.

- after\_id

    A story ID after which this story should be added.

By default the story will be added as the last story in the icebox.

## $pt->project\_memberships(...)

This looks up memberships in a project. It returns an array reference of
[WebService::PivotalTracker::ProjectMembership](https://metacpan.org/pod/WebService%3A%3APivotalTracker%3A%3AProjectMembership) objects.

It is useful if you need to discover information about a person who is a member
of your project.

The `project_id` parameter is required.

The `sort_by` parameter is optional.

## $pt->me

This returns a [WebService::PivotalTracker::Me](https://metacpan.org/pod/WebService%3A%3APivotalTracker%3A%3AMe) object for the user to which
the token belongs.

# SUPPORT

Bugs may be submitted through [https://github.com/maxmind/WebService-PivotalTracker/issues](https://github.com/maxmind/WebService-PivotalTracker/issues).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Dave Rolsky <drolsky@maxmind.com>
- Florian Ragwitz <rafl@debian.org>
- Greg Oschwald <goschwald@maxmind.com>
- William Storey <wstorey@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 - 2020 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
