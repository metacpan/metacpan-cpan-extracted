use strict;
use warnings;
package WebService::ChatWorkApi::UserAgent;
use parent "LWP::UserAgent";
use Carp ( );
use Readonly;
use String::CamelCase qw( camelize );
use URI;
use JSON;
use Mouse;
use Smart::Args;
use Class::Load qw( try_load_class );
use WebService::ChatWorkApi::Response;

our $VERSION = '0.01';

Readonly my $AGENT               => sprintf "%s/%s", __PACKAGE__, $VERSION;
Readonly my $CODEC               => JSON->new;
Readonly my $BASE_URL            => "https://api.chatwork.com/v1/";
Readonly my $BASE_RESPONSE_CLASS => "WebService::ChatWorkApi::Response";

has api_token => ( is => "rw", isa => "Str" );
has base_url  => ( is => "rw", isa => "URI" );

sub new {
    my $class = shift;
    my %param = @_;

    my $api_token = delete $param{api_token}
        or Carp::croak( "api_token required." );
    my $base_url  = delete $param{base_url} || $BASE_URL;
    $base_url = "$base_url/"
        if $base_url !~ m{ / \z}msx;

    $param{agent} ||= $AGENT;
    my $ua = $class->SUPER::new( %param );

    $ua->api_token( $api_token );
    $ua->base_url( URI->new( $base_url ) );

    $ua->default_header( "X-ChatWorkToken" => $ua->api_token );

    $ua->add_handler(
        response_done => sub {
            my( $response, $ua, $h ) = @_;
            my $relative_url = $response->request->uri->rel( $ua->base_url );
            my $class_name = $ua->_load_longest_loadable_class( $relative_url->path_segments );
            bless $response, $class_name;
        },
    );

    return $ua;
}

sub _load_longest_loadable_class {
    my $self     = shift;
    my @segments = @_;
    my $root_class = $BASE_RESPONSE_CLASS;
    my $response_class = $root_class;

    while ( @segments ) {
        my $try_class = join q{::}, $response_class, map { camelize( $_ ) } @segments;
        try_load_class( $try_class )
            and return $try_class;
        pop @segments;
    }

    return $response_class;
}

sub request {
    my $self    = shift;
    my $request = shift;
    my @args    = @_;

    ( my $uri = $request->uri ) =~ s{\A / }{}msx;
    my $url = URI->new_abs( $uri, $self->base_url );
    $request->uri( $url );

    my $response = $self->SUPER::request( $request, @args );

    return $response;
}

sub me {
    my $self = shift;
    return $self->get( "/me" );
}

sub my_status {
    my $self = shift;
    return $self->get( "/my/status" );
}

sub my_tasks {
    my $self = shift;
    return $self->get( "/my/tasks" );
}

sub contacts {
    my $self = shift;
    return $self->get( "/contacts" );
}

sub rooms {
    my $self = shift;
    return $self->get( "/rooms" );
}

sub room {
    args_pos my $self,
             my $room_id;
    return $self->get( "/rooms/$room_id" );
}

sub messages {
    args_pos my $self,
             my $room_id => { isa => "Int" },
             my $force   => { isa => "Bool", optional => 1, default => 0 };
    my $path = URI->new( "/rooms/$room_id/messages" );
    $path->query_form( force => $force );
    return $self->get( "$path" );
}

sub post_message {
    args_pos my $self,
             my $room_id,
             my $body;
    return $self->post( "/rooms/$room_id/messages", { body => $body } );
}

1;

__END__
=encoding utf8

=head1 NAME

WebService::ChatWorkApi::UserAgent - A client to request to ChatWork REST API

=head1 SYNOPSIS

  uwe WebService::ChatWorkApi::UserAgent;
  my $ua = WebService::ChatWorkApi::UserAgent->new(
      api_token => $api_token,
  );
  my $res = $ua->get( "/me" );
  warn $res->dump;

=head1 DESCRIPTION

This module allows you to access the data which stored by ChatWork.

ChatWork API has very simple authentication way.  It's required only
`X-ChatWorkToken` header.

OAuth 2.0 may be released by ChatWork later, but for now it does not exist.

Except authentication, this module provides explicitly methods to
how access the ChatWork API.  And this module maps response to
new response class.
