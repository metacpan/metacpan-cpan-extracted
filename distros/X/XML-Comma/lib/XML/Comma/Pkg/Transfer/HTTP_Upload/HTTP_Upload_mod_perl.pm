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

package XML::Comma::Pkg::Transfer::HTTP_Upload::HTTP_Upload_mod_perl;

use Apache::Constants ':common';
use XML::Comma;
use Apache::Request;

## Server-side of an HTTP_Upload transfer -- configurable via mod_perl
##
# PerlModule XML::Comma
#  PerlModule XML::Comma::Transferrance::HTTP_Upload_mod_perl
#  <Location /comma/HTTP_upload_transfer>
#    SetHandler perl-script
#    PerlHandler   XML::Comma::Transferrance::HTTP_Upload_mod_perl
#  </Location>


sub handler {
  my $r = Apache::Request->new ( shift() );
  my $command = $r->param ( 'command' );
  if ( $command eq 'put' ) {
    put ( $r );
  } elsif ( $command eq 'get_hash' ) {
    get_hash ( $r );
  } elsif ( $command eq 'erase' ) {
    erase ( $r );
  } else {
    return output_not_ok ( $r, "unrecognized command: $command" );
  }
}


sub put {
  my $r = shift();
  my $id;
  eval {
    local $/ = undef;  # so we can slurp filehandle contents into scalars
    $id = $r->param ( 'id' );
    my $store_name = $r->param ( 'store_name' );
    my $upload = $r->upload ( 'comma_doc_to_string' );
    my $fh = $upload->fh();
    my $doc_string = <$fh>;
    my $store = XML::Comma::Def->read ( name => $r->param('type') )
      ->get_store ( $store_name );
    my %blobs;
    foreach my $i ( 1 .. $r->param('number_of_blobs') ) {
      my $upload = $r->upload ( "blob_$i" );
      my $fh = $upload->fh();
      my $content = <$fh>;
      $blobs{$upload->filename} = $content;
    }
    my $hashes_ok = 1;
    my $hashes_ok = $store->put_store ( id => $id,
                                        doc_string => $doc_string,
                                        blobs => \%blobs,
                                        comma_hash => $r->param('comma_hash') );
    if ( $hashes_ok ) {
      return output_ok ( $r, "put ok" );
    } else {
      return output_not_ok ( $r, "put failed for $id -- hashes do not match" );
    }
  }; if ( $@ ) {
    return output_not_ok ( $r, "put failed for $id -- $@" );
  }
}


sub get_hash {
  my $r = shift();
  my $type = $r->param ( 'type' );
  my $id = $r->param ( 'id' );
  my $store_name = $r->param ( 'store' );
  my $doc = eval {
    XML::Comma::Doc->read( type => $type,
                           id => $id,
                           store => $store_name );
  };
  if ( ! $doc ) {
    #return output_not_ok ( $r, "get_hash failed -- couldn't get doc: $@" );
    return output_ok ( $r, '' );
  } else {
    return output_ok ( $r, $doc->comma_hash() );
  }
}


sub erase {
  my $r = shift();
  my $type = $r->param ( 'type' );
  my $id = $r->param ( 'id' );
  my $store_name = $r->param ( 'store_name' );
  eval {
    my $doc = XML::Comma::Doc->retrieve( type => $type,
                                         id => $id,
                                         store => $store_name );
    $doc->erase();
  };
  if ( $@ ) {
    return output_not_ok ( $r, "erase failed -- error: $@" );
  } else {
    return output_ok ( $r, "erase ok" );
  }
}


sub output_ok {
  my ( $r, $string ) = @_;
  $r->status ( 200 );
  $r->content_type ( "text/plain" );
  $r->send_http_header();
  $r->print ( $string );
  return OK;
}


sub output_not_ok {
  my ( $r, $string ) = @_;
  $r->status ( 500 );
  $r->send_http_header();
  $r->log_error ( $string );
  return SERVER_ERROR;
}

1;

