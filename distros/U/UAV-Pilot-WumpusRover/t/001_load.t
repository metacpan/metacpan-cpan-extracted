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
use Test::More tests => 15;
use v5.14;

use_ok( 'UAV::Pilot::WumpusRover' );
use_ok( 'UAV::Pilot::WumpusRover::Control' );
use_ok( 'UAV::Pilot::WumpusRover::Control::Event' );
use_ok( 'UAV::Pilot::WumpusRover::Driver' );
use_ok( 'UAV::Pilot::WumpusRover::Packet' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::Ack' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::Heartbeat' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RadioMaxes' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RadioMins' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RadioOutputs' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RadioTrims' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::RequestStartupMessage' );
use_ok( 'UAV::Pilot::WumpusRover::Packet::StartupMessage' );
use_ok( 'UAV::Pilot::WumpusRover::PacketFactory' );
use_ok( 'UAV::Pilot::WumpusRover::Video' );
