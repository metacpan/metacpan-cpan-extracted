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
# This package contains handlers.
# ------------------------

package Web::MREST::Dispatch;

use strict;
use warnings;
use feature "state";

use App::CELL qw( $CELL $log $core $meta $site );
use Data::Dumper;
use Exporter qw( import );
use Module::Runtime qw( use_module );
use Params::Validate qw( :all );
use Web::MREST::InitRouter qw( $router $resources );
use Web::MREST::Util qw( pod_to_html pod_to_text );

use parent 'Web::MREST::Entity';

=head1 NAME

App::MREST::Dispatch - Resource handlers




=head1 DESCRIPTION

Your application should not call any of the routines in this module directly.
They are called by L<Web::MREST::Resource> during the course of request processing.
What your application can do is provide its own resource handlers.

The resource handlers are called as ordinary functions with a sole argument:
the MREST context.

=cut



=head1 INITIALIZATION/RESOURCE DEFINITIONS

In this section we provide definitions of all resources handled by this module.
These are picked up by L<Web::MREST::InitRouter>.

=cut

our @EXPORT_OK = qw( init_router );
our $resource_defs = {

        # root resource
        '/' => {
            handler => 'handler_noop',
            description => 'The root resource',
            documentation => <<'EOH',
=pod

This resource is the parent of all resources that do not specify
a parent in their resource definition.
EOH
        },
    
        # bugreport
        'bugreport' => 
        {
            parent => '/',
            handler => {
                GET => 'handler_bugreport',
            },
            cli => 'bugreport',
            description => 'Display instructions for reporting bugs in Web::MREST',
            documentation => <<'EOH',
=pod

Returns a JSON structure containing instructions for reporting bugs.
EOH
        },
    
        # configinfo
        'configinfo' =>
        {
            parent => '/',
            handler => {
                GET => 'handler_configinfo',
            },
            cli => 'configinfo',
            description => 'Display information about Web::MREST configuration',
            documentation => <<'EOH',
=pod

Returns a list of directories that were scanned for configuration files.
EOH
        },
    
        # docu
        'docu' => 
        { 
            parent => '/',
            handler => 'handler_noop',
            cli => 'docu',
            description => 'Access on-line documentation (via POST to appropriate subresource)',
            documentation => <<'EOH',
=pod

This resource provides access to on-line documentation through its
subresources: 'docu/pod', 'docu/html', and 'docu/text'.

To get documentation on a resource, send a POST reqeuest for one of
these subresources, including the resource name in the request
entity as a bare JSON string (i.e. in double quotes).
EOH
        },
    
        # docu/pod
        'docu/pod' => 
        {
            parent => 'docu',
            handler => {
                POST => 'handler_docu', 
            },
            cli => 'docu pod $RESOURCE',
            description => 'Display POD documentation of a resource',
            documentation => <<'EOH',
=pod
        
This resource provides access to on-line help documentation in POD format. 
It expects to find a resource name (e.g. "employee/eid/:eid" including the
double-quotes, and without leading or trailing slash) in the request body. It
returns a string containing the POD source code of the resource documentation.
EOH
        },
    
        # docu/html
        'docu/html' => 
        { 
            parent => 'docu',
            handler => {
                POST => 'handler_docu', 
            },
            cli => 'docu html $RESOURCE',
            description => 'Display HTML documentation of a resource',
            documentation => <<'EOH',
=pod

This resource provides access to on-line help documentation. It expects to find
a resource name (e.g. "employee/eid/:eid" including the double-quotes, and without
leading or trailing slash) in the request body. It generates HTML from the 
resource documentation's POD source code.
EOH
        },
    
        # docu/text
        'docu/text' =>
        { 
            parent => 'docu',
            handler => {
                POST => 'handler_docu', 
            },
            cli => 'docu text $RESOURCE',
            description => 'Display resource documentation in plain text',
            documentation => <<'EOH',
=pod

This resource provides access to on-line help documentation. It expects to find
a resource name (e.g. "employee/eid/:eid" including the double-quotes, and without
leading or trailing slash) in the request body. It returns a plain text rendering
of the POD source of the resource documentation.
EOH
        },
    
        # echo
        'echo' => 
        {
            parent => '/',
            handler => {
                POST => 'handler_echo', 
            },
            cli => 'echo [$JSON]',
            description => 'Echo the request body',
            documentation => <<'EOH',
=pod

This resource simply takes whatever content body was sent and echoes it
back in the response body.
EOH
        },
    
        # noop
        'noop' =>
        { 
            parent => '/',
            handler => 'handler_noop', 
            cli => 'noop',
            description => 'A resource that does nothing',
            documentation => <<'EOH',
=pod

Regardless of anything, this resource does nothing at all.
EOH
        },
    
        # param/:type/:param
        'param/:type/:param' => 
        {
            parent => '/',
            handler => {
                'GET' => 'handler_param',
                'PUT' => 'handler_param',
                'DELETE' => 'handler_param',
            },
            cli => {
                'GET' => 'param $TYPE $PARAM',
                'PUT' => 'param $TYPE $PARAM $VALUE',
                'DELETE' => 'param $TYPE $PARAM', 
            },
            description => {
                'GET' => 'Display value of a meta/core/site parameter',
                'PUT' => 'Set value of a parameter (meta only)',
                'DELETE' => 'Delete a parameter (meta only)',
            },
            documentation => <<'EOH',
=pod

This resource can be used to look up (GET) meta, core, and site parameters, 
as well as to set (PUT) and delete (DELETE) meta parameters.
EOH
            validations => {
                'type' => qr/^(meta)|(core)|(site)$/,
                'param' => qr/^[[:alnum:]_][[:alnum:]_-]+$/,
            },
        },
    
        # test/?:specs
        'test/?:specs' =>
        {
            parent => '/',
            handler => 'handler_test',
            cli => 'test [$SPECS]',
            description => "Resources for testing resource handling semantics",
        },
    
        # version
        'version' =>
        { 
            parent => '/',
            handler => {
                GET => 'handler_version', 
            },
            cli => 'version',
            description => 'Display application name and version',
            documentation => <<'EOH',
=pod

Shows the software version running on the present instance. The version displayed
is taken from the C<$VERSION> package variable of the package specified in the
C<MREST_APPLICATION_MODULE> site parameter.
EOH
        },

    };



=head1 FUNCTIONS

=cut

=head2 init_router

Initialize (populate) the router. Called from Resource.pm when the first
request comes waltzing in.

=cut

sub init_router {
    $log->debug("Entering " . __PACKAGE__. "::init_router");
    #
    # initialize Path::Router singleton
    #
    $router = Path::Router->new unless ref( $router ) and $router->can( 'match' );
    #
    # load resource definitions
    #
    Web::MREST::InitRouter::load_resource_defs( $resource_defs );
    # ... might need to be called multiple times ...
}


=head2 _first_pass_always_exists

Boilerplate code for use in handlers of resources that always exist

=cut

sub _first_pass_always_exists {
    my ( $self, $pass ) = @_;

    if ( $pass == 1 ) {
        $log->debug( "Resource handler first pass, resource always exists" );
        return 1;
    }
    return 0;
}


=head2 handler_bugreport

Handler for the C<bugreport> resource.

=cut

sub handler_bugreport {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_bugreport, pass number $pass" );

    # first pass
    return 1 if $self->_first_pass_always_exists( $pass ); 

    # second pass
    return $CELL->status_ok( 'MREST_DISPATCH_BUGREPORT', 
        payload => { report_bugs_to => $site->MREST_REPORT_BUGS_TO },
    );
}


=head2 handler_configinfo

Handler for the C<configinfo> resource.

=cut

sub handler_configinfo {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_configinfo, pass number $pass" );

    # first pass
    return 1 if $self->_first_pass_always_exists( $pass ); 

    # second pass
    return $CELL->status_ok( 'MREST_DISPATCH_CONFIGINFO', 
        payload => $meta->CELL_META_SITEDIR_LIST,
    );
}


=head2 handler_docu

=cut

sub handler_docu {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_docu, pass number $pass" );

    # first pass
    return 1 if $self->_first_pass_always_exists( $pass ); 

    # '/docu/...' resources only

    # the resource to be documented should be in the request body - if not, return 400
    my $docu_resource = $self->context->{'request_entity'};
    if ( $docu_resource ) {
        $log->debug( "handler_docu: request body is ->$docu_resource<-" );
    } else {
        $self->mrest_declare_status( 'code' => 400, 'explanation' => 'Missing request entity' );
        return $CELL->status_not_ok;
    }

    # the resource should be defined - if not, return 404
    my $def = $resources->{$docu_resource};
    $log->debug( "handler_docu: resource definition is " . Dumper( $def ) );
    if ( ref( $def ) ne 'HASH' ) {
        $self->mrest_declare_status( 'code' => 404, 'explanation' => 'Undefined resource' );
        $log->debug( "Resource not defined: " . Dumper( $docu_resource ) );
        return $CELL->status_not_ok;
    }

    # all green - assemble the requested documentation
    my $method = $self->context->{'method'};
    my $resource_name = $self->context->{'resource_name'};
    my $pl = {
        'resource' => $docu_resource,
    };
    my $docs = $def->{'documentation'} || <<"EOH";
=pod

The definition of resource $docu_resource lacks a 'documentation' property 
EOH
    # if they want POD, give them POD; if they want HTML, give them HTML, etc.
    if ( $resource_name eq 'docu/pod' ) {
        $pl->{'format'} = 'POD';
        $pl->{'documentation'} = $docs;
    } elsif ( $resource_name eq 'docu/html' ) {
        $pl->{'format'} = 'HTML';
        $pl->{'documentation'} = pod_to_html( $docs );
    } else {
        # fall back to plain text
        $pl->{'format'} = 'text';
        $pl->{'documentation'} = pod_to_text( $docs );
    }
    return $CELL->status_ok( 'MREST_DISPATCH_ONLINE_DOCUMENTATION', payload => $pl );
}


=head2 handler_echo

Echo request body back in the response

=cut

sub handler_echo {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_echo, pass number $pass" );
    
    return 1 if $self->_first_pass_always_exists( $pass ); 

    # second call - just echo, nothing else
    return $CELL->status_ok( "ECHO_REQUEST_ENTITY", payload =>
       $self->context->{'request_entity'} );
}


=head2 handler_param

Handler for 'param/:type/:param' resource.

=cut

sub handler_param {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_param, pass number $pass" );

    # get parameters
    my $method = $self->context->{'method'};
    my $mapping = $self->context->{'mapping'};
    my ( $type, $param );
    if ( $mapping ) {
        $type = $self->context->{'mapping'}->{'type'};
        $param = $self->context->{'mapping'}->{'param'};
    } else {
        die "AAAHAHAHAAHAAHAAAAAAAA! no mapping?? in handler_param_get";
    }
    my $resource_name = $self->context->{'resource_name'};

    my ( $bool, $param_obj );
    if ( $type eq 'meta' ) {
        $param_obj = $meta;
    } elsif ( $type eq 'core' ) {
        $param_obj = $core;
    } elsif ( $type eq 'site' ) {
        $param_obj = $site;
    }
    if ( ! $param_obj) {
        $self->mrest_declare_status( code => '500', explanation => 'IMPROPER TYPE' );
        return 0;
    }

    # first pass
    if ( $pass == 1 ) {
        $bool = $param_obj->exists( $param );
        $bool = $bool ? 1 : 0;
        $self->context->{'stash'}->{'param_value'} = $param_obj->get( $param ) if $bool;
        return $bool;
    }

    # second pass
    if ( $type ne 'meta' and $method =~ m/^(PUT)|(DELETE)$/ ) {
        $self->mrest_declare_status( code => 400, explanation => 
            'PUT and DELETE can be used with meta parameters only' );
        return $CELL->status_not_ok;
    }
    if ( $method eq 'GET' ) {
        return $CELL->status_ok( 'MREST_PARAMETER_VALUE', payload => {
            $param => $self->context->{'stash'}->{'param_value'},
        } );
    } elsif ( $method eq 'PUT' ) {
        $log->debug( "Request entity: " . Dumper( $self->context->{'request_entity'} ) );
        return $param_obj->set( $param, $self->context->{'request_entity'} );
    } elsif ( $method eq 'DELETE' ) {
        delete $param_obj->{$param};
        return $CELL->status_ok( 'MREST_PARAMETER_DELETED', payload => {
            'type' => $type,
            'param' => $param,
        } );
    }
}


=head2 handler_noop

Generalized handler for resources that don't do anything.

=cut

sub handler_noop {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::noop" );

    # pass one
    return 1 if $self->_first_pass_always_exists( $pass ); 

    # pass two
    my $method = $self->context->{'method'};
    my $resource_name = $self->context->{'resource_name'};
    my $def = $resources->{$resource_name};
    my $pl = {
        'resource_name' => $resource_name,
        'description' => $def->{$method}->{'description'},
        'parent' => $def->{'parent'},
        'children' => $def->{'children'},
    };
    return $CELL->status_ok( 'MREST_DISPATCH_NOOP',
        payload => $pl
    );
}


=head2 handler_test

The only purpose of this resource is testing/demonstration of request
handling.

=cut

sub handler_test {
    my ( $self, $pass ) = @_;

    my $method = $self->context->{'method'};
    my $mapping = $self->context->{'mapping'};
    my $specs = $self->context->{'mapping'}->{'specs'} if $mapping;

    # first pass
    if ( $pass == 1 ) {
        my $re = 0;
        if ( not defined $specs ) {
            $log->debug( "handler_test: \$specs is missing and the resource exists" );
            $re = 1;
        } elsif ( $specs eq '0' ) {
            $log->debug( "handler_test: \$specs is ->$specs<- and the resource does not exist" );
        } else {
            $log->debug( "handler_test: \$specs is ->$specs<- and the resource exists" );
            $re = 1;
            if ( $method eq 'POST' ) {
                if ( $specs ne '1' ) {
                    $self->context->{'post_is_create'} = 1;
                    $self->context->{'create_path'} = $self->context->{'uri_path'};
                }
            }
        }
        return $re;
    }

    # second pass
    if ( $method eq 'GET' ) {
        return $self->_test_get( $specs );
    } elsif ( $method eq 'POST' ) {
        return $self->_test_post( $specs );
    } elsif ( $method eq 'PUT' ) {
        return $self->_test_put( $specs );
    } elsif ( $method eq 'DELETE' ) {
        return $self->_test_delete( $specs );
    } else {
        return $CELL->status_crit( 'ERROR_UNSUPPORTED_METHOD' );
    }
}

sub _test_get {
    my ( $self, $specs ) = @_;

    my $status = $CELL->status_ok( 'TEST_GET_RESOURCE' );
    $status->payload( 'DUMMY' );
    return $status;
}

sub _test_post {
    my ( $self, $specs ) = @_;
    # $specs cannot be 0, but can be anything else, including undef
    # we interpret the values '1' and undef to mean post_is_create is false

    my $status;
    if ( not defined $specs or $specs eq '1' ) {
        # this post does not create a new resource
        $status = $CELL->status_ok( 'TEST_POST_OK' );
        $self->context->{'post_is_create'} = 0;
    } elsif ( $specs eq '0' ) {
        # already handled in caller
        die "AAAADAHDDAAAAADDDDGGAAAA!";
    } else {
        # pretend that this POST creates a new resource
        $status = $CELL->status_ok( 'TEST_POST_IS_CREATE' );
    }
    $status->payload( 'DUMMY' );
    return $status;
}

sub _test_put {
    my ( $self, $specs ) = @_;
    my $bool = $specs ? 1 : 0;

    my $status;
    if ( $specs ) {
        # pretend that the resource already existed
        $status = $CELL->status_ok( 'TEST_PUT_RESOURCE_EXISTS' );
    } else {
        # pretend that a new resource was created
        $status = $CELL->status_ok( 'TEST_PUT_NEW_RESOURCE_CREATED' );
    }
    $status->payload( 'DUMMY' );
    return $status;
}

sub _test_delete {
    my ( $self, $specs ) = @_;
    my $bool = $specs ? 1 : 0;

    my $status;
    if ( $specs ) {
        # pretend we deleted something
        $status = $CELL->status_ok( 'TEST_RESOURCE_DELETED' );
    } else {
        # resource didn't exist
        $status = $CELL->status_not_ok( 'TEST_NON_EXISTENT_RESOURCE', args => [ 'DELETE' ], );
        # we have to force 404 here - due to how Web::Machine handles DELETE 
        $self->mrest_declare_status( 'code' => 404, 
            explanation => 'Request to delete non-existent resource; nothing to do' );
    }
    $status->payload( 'DUMMY' );
    return $status;
}


=head2 handler_version

Handler for the C<version> resource.

=cut

sub handler_version {
    my ( $self, $pass ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::handler_version, pass number $pass" );

    # first pass
    return 1 if $self->_first_pass_always_exists( $pass ); 

    # second pass
    my $param = $site->MREST_APPLICATION_MODULE;
    my $version = use_module( $param )->version;
    my $payload = ( $version )
        ? {
            'application' => $param,
            'version' => $version,
        }
        : "BUBBA did not find nothin";

    return $CELL->status_ok( 'MREST_DISPATCH_VERSION', payload => $payload );
}


1;

