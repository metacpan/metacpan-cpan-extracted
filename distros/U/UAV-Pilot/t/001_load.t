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
use Test::More tests => 18;
use v5.14;

use_ok( 'UAV::Pilot' );
use_ok( 'UAV::Pilot::Exceptions' );
use_ok( 'UAV::Pilot::Driver' );
use_ok( 'UAV::Pilot::Control' );
use_ok( 'UAV::Pilot::ControlHelicopter' );
use_ok( 'UAV::Pilot::ControlRover' );
use_ok( 'UAV::Pilot::Server' );
use_ok( 'UAV::Pilot::Commands' );
use_ok( 'UAV::Pilot::EasyEvent' );
use_ok( 'UAV::Pilot::EventHandler' );
use_ok( 'UAV::Pilot::Events' );
use_ok( 'UAV::Pilot::NavCollector' );
use_ok( 'UAV::Pilot::NavCollector::AckEvents' );
use_ok( 'UAV::Pilot::ControlRover' );
use_ok( 'UAV::Pilot::Video::H264Handler' );
use_ok( 'UAV::Pilot::Video::JPEGHandler' );
use_ok( 'UAV::Pilot::Video::RawHandler' );
use_ok( 'UAV::Pilot::Video::Mock::RawHandler' );
