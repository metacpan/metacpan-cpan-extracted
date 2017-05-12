# -*- cperl; cperl-indent-level: 4 -*-
package WWW::Wookie::Connector::Service 0.102;
use strict;
use warnings;

use utf8;
use 5.020000;

use Exception::Class;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Status qw(HTTP_CREATED HTTP_OK HTTP_UNAUTHORIZED HTTP_FORBIDDEN);
use LWP::UserAgent qw/POST/;
use Log::Log4perl qw(:easy get_logger);
use Moose qw/around has with/;
use Regexp::Common qw(URI);
use URI::Escape qw(uri_escape);
use XML::Simple;
use namespace::autoclean '-except' => 'meta', '-also' => qr/^__/sxm;

use WWW::Wookie::Connector::Exceptions;
use WWW::Wookie::Server::Connection;
use WWW::Wookie::User;
use WWW::Wookie::Widget;
use WWW::Wookie::Widget::Category;
use WWW::Wookie::Widget::Property;
use WWW::Wookie::Widget::Instance;
use WWW::Wookie::Widget::Instances;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $DEFAULT_ICON =>
  q{http://www.oss-watch.ac.uk/images/logo2.gif};
Readonly::Scalar my $TIMEOUT => 15;
Readonly::Scalar my $AGENT   => q{WWW::Wookie/}
  . $WWW::Wookie::Connector::Service::VERSION;
Readonly::Scalar my $TESTUSER => q{testuser};

Readonly::Scalar my $EMPTY => q{};
Readonly::Scalar my $QUERY => q{?};
Readonly::Scalar my $SLASH => q{/};
Readonly::Scalar my $TRUE  => 1;
Readonly::Scalar my $FALSE => 0;

Readonly::Scalar my $MORE_ARGS => 4;
Readonly::Scalar my $MOST_ARGS => 5;

Readonly::Scalar my $GET    => q{GET};
Readonly::Scalar my $POST   => q{POST};
Readonly::Scalar my $DELETE => q{DELETE};
Readonly::Scalar my $PUT    => q{PUT};

Readonly::Scalar my $ALL             => q{all};
Readonly::Scalar my $PARTICIPANTS    => q{participants};
Readonly::Scalar my $PROPERTIES      => q{properties};
Readonly::Scalar my $SERVICES        => q{services};
Readonly::Scalar my $WIDGETS         => q{widgets};
Readonly::Scalar my $WIDGETINSTANCES => q{widgetinstances};

Readonly::Scalar my $DEFAULT_SCHEME => q{http};
Readonly::Scalar my $VALID_SCHEMES  => $DEFAULT_SCHEME . q{s?};    # http(s)

Readonly::Hash my %LOG => (
    'GET_USERS'     => q{Getting users for instance of '%s'},
    'USING_URL'     => q{Using URL '%s'},
    'RESPONSE_CODE' => q{Got response code %s},
    'DO_REQUEST'    => q{Requesting %s '%s'},
    'ALL_TRUE'      => q{Requesting all widgets},
);

Readonly::Hash my %ERR => (
    'NO_WIDGET_INSTANCE'     => q{No Widget instance},
    'NO_PROPERTIES_INSTANCE' => q{No properties instance},
    'NO_USER_OBJECT'         => q{No User object},
    'NO_WIDGET_GUID'         => q{No GUID nor widget object},
    'MALFORMED_URL' => q{URL for supplied Wookie Server is malformed: %s},
    'INCORRECT_PARTICIPANTS_REST_URL' =>
      q{Participants rest URL is incorrect: %s},
    'INCORRECT_PROPERTIES_REST_URL' => q{Properties rest URL is incorrect: %s},
    'INVALID_API_KEY'               => q{Invalid API key},
    'HTTP'                          => q{%s<br />%s},
);
## use critic

## no critic qw(ProhibitCallsToUnexportedSubs)
Log::Log4perl::easy_init($ERROR);
## use critic

has '_logger' => (
    'is'  => 'ro',
    'isa' => 'Log::Log4perl::Logger',
    'default' =>
      sub { Log::Log4perl->get_logger('WWW::Wookie::Connector::Service') },
    'reader' => 'getLogger',
);

has '_conn' => (
    'is'     => 'rw',
    'isa'    => 'WWW::Wookie::Server::Connection',
    'reader' => 'getConnection',
    'writer' => '_setConnection',
);

has '_locale' => (
    'is'     => 'rw',
    'isa'    => 'Str',
    'reader' => 'getLocale',
    'writer' => 'setLocale',
);

## no critic qw(Capitalization)
sub getAvailableServices {
## use critic
    my ( $self, $service_name ) = @_;
    my $url = $self->_append_path($SERVICES);
    __check_url( $url, $ERR{'MALFORMED_URL'} );
    my $content = {};
    if ($service_name) {
        $url .= $SLASH . URI::Escape::uri_escape($service_name);
    }
    if ( $self->getLocale ) {
        $content->{'locale'} = $self->getLocale;
    }

    my %services = ();
    my $response = $self->_do_request( $url, $content, $GET );
    my $xml_obj  = XML::Simple->new(
        'ForceArray' => 1,
        'KeyAttr'    => { 'widget' => q{id}, 'service' => q{name} },
    )->XMLin( $response->content );
    while ( my ( $name, $value ) = each %{ $xml_obj->{'service'} } ) {
        $self->getLogger->debug($name);
        my $service = WWW::Wookie::Widget::Category->new( 'name' => $name );
        while ( my ( $id, $value ) = each %{ $value->{'widget'} } ) {
            $service->put(
                WWW::Wookie::Widget->new( $id, $self->_parse_widget($value) ) );
        }
        $services{$name} = $service;
    }
    return values %services;
}

## no critic qw(Capitalization)
sub getAvailableWidgets {
## use critic
    my ( $self, $service ) = @_;
    my %widgets = ();
    my $url     = $self->_append_path($WIDGETS);
    my $content = {};
    if ( !defined $service || $service eq $ALL ) {
        $self->getLogger->debug( $LOG{'ALL_TRUE'} );
        $content->{'all'} = q{true};
    }
    elsif ($service) {
        $url .= $SLASH . URI::Escape::uri_escape($service);
    }
    if ( $self->getLocale ) {
        $content->{'locale'} = $self->getLocale;
    }
    __check_url( $url, $ERR{'MALFORMED_URL'} );

    my $response = $self->_do_request( $url, $content, $GET );
    my $xml_obj =
      XML::Simple->new( 'ForceArray' => 1, 'KeyAttr' => 'id' )
      ->XMLin( $response->content );
    while ( my ( $id, $value ) = each %{ $xml_obj->{'widget'} } ) {
        $widgets{$id} =
          WWW::Wookie::Widget->new( $id,
            $self->_parse_widget( $xml_obj->{'widget'}->{$id} ) );
    }
    return values %widgets;
}

has '_user' => (
    'is'     => 'ro',
    'isa'    => 'WWW::Wookie::User',
    'reader' => '_getUser',
    'writer' => '_setUser',
);

## no critic qw(Capitalization)
sub getUser {
## use critic
    my ( $self, $userid ) = @_;
    if ( defined $userid && $userid =~ /$TESTUSER(\d+)/gsmxi ) {
        return WWW::Wookie::User->new( $userid, qq{Test User $1} );
    }
    return $self->_getUser;
}

## no critic qw(Capitalization)
sub setUser {
## use critic
    my ( $self, $login, $screen ) = @_;
    $self->_setUser( WWW::Wookie::User->new( $login, $screen ) );
    return;
}

has 'WidgetInstances' => (
    'is'      => 'rw',
    'isa'     => 'WWW::Wookie::Widget::Instances',
    'default' => sub { WWW::Wookie::Widget::Instances->new() },
    'writer'  => '_setWidgetInstances',
);

## no critic qw(Capitalization)
sub getWidget {
## use critic
    my ( $self, $widget_id ) = @_;
    my @widgets =
      grep { $_->getIdentifier eq $widget_id } $self->getAvailableWidgets;
    return shift @widgets;

    ## no critic qw(ProhibitCommentedOutCode)
    # API method isn't implemented using proper id on the server.
    #my $url = $self->_append_path($WIDGETS);
    #if ( defined $widget_id ) {
    #    $url .= $SLASH . URI::Escape::uri_escape($widget_id);
    #}
    #__check_url($url, $ERR{'MALFORMED_URL'});

    #my $response = $self->_do_request( $url, {}, $GET );
    #my $xs = XML::Simple->new( 'ForceArray' => 1, 'KeyAttr' => 'id' );
    #my $xml_obj = $xs->XMLin( $response->content );
    #return WWW::Wookie::Widget->new( $widget_id,
    #    $self->_parse_widget($xml_obj) );
    ## use critic
}

## no critic qw(Capitalization)
sub getOrCreateInstance {
## use critic
    my ( $self, $widget_or_guid ) = @_;
    my $guid = $widget_or_guid;
    if ( q{WWW::Wookie::Widget} eq ref $widget_or_guid ) {
        $guid = $widget_or_guid->getIdentifier;
    }
    my $result = eval {
        if ( defined $guid && $guid eq $EMPTY ) {
            ## no critic qw(RequireExplicitInclusion)
            WookieConnectorException->throw(
                'error' => $ERR{'NO_WIDGET_GUID'} );
            ## use critic
        }
        my $url = $self->_append_path($WIDGETINSTANCES);
        __check_url( $url, $ERR{'MALFORMED_URL'} );
        my $content = { 'widgetid' => $guid };
        if ( my $locale = $self->getLocale ) {
            $content->{'locale'} = $locale;
        }
        my $response = $self->_do_request( $url, $content );
        if ( $response->code == HTTP_CREATED ) {
            $response = $self->_do_request( $url, $content );
        }

        my $instance = $self->_parse_instance( $guid, $response->content );
        if ($instance) {
            $self->WidgetInstances->put($instance);
            $self->addParticipant( $instance, $self->getUser );
        }
        return $instance;
    };

    if ( my $e = Exception::Class->caught('WookieConnectorException') ) {
        $self->getLogger->error( $e->error );
        $e->rethrow;
        return $FALSE;
    }
    return $result;
}

## no critic qw(Capitalization)
sub getUsers {
## use critic
    my ( $self, $instance ) = @_;
    if ( ref $instance ne q{WWW::Wookie::Widget::Instance} ) {
        $instance = $self->getOrCreateInstance($instance);
    }
    $self->getLogger->debug( sprintf $LOG{'GET_USERS'},
        $instance->getIdentifier );
    my $url = $self->_append_path($PARTICIPANTS);
    $self->getLogger->debug( sprintf $LOG{'USING_URL'}, $url );

    __check_url( $url, $ERR{'MALFORMED_URL'} );
    my $response =
      $self->_do_request( $url, { 'widgetid' => $instance->getIdentifier, },
        $GET, );

    if ( $response->code > HTTP_OK ) {
        __throw_http_err($response);
    }
    my $xml_obj =
      XML::Simple->new( 'ForceArray' => 1, 'KeyAttr' => 'id' )
      ->XMLin( $response->content );
    my @users = ();
    while ( my ( $id, $value ) = each %{ $xml_obj->{'participant'} } ) {
        my $new_user = WWW::Wookie::User->new(
            $id,
            defined $value->{'displayName'}   || $id,
            defined $value->{'thumbnail_url'} || $EMPTY,
        );
        push @users, $new_user;
    }
    return @users;
}

## no critic qw(Capitalization)
sub addProperty {
## use critic
    my ( $self, $widget, $property ) = @_;
    my $url = $self->_append_path($PROPERTIES);
    __check_url( $url, $ERR{'INCORRECT_PROPERTIES_REST_URL'} );
    my $response = $self->_do_request(
        $url,
        {
            'widgetid'      => $widget->getIdentifier,
            'propertyname'  => $property->getName,
            'propertyvalue' => $property->getValue,
            'is_public'     => $property->getIsPublic,
        },
        $POST,
    );
    if ( $response->code == HTTP_OK || $response->code == HTTP_CREATED ) {
        return $TRUE;
    }
    elsif ( $response->code > HTTP_CREATED ) {
        return $response->content;
    }
    return $FALSE;
}

## no critic qw(Capitalization)
sub getProperty {
## use critic
    my ( $self, $widget_instance, $property_instance ) = @_;
    my $url = $self->_append_path($PROPERTIES);
    __check_widget($widget_instance);
    __check_property($property_instance);
    __check_url( $url, $ERR{'MALFORMED_URL'} );
    my $response = $self->_do_request(
        $url,
        {
            'widgetid'     => $widget_instance->getIdentifier,
            'propertyname' => $property_instance->getName,
        },
        $GET,
    );
    if ( !$response->is_success ) {
        __throw_http_err($response);
        return $FALSE;
    }
    return WWW::Wookie::Widget::Property->new( $property_instance->getName,
        $response->content );

}

## no critic qw(Capitalization)
sub setProperty {
## use critic
    my ( $self, $widget, $property ) = @_;
    my $url    = $self->_append_path($PROPERTIES);
    my $result = eval {
        __check_widget($widget);
        __check_property($property);
        __check_url( $url, $ERR{'INCORRECT_PROPERTIES_REST_URL'} );
        my $response = $self->_do_request(
            $url,
            {
                'widgetid'      => $widget->getIdentifier,
                'propertyname'  => $property->getName,
                'propertyvalue' => $property->getValue,
                'is_public'     => $property->getIsPublic,
            },

            ## no critic qw(ProhibitFlagComments)
            # TODO: $PUT breaks, but should be used instead of $POST
            ## use critic
            $POST,
        );
        if ( $response->code == HTTP_CREATED || $response == HTTP_OK ) {
            return $property;
        }
        else {
            __throw_http_err($response);
        }
    };
    if ( my $e = Exception::Class->caught('WookieConnectorException') ) {
        $self->getLogger->error( $e->error );
        $e->rethrow;
        return $FALSE;
    }
    if ( my $e = Exception::Class->caught('WookieWidgetInstanceException') ) {
        $self->getLogger->error( $e->error );
        $e->rethrow;
        return $FALSE;
    }
    return $result;
}

## no critic qw(Capitalization)
sub deleteProperty {
## use critic
    my ( $self, $widget, $property ) = @_;
    my $url = $self->_append_path($PROPERTIES);
    __check_url( $url, $ERR{'INCORRECT_PROPERTIES_REST_URL'} );
    __check_widget($widget);
    __check_property($property);
    my $response = $self->_do_request(
        $url,
        {
            'widgetid'     => $widget->getIdentifier,
            'propertyname' => $property->getName,
        },
        $DELETE,
    );
    if ( $response->code == HTTP_OK ) {
        return $TRUE;
    }
    return $FALSE;
}

## no critic qw(Capitalization)
sub addParticipant {
## use critic
    my ( $self, $widget_instance, $user ) = @_;
    __check_widget($widget_instance);
    my $url = $self->_append_path($PARTICIPANTS);
    __check_url( $url, $ERR{'INCORRECT_PARTICIPANTS_REST_URL'} );
    my $response = $self->_do_request(
        $url,
        {
            'widgetid'                  => $widget_instance->getIdentifier,
            'participant_id'            => $self->getUser->getLoginName,
            'participant_display_name'  => $user->getScreenName,
            'participant_thumbnail_url' => $user->getThumbnailUrl,
        },
    );
    if ( $response->code == HTTP_OK ) {
        return $TRUE;
    }
    elsif ( $response->code == HTTP_CREATED ) {
        return $TRUE;
    }
    elsif ( $response->code > HTTP_CREATED ) {
        return $response->content;
    }
    return $FALSE;
}

## no critic qw(Capitalization)
sub deleteParticipant {
## use critic
    my ( $self, $widget, $user ) = @_;
    __check_widget($widget);
    my $url = $self->_append_path($PARTICIPANTS);
    __check_url( $url, $ERR{'INCORRECT_PARTICIPANTS_REST_URL'} );
    my $response = $self->_do_request(
        $url,
        {
            'widgetid'                  => $widget->getIdentifier,
            'participant_id'            => $self->getUser->getLoginName,
            'participant_display_name'  => $user->getScreenName,
            'participant_thumbnail_url' => $user->getThumbnailUrl,
        },
        $DELETE,
    );
    if ( $response->code == HTTP_OK ) {
        return $TRUE;
    }
    elsif ( $response->code == HTTP_CREATED ) {
        return $TRUE;
    }
    elsif ( $response->code > HTTP_CREATED ) {
        __throw_http_err($response);
    }
    return $FALSE;
}

## no critic qw(Capitalization)
sub _setWidgetInstancesHolder {
## use critic
    my $self = shift;
    $self->_setWidgetInstances( WWW::Wookie::Widget::Instances->new );
    return;
}

has '_ua' => (
    'is'      => 'rw',
    'isa'     => 'LWP::UserAgent',
    'default' => sub {
        LWP::UserAgent->new(
            'timeout' => $TIMEOUT,
            'agent'   => $AGENT,
        );
    },
);

around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == $MORE_ARGS ) {
        push @_, $EMPTY;
    }
    if ( @_ == $MOST_ARGS && !ref $_[0] ) {
        my ( $url, $api_key, $shareddata_key, $loginname, $screenname ) = @_;
        return $class->$orig(
            '_user' => WWW::Wookie::User->new( $loginname, $screenname ),
            '_conn' => WWW::Wookie::Server::Connection->new(
                $url, $api_key, $shareddata_key,
            ),
        );
    }
    return $class->$orig(@_);
};

sub BUILD {
    my $self = shift;
    $self->_setWidgetInstancesHolder;
    return;
}

sub _append_path {
    my ( $self, $path ) = @_;
    return $self->getConnection->getURL . URI::Escape::uri_escape($path);
}

sub __check_url {
    my ( $url, $message ) = @_;
    if ( $url !~ m{^$RE{URI}{HTTP}{-keep}{ '-scheme' => $VALID_SCHEMES }$}smx )
    {
        ## no critic qw(RequireExplicitInclusion)
        WookieConnectorException->throw( 'error' => sprintf $message, $url );
        ## use critic
    }
    return;
}

sub __check_widget {
    my ($ref) = @_;
    if ( ref $ref ne q{WWW::Wookie::Widget::Instance} ) {
        ## no critic qw(RequireExplicitInclusion)
        WookieWidgetInstanceException->throw(
            ## use critic
            'error' => $ERR{'NO_WIDGET_INSTANCE'},
        );
    }
    return;
}

sub __check_property {
    my ($ref) = @_;
    if ( ref $ref ne q{WWW::Wookie::Widget::Property} ) {
        ## no critic qw(RequireExplicitInclusion)
        WookieConnectorException->throw(
            ## use critic
            'error' => $ERR{'NO_PROPERTIES_INSTANCE'},
        );
    }
    return;
}

sub __throw_http_err {
    my ($response) = @_;
    ## no critic qw(RequireExplicitInclusion)
    WookieConnectorException->throw(
        ## use critic
        'error' => sprintf $ERR{'HTTP'},
        $response->headers->as_string, $response->content,
    );
    return;
}

sub _do_request {
    my ( $self, $url, $payload, $method ) = @_;

    # Widgets and Services request doesn't require API key stuff:
    if ( $url !~ m{/(?:widgets|services)(?:[?/]|$)}gismx ) {
        $payload = {
            'api_key'       => $self->getConnection->getApiKey,
            'shareddatakey' => $self->getConnection->getSharedDataKey,
            'userid'        => $self->getUser->getLoginName,
            %{$payload},
        };
    }
    if ( !defined $method ) {
        $method = $POST;
    }

    if ( ( my $content = [ POST $url, [ %{$payload} ] ]->[0]->content ) ne
        $EMPTY )
    {
        $url .= $QUERY . $content;
    }
    $self->getLogger->debug( sprintf $LOG{'DO_REQUEST'}, $method, $url );
    my $request = HTTP::Request->new(
        $method => $url,
        HTTP::Headers->new(),
    );
    my $response = $self->_ua->request($request);
    $self->getLogger->debug( sprintf $LOG{'RESPONSE_CODE'}, $response->code );
    if (   $response->code == HTTP_UNAUTHORIZED
        || $response->code == HTTP_FORBIDDEN )
    {
        ## no critic qw(RequireExplicitInclusion)
        WookieConnectorException->throw( 'error' => $ERR{'INVALID_API_KEY'} );
        ## use critic
    }
    return $response;
}

sub _parse_instance {
    my ( $self, $guid, $xml ) = @_;
    my $xml_obj =
      XML::Simple->new( 'ForceArray' => 1, 'KeyAttr' => 'id' )->XMLin($xml);
    if (
        my $instance = WWW::Wookie::Widget::Instance->new(
            $xml_obj->{'url'}[0],   $guid,
            $xml_obj->{'title'}[0], $xml_obj->{'height'}[0],
            $xml_obj->{'width'}[0],
        )
      )
    {
        $self->WidgetInstances->put($instance);
        $self->addParticipant( $instance, $self->getUser );
        return $instance;
    }
    return;
}

sub _parse_widget {
    my ( $self, $xml ) = @_;
    my $title = $xml->{'name'}[0]->{'content'};
    my $description =
      ref $xml->{'description'}[0]
      ? $xml->{'description'}[0]->{'content'}
      : $xml->{'description'}[0];
    my $icon =
      ref $xml->{'icon'}[0]
      ? $xml->{'icon'}[0]->{'content'}
      : $xml->{'icon'}[0];
    if ( !$icon ) {
        $icon = $DEFAULT_ICON;
    }
    return ( $title, $description, $icon );
}

with 'WWW::Wookie::Connector::Service::Interface';

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=for stopwords API Readonly Wookie guid Ipenburg login MERCHANTABILITY

=head1 NAME

WWW::Wookie::Connector::Service - Wookie connector service, handles all the
data requests and responses

=head1 VERSION

This document describes WWW::Wookie::Connector::Service version 0.102

=head1 SYNOPSIS

    use WWW::Wookie::Connector::Service;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

This module is an implementation of the
L<WWW::Wookie::Connector::Service::Interface
|WWW::Wookie::Connector::Service::Interface/"SUBROUTINES/METHODS">.

=head2 C<new>

Create a new connector

=over

=item 1. URL to Wookie host as string

=item 2. Wookie API key as string

=item 3. Shared data key to use as string

=item 4. User login name

=item 5. User display name

=back

=head2 C<getAvailableServices>

Get a all available service categories in the server. Returns an array of
L<WWWW::Wookie::Widget::Category|WW::Wookie::Widget::Category> objects.
Throws a C<WookieConnectorException>.

=head2 C<getAvailableWidgets>

Get all available widgets in the server, or only the available widgets in the
specified service category. Returns an array of
L<WWW::Wookie::Widget|WWW::Wookie::Widget> objects, otherwise false. Throws a
C<WookieConnectorException>.

=over

=item 1. Service category name as string

=back

=head2 C<getWidget>

Get the details of the widget specified by it's identifier. Returns a
L<WWW::Wookie::Widget|WWW::Wookie::Widget> object.

=over

=item 1. The identifier of an available widget

=back

=head2 C<getConnection>

Get the currently active connection to the Wookie server. Returns a
L<WWW::Wookie::Server::Connection|WWW::Wookie::Server::Connection> object.

=head2 C<setUser>

Set the current user.

=over

=item 1. User name for the current Wookie connection 

=item 2. Screen name for the current Wookie connection

=back

=head2 C<getUser>

Retrieve the details of the current user. Returns an instance of the user as a
L<WWW::Wookie::User|WWW::Wookie::User> object.

=head2 C<getOrCreateInstance>

Get or create a new instance of a widget. The current user will be added as a
participant. Returns a
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object if
successful, otherwise false. Throws a C<WookieConnectorException>. 

=over

=item 1. Widget as guid string or a L<WWW::Wookie::Widget|WWW::Wookie::Widget>
object

=back

=head2 C<addParticipant>

Add a participant to a widget. Returns true if successful, otherwise false.
Throws a C<WookieWidgetInstanceException> or a C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of user as L<WWW::Wookie::User|WWW::Wookie::User> object

=back

=head2 C<deleteParticipant>

Delete a participant. Returns true if successful, otherwise false. Throws a
C<WookieWidgetInstanceException> or a C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of user as L<WWW::Wookie::User|WWW::Wookie::User> object

=back

=head2 C<getUsers>

Get all participants of the current widget. Returns an array of
L<WWW::Wookie::User|WWW::Wookie::User> instances. Throws a
C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=back

=head2 C<addProperty>

Adds a new property. Returns true if successful, otherwise false. Throws a
C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> object

=back

=head2 C<setProperty>

Set a new property. Returns the property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> if successful,
otherwise false. Throws a C<WookieWidgetInstanceException> or a
C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> object

=back

=head2 C<getProperty>

Get a property. Returns the property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> if successful,
otherwise false. Throws a C<WookieWidgetInstanceException> or a
C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> object

=back

=head2 C<deleteProperty>

Delete a property. Returns true if successful, otherwise false. Throws a
C<WookieWidgetInstanceException> or a C<WookieConnectorException>.

=over

=item 1. Instance of widget as
L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance> object

=item 2. Instance of property as
L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property> object

=back

=head2 C<setLocale>

Set a locale.

=over

=item 1. Locale as string

=back

=head2 C<getLocale>

Get the current locale setting. Returns current locale as string.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over 4

=item * L<HTTP::Headers|HTTP::Headers>

=item * L<HTTP::Request|HTTP::Request>

=item * L<HTTP::Request::Common|HTTP::Request::Common>

=item * L<HTTP::Status|HTTP::Status>

=item * L<LWP::UserAgent|LWP::UserAgent>

=item * L<Log::Log4perl|Log::Log4perl>

=item * L<Moose|Moose>

=item * L<Moose::Util::TypeConstraints|Moose::Util::TypeConstraints>

=item * L<Readonly|Readonly>

=item * L<Regexp::Common|Regexp::Common>

=item * L<WWW::Wookie::Connector::Exceptions|WWW::Wookie::Connector::Exceptions>

=item * L<WWW::Wookie::Server::Connection|WWW::Wookie::Server::Connection>

=item * L<WWW::Wookie::User|WWW::Wookie::User>

=item * L<WWW::Wookie::Widget::Instance|WWW::Wookie::Widget::Instance>

=item * L<WWW::Wookie::Widget::Instances|WWW::Wookie::Widget::Instances>

=item * L<WWW::Wookie::Widget::Property|WWW::Wookie::Widget::Property>

=item * L<WWW::Wookie::Widget|WWW::Wookie::Widget>

=item * L<XML::Simple|XML::Simple>

=item * L<namespace::autoclean|namespace::autoclean>

=back

=head1 INCOMPATIBILITIES

=head1 DIAGNOSTICS

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at L<RT for
rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-Wookie>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
