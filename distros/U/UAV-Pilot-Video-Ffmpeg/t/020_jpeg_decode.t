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
use Test::More tests => 8;
use v5.14;
use UAV::Pilot;
use UAV::Pilot::Video::JPEGDecoder;
use UAV::Pilot::Video::Mock::RawHandler;
use Test::Moose;

use constant VIDEO_DUMP_FILE => 't_data/frame.jpg';


my $display = UAV::Pilot::Video::Mock::RawHandler->new({
    cb => sub {
        my ($self, $width, $height, $decoder) = @_;
        cmp_ok( $width,  '==', 320, "Width passed" );
        cmp_ok( $height, '==', 240, "Height passed" );

        isa_ok( $decoder => 'UAV::Pilot::Video::JPEGDecoder' );

        my $pixels = $decoder->get_last_frame_pixels_arrayref;
        cmp_ok( ref($pixels), 'eq', 'ARRAY', "Got array ref of pixels" );
        cmp_ok( scalar(@$pixels), '==', 3, "Got 3 channels in YUV420P format" );
    },
});
my $display2 = UAV::Pilot::Video::Mock::RawHandler->new({
    cb => sub {
        pass( "Got stacked handler" );
    },
});
my $video = UAV::Pilot::Video::JPEGDecoder->new({
    displays => [ $display, $display2 ],
});
isa_ok( $video => 'UAV::Pilot::Video::JPEGDecoder' );
does_ok( $video => 'UAV::Pilot::Video::JPEGHandler' );


my @frame;
open( my $fh, '<', VIDEO_DUMP_FILE )
    or die "Can't open " . VIDEO_DUMP_FILE . ": $!\n";
while( read( $fh, my $buf, 4096 ) ) {
    push @frame, unpack( 'C*', $buf );
}
close $fh;


$video->process_jpeg_frame( \@frame, 640, 480, 640, 480 );
