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
# t/resources/docu.t - test the 'docu', 'docu/pod', and 'docu/html' resources
# ------------------------

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $log $site );
use Web::MREST::Test qw( initialize_unit req );
use Test::Deep;
use Test::More;
use Test::Warnings;

# instantiate Plack::Test object
my $test = initialize_unit();

#
# run the tests
#
my $status;

# 'docu'
foreach my $method ( qw( DELETE GET POST PUT ) ) {

    $status = req( $test, 200, 'GET', 'docu' );
    is( $status->level, 'OK' );
    ok( $status->payload );
    cmp_deeply( $status->payload, {
        'description' => 'Access on-line documentation (via POST to appropriate subresource)',
        'resource_name' => 'docu',
        'parent' => '/',
        'children' => bag( 'docu/pod', 'docu/html', 'docu/text' ),
    } );
}

# 'docu/pod'
# 'docu/html'
foreach my $spec ( [ 'docu/pod', 'POD' ], [ 'docu/html', 'HTML' ] ) {
    $status = req( $test, 200, 'POST', $spec->[0], '"docu"' );
    is( $status->level, 'OK' );
    ok( $status->payload );
    cmp_deeply( $status->payload, {
        'resource' => 'docu',
        'format' => $spec->[1],
        'documentation' => re('.+'),
    } );
}

foreach my $resource ( 'docu/pod', 'docu/html' ) {
    foreach my $method ( qw( GET PUT DELETE ) ) {
        req( $test, 405, $method, $resource );
    }
}

# wrap up
done_testing;
