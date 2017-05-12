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
use Test::More tests => 3;
use v5.14;
use UAV::Pilot;
use UAV::Pilot::ARDrone::Driver::Mock;
use UAV::Pilot::ARDrone::Video::Fileno::Mock;
use AnyEvent;
use Test::Moose;

use constant VIDEO_DUMP_FILE => 't_data/ardrone_video_stream_dump.bin';


my $cv = AnyEvent->condvar;
my $ardrone = UAV::Pilot::ARDrone::Driver::Mock->new({
    host => 'localhost',
});
my $video = UAV::Pilot::ARDrone::Video::Fileno::Mock->new({
    file     => VIDEO_DUMP_FILE,
    condvar  => $cv,
    driver   => $ardrone,
});
isa_ok( $video => 'UAV::Pilot::ARDrone::Video::Fileno' );
does_ok( $video => 'UAV::Pilot::ARDrone::Video::BuildIO' );

ok( $video->fileno, "Returned fileno of input stream" );
