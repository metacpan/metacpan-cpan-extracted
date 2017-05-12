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
# t/resources/echo.t - test the 'param' resource
# ------------------------

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $log $site );
use Data::Dumper;
use Test::More;
use Test::Warnings;
use Web::MREST::Test qw( initialize_unit req );

# instantiate Plack::Test object
my $test = initialize_unit();

#
# run the tests
#
my $status = req( $test, 200, 'GET', 'param/core/MREST_HOST' );
is( $status->level, 'OK' );
is_deeply( $status->payload, { 'MREST_HOST' => 'localhost' } );

# PUT is create
$status = req( $test, 201, 'PUT', 'param/meta/BUBBA', '{ "foobar" : 123 }' );
is( $status->level, 'OK' );
is( $status->{'location_header'}, 'param/meta/BUBBA' );

# GET it to confirm it is there
$status = req( $test, 200, 'GET', 'param/meta/BUBBA' );
is( $status->level, 'OK' );
is_deeply( $status->payload, { 'BUBBA' => { 'foobar' => 123 } } );

# PUT is modify
$status = req( $test, 200, 'PUT', 'param/meta/BUBBA', '{ "foobar" : null }' );
is( $status->level, 'OK' );
is( $status->code, 'CELL_OVERWRITE_META_PARAM' );

# GET it to confirm it was modified
$status = req( $test, 200, 'GET', 'param/meta/BUBBA' );
is( $status->level, 'OK' );
is_deeply( $status->payload, { 'BUBBA' => { 'foobar' => undef } } );

# overwrite to null
$status = req( $test, 200, 'PUT', 'param/meta/BUBBA', 'null' );
is( $status->level, 'OK' );
is( $status->code, 'CELL_OVERWRITE_META_PARAM' );

# GET it to confirm it was modified
$status = req( $test, 200, 'GET', 'param/meta/BUBBA' );
is( $status->level, 'OK' );
is_deeply( $status->payload, { 'BUBBA' => undef } );

# DELETE it, since it was only there for testing purposes
$status = req( $test, 200, 'DELETE', 'param/meta/BUBBA' );
is( $status->level, 'OK' );

# not there anymore
$status = req( $test, 404, 'GET', 'param/meta/BUBBA' );
$status = req( $test, 404, 'DELETE', 'param/meta/BUBBA' );

# wrap up
done_testing;

