# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
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
use Test::More tests => 9;
use v5.14;
use UAV::Pilot;
use UAV::Pilot::Commands;


my $repl = UAV::Pilot::Commands->new;
isa_ok( $repl => 'UAV::Pilot::Commands' );


eval {
    $repl->run_cmd( 'mock;' );
};
ok( $@, "No such command 'mock'" );

eval {
    $repl->run_cmd( q{load 'NoExists';} );
};
like( $@, qr/\ACould not load NoExists/ );


$repl->run_cmd( q{load 'Mock';} );
$repl->run_cmd( 'mock;' );
ok( 1, "Mock command ran" );

$repl->run_cmd( q(load 'Mock', { namespace => 'Local' };) );
$repl->run_cmd( 'Local::mock;' );
ok( 1, "Mock commands placed in namespace" );

$repl->run_cmd( q(load 'MockInit', { setting => 5 };) );
cmp_ok( $UAV::Pilot::mock_init_set, '==', 5,
    "MockInit loaded and ran uav_module_init() with param" );

eval {
    $repl->run_cmd( 'uav_module_init();' );
};
ok( $@, "MockInit uav_module_init() call does not appear" );


ok(! $main::DID_QUIT, "Have not yet sent quit signal" );
$repl->quit;
ok( $main::DID_QUIT, "Sent quit signal" );
