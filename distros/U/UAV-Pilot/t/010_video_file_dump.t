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
use Test::More tests => 5;
use v5.14;
use UAV::Pilot::Video::FileDump;
use File::Temp ();
use Test::Moose;

my ($OUTPUT_FH, $OUTPUT_FILE) = File::Temp::tempfile( 'uav_pilot_file_dump.XXXXXX',
    UNLINK => 1,
);

my $dump = UAV::Pilot::Video::FileDump->new({
    fh => $OUTPUT_FH,
});
isa_ok( $dump => 'UAV::Pilot::Video::FileDump' );
does_ok( $dump => 'UAV::Pilot::Video::H264Handler' );
cmp_ok( $dump->_frame_count, '==', 0, "Frame count is zero" );


$dump->process_h264_frame([ 0x12, 0x34, 0x56, 0x78 ]);
close $OUTPUT_FH;
cmp_ok( (-s $OUTPUT_FILE), '==', 4, "Wrote to output file" );
cmp_ok( $dump->_frame_count, '==', 1, "Frame count incremented" );
