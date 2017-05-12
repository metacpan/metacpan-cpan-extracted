[![Build Status](https://travis-ci.org/tsucchi/p5-WebService-PivotalTracker-Simple.svg?branch=master)](https://travis-ci.org/tsucchi/p5-WebService-PivotalTracker-Simple)
# NAME

WebService::PivotalTracker::Simple - Web API client for PivotalTracker

# SYNOPSIS

    use WebService::PivotalTracker::Simple;
    my $pivotal = WebService::PivotalTracker::Simple->new( token => ... );
    my $project_id = ...;
    my $story_id   = ...;
    my $response = $pivotal->get("/projects/$project_id/stories/$story_id");

# DESCRIPTION

WebService::PivotalTracker::Simple is very thin API client for Pivotal Tracker.

# METHODS

## $instance = $class->new( token => 'your API token' )

create instance

## $response\_href = $self->get($end\_point, $query\_param\_href)

call API using GET request

## $response\_href = $self->post($end\_point, $data\_href)

call API using POST request

## $response\_href = $self->put($end\_point, $data\_href)

call API using PUT request

## $response\_href = $self->delete($end\_point)

call API using DELETE request

# SEE ALSO

[http://www.pivotaltracker.com/help/api/rest/v5](http://www.pivotaltracker.com/help/api/rest/v5), [http://search.cpan.org/dist/WWW-PivotalTracker/](http://search.cpan.org/dist/WWW-PivotalTracker/), [http://search.cpan.org/dist/WebService-PivotalTracker/](http://search.cpan.org/dist/WebService-PivotalTracker/)

# LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takuya Tsuchida <tsucchi@cpan.org>
