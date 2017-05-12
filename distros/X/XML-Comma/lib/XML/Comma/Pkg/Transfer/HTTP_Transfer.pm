##
#
#    Copyright 2001-2007, AllAfrica Global Media
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

#TODO: return a useful error message to the client as well - 
# don't just stuff it in error.log here

package XML::Comma::Pkg::Transfer::HTTP_Transfer;

# _target           : url to get/post to/from
# _ignore_here      : flag -- ignore all network commands except ping
# _https_cert_file  : certificate file, for any  https client authentication
# _https_key_file   : key file          ''  ''   ''    ''     ''

# Clients shouldn't need to have the Apache modules installed. So
# we'll BEGIN/eval the use'ing of those modules, and define some dummy
# subs if the use throws an error
use strict;
BEGIN {
  eval 'use Apache::Constants qw(:common);
        use Apache::Request;';
  if ( $@ ) {
    eval 'sub OK           { client_only_error() }
          sub NOT_FOUND    { client_only_error() }
          sub SERVER_ERROR { client_only_error() }
          sub client_only_error {
            die "HTTP_Transfer does not have access to Apache modules\n";
          }';
  }
  eval 'use Crypt::SSLeay;';
};


use LWP::UserAgent;
use HTTP::Request::Common;
use MIME::Base64;
use Storable qw( nfreeze thaw );
use Sys::Hostname qw();

use XML::Comma;
use XML::Comma::Util qw( dbg array_includes );


sub new {
  my ( $class, %args ) = @_;
  my $self = {}; bless ( $self, $class );
  $self->{_target} = $args{target} ||
    XML::Comma::Log->err ( 'TRANSFER_ERROR', 'no target given to new()' );
  $args{ignore_on} = [] unless(ref($args{ignore_on})); 
  if ( my @ignores = @{$args{ignore_on}} ) {
    my $hn = Sys::Hostname::hostname();
    $self->{_ignore_here} = $hn  if  array_includes ( @ignores, $hn );
  }
  $self->{_https_cert_file} = $args{https_cert_file};
  $self->{_https_key_file} = $args{https_key_file};
  # FIX: perhaps these should be set just before each request?
  $ENV{HTTPS_CERT_FILE} = $self->{_https_cert_file} || '';
  $ENV{HTTPS_KEY_FILE}  = $self->{_https_key_file} || '';
  return $self; 
}


sub test_ignore_here {
  my $self = shift;
  if ( my $hostname = $self->{_ignore_here} ) {
    return "ignoring network commands on $hostname\n"
  } else {
    return;
  }
}


# takes no arguments, tests connection to server. returns 1 on
# successfull connection and data exchange, '' otherwise
sub ping {
  my $self = shift();
  my $ua = LWP::UserAgent->new();
  my $req = $self->_get_request ( 'ping' );
  my $response = $ua->request ( $req );
  if ( $response && $response->is_success() ) {
    return $response->content();
  } else {
    XML::Comma::Log->err ( 'TRANSFER_ERROR', 
                           "couldn't ping remote on ".$self->{_target} );
    return undef;
  }
}

# takes the same type,store,id or key arguments that a Doc->read()
# does. gets the identified doc on the remote server and writes that
# doc (with the same store and id) to permanent storage on the local
# side. over-writes any existing doc. returns a read-only Doc object
# on success. returns undef if the doc was not found on the remote
# server. throws an error if it encounters severe difficulties either
# on the network or while trying to store the local doc.
sub get_and_store {
  my ( $self, @args ) = @_;
  my $msg = $self->test_ignore_here(); return $msg if $msg;
  my $ua = LWP::UserAgent->new();
  my $req = $self->_get_request ( 'get_and_store',
                                  XML::Comma::Doc->parse_read_args(@args) );
  my $response = $ua->request ( $req );
  if ( $response && $response->is_success() ) {
    return $self->_store ( thaw $response->content() )
      if $response->content_length();
  } else {
    XML::Comma::Log->err ( 'TRANSFER_ERROR',
                           'remote get_and_store error' );
  }
  return;
}

# takes the same type,store,id or key arguments that a Doc->read()
# does. gets the comma_hash of the identified doc on the remote
# server. returns the hash on success, returns '' if the doc was not
# found. throws an error it encounters severe difficulties on the
# network or remote server.
sub get_hash {
  my ( $self, @args ) = @_;
  my $msg = $self->test_ignore_here(); return $msg if $msg;
  my $ua = LWP::UserAgent->new();
  my $req = $self->_get_request ( 'get_hash',
                                  XML::Comma::Doc->parse_read_args(@args) );
  my $response = $ua->request ( $req );
  if ( $response && $response->is_success() ) {
    return $response->content();
  } else {
    XML::Comma::Log->err ( 'TRANSFER_ERROR', 
                           'remote get_hash error on '.$self->{_target} );
  }
}

# takes a doc object as its argument. puts the doc on the remote
# server, preserving its store and id. returns the id of the doc on
# success. throws an error it encounters severe difficulties on the
# network or remote server.
sub put {
  my ( $self, $doc, $no_hooks ) = @_;
  my $msg = $self->test_ignore_here(); return $msg if $msg;
  my $ua = LWP::UserAgent->new();
  my $req = $self->_put_request ( 'put', $doc, '', $no_hooks );
  my $response = $ua->request ( $req );
  if ( $response && $response->is_success() ) {
    return $response->content();
  } else {
    XML::Comma::Log->err ( 'TRANSFER_ERROR', 
                           'remote put error on '.$self->{_target}.
                           ' for ' . $doc->doc_key() );
  }
}


# takes a doc object as its argument. puts the doc on the remote
# server, preserving its id but possibly changing its store. returns
# the id of the doc on success. throws an error it encounters severe
# difficulties on the network or remote server. (this is really an odd
# species of "put", but since it's intended to be used for specific
# kinds of things, we've given it a different method name.)
sub put_archive {
  my ( $self, $doc, $store_name, $no_hooks ) = @_;
  my $msg = $self->test_ignore_here(); return $msg if $msg;
  my $ua = LWP::UserAgent->new();
  my $req = $self->_put_request ( 'put', $doc, $store_name, $no_hooks );
  my $response = $ua->request ( $req );
  if ( $response && $response->is_success() ) {
    return $response->content();
  } else {
    XML::Comma::Log->err ( 'TRANSFER_ERROR', 
                           'remote put_archive error on '.$self->{_target}.
                           ' for ' . $doc->doc_key() );
  }
}

# takes a doc object as its argument. puts the doc on the remote
# server, storing the doc as a new object. if given an optional second
# argument, $store_name, that store will be used in writing out the
# doc on the remote server, otherwise the doc's current store_name
# will be used. returns the id of the newly-saved doc on
# success. throws an error it encounters severe difficulties on the
# network or remote server.
sub put_push {
  my ( $self, $doc, $store_name ) = @_;
  my $msg = $self->test_ignore_here(); return $msg if $msg;
  my $ua = LWP::UserAgent->new();
  my $req = $self->_put_request ( 'put_push', $doc, $store_name );
  my $response = $ua->request ( $req );
  if ( $response && $response->is_success() ) {
    return $response->content();
  } else {
    XML::Comma::Log->err ( 'TRANSFER_ERROR', 
                           'remote put_push error on '.$self->{_target}.
                           ' for ' . $doc->doc_key() );
  }
}

# takes a doc object as its argument. tries to erase the doc from the
# remote server. returns the doc key on success; returns the empty
# string if the doc was not found on the remote server; throws an
# error on encountering network problems.
sub erase {
  my ( $self, $doc ) = @_;
  my $msg = $self->test_ignore_here(); return $msg if $msg;
  my $ua = LWP::UserAgent->new();
  my $req = $self->_put_request ( 'erase', $doc );
  my $response = $ua->request ( $req );
  if ( $response && $response->is_success() ) {
    return $response->content();
  } else {
    XML::Comma::Log->err ( 'TRANSFER_ERROR', 
                           'remote erase error on '.$self->{_target}.
                           ' for ' . $doc->doc_key() );
  }
}


####
####
####


sub handler {
  my $r = shift();
  $r->read ( my $buffer, $r->header_in('Content-Length') );
  my $params = thaw ( $buffer );
  my $method_name = $params->{command} . '_handler';
  if ( my $m = XML::Comma::Pkg::Transfer::HTTP_Transfer->can($method_name) ) {
    return $m->( $r, $params );
  } else {
    return _not_ok ( $r, 'unrecognized command: ' . $params->{command} );
  }
}

sub get_and_store_handler {
  my ( $r, $params ) = @_;
  eval {
    my ( $type, $store, $id ) = ( $params->{type},
                                  $params->{store},
                                  $params->{id} );
    my $output_string = '';
    eval {
      my $doc = XML::Comma::Doc->read ( type => $type,
                                        store => $store,
                                        id => $id );
      # our response body is a "put_bundle" minus the command field
      $output_string = _put_bundle ( '', $doc );
    }; # (or empty, if the inner eval failed)
    return _ok ( $r, 'bin/data', \$output_string );
  }; if ( $@ ) {
    return _not_ok ( $r, "get_and_store_handler: $@" );
  }
}

sub get_hash_handler {
  my ( $r, $params ) = @_;
  my $hash = '';
  eval {
    my ( $type, $store, $id ) = ( $params->{type},
                                  $params->{store},
                                  $params->{id} );
    my $output_string = '';
    eval {
      my $doc = XML::Comma::Doc->read ( type => $type,
                                        store => $store,
                                        id => $id );
      $hash = $doc->comma_hash();
    };
    return _ok ( $r, 'bin/data', \$hash );
  }; if ( $@ ) {
    return _not_ok ( $r, "get_hash_handler: $@" );
  }
}

sub put_handler {
  my ( $r, $params ) = @_;
  my $response_string = '';
  eval {
    $response_string =
      XML::Comma::Pkg::Transfer::HTTP_Transfer->_store ( $params )->doc_id();
  }; if ( $@ ) {
    return _not_ok ( $r, "put_handler: $@" );
  }
  return _ok ( $r, 'text/plain', \$response_string );
}

sub put_push_handler {
  my ( $r, $params ) = @_;
  delete ${$params}{id};
  my $response_string = '';
  eval {
    $response_string =
      XML::Comma::Pkg::Transfer::HTTP_Transfer->_store ( $params )->doc_id();
  }; if ( $@ ) {
    return _not_ok ( $r, "put_push_handler: $@" );
  }
#    my $output_string;
#    while ( my ($key, $value) = each %$params ) {
#      $output_string .= "$key -- " . substr ( $value, 0, 20 ) . "\n";
#    }
  return _ok ( $r, 'text/plain', \$response_string );
}

sub erase_handler {
  my ( $r, $params ) = @_;
  my $response_string;
  eval {
    $response_string = XML::Comma::Def->read(name=>$params->{type})
      ->get_store($params->{store})->force_erase ( %$params );
  }; if ( $@ ) {
    return _not_ok ( $r, "erase_handler: $@" );
  }
#    my $output_string;
#    while ( my ($key, $value) = each %$params ) {
#      $output_string .= "$key -- " . substr ( $value, 0, 20 ) . "\n";
#    }
  return _ok ( $r, 'text/plain', \$response_string );
}

sub ping_handler {
  my $response_string = "1";
  return _ok ( $_[0], 'text/plain', \$response_string );
}

sub _ok {
  my ( $r, $content_type, $content_ref ) = @_;
  $r->content_type ( $content_type );
  $r->header_out ( 'Content-Length' => length $$content_ref );
  $r->send_http_header();
  $r->print ( $$content_ref );
  return OK;
}

sub _not_ok {
  my ( $r, $log_msg )  = @_;
  $r->log_error ( "HTTP_Transfer: $log_msg" );
  return SERVER_ERROR;
}

# ( $command, $doc, $store_name )
sub _put_request {
  my $self = shift();
  my $body = _put_bundle ( @_ );
  my $request = HTTP::Request->new ( POST => $self->{_target} );
  $request->push_header ( 'Content-Length' => length $body );
  $request->add_content ( $body );
  return $request; 
}

sub _put_bundle {
  my ( $command, $doc, $store_name, $no_hooks ) = @_;
  return nfreeze {
    command    => $command,
    type       => $doc->tag(),
    store      => $store_name || $doc->doc_store()->name(),
    no_hooks   => $no_hooks,
    id         => $doc->doc_id,
    key        => $doc->doc_key(),
    doc_string => $doc->system_stringify(),
    blobs      =>
      { map { $_->get_location(), $_->get() } $doc->get_all_blobs() } };
}

sub _get_request {
  my $self = shift();
  my $body = _get_bundle ( @_ );
  my $request = HTTP::Request->new ( POST => $self->{_target} );
  $request->push_header ( 'Content-Length' => length $body );
  $request->add_content ( $body );
  return $request; 
}

sub _get_bundle {
  my ( $command, %args ) = @_;
  return nfreeze { command => $command, %args };
}

# args: id, type, store, doc_string, blobs
sub _store {
  my ( $self_or_class, $args ) = @_;
  my $store = XML::Comma::Def->read (name=>$args->{type})
    ->get_store($args->{store});
  return $store->force_store ( %$args );
}


##
# For historical interest and possibly future reference: a possible
# multipart/form-data encoding of a doc
#
#
#  sub _put_request {
#    my ( $self, $command, $doc, $store_name ) = @_;
#    my $doc_string = $doc->system_stringify();
#    my @blobs = $doc->get_all_blobs();
#    my $blob_name_counter = 1;
#    return POST ( $self->{_target},
#                  Content_Type => 'form-data',
#                  Content =>
#                  [ command => $command,
#                    type => $doc->tag(),
#                    id => $doc->doc_id(),
#                    store_name => $store_name || $doc->doc_store()->name(),
#                    number_of_blobs => scalar @blobs,
#                    comma_hash => $doc->comma_hash(),
#                    doc_string => [ undef, # file
#                                    ''   , # filename
#                                    'Content-Length' => length $doc_string,
#                                    'Content-Type' => 'text/plain',
#                                    'Content' => $doc_string ],
#                    map { ('blob_'.$blob_name_counter++) =>
#                            [ $_->get_location(),
#                              $_->get_location()] } @blobs
#                  ] );
#  }

1;





