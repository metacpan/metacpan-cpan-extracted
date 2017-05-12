package WWW::Live::Auth::ConsentToken;

use strict;
use warnings;

use WWW::Live::Auth::Utils;
use Carp;

require WWW::Live::Auth::SecretKey;
require WWW::Live::Auth::Offer;
require Math::BigInt;

sub new {
  my ( $proto, %args ) = @_;
  my $class = ref $proto || $proto;
  
  my $self = bless {
    'string' => $args{'consent_token'},
  }, $class;
  
  $self->_process( $args{'secret_key'} );
  
  return $self;
}

sub as_string {
  my $self = shift;
  return $self->{'string'};
}

sub delegation_token {
  my $self = shift;
  return $self->{'delegation_token'};
}

sub refresh_token {
  my $self = shift;
  return $self->{'refresh_token'};
}

sub session_key {
  my $self = shift;
  return $self->{'session_key'};
}

sub location_id {
  my $self = shift;
  return $self->{'location_id'};
}

sub int_location_id {
  my $self = shift;
  my $num = Math::BigInt->new('0x'.$self->{'location_id'});
  my ($base2)  = $num->as_bin() =~ /^0b(\d+)/;
  warn "BASE2: $base2";
  
  if ( length($base2) == 64 && substr($base2, 0, 1) eq '1' ) {
    $base2 =~ tr/01/10/;
    my @chars = split //, $base2;
    for (my $i=63; $i>0; $i--) {
      $chars[$i] =~ tr/01/10/;
      if ($chars[$i] eq '1') {
        last;
      }
    }
    $base2 = join '', @chars;
    return '-' . Math::BigInt->new("0b$base2")->bstr;
  } else {
    return $num->bstr;
  }
}

sub offers {
  my $self = shift;
  return wantarray ? @{ $self->{'offers'} || [] } : $self->{'offers'};
}

sub expires {
  my $self = shift;
  return $self->{'expires'};
}

sub _process {
  my ( $self, $secret_key ) = @_;
  
  $secret_key || croak('Secret key is required');
  my $consent_token = $self->{'string'} || croak('Consent token is required');
  
  if ( !ref $secret_key ) {
    $secret_key = WWW::Live::Auth::SecretKey->new( $secret_key );
  }
  
  $consent_token = _unescape( $consent_token );
  $consent_token = _split( $consent_token );
  
  if ( $consent_token->{'eact'} ) {
    $consent_token = _unescape( $consent_token->{'eact'} );
    $consent_token = _decode  ( $consent_token );
    $consent_token = _decrypt ( $consent_token, $secret_key->encryption_key );
    $consent_token = _validate( $consent_token, $secret_key->signature_key  );
    $consent_token = _split   ( $consent_token );
  }
  
  my @offers = map {
    WWW::Live::Auth::Offer->new( 'offer' => $_ )
  } split /;/, $consent_token->{'offer'};
  
  scalar @offers || croak('Consent token contains no offers');
  
  $self->{'delegation_token'} = $consent_token->{'delt'}  || croak('Consent token contains no delegation token');
  $self->{'refresh_token'}    = $consent_token->{'reft'}  || croak('Consent token contains no refresh token');
  $self->{'session_key'}      = $consent_token->{'skey'}  || croak('Consent token contains no session key');
  $self->{'expires'}          = $consent_token->{'exp'}   || croak('Consent token contains no expiry time');
  $self->{'location_id'}      = $consent_token->{'lid'}   || croak('Consent token contains no location ID');
  $self->{'offers'}           = \@offers;
}

1;
__END__

=head1 NAME

WWW::Live::Auth::ConsentToken

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