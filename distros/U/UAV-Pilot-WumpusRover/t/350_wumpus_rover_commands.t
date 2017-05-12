# Copyright (c) 2014  Timm Murray
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
use Test::More tests => 7;
use strict;
use warnings;
use UAV::Pilot::WumpusRover::Control;
use UAV::Pilot::WumpusRover::Driver::Mock;
use UAV::Pilot::Commands;
use AnyEvent;

my $LIB_DIR = 'share';


my $driver = UAV::Pilot::WumpusRover::Driver::Mock->new({
    host => 'localhost',
    port => 49000,
});
$driver->connect;
my $control = UAV::Pilot::WumpusRover::Control->new({
    driver => $driver,
});

my $repl = UAV::Pilot::Commands->new({
    controller_callback_wumpusrover => sub { $control },
});
my $cv = AnyEvent->condvar;


$repl->add_lib_dir( UAV::Pilot->default_module_dir );
$repl->load_lib( 'WumpusRover', {
    controller => $control,
    condvar    => $cv,
});
pass( "WumpusRover library loaded" );

my @TESTS = (
    {
        cmd    => 'throttle 100;',
        expect => {
            packet_type => 'RadioOutputs',
            ch1_out     => 100,
            ch2_out     => 0,
        },
        name   => "Throttle command",
    },
    {
        cmd    => 'turn 90;',
        expect => {
            packet_type => 'RadioOutputs',
            ch1_out     => 100,
            ch2_out     => 90,
        },
        name   => "Turn command (combined with previous throttle)",
    },
    {
        cmd    => 'stop;',
        expect => {
            packet_type => 'RadioOutputs',
            ch1_out     => 0,
            ch2_out     => 0,
        },
        name   => "Stop command",
    },
);
foreach my $test (@TESTS) {
    my $cmd       = $$test{cmd};
    my $test_name = $$test{name};
    my $expect    = $$test{expect};

    my $expect_packet_type = 'UAV::Pilot::WumpusRover::Packet::'
        . delete $$expect{packet_type};

    $repl->run_cmd( $cmd );
    # This would normally be handled by UAV::Pilot::WumpusRover::Control::Event,
    # but we're not using that in this test.
    $control->send_move_packet;

    my $last_sent_packet = $driver->last_sent_packet;
    my $got = {
        map {
            $_ => $last_sent_packet->$_;
        } keys %$expect
    };
    
    isa_ok( $last_sent_packet => $expect_packet_type );
    is_deeply( 
        $got,
        $expect,
        $test_name,
    );
}
