##
#
#    Copyright 2005-2006, AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Storage::Output::Blowfish;

use Crypt::CBC;
use Crypt::Blowfish;
use Digest::MD5 qw( md5_hex );
use XML::Comma::Util qw( dbg );

# _cipher;

sub new {
  my ( $class, %args ) = @_;
  my $self = {}; bless ( $self, $class );
  XML::Comma::Log->err ( 'ENCRYPTION_ERROR', "couldn't get blowfish key" )
      unless ( $args{key} );
  XML::Comma::Log->err ( 'ENCRYPTION_ERROR', "couldn't get key checking hash" )
      unless ( $args{key_hash} );
  XML::Comma::Log->err ( 'ENCRYPTION_ERROR',
                         "key doesn't match hash '$args{key_hash}'" )
      unless $args{key_hash} eq md5_hex($args{key});
  $self->{_cipher} = Crypt::CBC->new ( $args{key}, 'Blowfish' );
  return $self;
}

sub output {
  # Blowfish doesn't always gracefully pad binary data -- which we
  # might be receiving from a previous output chain. So we need to pad
  # the string so that we feed Twofish an even number of blocks of
  # data, and append our length so that we can trim on the input
  # side. The blocksize is 16.
  my $len = length ( $_[1] );
  my $blocks = int( $len/16 ) + 1;
  return pack ( 'N', $len ) .
    $_[0]->{_cipher}->encrypt ( pack( 'a'.$blocks*16, $_[1]) );
}

sub input {
  # strip off the length
  my $len = unpack ( 'N', substr($_[1], 0, 4) );
  my $in_str = substr ( $_[1], 4 );
  # decrypt
  my $decrypted = $_[0]->{_cipher}->decrypt ( $in_str );
  # return trimmed to length
  return substr ( $decrypted, 0, $len );
}


1;


