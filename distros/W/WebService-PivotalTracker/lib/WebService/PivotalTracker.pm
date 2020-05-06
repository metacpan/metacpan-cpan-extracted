package WebService::PivotalTracker;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.12';

use DateTime::Format::RFC3339;
use Params::ValidationCompiler qw( validation_for );
use Scalar::Util qw( blessed );
use WebService::PivotalTracker::Client;
use WebService::PivotalTracker::Me;
use WebService::PivotalTracker::Project;
use WebService::PivotalTracker::ProjectIteration;
use WebService::PivotalTracker::ProjectMembership;
use WebService::PivotalTracker::Story;
use WebService::PivotalTracker::Types
    qw( ArrayRef ClientObject IterationScope LWPObject MD5Hex NonEmptyStr PositiveInt Uri );

use Moo;

has token => (
    is       => 'ro',
    isa      => MD5Hex,
    required => 1,
);

has base_uri => (
    is      => 'ro',
    isa     => Uri,
    coerce  => 1,
    default => 'https://www.pivotaltracker.com/services/v5',
);

has _ua => (
    is        => 'ro',
    isa       => LWPObject,
    init_arg  => 'ua',
    predicate => '_has_ua',
);

has _client => (
    is      => 'ro',
    isa     => ClientObject,
    lazy    => 1,
    builder => '_build_client',
);

# This is gross. Is there a better way to manage this? This is the only way to
# get the Person who is the requester. There is no person endpoint from which
# to retrieve this information later!
my $StoryFields = do {
    ## no critic (Subroutines::ProtectPrivateSubs)
    my %props = WebService::PivotalTracker::Story->_properties;
    join ',', sort ( keys %props, 'requested_by' );
};

sub projects {
    my $self = shift;

    my $uri = $self->_client->build_uri('/projects');

    return [
        map {
            WebService::PivotalTracker::Project->new(
                raw_content => $_,
                pt_api      => $self,
            )
        } @{ $self->_client->get($uri) }
    ];
}

{
    my $check = validation_for(
        params => {
            project_id => { type => PositiveInt },
            filter     => {
                type     => NonEmptyStr,
                optional => 1
            },
        }
    );

    sub project_stories_where {
        my $self = shift;
        my %args = $check->(@_);

        my $uri = $self->_client->build_uri(
            "/projects/$args{project_id}/stories?",
            {
                %args,
                fields => $StoryFields,
            },
        );

        return [
            map {
                WebService::PivotalTracker::Story->new(
                    raw_content => $_,
                    pt_api      => $self,
                )
            } @{ $self->_client->get($uri) }
        ];
    }
}

{
    my $check = validation_for(
        params => {
            story_id => { type => PositiveInt },
        }
    );

    sub story {
        my $self = shift;
        my %args = $check->(@_);

        my $content = $self->_client->get(
            $self->_client->build_uri(
                "/stories/$args{story_id}",
                { fields => $StoryFields }
            ),
        );
        WebService::PivotalTracker::Story->new(
            raw_content => $content,
            pt_api      => $self,
        );
    }
}

{
    my $check = validation_for(
        params => {
            project_id => { type => PositiveInt },
            sort_by    => {
                type     => NonEmptyStr,    # This could be an enum.
                optional => 1,
            },
        },
    );

    sub project_memberships {
        my $self = shift;
        my %args = $check->(@_);

        my $project_id = delete $args{project_id};
        my $uri        = $self->_client->build_uri(
            "/projects/$project_id/memberships",
            \%args,
        );

        return [
            map {
                WebService::PivotalTracker::ProjectMembership->new(
                    raw_content => $_,
                    pt_api      => $self,
                )
            } @{ $self->_client->get($uri) }
        ];
    }
}

{
    my $check = validation_for(
        params => {
            project_id => { type => PositiveInt },
            label      => {
                type     => NonEmptyStr,
                optional => 1
            },
            limit => {
                type    => PositiveInt,
                default => 1,
            },
            offset => {
                type     => PositiveInt,
                optional => 1,
            },
            scope => {
                type     => IterationScope,
                optional => 1
            },
        },
    );

    sub project_iterations {
        my $self = shift;
        my %args = $check->(@_);

        my $uri = $self->_client->build_uri(
            "/projects/$args{project_id}/iterations",
            \%args,
        );

        return [
            map {
                WebService::PivotalTracker::ProjectIteration->new(
                    raw_content => $_,
                    pt_api      => $self,
                )
            } @{ $self->_client->get($uri) }
        ];
    }
}

# XXX - if we want to add more create_X methods we should find a way to
# streamline & simplify this code so we don't have to repeat this sort of
# boilerplate over and over. Maybe each entity class should provide more
# detail about the properties, including type, coercions (like DateTime ->
# RFC3339 string), required for create/update, etc.
{
    ## no critic (Subroutines::ProtectPrivateSubs)
    my %props  = WebService::PivotalTracker::Story->_properties;
    my %params = map {
        $_ => blessed $props{$_}
            ? { type => $props{$_} }
            : { type => $props{$_}{type} }
    } keys %props;

    my %required = map { $_ => 1 } qw( project_id name );
    $params{$_}{optional} = 1 for grep { !$required{$_} } keys %props;

    %params = (
        %params,
        before_id => {
            type     => PositiveInt,
            optional => 1,
        },
        after_id => {
            type     => PositiveInt,
            optional => 1,
        },
        labels => {
            type     => ArrayRef [NonEmptyStr],
            optional => 1
        },
    );

    my $check = validation_for(
        params => \%params,
    );

    sub create_story {
        my $self = shift;
        my %args = $check->(@_);

        $self->_deflate_datetime_values( \%args );

        my $project_id  = delete $args{project_id};
        my $raw_content = $self->_client->post(
            $self->_client->build_uri("/projects/$project_id/stories"),
            \%args,
        );

        return WebService::PivotalTracker::Story->new(
            raw_content => $raw_content,
            pt_api      => $self,
        );
    }
}

sub me {
    my $self = shift;

    return WebService::PivotalTracker::Me->new(
        raw_content =>
            $self->_client->get( $self->_client->build_uri('/me') ),
        pt_api => $self,
    );
}

sub _build_client {
    my $self = shift;

    return WebService::PivotalTracker::Client->new(
        token    => $self->token,
        base_uri => $self->base_uri,
        ( $self->_has_ua ? ( ua => $self->_ua ) : () ),
    );
}

sub _deflate_datetime_values {
    my $self = shift;
    my $args = shift;

    for my $key ( keys %{$args} ) {
        next unless blessed $args->{$key} && $args->{$key}->isa('DateTime');
        $args->{$key}
            = DateTime::Format::RFC3339->format_datetime( $args->{$key} );
    }

    return;
}

1;

# ABSTRACT: Perl library for the Pivotal Tracker REST API

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::PivotalTracker - Perl library for the Pivotal Tracker REST API

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my $pt =  WebService::PivotalTracker->new(
        token => '...',
    );
    my $story = $pt->story( story_id => 1234 );
    my $me = $pt->me;

    for my $label ( $story->labels ) { }

    for my $comment ( $story->comments ) { }

=head1 DESCRIPTION

B<This is fairly alpha software. The API is likely to change in breaking ways
in the future.>

This module provides a Perl interface to the L<REST API
V5|https://www.pivotaltracker.com/help/api/rest/v5> for L<Pivotal
Tracker|https://www.pivotaltracker.com/>. You will need to refer to the L<REST
API docs|https://www.pivotaltracker.com/help/api/rest/v5> for some details, as
this documentation does not reproduce the details of every attribute available
for a resource.

This class, C<WebService::PivotalTracker>, provides the main entry point for
all API calls.

=for Pod::Coverage project_iterations

=head1 METHODS

All web requests which return anything other than a success status result in a
call to C<die> with a simple string error message. This will probably change
to something more useful in the future.

This class provides the following methods:

=head2 WebService::PivotalTracker->new(...)

This creates a new object of this class. It accepts the following arguments:

=over 4

=item * token

An MD5 access token for Pivotal Tracker. May be provided as a string or
something that stringifies to the token.

This is required.

=item * base_uri

The base URI against which all requests will be made. This defaults to
C<https://www.pivotaltracker.com/services/v5>.

=back

=head2 $pt->projects

This method returns an array reference of
L<WebService::PivotalTracker::Project> objects, one for each project to which
the token provides access.

=head2 $pt->project_stories_where(...)

This method accepts the following arguments:

=over 4

=item * story_id

The id of the project you are querying.

This is required.

=item * filter

A search filter. This is the same syntax as you would use in the PT
application for searching. See
L<https://www.pivotaltracker.com/help/articles/advanced_search/> for details.

=back

=head2 $pt->story(...)

This method returns a single L<WebService::PivotalTracker::Story> object, if
one exists for the given id.

This method accepts the following arguments:

=over 4

=item * story_id

The id of the story you are querying.

This is required.

=back

=head2 $pt->create_story(...)

This creates a new story. This method accepts every attribute of a
L<WebService::PivotalTracker::Story> object. The C<project_id> and C<name>
parameters are required.

It also accepts two additional optional parameters:

=over 4

=item * before_id

A story ID before which this story should be added.

=item * after_id

A story ID after which this story should be added.

=back

By default the story will be added as the last story in the icebox.

=head2 $pt->project_memberships(...)

This looks up memberships in a project. It returns an array reference of
L<WebService::PivotalTracker::ProjectMembership> objects.

It is useful if you need to discover information about a person who is a member
of your project.

The C<project_id> parameter is required.

The C<sort_by> parameter is optional.

=head2 $pt->me

This returns a L<WebService::PivotalTracker::Me> object for the user to which
the token belongs.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-PivotalTracker/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky Florian Ragwitz Greg Oschwald William Storey

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Greg Oschwald <goschwald@maxmind.com>

=item *

William Storey <wstorey@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 - 2020 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
