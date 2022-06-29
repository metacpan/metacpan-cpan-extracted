# ************************************************************************* 
# Copyright (c) 2014-2022, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

# ------------------------
# This package contains methods for dealing with request and response
# entities (parts two and four of the FSM as described in the L<Web::MREST>
# documentation 
# ------------------------

package Web::MREST::Entity;

use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use Data::Dumper;
use Try::Tiny;
use Web::Machine::FSM::States;
use Web::MREST::Util qw( $JSON );

use parent 'Web::MREST::Resource';




=head1 NAME

Web::MREST::Entity - Methods for dealing with request, response entities




=head1 SYNOPSIS

Methods for dealing with request, response entities




=head1 METHODS


=head2 get_acceptable_content_type_handler

The method to use to process the request entity (i.e, the "acceptable content
type handler") is set in content_types_accepted. Web::Machine only calls the
method on PUT requests and those POST requests for which post_is_create is
true. On POST requests where post_is_create is false, we have to call it
ourselves, and for that we need a way to get to it.

=cut

sub get_acceptable_content_type_handler {
    my $self = shift;
    Web::Machine::FSM::States::_get_acceptable_content_type_handler( $self, $self->request );
}


=head2 content_types_provided

L<Web::Machine> calls this routine to determine how to generate the response
body GET requests. (It is not called for PUT, POST, or DELETE requests.)

The return value has the following format:

    [
        { 'text/html' => 'method_for_html' },
        { 'application/json' => 'method_for_json' },
        { 'other/mime' => 'method_for_other_mime' },
    ]

As you can see, this is a list of tuples. The key is a media type and the 
value is the name of a method. The first tuple is taken as the default.

=cut
 
sub content_types_provided { 
    my $self = shift;
    my @caller = caller;
    $log->debug( "Entering " . __PACKAGE__ . "::content_types_provided, caller is " . Dumper( \@caller ) );

    return [
        { 'text/html' => 'mrest_generate_response_html' },
        { 'application/json' => 'mrest_generate_response_json' },
    ];
}


=head2 mrest_generate_response_html

Normally, clients will communicate with the server via
'_render_response_json', but humans need HTML. This method takes the
server's JSON response and wraps it up in a nice package. 
The return value from this method becomes the response entity.

=cut

sub mrest_generate_response_html { 
    my ( $self ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_render_response_html (response generator)" );
    
    my $json = $self->mrest_generate_response_json;
    return $json if ref( $json ) eq 'SCALAR';

    my $msgobj = $CELL->msg( 
        'MREST_RESPONSE_HTML', 
        $site->MREST_APPLICATION_MODULE,
        $json,
    );
    my $entity = $msgobj
        ? $msgobj->text
        : '<html><body><h1>Internal Error</h1><p>See Resource.pm->_render_response_html</p></body></html>';

    $self->response->header('Content-Type' => 'text/html' );
    $self->response->content( $entity );

    return $entity;
}


=head2 content_types_accepted

L<Web::Machine> calls this routine to determine how to handle the request
body (e.g. in PUT requests).

=cut
 
sub content_types_accepted { 
    my $self = shift;
    my @caller = caller;
    $log->debug("Entering " . __PACKAGE__ . "::content_types_accepted, caller is " . Dumper( \@caller ) );

    return [ { 'application/json' => 'mrest_process_request_json' }, ] 
}


=head2 mrest_process_request_json

PUT and POST requests may contain a request body. This is the "handler
function" where we process those requests.

We associate this function with 'application/json' via
C<content_types_accepted>.

=cut

sub mrest_process_request_json {
    my $self = shift;
    my @caller = caller;
    $log->debug("Entering " . __PACKAGE__ . "::mrest_process_request_json, caller is " . Dumper( \@caller ) );

    # convert body to JSON
    my ( $from_json, $status );
    try {
        my $content = $self->request->content;
        if ( ! defined $content or $content eq '' ) {
            $log->debug( "There is no request body, assuming JSON null" );
            $content = 'null';
        }
        $log->debug( "Attempting to decode JSON request entity $content" );
        $from_json = $JSON->decode( $content );
        $log->debug( "Success" );
    } catch {
        $status = \400;
        $log->error( "Caught JSON decode error; response code should be " . $$status );
        $self->mrest_declare_status( 'code' => $$status, explanation => $_ );
    };
    return $status if ref( $status ) eq 'SCALAR';
    $self->push_onto_context( { 'request_entity' => $from_json } );

    return $self->mrest_generate_response;
}


=head2 mrest_process_request

Used to call the request handler manually in cases when L<Web::Machine> does
not call it for us.

=cut

sub mrest_process_request {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::mrest_process_request" );
    my $handler = $self->get_acceptable_content_type_handler;
    if ( ref( $handler ) eq 'SCALAR' ) {
        $self->mrest_declare_status( code => $$handler, 
            explanation => 'Could not get acceptable content type handler' );
        return $CELL->status_not_ok;
    }
    $log->debug( "acceptable request handler is: " . Dumper( $handler ) );
    return $self->$handler;
}


=head2 mrest_generate_response_json

First, run pass 2 of the resource handler, which is expected to return an
App::CELL::Status object. Second, push that object onto the context. Third,
convert that object into JSON and push the JSON onto the context, too. Return
the JSON representation of the App::CELL::Status object - this becomes the
HTTP response entity.

=cut

sub mrest_generate_response_json {
    my ( $self ) = @_;
    my ( $d, %h, $before, $after, $after_utf8 );
    my @caller = caller;
    $log->debug( "Entering " . __PACKAGE__ . "::mrest_generate_response_json, caller is " .
        Dumper( \@caller ) );

    # run the handler
    my $handler = $self->context->{'handler'}; # WWWW
    $log->debug( "mrest_generate_response_json: Calling resource handler $handler for pass two" );
    my ( $status, $response_obj, $entity );
    try {
        $status = $self->$handler(2);
        if ( ( my $reftype = ref( $status ) ) ne 'App::CELL::Status' ) {
            die "AAAAHAGGHG! Handler $handler, pass two, returned a ->$reftype<-, " . 
                "which is not an App::CELL::Status object!";
        }
        if ( $status->not_ok and ! $self->status_declared ) {
            $status->{'http_code'} = 500;
            $self->mrest_declare_status( $status );
        }
        $response_obj = $status->expurgate;
        $entity = $JSON->encode( $response_obj );
    } catch {
        if ( ! $self->status_declared ) {
            $self->mrest_declare_status( code => 500, explanation => $_ );
        }
        my $code = $self->mrest_declared_status_code;
        $code += 0;
        $status = \$code;
    };
    $log->debug( "response generator returned " . Dumper( $status ) );
    return $status if ref( $status ) eq 'SCALAR';

    # for PUT requests, we need a Location header if a new resource was created
    if ( $self->context->{'method'} eq 'PUT' ) {
        my $headers = $self->response->headers;
        my $uri_path = $self->context->{'uri_path'};
        $headers->header( 'Location' => $uri_path ) unless $self->context->{'resource_exists'};
    }

    # stage the status object to become the response entity
    $self->push_onto_context( { 
        'handler_status' => $status,
        'response_object' => $response_obj,
        'response_entity' => $entity,
    } );

    # put the entity into the response
    $self->response->header('Content-Type' => 'application/json' );
    $self->response->content( $entity );

    $log->debug( "Response will be: " . $self->response->content );

    return $entity;
}


=head2 mrest_generate_response

This should somehow get the response handler and run it.

=cut

sub mrest_generate_response {
    my $self = shift;
    return $self->mrest_generate_response_json;
}


1;
