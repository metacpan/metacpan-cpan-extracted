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
# t/201-Created.t
# ------------------------
#
# Send HTTP requests to trigger "201 Created" (and perform related tests)
#

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $log $site );
use Data::Dumper;
use HTTP::Request;
use Test::Deep;
use Test::More;
use Test::Warnings;
use Web::MREST::Test qw( initialize_unit llreq );

my $test = initialize_unit();
my ( $request, $response );

my $headers = [
    'accept' => 'application/json',
    'content-type' => 'application/json',
];

#
# 'test/?:specs' 
#
# POST 
#
# - resource does not exist
$response = $test->request( llreq( 'POST', 'test/0', $headers ) );
is( $response->code, 404, "specs value 0 should trigger 404" );

# - resource exists, post_is_create is true
$response = $test->request( llreq( 'POST', 'test/create', $headers ) );
is( $response->code, 201, "specs value 'create' should trigger 201" );
my $expected = '/test/create';
is( $response->header( 'location' ), $expected );

# - resource exists, post_is_create is false
$response = $test->request( llreq( 'POST', 'test/1', $headers ) );
is( $response->code, 200 );
is( $response->header( 'location' ), undef );

done_testing;
