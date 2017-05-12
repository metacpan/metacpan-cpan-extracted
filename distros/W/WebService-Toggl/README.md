# NAME

WebService::Toggl - Wrapper for the toggl.com task logging API

# SYNOPSIS

    use WebService::Toggl;

    my $toggl = WebService::Toggl->new({api_key => $ENV{API_KEY}});
    my $me = $toggl->me();
    say "Me: " . $me->fullname . " <" . $me->email . ">:";

    say "My Workspaces:";
    for my $ws ($me->workspaces->all) {
        say "  " . $ws->name . " (" . $ws->id . ")";
        say "    Projects:";
        say "      " . $_->name . " (" . $_->id . ") " for ($ws->projects->all);
    }

# DESCRIPTION

**NB: This is a new module, and the API is still under development.
While I'm pretty happy with the current interface, expect the
internals to be heavily refactored before v1.0.  This version
currently only supports read access to the API, but I plan to add
write access in the near future.**

[WebService::Toggl](https://metacpan.org/pod/WebService::Toggl) is a perl interface to the
[Toggl](http://www.toggl.com) API, as described at
[https://github.com/toggl/toggl\_api\_docs](https://github.com/toggl/toggl_api_docs).  When a new
`WebService::Toggl` object is created, it is associated with a
particulars user's credentials via their API token.  The API token can
be found at the bottom of your 'My Profile' on Toggl.  Any new objects
created by the `WebService::Toggl` object will inherit its credentials.

## Laziness

All `Webservice::Toggl::API::` and `WebService::Toggl::Report::`
objects are created lazily.  If you ask for a particular
`::API::Workspace` object by id, no GET request against the Toggl API
will be issued until you request an attribute that has not yet been set. E.g.

    my $workspace = $toggl->workspace(1234);
    say $workspace->id;  # prints 1234, no GET yet issued
    say $workspace->name; # name is not yet set, will issue GET request

## Raw data

Each `API::` and `Report::` object stores the raw response received
from Toggl in an attribute called `raw`.  If you want to force the
object to fill itself in with data from the API, calling
`$object->raw()` will do so.

## Set objects

Each `API::` class has a corresponding class that represents a set of
the objects.  These set objects store the raw response query and will
return a list of the objects it comprises via the `->all()`
method.

## Additional queries

You can make other requests against the Toggle API via the
`api_{get,post,put,delete}()` methods provided by
[WebService::Toggl::Role::Base](https://metacpan.org/pod/WebService::Toggl::Role::Base).  For instance, if you had a
[WebService::Toggl::API::Tag](https://metacpan.org/pod/WebService::Toggl::API::Tag) object that you wanted to delete, you
could write:

    $tag->api_delete( $tag->my_url );

# METHODS

## API objects

### me()

Returns the [WebService::Toggl::API::Me](https://metacpan.org/pod/WebService::Toggl::API::Me) object representing the
authorized user.

### workspace($id)

Returns the [WebService::Toggl::API::Workspace](https://metacpan.org/pod/WebService::Toggl::API::Workspace) object with the given id.

### workspace\_user( $id )

Returns the [WebService::Toggl::API::WorkspaceUser](https://metacpan.org/pod/WebService::Toggl::API::WorkspaceUser) object with the given id.

### client( $id )

Returns the [WebService::Toggl::API::Client](https://metacpan.org/pod/WebService::Toggl::API::Client) object with the given id.

### project( $id )

Returns the [WebService::Toggl::API::Project](https://metacpan.org/pod/WebService::Toggl::API::Project) object with the given id.

### project\_user( $id )

Returns the [WebService::Toggl::API::ProjectUser](https://metacpan.org/pod/WebService::Toggl::API::ProjectUser) object with the given id.

### tag( $id )

Returns the [WebService::Toggl::API::Tag](https://metacpan.org/pod/WebService::Toggl::API::Tag) object with the given id.

### task( $id )

Returns the [WebService::Toggl::API::Task](https://metacpan.org/pod/WebService::Toggl::API::Task) object with the given id.

### time\_entry( $id )

Returns the [WebService::Toggl::API::TimeEntry](https://metacpan.org/pod/WebService::Toggl::API::TimeEntry) object with the given id.

### user( $id )

Returns the [WebService::Toggl::API::User](https://metacpan.org/pod/WebService::Toggl::API::User) object with the given id.

## Reports

### details( $args )

Returns the [WebService::Toggl::Report::Details](https://metacpan.org/pod/WebService::Toggl::Report::Details) object with the
given arguments.

### summary( $args )

Returns the [WebService::Toggl::Report::Summary](https://metacpan.org/pod/WebService::Toggl::Report::Summary) object with the
given arguments.

### weekly( $args )

Returns the [WebService::Toggl::Report::Weekly](https://metacpan.org/pod/WebService::Toggl::Report::Weekly) object with the given
arguments.

# LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Fitz Elliott <felliott@fiskur.org>
