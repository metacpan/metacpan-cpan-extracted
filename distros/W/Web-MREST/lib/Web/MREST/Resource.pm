# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
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
# This package defines how our web server handles the request-response 
# cycle. All the "heavy lifting" is done by Web::Machine and Plack.
# ------------------------

package Web::MREST::Resource;

use strict;
use warnings;
use feature "state";

use App::CELL qw( $CELL $log $meta $site );
use App::CELL::Status;
use Data::Dumper;
use JSON;
use Params::Validate qw( :all );
use Plack::Session;
use Try::Tiny;
use Web::MREST::InitRouter qw( $router );
use Web::MREST::Util qw( $JSON );

# methods/attributes not defined in this module will be inherited from:
use parent 'Web::Machine::Resource';

# use this to muffle debug messages in parts of the FSM
my %muffle = (
    '1' => 0,
    '2' => 1,
    '3' => 1,
    '4' => 1,
    '5' => 0,
);

=head1 NAME

App::MREST::Resource - HTTP request/response cycle




=head1 SYNOPSIS

In C<YourApp/Resource.pm>:

    use parent 'Web::MREST::Resource';

In PSGI file:

    use Web::Machine;

    Web::Machine->new(
        resource => 'App::YourApp::Resource',
    )->to_app;

It is important to understand that the L<Web::Machine> object created is
actually blessed into C<YourApp::Resource>. The line of inheritance is:

    YourApp::Resource 
        -> Web::MREST::Resource 
            -> Web::Machine::Resource
                -> Plack::Component




=head1 DESCRIPTION

Your application should not call any of the routines in this module directly.
They are called by L<Web::Machine> during the course of request processing.
What your application can do is provide its own versions of selected routines.



=head1 METHODS


=head2 Context methods

Methods for manipulating the context, a hash where we accumulate information
about the request.


=head3 context

Constructor/accessor

=cut

sub context {
    my $self = shift;
    $self->{'context'} = shift if @_;
    if ( ! $self->{'context'} ) {
        $self->{'context'} = {};
    }
    return $self->{'context'};
}


=head3 push_onto_context

Takes a hashref and "pushes" it onto C<< $self->{'context'} >> for use later
on in the course of processing the request.

=cut

sub push_onto_context {
    my $self = shift;
    my ( $hr ) = validate_pos( @_, { type => HASHREF } );

    my $context = $self->context;
    foreach my $key ( keys %$hr ) {
        $context->{$key} = $hr->{$key};
    }
    $self->context( $context );
}


=head2 Status declaration methods

Although L<Web::Machine> takes care of setting the HTTP response status code,
but when we have to override L<Web::Machine>'s value we have this "MREST
declared status" mechanism, which places a C<declared_status> property in
the context. During finalization, the HTTP status code placed in this
property overrides the one L<Web::Machine> came up with.


=head3 mrest_declare_status

This method takes either a ready-made L<App::CELL::Status> object or,
alternatively, a PARAMHASH. In the former case, an HTTP status code can be
"forced" on the response by including a C<http_code> property in the
object. In the latter case, the following keys are recognized (and all of
them are optional):

=over

=item level

L<App::CELL::Status> level, can be any of the strings accepted by that module.
Defaults to 'ERR'.

=item code

The HTTP status code to be applied to the response. Include this only if you 
need to override the code set by L<Web::Machine>.

=item explanation

Text explaining the status - use this to comply with RFC2616. Defaults to '<NONE>'.

=item permanent

Boolean value for error statuses, specifies whether or not the error is
permanent - use this to comply with RFC2616. Defaults to true.

=back

=cut

sub mrest_declare_status {
    my $self = shift;
    my @ARGS = @_;
    my @caller = caller;
    $log->debug( "Entering " . __PACKAGE__ . "::mrest_declare_status with argument(s) " .
        Dumper( \@ARGS ) . "\nCaller: " . Dumper( \@caller ) );

    # if status gets declared multiple times, keep only the first one
    if ( exists $self->context->{'declared_status'} ) {
        $log->notice( 
            "Cowardly refusing to overwrite previously declared status with this one: " . 
            Dumper( \@ARGS ) 
        );
        return;
    }

    my $declared_status;

    if ( @ARGS and ref( $ARGS[0] ) eq 'App::CELL::Status' ) {

        #
        # App::CELL::Status object was given; bend it to our needs
        #
        $declared_status = $ARGS[0];

        # make sure there is a payload and it is a hashref
        if ( ! $declared_status->payload ) {
            $declared_status->payload( {} );
        }

        # if 'http_code' property given, move it to the payload
        if ( my $hc = delete( $declared_status->{'http_code'} ) ) {
            $log->debug( "mrest_declare_status: HTTP code is $hc" );
            $declared_status->payload->{'http_code'} = $hc;
        }

        # handle 'permanent' property
        if ( my $pt = delete( $declared_status->{'permanent'} ) ) {
            $declared_status->payload->{'permanent'} = $pt ? JSON::true : JSON::false;
        } else {
            $declared_status->payload->{'permanent'} = JSON::true;
        }

    } else {

        #
        # PARAMHASH was given
        #
        my %ARGS = validate( @ARGS, {
            'level' => { type => SCALAR, default => 'ERR' },
            'code' => { type => SCALAR|UNDEF, default => undef },
            'explanation' => { type => SCALAR, default => '<NONE>' },
            'permanent' => { type => SCALAR, default => 1 },
            'args' => { type => ARRAYREF, optional => 1 },
        } );
        $ARGS{'args'} = [] unless $ARGS{'args'};
        $declared_status = App::CELL::Status->new(
            level => $ARGS{'level'},
            code => $ARGS{'explanation'},
            args => $ARGS{'args'},
            payload => {
                http_code => $ARGS{'code'},  # might be undef
                permanent => ( $ARGS{'permanent'} )
                    ? JSON::true
                    : JSON::false,
            },
        );

    }

    # add standard properties to the payload
    $declared_status->payload->{'uri_path'} = $self->context->{'uri_path'};
    $declared_status->payload->{'resource_name'} = $self->context->{'resource_name'};
    $declared_status->payload->{'http_method'} = $self->context->{'method'};
    $declared_status->payload->{'found_in'} = {
        package => (caller)[0],
        file => (caller)[1],
        line => (caller)[2]+0,
    };

    # the object is "done": push it onto the context
    $self->push_onto_context( {
        'declared_status' => $declared_status,
    } );
}


=head3 mrest_declared_status_code

Accessor method, gets just the HTTP status code (might be undef);
and allows setting the HTTP status code, as well, by providing an argument.

=cut

sub mrest_declared_status_code {
    my ( $self, $arg ) = @_;
    return unless ref( $self->context->{'declared_status'} ) eq 'App::CELL::Status';

    my $dsc = $self->context->{'declared_status'}->payload->{'http_code'};

    if ( $arg ) {
        $log->warn( "Overriding previous declared status code ->" .
            ( $dsc || 'undefined' ) .
            "<- with new value -> " .
            ( $arg || 'undefined' ) .
            "<->" );
        $self->context->{'declared_status'}->payload->{'http_code'} = $arg;
        $dsc = $arg;
    } 

    return $dsc;
}


=head3 mrest_declared_status_explanation

Accessor method, gets just the explanation (might be undef).
Does not allow changing the explanation - for this, nullify the 
declared status and declare a new one.

=cut

sub mrest_declared_status_explanation {
    my ( $self, $arg ) = @_;
    return unless ref( $self->context->{'declared_status'} ) eq 'App::CELL::Status';

    return $self->context->{'declared_status'}->text;
}

=head2 status_declared

Boolean method - checks context for presence of 'declared_status' property. If 
it is present, the value of that property is returned, just as if we had done
C<< $self->context->{'declared_status'} >>. Otherwise, undef (false) is returned.

=cut

sub status_declared {
    my $self = shift;
    if ( my $declared_status_object = $self->context->{'declared_status'} ) {
        #$log->debug( "Declared status: " . Dumper( $declared_status_object ) );
        if ( ref( $declared_status_object ) ne 'App::CELL::Status' ) {
            die "AAAHAAHAAA! Declared status object is not an App::CELL::Status!";
        }
        return $declared_status_object;
    }
    return;
}


=head2 declared_status

Synonym for C<status_declared>

=cut

sub declared_status {
    my $self = shift;
    return $self->status_declared;
}


=head2 nullify_declared_status

This method nullifies any declared status that might be pending.

=cut

sub nullify_declared_status {
    my $self = shift;
    $log->debug( "Nullifying declared status: " . Dumper( $self->context->{'declared_status'} ) );
    delete $self->context->{'declared_status'};
    return;
}


=head2 FSM Part One

The following methods override methods defined by L<Web::Machine::Resource>.
They correspond to what the L<Web::MREST> calls "Part One" of the FSM. To muffle
debug-level log messages from this part of the FSM, set $muffle{1} = 1 (above).


=head3 service_available (B13)

This is the first method called on every incoming request.

=cut

sub service_available {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::service_available (B13)" ) unless $muffle{1};

    $self->init_router unless ref( $router ) and $router->can( 'match' );

    my $path = $self->request->path_info;
    $path =~ s{^\/}{};
    my $reported_path = ( $path eq '' )
        ? 'the root resource'
        : $path;
    $log->info( "Incoming " . $self->request->method . " request for $reported_path" );
    $log->info( "Self is a " . ref( $self ) );
    $self->push_onto_context( { 
        'headers' => $self->request->headers,
        'request' => $self->request,
        'uri_path' => $path,
        'method' => $self->request->method,
    } );
    return $self->mrest_service_available;
}


=head3 mrest_service_available

Hook. If you overlay this and intend to return false, you should call 
C<< $self->mrest_declare_status >> !!

=cut

sub mrest_service_available {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::mrest_service_available" ) unless $muffle{1};
    return 1;
}


=head3 known_methods (B12)

Returns the value of C<MREST_SUPPORTED_HTTP_METHODS> site parameter

=cut

sub known_methods {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::known_methods (B12)" ) unless $muffle{1};

    my $method = $self->context->{'method'};
    my $known_methods = $site->MREST_SUPPORTED_HTTP_METHODS || [ qw( GET POST PUT DELETE ) ];
    $log->debug( "The known methods are " . Dumper( $known_methods ) ) unless $muffle{1};

    if ( ! grep { $method eq $_; } @$known_methods ) {
        $log->debug( "$method is not among the known methods" ) unless $muffle{1};
        $self->mrest_declare_status( explanation => "The request method $method is not one of the supported methods " . join( ', ', @$known_methods ) );
    }
    return $known_methods;
}


=head3 uri_too_long (B11)

Is the URI too long?

=cut

sub uri_too_long {
    my ( $self, $uri ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::uri_too_long (B11)" ) unless $muffle{1};

    my $max_len = $site->MREST_MAX_LENGTH_URI || 100;
    $max_len += 0;
    if ( length $uri > $max_len ) {
        $self->mrest_declare_status;
        return 1;
    }

    $self->push_onto_context( { 'uri' => $uri } );

    return 0;
}



=head3 allowed_methods (B10)

Determines which HTTP methods we recognize for this resource. We return these
methods in an array. If the requested method is not included in the array,
L<Web::Machine> will return the appropriate HTTP error code.

RFC2616 on 405: "The response MUST include an Allow header containing a list of
valid methods for the requested resource." -> this is handled by Web::Machine,
but be aware that if the methods arrayref returned by allowed_methods does
not include the current request method, allow_methods gets called again.

=cut

sub allowed_methods { 
    my ( $self ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::allowed_methods (B10)" ) unless $muffle{1};

    #
    # Does the URI match a known resource?
    #
    my $path = $self->context->{'uri_path'};
    my $method = uc $self->context->{'method'};
    $log->debug( "allowed_methods: path is $path, method is $method" ) unless $muffle{1};
    if ( my $match = $router->match( $path ) ) {
        # path matches resource, but is it defined for this method?
        #$log->debug( "match object: " . Dumper( $match ) );

        my $resource_name = $match->route->target->{'resource_name'};
        $resource_name = ( defined $resource_name )
            ? $resource_name
            : 'NONE_AAGH!';
        $self->push_onto_context( {
            'match_obj' => $match,
            'resource_name' => $resource_name 
        } );
        $log->info( "allowed_methods: $path matches resource ->$resource_name<-" );

        my ( $def, @allowed_methods ) = $self->_extract_allowed_methods( $match->route->target );
        if ( $def ) {
            # method is allowed for this resource; push various values onto the context for later use
            $self->_stash_resource_info( $match );
            $self->_get_handler( $def );
        } else {
            # method not allowed for this resource
            $self->mrest_declare_status( 'explanation' => "Method not allowed for this resource" );
            return \@allowed_methods;
        }

        if ( $self->status_declared ) {
            # something bad happened
            return [];
        }

        # success 
        return \@allowed_methods;

    }
    # if path does not match, return an empty arrayref, which triggers a 405 status code
    $self->mrest_declare_status( 'code' => 400, 'explanation' => "URI does not match a known resource" );
    return []; 
}


sub _extract_allowed_methods {
    my ( $self, $target ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_extract_allowed_methods" ) unless $muffle{1};
    #$log->debug( "Target is: " . Dumper( $target ) );

    # ---------------------------------------------------------------
    # FIXME: need to come up with a more reasonable way of doing this
    # ---------------------------------------------------------------
    #
    # The keys of the $route->target hash are the allowed methods plus:
    # - 'resource_name'
    # - 'parent'
    # - 'children'
    # - 'documentation'
    #
    # So, using set theory we can say that the set of allowed methods
    # is equal to the set of $route->target hash keys MINUS the set
    # of keys listed above. (This is fine until someone decides to 
    # add another key to a resource definition and forgets to add it 
    # here as well.)
    #
    # ---------------------------------------------------------------

    my @allowed_methods;
    foreach my $method ( keys %{ $target } ) {
        push( @allowed_methods, $method ) unless $method =~ m/(resource_name)|(parent)|(children)|(documentation)/;
    }
    $log->debug( "Allowed methods are " . join( ' ', @allowed_methods ) ) unless $muffle{1};

    return ( $target->{ $self->context->{'method'} }, @allowed_methods );
}


sub _stash_resource_info {
    my ( $self, $match ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_stash_resource_info" ) unless $muffle{1};

    # N.B.: $uri is the base URI, not the path
    my $uri = $site->MREST_URI
        ? $site->MREST_URI
        : $self->request->base->as_string;

    my $push_hash = { 
        'mapping' => $match->mapping,       # mapping contains values of ':xyz' parts of path
        'uri_base' => $uri,                      # base URI of the REST server
        'components' => $match->route->components, # resource components
    };
    $self->push_onto_context( $push_hash );
    #$log->debug( "allowed_methods: pushed onto context " . Dumper( $push_hash ) );
}


sub _get_handler {
    my ( $self, $def ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_get_handler with resource definition: " . Dumper( $def ) ) unless $muffle{1};

    # be idempotent
    if ( my $handler_from_context = $self->context->{'handler'} ) {
        return $handler_from_context;
    }

    my $status = 0;
    my $handler_name;
    if ( $handler_name = $def->{'handler'} ) {
	# $handler_name is the name of a method that will hopefully be callable
	# by doing $self->$handler_name
        $self->push_onto_context( {
            'handler' => $handler_name,
        } );
    } else {
       $status = "No handler defined for this resource+method combination!";
    }
    if ( $status ) {
        $self->mrest_declare_status( 'code' => '500', explanation => $status );
        $log->err( "Leaving _get_handler with status $status" );
    } else {
        $log->info( "Leaving _get_handler (all green) - handler is ->$handler_name<-" );
    }
}
  

=head3 malformed_request (B9)

A true return value from this method aborts the FSM and triggers a "400 Bad
Request" response status.

=cut

sub malformed_request {
    my ( $self ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::malformed_request (B9)" ) unless $muffle{1};

    # we examing the request body on PUT and POST only (FIXME: make this configurable)
    my $method = $self->context->{'method'};
    return 0 unless $method =~ m/^(PUT)|(POST)$/;
    #$log->debug( "Method is $method" );

    # get content-type and content-length
    my $content_type = $self->request->headers->header('Content-Type');
    $content_type = '<NONE>' unless defined( $content_type );
    my $content_length = $self->request->headers->header('Content-Length');
    $content_length = '<NONE>' unless defined( $content_length );
    #$log->debug( "Content-Type: $content_type, Content-Length: $content_length" );

    # no Content-Type and/or no Content-Length, yet request body present ->
    # clearly a violation
    if ( $self->request->content ) {
        if ( $content_type eq '<NONE>' or $content_length eq '<NONE>' ) {
            $self->mrest_declare_status( 
                explanation => 'no Content-Type and/or no Content-Length, yet request body present' 
            );
            return 1;
        }
    }

    $self->push_onto_context( { 'headers' => 
        {
            'content-length' => $content_length,
            'content-type' => $content_type,
        } 
    } );

    return $self->mrest_malformed_request;
}


=head3 mrest_malformed_request

Hook

=cut

sub mrest_malformed_request {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::mrest_malformed_request (B9)" ) unless $muffle{1};
    
    return 0;
}


=head3 is_authorized (B8)

Authentication method - should be implemented in the application.

=cut

sub is_authorized {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::is_authorized (B8)" ) unless $muffle{1};
    return 1;
}


=head3 forbidden (B7)

Authorization method - should be implemented in the application.

=cut

sub forbidden {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::forbidden (B7)" ) unless $muffle{1};
    return 0;
}


=head3 valid_content_headers (B6)

Receives a L<Hash::MultiValue> object containing all the C<Content-*> headers
in the request. Checks these against << $site->MREST_VALID_CONTENT_HEADERS >>,
returns false if the check fails, true if it passes.

=cut

sub valid_content_headers {
    my ( $self, $content_headers ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::valid_content_headers (B6)" ) unless $muffle{1};
    $log->debug( "Content headers: " . join( ', ', keys( %$content_headers ) ) ) unless $muffle{1};

    # get site param 
    my $valid_content_headers = $site->MREST_VALID_CONTENT_HEADERS;
    die "AAAAAHAHAAAAAHGGGG!! \$valid_content_headers is not an array reference!!" 
       unless ref( $valid_content_headers ) eq 'ARRAY';

    # check these content headers against it 
    my $valids = _b6_make_hash( $valid_content_headers );
    foreach my $content_header ( keys( %$content_headers ) ) {
        if ( not exists $valids->{$content_header} ) {
            $self->mrest_declare_status( explanation => 
                "Content header ->$content_header<- not found in MREST_VALID_CONTENT_HEADERS"
            );
            return 0;
        }
    }
    return 1;
}

sub _b6_make_hash {
    my $ar = shift;
    my %h;
    foreach my $chn ( @$ar ) {
        $chn = 'Content-' . $chn unless $chn =~ m/^Content-/;
        $h{ $chn } = '';
    }
    return \%h;
}


=head3 known_content_type (B5)

The assumption for C<PUT> and C<POST> requests is that they might have an
accompanying request entity, the type of which should be declared via a
C<Content-Type> header. If the content type is not recognized by the
application, return false from this method to trigger a "415 Unsupported Media
Type" response.

The basic content-types (major portions only) accepted by the application
should be listed in C<< $site->MREST_SUPPORTED_CONTENT_TYPES >>. Override this
method if that's not good by you.

=cut

sub known_content_type {
    my ( $self, $content_type ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::known_content_type (B5)" ) unless $muffle{1};

    return 1 if not $content_type;

    # if $content_type is a blessed object, deal with that
    my $ct_isa = ref( $content_type );
    if ( $ct_isa ) {
        $log->debug( "\$content_type is a ->$ct_isa<-" ) unless $muffle{1};
        if ( $ct_isa ne 'HTTP::Headers::ActionPack::MediaType' ) {
            $self->mrest_declare_status( code => '500', 
                explanation => "Bad content_type class ->$ct_isa<-" );
            return 0;
        }
        $content_type = $content_type->type; # convert object to string
    }

    $log->debug( "Content type of this request is ->$content_type<-" ) unless $muffle{1};

    # push it onto context
    $self->context->{'content_type'} = $content_type;

    # convert supported content types into a hash for easy lookup
    my %types = map { ( $_ => '' ); } @{ $site->MREST_SUPPORTED_CONTENT_TYPES };
    if ( exists $types{ $content_type } ) {
        $log->info( "$content_type is supported" );
        return 1;
    }
    $self->mrest_declare_status( explanation => "Content type ->$content_type<- is not supported" );
    return 0;
}


=head3 valid_entity_length (B4)

Called by Web::Machine with one argument: the length of the request 
body. Return true or false.

=cut

sub valid_entity_length {
    my ( $self, $body_len ) = @_;
    state $max_len = $site->MREST_MAX_LENGTH_REQUEST_ENTITY;
    $log->debug( "Entering " . __PACKAGE__ . "::valid_entity_length, maximum request entity length is $max_len" ) unless $muffle{1};
    $body_len = $body_len || 0;
    $log->info( "Request body is $body_len bytes long" );
    
    if ( $body_len > $max_len ) {
        $self->mrest_declare_status( explanation => "Request body is $body_len bytes long, which exceeds maximum length set in \$site->MREST_MAX_LENGTH_REQUEST_ENTITY" );
        return 0;
    }
    return 1;
}


=head3 charsets_provided

This method causes L<Web::Machine> to encode the response body (if any) in
UTF-8. 

=cut

sub charsets_provided { 
    return [ qw( UTF-8 ) ]; 
}


#=head3 default_charset
#
#Really use UTF-8 all the time.
#
#=cut
#
#sub default_charset { 'utf8'; }


=head2 FSM Part Two (Content Negotiation)

See L<Web::MREST::Entity>.


=head2 FSM Part Three (Resource Existence)


=head2 resource_exists (G7)

The initial check for resource existence is the URI-to-resource mapping, 
which has already taken place in C<allowed_methods>. Having made it to here,
we know that was successful. 

So, what we do here is call the handler function, which is expected to 
return an L<App::CELL::Status> object. How this status is interpreted is
left up to the application: we pass the status object to the
C<mrest_resource_exists> method, which should return either true or false.

For GET and POST, failure means 404 by default, but can be overrided 
by calling C<mrest_declare_status> from within C<mrest_resource_exists>.

For PUT, success means this is an update operation and failure means insert.

For DELETE, failure means "202 Accepted" - i.e. a request to delete a
resource that doesn't exist is accepted, but nothing actually happens.

=cut 

sub resource_exists {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::resource_exists" );
    #$log->debug( "Context is " . Dumper( $self->context ) );
    
    # no handler is grounds for 500
    if ( not exists $self->context->{'handler'} ) {
        $self->mrest_declare_status( code => '500', 
            explanation => 'AAAAAAAAAAGAHH!!! In resource_exists, no handler/mapping on context' );
        return 0; 
    }

    #
    # run handler (first pass) and push result onto context
    #
    my $handler = $self->context->{'handler'};
    $log->debug( "resource_exists: Calling resource handler $handler for the first time" );
    my $bool;
    try {
        $bool = $self->$handler(1);
    } catch {
        $self->mrest_declare_status( code => 500, explanation => $_ );
        $bool = 0;
    };
    $self->push_onto_context( { 'resource_exists' => $bool } );
    return 1 if $bool;

    # Application thinks the resource doesn't exist. Return value will be
    # 0. For GET and DELETE, this should trigger 404 straightaway: make
    # sure the status is declared so we don't send back a bare response.
    # For POST, the next method will be 'allow_missing_post'.
    # For PUT, it will be ...?...

    if ( not $self->status_declared ) {
        my $method = $self->context->{'method'};
        my $explanation = "Received request for non-existent resource";
        if ( $method eq 'GET' ) {
            # 404 will be assigned by Web::Machine
            $self->mrest_declare_status( 'explanation' => $explanation );
        } elsif ( $method eq 'DELETE' ) {
            # for DELETE, Web::Machine would ordinarily return a 202 so
            # we override that
            $self->mrest_declare_status( 'code' => 404, 'explanation' => $explanation );
        }
    }
    return 0;
}


=head2 allow_missing_post

If the application wishes to allow POST to a non-existent resource, this
method will need to be overrided.

=cut

sub allow_missing_post {
    my ( $self ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::allow_missing_post" );

    # we do not allow POST to a non-existent resource, so we declare 404
    $self->mrest_declare_status( 'code' => 404, explanation => 
        'Detected attempt to POST to non-existent resource' ) unless $self->status_declared;

    return 0;
}


=head2 post_is_create

=cut

sub post_is_create {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::post_is_create" );
    
    return $self->mrest_post_is_create;
}


=head2 mrest_post_is_create

Looks for a 'post_is_create' property in the context and returns
1 or 0, as appropriate.

=cut

sub mrest_post_is_create {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::mrest_post_is_create" );

    my $pic = $self->context->{'post_is_create'};
    if ( ! defined( $pic ) ) {
        $log->error( "post_is_create property is missing; defaults to false" );
        return 0;
    }
    if ( $pic ) {
        $log->info( "post_is_create property is true" );
        return 1;
    }
    $log->info( "post_is_create property is false" );
    return 0;
}


=head2 create_path

=cut

sub create_path {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::create_path" );

    # if there is a declared status, return a dummy value
    return "DUMMY" if $self->status_declared;

    return $self->mrest_create_path;
}


=head2 mrest_create_path

This should always return _something_ (never undef)

=cut

sub mrest_create_path {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::mrest_create_path" );

    my $create_path = $self->context->{'create_path'};
    if ( ! defined( $create_path ) ) {
        $site->mrest_declare_status( code => 500, 
            explanation => "Post is create, but create_path missing in handler status" );
        return 'ERROR';
    }
    $log->debug( "Returning create_path " . Dumper( $create_path ) );
    return $create_path;
}


=head2 create_path_after_handler

This is set to true so we can set C<< $self->context->{'create_path'} >> in the handler.

=cut

sub create_path_after_handler { 1 }



=head2 process_post

This is where we construct responses to POST requests that do not create
a new resource. Since we expect our resource handlers to "do the needful",
all we need to do is call the resource handler for pass two.

The return value should be a Web::Machine/HTTP status code
like, e.g., \200 - this ensures that Web::Machine does not attempt to 
encode the response body, as in our case this would introduce a double-
encoding bug.

=cut

sub process_post {
    my $self = shift;
    $log->debug("Entering " . __PACKAGE__ . "::process_post" );

    # Call the request handler.  This way is bad, because it ignores any
    # 'Accept' header provided in the request by the user agent. However, until
    # Web::Machine is patched we have no other way of knowing the request
    # handler's name so we have to hard-code it like this.
    #$self->_load_request_entity;
    #my $status = $self->mrest_process_request;
    #return $status if ref( $status ) eq 'SCALAR';
    #
    #return \200 if $self->context->{'handler_status'}->ok;
    #
    # if the handler status is not ok, there SHOULD be a declared status
    #return $self->mrest_declared_status_code || \500;

    my $status = $self->mrest_process_request;
    $log->debug( "Handler returned: " . Dumper( $status ) );
    return $status;
}


=head2 delete_resource

This method is called on DELETE requests and is supposed to tell L<Web::Machine>
whether or not the DELETE operation was enacted. In our case, we call the
resource handler (pass two).

=cut

sub delete_resource { 
    my $self = shift;
    $log->debug("Entering " . __PACKAGE__ . "::delete_resource");

    my $status = $self->mrest_generate_response;
    return 0 if ref( $status ) eq 'SCALAR' or $self->context->{'handler_status'}->not_ok;
    return 1;
};



=head2 finish_request

This overrides the Web::Machine method of the same name, and is called just
before the final response is constructed and sent. We use it for adding certain
headers in every response.

=cut

sub finish_request {
    my ( $self, $metadata ) = @_;
    state $http_codes = $site->MREST_HTTP_CODES;

    $log->debug( "Entering " . __PACKAGE__ . "::finish_request with metadata: " . Dumper( $metadata ) );

    if ( ! $site->MREST_CACHE_ENABLED ) {
        #
        # tell folks not to cache
        #
        $self->response->header( 'Cache-Control' => $site->MREST_CACHE_CONTROL_HEADER );
        $self->response->header( 'Pragma' => 'no-cache' );
    }

    #
    # when Web::Machine catches an exception, it sends us the text in the
    # metadata -- in practical terms, this means: if the metadata contains an
    # 'exception' property, something died somewhere
    #
    if ( $metadata->{'exception'} ) {
        my $exception = $metadata->{'exception'};
        $exception =~ s/\n//g;
        $self->mrest_declare_status( code => '500', explanation => $exception );
    }

    #
    # if there is a declared status, we assume that it contains the entire
    # intended response and clobber $self->response->content with it
    #
    if ( $self->status_declared ) {
        my $declared_status = $self->context->{'declared_status'};
        $log->debug( "finish_request: declared status is " . Dumper( $declared_status ) );
        if ( ! $declared_status->payload->{'http_code'} ) {
            $declared_status->payload->{'http_code'} = $self->response->code;
        } else {
            $self->response->code( $declared_status->payload->{'http_code'} );
        }
        my $json = $JSON->encode( $declared_status->expurgate );
        $self->response->content( $json ); 
        $self->response->header( 'content-length' => length( $json ) );
    }

    # The return value is ignored, so any effect of this method must be by
    # modifying the response.
    $log->debug( "Response finalized: " . Dumper( $self->response ) );
    return; 
} 

1;

