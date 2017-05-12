# NAME

WebService::PivotalTracker - Perl library for the Pivotal Tracker REST API

# VERSION

version 0.07

# SYNOPSIS

    my $pt =  WebService::PivotalTracker->new(
        token => '...',
    );
    my $story = $pt->story( story_id => 1234 );
    my $me = $pt->me;

    for my $label ( $story->labels ) { ... }

    for my $comment ( $story->comments ) { ... }

# DESCRIPTION

**This is very alpha (and as of yet mostly undocumented) software**.

This module provides a Perl interface to the [Pivotal
Tracker](https://www.pivotaltracker.com/) REST API.

# SUPPORT

Bugs may be submitted through [https://github.com/maxmind/WebService-PivotalTracker/issues](https://github.com/maxmind/WebService-PivotalTracker/issues).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Dave Rolsky <drolsky@maxmind.com>
- Florian Ragwitz <rafl@debian.org>
- Greg Oschwald <goschwald@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
