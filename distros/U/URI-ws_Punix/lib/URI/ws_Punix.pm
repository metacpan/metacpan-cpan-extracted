package URI::ws_Punix;

our $VERSION=.002;
our %KNOWN;

=head1 NAME

URI::ws_Punix - URI for ws+unix

=head1 SYNOPSIS

  use URI;
  my $url='ws+unix://unix%2F:%2Ftest%2Fsocket.sock/testing';

  my $uri=new URI($url);

  # will output: ws+unix
  print $uri->scheme,"\n";

  # will output: unix/
  print $uri->host,"\n";

  # will output: /test/socket.sock
  print $uri->port

  # some classes don't yet understand the scheme ws+unix, so here is a work around
  $uri->set_false_scheme('ws');
  print $uri->scheme,"\n"; # now prints "ws"

=head1 DESCRIPTION

This class acts as a parser layer for URI, and adds support for handling the rare WebSocket URI using a "Unix Domain Socket.  The scheme expected is "ws+unix".  Since most modules don't understand this just yet, the fake scheme or $uri->set_false_scheme('ws') was added. 

=cut

use strict;
use warnings;

use parent q(URI::_server);
use URI::Escape qw(uri_unescape);

=head1 METHODS

=head2 URI::ws_Punix-E<gt>default_port

Returns the default port /tmp/unix.sock

=cut

sub default_port { '/tmp/unix.sock' }

sub _port {
  my $self=shift;
  return $self->SUPER::_port(@_) if $#_ >-1;
  if($$self=~ m,^ws+\+unix://unix%2F:?([^/]+),is) {
    return uri_unescape($1);
  }
  return $self->SUPER::_port(@_);
}

sub host {
  my $self=shift;
  return $self->SUPER::host('unix/') if $#_ >-1;
  if($$self=~ m,^ws+\+unix://unix%2F:?.*$,is) {
    return 'unix/';
  }
  return $self->SUPER::host(@_);
}

=head2 $uri->set_false_scheme('ws')

Used to overload the default behavior.. sometimes you may want to say "ws" in place of "ws+unix".  Some modules expect ws, this method lets you overload the default of $uri->scheme.

=cut

sub set_false_scheme {
  my ($self,$scheme)=@_;

  $KNOWN{$self}=$scheme;
}

=head2 URI::ws_Punix-E<gt>scheme

Normally follows the defaults unless $uri->set_false_scheme('value') was called on this instance.

=cut

sub scheme {
  my $self=shift;
  if($#_ >-1) {
    return $self->SUPER::scheme(@_);
  }

  if(exists $KNOWN{$self}) {
    return $KNOWN{$self};
  }

  return $self->SUPER::scheme;
}

=head2 URI::ws_Punix-E<gt>secure

Returns false

=cut

sub secure { 0 } 

our %KNWON=();

sub DESTROY {
  my $self=shift;

  delete $KNOWN{$self};
}

=head1 AUTHOR

Michael Shipper <AKALINUX@CPAN.ORG>

=cut

1;

