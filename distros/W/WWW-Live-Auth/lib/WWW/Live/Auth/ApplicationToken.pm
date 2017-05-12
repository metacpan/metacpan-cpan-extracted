package WWW::Live::Auth::ApplicationToken;

use strict;
use warnings;

use WWW::Live::Auth::Utils;

sub new {
  my ( $proto, $signature_key, $app_id, $client_ip ) = @_;
  my $class = ref $proto || $proto;

  my $self = bless {}, $class;
  $self->_process( $signature_key, $app_id, $client_ip );

  return $self;
}

sub as_string {
  my $self = shift;
  return $self->{'string'};
}

sub application_id {
  my $self = shift;
  return $self->{'application_id'};
}

sub timestamp {
  my $self = shift;
  return $self->{'timestamp'};
}

sub client_ip {
  my $self = shift;
  return $self->{'client_ip'};
}

sub _process {
  my ( $self, $signature_key, $app_id, $client_ip ) = @_;

  my $timestamp = _timestamp();
  $self->{'timestamp'} = $timestamp;
  $self->{'application_id'} = $app_id;

  my $token = sprintf "appid=%s&ts=%s", $app_id, $timestamp;
  if ( $client_ip ) {
    $token .= sprintf "&ip=%s", $client_ip;
    $self->{'client_ip'} = $client_ip;
  }

  my $signature = _escape( _encode( _sign( $token, $signature_key ) ) );
  $self->{'signature'} = $signature;
  $token .= sprintf '&sig=%s', $signature;

  $self->{'string'} = _escape( $token );
}

1;
__END__

=head1 NAME

WWW::Live::Auth::ApplicationToken

=head1 VERSION

1.0.0

=head1 AUTHOR

Andrew M. Jenkinson <jenkinson@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 Andrew M. Jenkinson.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut