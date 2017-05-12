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
# t/415-Unsupported-Media-Type.t
# ------------------------
#
# Test that an unsupported content type triggers a 415.
#

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $log $site );
use Data::Dumper;
use JSON;
use Test::Deep;
use Test::More;
use Test::Warnings;
use Web::MREST::Test qw( initialize_unit llreq );

use parent 'Web::MREST::Resource';

my $test = initialize_unit();
my ( $request, $response );

#
# check MREST_SUPPORTED_CONTENT_TYPES
#
cmp_deeply( $site->MREST_SUPPORTED_CONTENT_TYPES, bag( 'application/json' ) );

# GET request with no entity and no content-type
$response = $test->request( llreq( 'GET', 'bugreport' ) );
is( $response->code, 200 );

# GET request with no entity and kosher content-type
$response = $test->request( llreq( 'GET', 'bugreport', [ 'Content-Type' => 'application/json' ] ) );
is( $response->code, 200 );

# POST request with no entity and no content-type
$response = $test->request( llreq( 'POST', 'test' ) );
is( $response->code, 200 );

# POST request with bogus entity and no content-type
$response = $test->request( llreq( 'POST', 'test', [], ":-)" ) );
#diag( Dumper $response );
is( $response->code, 400 );
ok( $response->content );
my $status = decode_json( $response->content );
#diag( Dumper $status );
bless $status, 'App::CELL::Status';
isa_ok( $status, 'App::CELL::Status' );
is( $status->level, "ERR" );
is( $status->code, 'no Content-Type and/or no Content-Length, yet request body present' );

# POST request with bogus entity and bogus content-type
$response = $test->request( llreq( 'POST', 'test', [ 'Content-Length' => 4, 'Content-Bogus' => ':-)' ], 'asdf' ) );
is( $response->code, 400 );
ok( $response->content );
like( $response->content, qr/no Content-Type and\/or no Content-Length, yet request body present/ );

# POST request with proper entity and bogus content-type
$response = $test->request( llreq( 'POST', 'test', [ 'Content-Length' => 20, 'Content-Type' => ':-)' ], '{ "content" : 1234 }' ) );
#diag( Dumper $response );
is( $response->code, 415 );
ok( $response->content );
$status = decode_json( $response->content );
#diag( Dumper $status );
bless $status, 'App::CELL::Status';
isa_ok( $status, 'App::CELL::Status' );
is( $status->level, "ERR" );
is( $status->code, 'Content type ->:-)<- is not supported' );

# FIXME: more tests needed

done_testing;
