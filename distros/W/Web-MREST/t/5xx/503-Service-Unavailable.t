# ************************************************************************* 
# Copyright (c) 2014-2015-2015, SUSE LLC
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
# t/503-Service-Unavailable.t
# ------------------------
#
# Acting like I am an application, define a mrest_service_available 
# method that returns false. Then send a HTTP request to the application
# and test for 503 status code in the response.
#

#!perl
use 5.012;
use strict;
use warnings;

package Web::MREST::Test::503;

use App::CELL qw( $log );
use Data::Dumper;
use HTTP::Request::Common qw( GET PUT POST DELETE );
use JSON;
use Test::More;
use Test::Warnings;
use Web::MREST::Test qw( initialize_unit req );

use parent 'Web::MREST::Resource';

sub mrest_service_available {
    my $self = shift;
    $log->info( "Entering " . __PACKAGE__ . "::mrest_service_available" );
    $self->mrest_declare_status( explanation => 'Testing', permanent => 0 );
    return 0; # 503 Service Unavailable
}

my $test = initialize_unit( 'class' => 'Web::MREST::Test::503' );

# send a request
#my $response = $test->request( GET( '/' ) );
#isa_ok( $response, 'HTTP::Response' );
#is( $response->code, 503 );
my $status = req( $test, 503, 'GET', '/' );
isa_ok( $status, 'App::CELL::Status' );
is( $status->level, 'ERR' );
is( $status->code, 'Testing' );
ok( ! $status->payload->{'permanent'} );
#diag( Dumper( $status->payload ) );

done_testing;
