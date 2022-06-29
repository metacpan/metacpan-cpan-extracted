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
# Test helper functions module
# ------------------------

package Web::MREST::Test;

use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use Data::Dumper;
use File::HomeDir;
use HTTP::Request;
use JSON;
use Log::Any::Adapter;
use Params::Validate qw( :all );
use Plack::Test;
use Test::JSON;
use Test::More;
use Try::Tiny;
use Web::Machine;
use Web::MREST;



=head1 NAME

Web::MREST::Test - Test helper functions





=head1 DESCRIPTION

This module provides helper code for unit tests.

=cut




=head1 EXPORTS

=cut

use Exporter qw( import );
our @EXPORT = qw( initialize_unit req llreq docu_check );




=head1 PACKAGE VARIABLES

=cut

# dispatch table with references to HTTP::Request::Common functions
my %methods = ( 
    GET => \&GET,
    PUT => \&PUT,
    POST => \&POST,
    DELETE => \&DELETE,
    HEAD => \&HEAD,
);




=head1 FUNCTIONS

=cut


=head2 initialize_unit

Perform the boilerplate tasks that have to be done at the beginning of every
unit. Takes a PARAMHASH with two optional parameters:

    'class' => class into which Web::Machine object is to be blessed
    'sitedir' => sitedir parameter to be passed to Web::MREST::init

=cut

sub initialize_unit {
    my %ARGS = @_;
    note( "Initializing unit " . (caller)[1] . " with arguments " . Dumper( \%ARGS ) );
    my $class = $ARGS{'class'} || undef;
    my %init_options = $ARGS{'sitedir'}
        ? ( 'sitedir' => $ARGS{'sitedir'} )
        : ();

    # zero logfile and tell Log::Any to log to it
    my $log_file_spec = File::HomeDir->my_home . "/mrest.log";
    unlink $log_file_spec;
    Log::Any::Adapter->set( 'File', $log_file_spec );
    $log->init( ident => 'MREST_UNIT_TEST' );

    # load configuration parameters
    my $status = Web::MREST::init( %init_options );
    is( $status->level, 'OK' );

    note( 'check that site configuration parameters were loaded' );
    is_deeply( [ $site->MREST_SUPPORTED_CONTENT_TYPES ], [ [ 'application/json' ] ],
        'configuration parameters loaded?' );

    # set debug mode
    $log->debug_mode( $site->MREST_DEBUG_MODE );

    my $app = Web::Machine->new(
        resource => ( $class || 'Web::MREST::Dispatch' )
    )->to_app;

    my $test = Plack::Test->create( $app );
    isa_ok( $test, 'Plack::Test::MockHTTP' );
    return $test;

}


=head2 status_from_json

L<Web::MREST> is designed to return status objects in the HTTP response entity.
Before inclusion in the response, the status object is converted to JSON. This
routine goes the opposite direction, taking a JSON string and converting it
back into a status object.

FIXME: There may be some encoding issues here!

=cut

sub status_from_json {
    my ( $json ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::status_from_json" );
    my $obj;
    try {
        $obj = bless from_json( $json ), 'App::CELL::Status';
    } catch {
        $obj = $_;
    };
    return $obj if ref( $obj) eq 'App::CELL::Status';
    die "\n\nfrom_json died";
}


=head2 req

Assemble and process a HTTP request. Takes the following positional arguments:

    * Plack::Test object
    * expected HTTP result code
    * user to authenticate with (can be 'root', 'demo', or 'active')
    * HTTP method
    * resource string
    * optional JSON string

If the HTTP result code is 200, the return value will be a status object, undef
otherwise.

=cut

sub req {
    my ( $test, $code, $method, $resource, $json ) = validate_pos( @_, 1, 1, 1, 1, 0 );
    $log->debug( "Entering " . __PACKAGE__ . "::req" );

    if ( ref( $test ) ne 'Plack::Test::MockHTTP' ) {
        diag( "Plack::Test::MockHTTP object not passed to 'req' from " . (caller)[1] . " line " . (caller)[2] );
        BAIL_OUT(0);
    }

    # assemble request
    my @headers = (
        'accept' => 'application/json',
        'content-type' => 'application/json',
    );
    my $r = llreq( $method, $resource, \@headers, $json );

    # send request; get response
    my $res = $test->request( $r );
    isa_ok( $res, 'HTTP::Response' );
    diag( Dumper $res ) if ( $res->code == 500 );

    #diag( $res->code . " " . $res->message );
    is( $res->code, $code, "$method $resource" . ( $json ? " with $json" : "" ) . " 1" );
    my $content = $res->content;
    if ( $content ) {
        #diag( Dumper $content );
        is_valid_json( $content, "$method $resource" . ( $json ? " with $json" : "" ) . " 2" );
        my $status = status_from_json( $content );
        if ( my $location_header = $res->header( 'Location' ) ) {
            $status->{'location_header'} = $location_header;
        }
        return $status;
    }
    return;
}


=head2 llreq

Low-level request generator

=cut

sub llreq {
    my ( $method, $uri, @args ) = @_;
    my ( $headers, $content );
    if ( @args ) {
        $headers = shift @args;
        $log->debug( "llreq: headers set to " . Dumper( $headers ) );
    } else {
        $headers = [
            'accept' => 'application/json',
            'content-type' => 'application/json',
        ];
    }
    if ( @args and defined( $args[0] ) ) {
        $log->debug( "llreq: args is " . Dumper( \@args ) );
        $content = join( ' ', @args );
    }
    return HTTP::Request->new( $method, $uri, $headers, $content );
}


=head2 docu_check

Check that the resource has on-line documentation (takes Plack::Test object
and resource name without quotes)

=cut

sub docu_check {
    my ( $test, $resource ) = @_;

    #diag( "Entering " . __PACKAGE__ . "::docu_check with argument $resource" );

    if ( ref( $test ) ne 'Plack::Test::MockHTTP' ) {
        diag( "Plack::Test::MockHTTP object not passed to 'req' from " . (caller)[1] . " line " . (caller)[2] );
        BAIL_OUT(0);
    }

    my $tn = "docu_check $resource ";
    my $t = 0;
    my ( $docustr, $docustr_len );
    #
    # - straight 'docu' resource
    my $status = req( $test, 200, 'demo', 'POST', '/docu', <<"EOH" );
{ "resource" : "$resource" }
EOH
    is( $status->level, 'OK', $tn . ++$t );
    is( $status->code, 'DISPATCH_ONLINE_DOCUMENTATION', $tn . ++$t );
    if ( exists $status->{'payload'} ) {
        ok( exists $status->payload->{'resource'}, $tn . ++$t );
        is( $status->payload->{'resource'}, $resource, $tn . ++$t );
        ok( exists $status->payload->{'documentation'}, $tn . ++$t );
        $docustr = $status->payload->{'documentation'};
        $docustr_len = length( $docustr );
        ok( $docustr_len > 10, $tn . ++$t );
        isnt( $docustr, 'NOT WRITTEN YET', $tn . ++$t );
    }
    #
    # - not a very thorough examination of the 'docu/html' version
    $status = req( $test, 200, 'demo', 'POST', '/docu/html', <<"EOH" );
{ "resource" : "$resource" }
EOH
    is( $status->level, 'OK', $tn . ++$t );
    is( $status->code, 'DISPATCH_ONLINE_DOCUMENTATION', $tn . ++$t );
    if ( exists $status->{'payload'} ) {
        ok( exists $status->payload->{'resource'}, $tn . ++$t );
        is( $status->payload->{'resource'}, $resource, $tn . ++$t );
        ok( exists $status->payload->{'documentation'}, $tn . ++$t );
        $docustr = $status->payload->{'documentation'};
        $docustr_len = length( $docustr );
        ok( $docustr_len > 10, $tn . ++$t );
        isnt( $docustr, 'NOT WRITTEN YET', $tn . ++$t );
    }
}

1;
