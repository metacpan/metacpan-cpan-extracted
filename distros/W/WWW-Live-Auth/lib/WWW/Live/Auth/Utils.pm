# Copyright 2008 Andrew M. Jenkinson, all rights reserved
# Use and/or distribution is permitted only with prior consent
package WWW::Live::Auth::Utils;

use strict;
use warnings;

use base qw(Exporter);

require Crypt::Rijndael;
require Digest::SHA;
require MIME::Base64;
use Carp;

use vars qw(@EXPORT @EXPORT_OK);
@EXPORT = @EXPORT_OK = qw(_unescape _escape _decode _encode _decrypt _validate _sign _timestamp _split);

sub _unescape {
  return URI::Escape::uri_unescape( shift );
}

sub _escape {
  return URI::Escape::uri_escape( shift );
}

sub _decode {
  my $decoded = MIME::Base64::decode_base64( shift );
  if ( length $decoded <= 16 || (length $decoded) % 16 != 0 ) {
    croak('Unable to decode token');
  }
  return $decoded;
}

sub _encode {
  return MIME::Base64::encode_base64( shift );
}

sub _decrypt {
  my $decoded   = shift;
  my $encryption_key = shift;
  my $iv        = substr($decoded, 0, 16);
  my $encrypted = substr($decoded, 16);
  my $cipher = Crypt::Rijndael->new( $encryption_key,
                                     Crypt::Rijndael::MODE_CBC() );
  $cipher->set_iv($iv);
  return $cipher->decrypt( $encrypted );
}

sub _validate {
  my $decrypted     = shift;
  my $signature_key = shift;
  
  my ( $token, $signature ) = split /&sig=/, $decrypted;
  if ( !$token || !$signature ) {
    croak('Unable to validate decrypted token');
  }
  $signature = _decode( _unescape( $signature ) );
  
  my $compare_signature = _sign( $token, $signature_key );
  if ( $signature ne $compare_signature ) {
    croak('Decrypted token does not match signature');
  }
  
  return $token;
}

sub _sign {
  my ( $token, $signature_key ) = @_;
  return Digest::SHA::hmac_sha256( $token, $signature_key );
}

sub _timestamp {
  return time();
}

sub _split {
  my ( $s ) = @_;
  my %split = ();
  my @pairs = split /&/, $s;
  for ( @pairs ) {
    my ( $key, $val ) = split /=/, $_;
    $split{$key} = $val;
  }
  return wantarray ? %split : \%split;
}

1;
__END__

=head1 NAME

WWW::Live::Auth::Utils

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