##
#
#    Copyright 2001, AllAfrica Global Media
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

package XML::Comma::Storage::Output::HMAC_MD5;

use Digest::MD5 qw( md5_hex );
use Digest::HMAC_MD5 qw( hmac_md5_hex );
use XML::Comma::Util qw( dbg );

# _key;

sub new {
  my ( $class, %args ) = @_;
  my $self = {}; bless ( $self, $class );
  XML::Comma::Log->err ( 'DIGEST_ERROR', "couldn't get HMAC_MD5 key" )
      unless ( $args{key} );
  XML::Comma::Log->err ( 'DIGEST_ERROR', "couldn't get key checking hash" )
      unless ( $args{key_hash} );
  XML::Comma::Log->err ( 'DIGEST_ERROR',
                         "key doesn't match hash '$args{key_hash}'" )
      unless $args{key_hash} eq md5_hex($args{key});
  $self->{_key} = $args{key};
  return $self;
}

sub output {
  # dbg 'output', 'hmac_md5';
  return hmac_md5_hex ( $_[1], $_[0]->{_key} ) . $_[1];
}

sub input {
  # digest should be substr ( $_[1], 0, 32 );
  # content should be substr ( $_[1], 32 );
  XML::Comma::Log->err ( 'DIGEST_ERROR', "HMAC_MD5 match failed" )
      unless hmac_md5_hex ( substr($_[1], 32), $_[0]->{_key} )
        eq substr ( $_[1], 0, 32 );
  return substr ( $_[1], 32 );
}


1;


