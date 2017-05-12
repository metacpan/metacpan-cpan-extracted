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

package XML::Comma::Pkg::Transfer::HTTP_Upload;

use XML::Comma::Util qw( dbg trim );
use HTTP::Request::Common;
use LWP::UserAgent;
use Sys::Hostname ();

use strict;

# _HTTP_Upload_Doc   : the doc that defines this upload
# _HTTP_Upload_EMPTY : don't do any of the methods if this is set

sub new {
  my ( $class, %args ) = @_;
  my $self = {}; bless ( $self, $class );
  $self->{_HTTP_Upload_Doc} = XML::Comma::Doc->read
    ( "HTTP_Upload_Config|main|$args{name}" );
  $self->{_HTTP_Upload_EMPTY} = 1  if
    Sys::Hostname::hostname() ne
        $self->{_HTTP_Upload_Doc}->element('from')->get();
  return $self;
}

# takes the same args as a retrieve on the other side would take
# (fancy that). returns the hash if all goes well. returns 0 if the
# document is not found. throws an error if there is some kind of
# network or server error.
sub get_hash {
  my ( $self, @args ) = @_;
  my $ua = LWP::UserAgent->new();
  my $response = $ua->request 
    ( POST
      $self->{_HTTP_Upload_Doc}->element('target')->get(),
      [ command => 'get_hash',
        @args ] );
  #dbg 'code', $response->code();
  if ( $response->code() == 200 ) {
    return trim $response->content();
  } elsif ( $response->code() == 500 ) {
    return undef;
    #XML::Comma::Log->err ( 'TRANSFER_OPERATION_FAILED', "get_hash" );
  }
}


#  # takes same args as a retrieve on the other side
#  sub retrieve {
#  }


sub put {
  my ( $self, $doc ) = @_;
  return  if  $self->{_HTTP_Upload_EMPTY};
  # check permission -- user must have -w access to doc file to be
  # allowed to put it anywhere else
  if ( ! -w $doc->doc_location() ) {
    XML::Comma::Log->err ( 'TRANSFER_PERMISSION_DENIED', "put <address>" );
  }
  my $response;
  eval {
    my $string_upload = $doc->system_stringify();
    my @blobs = map { [$_->get_filename(), $_->get()] } $doc->get_all_blobs();
    my $blob_output_counter=1;
    my $ua = LWP::UserAgent->new();
    my $req = POST $self->{_HTTP_Upload_Doc}->element('target')->get(),
      Content_Type => 'form-data',
        Content =>
          [ command => 'put',
            type => $doc->tag(),
            id => $doc->doc_id(),
            store_name => $doc->doc_store()->name(),
            number_of_blobs => scalar @blobs,
            comma_hash => $doc->comma_hash(),
            comma_doc_to_string =>
            [ undef,
              'comma_doc_to_string',
              'Content-Length' => length ( $string_upload ),
              'Content-Type'   => 'text/plain',
              Content => $string_upload,
            ],
            map {
              'blob_'.$blob_output_counter++ =>
                [ undef,
                  $_->[0],
                  'Content-Length' => length ( $_->[1] ),
                  'Content-Type' => 'bin/data',
                  Content => $_->[1],
                ],
              } @blobs
          ];
    #print "over: " . $req->as_string() . "\n\n";
    $ua->timeout ( 30 );
    $response = $ua->request ( $req );
    #print "back: " . $response->content() . "\n";
  }; if ( $@ ) {
    XML::Comma::Log->err ( 'TRANSFER_OPERATION_FAILED',
                           "put error: $@" );
  }
  if ( $response->code() == 200 ) {
    return 1;
  } else {
    XML::Comma::Log->err ( 'TRANSFER_OPERATION_FAILED',
                           "put error: (" .
                           $response->code() . ") " );
#                           trim($response->content()) );
  }
}


sub erase {
  my ( $self, $doc ) = @_;
  return  if  $self->{_HTTP_Upload_EMPTY};
  # check permission -- user must have -w access to doc file to be
  # allowed to erase it
  if ( ! -w $doc->doc_location() ) {
    XML::Comma::Log->err ( 'TRANSFER_PERMISSION_DENIED', "erase <address>" );
  }
  my $ua = LWP::UserAgent->new();
  my $response = $ua->request 
    ( POST
      $self->{_HTTP_Upload_Doc}->element('target')->get(),
      [ command => 'erase',
        type => $doc->tag(),
        id => $doc->doc_id(),
        store_name => $doc->doc_store()->name()
      ] );
  if ( $response->code() == 200 ) {
    return 1;
  } else {
    XML::Comma::Log->err ( 'TRANSFER_OPERATION_FAILED',
                           "erase error: (" .
                           $response->code() . ") " .
                           trim($response->content()) );
  }
}


1;
