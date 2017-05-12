package WWW::Live::Auth::SecretKey;

use strict;
use warnings;

require Digest::SHA;

sub new {
  my ( $proto, $raw ) = @_;
  my $class = ref $proto || $proto;
  
  my $self = bless {
    'string' => $raw,
  }, $class;
  $self->_process( $raw );
  
  return $self;
}

sub as_string {
  my $self = shift;
  return $self->{'string'};
}

sub encryption_key {
  my $self = shift;
  return $self->{'encryption_key'};
}

sub signature_key {
  my $self = shift;
  return $self->{'signature_key'};
}

sub _process {
  my ( $self, $secret_key ) = @_;
  my $encryption_key = Digest::SHA::sha256( "ENCRYPTION$secret_key" );
  my $signature_key  = Digest::SHA::sha256( "SIGNATURE$secret_key" );
  $encryption_key = substr( $encryption_key, 0, 16);
  $signature_key  = substr( $signature_key, 0, 16);
  $self->{'encryption_key'} = $encryption_key;
  $self->{'signature_key'}  = $signature_key;
}

1;
__END__

=head1 NAME

WWW::Live::Auth::SecretKey

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