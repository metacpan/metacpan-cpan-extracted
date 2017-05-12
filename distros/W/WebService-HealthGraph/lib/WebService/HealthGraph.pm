use strict;
use warnings;
package WebService::HealthGraph;
$WebService::HealthGraph::VERSION = '0.000004';
use Moo;

use LWP::UserAgent ();
use Types::Standard qw( Bool HashRef InstanceOf Int Str );
use Types::URI qw( Uri );
use URI ();
use URI::FromHash qw( uri );
use WebService::HealthGraph::Response ();

has auto_pagination => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has base_url => (
    is      => 'ro',
    isa     => Uri,
    lazy    => 1,
    default => 'https://api.runkeeper.com',
    coerce  => 1,
);

has debug => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has token => (
    is        => 'ro',
    isa       => Str,
    predicate => '_has_token',
);

has ua => (
    is      => 'ro',
    isa     => InstanceOf ['LWP::UserAgent'],
    lazy    => 1,
    builder => '_build_ua',
);

has url_map => (
    is      => 'ro',
    isa     => HashRef,
    lazy    => 1,
    builder => '_build_url_map',
);

has user => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::HealthGraph::Response'],
    lazy    => 1,
    builder => '_build_user',
);

has user_id => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    default => sub { shift->user->content->{userID} },
);

sub _build_ua {
    my $self = shift;
    my $ua   = LWP::UserAgent->new;
    if ( $self->_has_token ) {
        $ua->default_header( Authorization => 'Bearer ' . $self->token );
    }

    return $ua unless $self->debug;
    require LWP::ConsoleLogger::Easy;
    LWP::ConsoleLogger::Easy::debug_ua($ua);
    return $ua;
}

sub _build_url_map {
    my $self = shift;
    my %map  = %{ $self->user->content };
    delete $map{userID};
    return \%map;
}

sub _build_user {
    my $self = shift;
    return $self->get('/user');
}

sub get {
    my $self    = shift;
    my $url     = shift;
    my $args    = shift;
    my $headers = $args->{headers} || {};
    my $feed    = $args->{feed} || 0;

    $url = URI->new($url) unless ref $url;

    my $path = $url->path;

    $url->scheme( $self->base_url->scheme );
    $url->host( $self->base_url->host );

    my @path_parts = $url->path_segments;
    shift @path_parts;    # first part is empty string with an absolute URL
    my $top_level = shift @path_parts;

    my %type = (
        backgroundActivities       => 'BackgroundActivitySet',
        changeLog                  => 'ChangeLog',
        diabetes                   => 'DiabetesMeasurementSet',
        fitnessActivities          => 'FitnessActivity',
        generalMeasurements        => 'GeneralMeasurementSet',
        nutrition                  => 'NutritionSet',
        profile                    => 'Profile',
        records                    => 'Records',
        settings                   => 'Settings',
        sleep                      => 'SleepSet',
        strengthTrainingActivities => 'StrengthTrainingActivity',
        team                       => 'Team',
        user                       => 'User',
        weight                     => 'WeightSet',
    );

    unless ( exists $headers->{Accept} ) {
        my $accept = $type{$top_level};

        # Weird exception to the rule
        if ( @path_parts and $top_level eq 'team' ) {
            $accept = 'Member';
        }

        $accept .= 'Feed' if $feed;

        $headers->{Accept}
            = sprintf( 'application/vnd.com.runkeeper.%s+json', $accept );
    }

    # Fix up URLs with a semicolon delimiter.
    if ( $url =~ m{;} ) {
        $url = $url->as_string;
        $url =~ s{;}{&}g;
    }

    my $res = $self->ua->get( $url, %{$headers} );
    return WebService::HealthGraph::Response->new(
        get => sub { $self->get( shift, $args ) }, raw => $res );
}

sub url_for { return shift->uri_for(@_) }

sub uri_for {
    my $self  = shift;
    my $type  = shift;
    my $query = shift;

    die "type $type not found" unless exists $self->url_map->{$type};

    return uri(
        path => $self->url_map->{$type},
        $query
        ? (
            query           => $query,
            query_separator => '&',
            )
        : (),
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebService::HealthGraph - A thin wrapper around the Runkeeper (Health Graph) API

=head1 VERSION

version 0.000004

=head1 SYNOPSIS

    my $runkeeper = WebService::HealthGraph->new(
        debug => 1,
        token => 'foo',
    );

    my $user = $runkeeper->user;

    use Data::Printer;
    p $user->content;

    # Fetch a weight feed

    use DateTime ();
    use URI::FromHash qw( uri );

    my $cutoff = DateTime->now->subtract( days => 7 );

    my $uri = uri(
        path  => '/weight',
        query => { noEarlierThan => $cutoff->ymd },
    );

    my $feed = $runkeeper->get($uri, { feed => 1 });
    p $feed->content;

=head1 DESCRIPTION

BETA BETA BETA.  The interface is subject to change.

This is a very thin wrapper around the Runkeeper (Health Graph) API.  At this
point it assumes that you already have an OAuth token to connect with.  You can
use L<Mojolicious::Plugin::Web::Auth::Site::Runkeeper> to create a token.  If
that doesn't suit you, patches to add OAuth token retrieval to this module will
be happily accepted.

=head1 CONSTRUCTOR ARGUMENTS

=head2 auto_pagination

Boolean.  If enabled, response objects will continue to fetch new result pages
as the iterator requires them.  Defaults to true.

=head2 base_url

The URL of the API.  Defaults to L<https://api.runkeeper.com>.  This is
settable in case you'd need this for mocking.

=head2 debug( $bool )

Turns on debugging via L<LWP::ConsoleLogger>.  Off by default.

=head2 token

OAuth token. Optional, but you'll need to to get any URLs.

=head2 ua

A user agent object of the L<LWP::UserAgent> family.  If you provide your own,
be sure you set the correct default headers required for authentication.

=head2 url_map

Returns a map of keys to URLs, as provided by the C<user> endpoint.  Runkeeper
wants you to use these URLs rather than constructing your own.

=head2 uri_for

Gives you the corresponding url (in the form of an L<URI> object) for any key
which exists in C<url_map>.  You can optionally pass a HashRef of query params
to this method.

    my $team_uri =  $runkeeper->uri_for( 'team', { pageSize => 10 } );

    my $friends = $runkeeper->get(
        $runkeeper->uri_for( 'team', { pageSize => 10 } ),
        { feed => 1 }
    );

=head2 url_for

Convenience method which points to C<url_for>.  Will be removed in a later
release.

=head2 user

The L<WebService::HealthGraph::Response> object for the C<user> endpoint.

=head2 user_id

The id of the user as provided by the C<user> endpoint.

=head1 METHODS

=head2 get( $url, $optional_args )

This module will try to do the right thing with the minimum amount of
information:

    my $weight_response = $runkeeper->get( 'weight', { feed => 1 } );
    if ( $weight_response->success ) {
        ...
    }

Optionally, you can provide your own Accept (or other) headers:

    my $record_response = $runkeeper->get(
        'records',
        {
            headers =>
                { Accept => 'application/vnd.com.runkeeper.Records+json' }
        );

Returns a L<WebService::HealthGraph::Response> object.

=head1 CAVEATS

Most response content will contain a C<HashRef>, but the C<records> endpoint
returns a response with an C<ArrayRef> in the content.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# ABSTRACT: A thin wrapper around the Runkeeper (Health Graph) API

