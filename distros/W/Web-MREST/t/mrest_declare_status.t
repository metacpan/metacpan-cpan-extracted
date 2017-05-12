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
# t/mrest_declare_status.t
# ------------------------

#!perl
use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use Data::Dumper;
use JSON;
use Test::More;
use Test::Warnings;
use Web::MREST;
use Web::MREST::Resource;

note( 'load configuration parameters' );
my $status = Web::MREST::init();
is( $status->level, 'OK' );

note( 'create a Web::MREST::Resource object with a context' );
my $r = bless {}, 'Web::MREST::Resource';
$r->{'context'} = {};
isa_ok( $r, 'Web::MREST::Resource', "Web::MREST::Resource object" );

note( 'push_onto_context should now work' );
$r->push_onto_context( { 'foo' => 'bar' } );
is( ref( $r->context ), 'HASH', "context method" );
is( $r->context->{'foo'}, 'bar', "foo property of context" );

note( 'declare a status -- simple' );
ok( ! $r->status_declared );
$r->mrest_declare_status(
    $CELL->status_ok
);
ok( $r->status_declared );
is( ref( $r->status_declared ), 'App::CELL::Status' );
ok( $r->status_declared->ok );

note( 'declared_status is a synonym for status_declared' );
ok( $r->declared_status->ok );

note( 'nullify declared status' );
$r->nullify_declared_status;
ok( ! $r->status_declared );

note( 'declare a new status using PARAMHASH' );
$r->mrest_declare_status(
    level => 'CRIT',
    explanation => 'Whack-a-mole status!',
);
ok( $r->status_declared, 'looks good' );

note( 'check if level is CRIT' );
is( $r->declared_status->level, 'CRIT' );

note( 'test declared_status_explanation accessor' );
is( $r->mrest_declared_status_explanation, 'Whack-a-mole status!' );

note( 'test declared_status_code accessor' );
is( $r->mrest_declared_status_code, undef );
$r->mrest_declared_status_code( 400 );
is( $r->mrest_declared_status_code, 400 );

note( 'permanent property defaults to JSON::true' );
ok( $r->declared_status->payload->{'permanent'} );

note( 'nullify declared status 2' );
$r->nullify_declared_status;
ok( ! $r->status_declared );

note( 'use defined message in config/srv/MREST_Message_en.conf' );
$r->mrest_declare_status(
    $CELL->status_warn(
        'TEST_NON_EXISTENT_RESOURCE',
        args => [ 'foobar' ],
        http_code => 334,
    )
);
ok( $r->status_declared, 'looks good' );

note( 'test declared_status_code accessor' );
is( $r->mrest_declared_status_code, 334 );

note( 'test declared_status_explanation accessor' );
is( $r->mrest_declared_status_explanation, 
    'The requested resource does not exist (foobar)' );

done_testing;
