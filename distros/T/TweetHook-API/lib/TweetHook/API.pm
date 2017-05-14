=head1 NAME

TweetHook::API - 

=head1 SYNOPSIS

use TweetHook::API;

my $th = TweetHook::API->new;

foreach my $hook ( @{$th->list->{searches}} ) {
    print "$hook{id} $hook{search} $hook{webhook} $hook{active}\n";
}

$th->start ( $id );
$th->stop ( $id );

$th->create ( 'search string', 'webhook url' );
$th->destroy ( $id );
$th->modify ( $id, { search => 'new search' } );
$th->modify ( $id, { webhook => 'new webhook' } );
$th->modify ( $id, { search => 'new search', webhook => 'new webhook' } );

=head1 DESCRIPTION

=cut

package TweetHook::API;
use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use MIME::Base64;
use JSON;
use fields ( 'format', 'username', 'password', 'basicauth' );

use Data::Dumper;

our $apiroot = 'https://api.tweethook.com';

1;

sub new {
  my ( $class, $un, $pw ) = @_;
  croak ( "Usage: $class->new ( username, password );" ) unless $un && $pw;
  my $self = {};
  $self->{format} = 'json';
  $self->{username} = $un;
  $self->{password} = $pw;
  $self->{basicauth} = 'Basic ' . MIME::Base64::encode ( "$un:$pw" );
  $self->{ua} = LWP::UserAgent->new;
  bless $self, ref $class || $class;
  return $self;
}

sub list {
  my $self = shift;
  my $resp = $self->{ua}->get ( $apiroot . "/list." . $self->{format},
				Authorization => $self->{basicauth} );
  return from_json ( $resp->content ) if $resp->is_success;
  return undef;
}

sub info {
  my ( $self, @ids ) = @_;
  
  if ( scalar @ids == 0  ) {
    carp "info needs at least 1 id";
    return;
  }
  my @res;
  foreach my $id ( @ids ) {
    my $url = URI->new ( $apiroot . "/info.json" );
    $url->query_form ( { id => $id } );
    my $resp = $self->{ua}->get ( $url, Authorization => $self->{basicauth} );
    if ( $resp->is_success ) {
      push @res, from_json ( $resp->content );
    }
  }
  return undef if scalar @res == 0;
  return wantarray ? @res : $res[0];
}

sub do_post {
  my ( $self, $thmethod, $args ) = @_;
  my $uri = URI->new ( "http:" );  # just want to do url encoding
  $uri->query_form ( $args );
  my $content = $uri->query;
  my $resp = $self->{ua}->request (  HTTP::Request->new ( "POST",
							  "$apiroot$thmethod",
							  [ Authorization => $self->{basicauth},
							    'Content-Type' => 'application/x-www-form-urlencoded' ],
							  $content ) );
  return from_json ( $resp->content ) if $resp->is_success;
  return undef;
}

sub start {
  my ( $self, $id ) = @_;
  if ( !$id ) {
    carp "start needs an id";
    return undef;
  }
  return $self->do_post ( '/start.json', { id => $id } );
}

sub stop {
  my ( $self, $id ) = @_;
  if ( !$id ) {
    carp "stop needs an id";
    return undef;
  }
  return $self->do_post ( '/stop.json', { id => $id } );
}

sub create {
  my ( $self, $search, $hook ) = @_;
  if ( !$search || !$hook ) {
    carp "create needs search and webhook";
    return undef;
  }
  return $self->do_post ( '/create.json', { search => $search, webhook => $hook } );
}

sub destroy {
  my ( $self, $id ) = @_;
  if ( !$id ) {
    carp "destroy needs an id";
    return undef;
  }
  return $self->do_post ( '/destroy.json', { id => $id } );
}

sub modify {
  my ( $self, $id, $args ) = @_;
  if ( !$id ) {
    carp "modify needs an id";
    return undef;
  }
  $args->{id} = $id;
  return $self->do_post ( '/modify.json', $args );
}
