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
# t/501-Not-Implemented.t
# ------------------------
#
# There are two scenarios that will trigger a 501:
# 
# 1. B12: the request method is not found in $site->MREST_SUPPORTED_HTTP_METHODS
# 2. B6: Unknown or unsupported Content-* header
#

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $log );
use Data::Dumper;
use Test::More;
use Test::Warnings;
use Web::MREST::Test qw( initialize_unit llreq );

use parent 'Web::MREST::Resource';

my $test = initialize_unit();
my $response;

#
# send a request that will trigger 501 in 'known_methods' (B12)
#
$response = $test->request( llreq( 'HEAD', '/' ) );
is( $response->code, 501 );
ok( $response->content );
like( $response->content, qr/The request method HEAD is not one of the supported methods GET, PUT, POST, DELETE, TRACE, CONNECT, OPTIONS/ );

#
# send a request that will trigger 501 in 'valid_content_headers' (B6)
#
$response = $test->request( llreq( 'GET', 'bugreport', [ 'Content-Bogus' => ':-)' ] ) );
is( $response->code, 501 );

# POST request with no entity and bogus content-type
# (if request entity is empty, content-type is irrelevant and will be ignored)
$response = $test->request( llreq( 'POST', 'test', [ 'Content-Bogus' => ':-)' ] ) );
is( $response->code, 501 );

done_testing;
