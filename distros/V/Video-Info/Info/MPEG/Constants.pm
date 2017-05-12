##------------------------------------------------------------------------
##  Package: Video::Info::MPEG::Constants
##   Author: Benjamin R. Ginter
##   Notice: Copyright (c) 2001 Benjamin R. Ginter
##  Purpose: MPEG codes, blocks, constants...
## Comments: None
##      CVS: $Header: /cvsroot/perlvideo/Info/MPEG/Constants.pm,v 1.3 2002/11/12 07:19:34 allenday Exp $
##------------------------------------------------------------------------

package Video::Info::MPEG::Constants;
use strict;

require Exporter;

our @ISA = qw( Exporter);

##------------------------------------------------------------------------
## FRAME_RATE
##
## A lookup table of all the standard frame rates.  Some rates adhere to
## a particular profile that ensures compatibility with VLSI capabilities
## of the early to mid 1990s.
##
## CPB
##   Constrained Parameters Bitstreams, an MPEG-1 set of sampling and 
##   bitstream parameters designed to normalize decoder computational 
##   complexity, buffer size, and memory bandwidth while still addressing 
##   the widest possible range of applications.
##
## Main Level
##   MPEG-2 Video Main Profile and Main Level is analogous to MPEG-1's 
##   CPB, with sampling limits at CCIR 601 parameters (720x480x30 Hz or 
##   720x576x24 Hz). 
##
##------------------------------------------------------------------------
our $FRAME_RATE =
    [ 0, 
      24000/1001, ## 3-2 pulldown NTSC                    (CPB/Main Level)
      24,         ## Film                                 (CPB/Main Level)
      25,         ## PAL/SECAM or 625/60 video
      30000/1001, ## NTSC                                 (CPB/Main Level)
      30,         ## drop-frame NTSC or component 525/60  (CPB/Main Level)
      50,         ## double-rate PAL
      60000/1001, ## double-rate NTSC
      60,         ## double-rate, drop-frame NTSC/component 525/60 video
      ];

##------------------------------------------------------------------------
## ASPECT_RATIO -- INCOMPLETE?
##
## This lookup table maps the header aspect ratio index to a common name.
## These are just the defined ratios for CPB I believe.  As I understand 
## it, a stream that doesn't adhere to one of these aspect ratios is
## technically considered non-compliant.
##------------------------------------------------------------------------
our $ASPECT_RATIO = [ 'Forbidden',
		      '1/1 (VGA)',
		      '4/3 (TV)',
		      '16/9 (Large TV)',
		      '2.21/1 (Cinema)',
		      ];

##------------------------------------------------------------------------
## The MPEG Audio Bit Rate Lookup Table
##
## MPEG Version [hashref]
##   |
##   +-- MPEG Layer [hashref]
##        |
##        +--  Bitrates [arrayref]
##------------------------------------------------------------------------
our $AUDIO_BITRATE = {
    1 => { 
	1 => [ 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0 ],
	2 => [ 0, 32, 48, 56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384, 0 ],
	3 => [ 0, 32, 40, 48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 0 ],
    },
    2 => { 
	1 => [ 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0 ],
	2 => [ 0,  8, 16, 24, 32, 40, 48,  56,  64,  80,  96, 112, 128, 144, 160, 0 ],
	3 => [ 0,  8, 16, 24, 32, 40, 48,  56,  64,  80,  96, 112, 128, 144, 160, 0 ],
    },
};

##------------------------------------------------------------------------
## The MPEG Audio Sampling Rate Lookup Table
##
## MPEG Layer [hashref]
##   |
##   +-- Sampling Rate [arrayref]
##
##------------------------------------------------------------------------
our $AUDIO_SAMPLING_RATE = {
    1 => [ 44100, 48000, 32000, 0 ],
    2 => [ 22050, 24000, 16000, 0 ],
    3 => [ 11025, 12000,  8000, 0 ], ## mpeg2.5
};



##------------------------------------------------------------------------
## START_CODE
##
## Start Codes, with 'slice' occupying 0x01..0xAF
## No inlining here but easy lookups when codes are encountered.  Only
## really useful for debugging or dumping the bitstream structure.
##------------------------------------------------------------------------
our $START_CODE = {
    0x00 => 'picture_start_code',
    ( map { $_ => 'slice_start_code' } ( 0x01..0xAF ) ),
    0xB0 => 'reserved',
    0xB1 => 'reserved',
    0xB2 => 'user_data_start_code',
    0xB3 => 'sequence_header_code',
    0xB4 => 'sequence_error_code',
    0xB5 => 'extension_start_code',
    0xB6 => 'reserved',
    0xB7 => 'sequence end',
    0xB8 => 'group of pictures',
};

##------------------------------------------------------------------------
## INLINED START CODES
##
## These should get inlined for a big speed boost.  We should only need
## these codes.
##------------------------------------------------------------------------
use constant PICTURE   => 0x00;
use constant USERDATA  => 0xB2;
use constant SEQ_HEAD  => 0xB3;
use constant SEQ_ERR   => 0xB4;
use constant EXT_START => 0xB5;
use constant SEQ_END   => 0xB7;
use constant GOP       => 0xB8;

use constant SEQ_START_CODE => 0xB3;
use constant PACK_PKT       => 0xBA;
use constant SYS_PKT        => 0xBB;
use constant PADDING_PKT    => 0xBE;

use constant AUDIO_PKT      => 0xC0;
use constant VIDEO_PKT      => 0xE0;



##------------------------------------------------------------------------
## FRAME TYPES
##------------------------------------------------------------------------
our $FRAME_TYPES = [ qw( Bad I P B ) ];

##------------------------------------------------------------------------
## STREAM_ID
##
## Stream Identifiers
##------------------------------------------------------------------------
our $STREAM_ID = {
    0x00 => 'Unknown',
    ( map { $_ => 'slice_start_code' } ( 0x01..0xAF ) ),

    0xB3 => 'Sequence Start',
    0xB7 => 'Sequence End',
    0xB8 => 'Group of Pictures',

    0xB9 => 'Program End',
    0xBA => 'Pack Header',
    0xBB => 'System Header',
    0xBC => 'Program Stream Map',
    0xBD => 'Private Stream 1',
    0xBE => 'Padding Stream',
    0xBF => 'Private Stream 2',
    ( map { $_ => 'MPEG-1 or MPEG-2 Audio Stream' } ( 0xC0..0xDF ) ),
    ( map { $_ => 'MPEG-1 or MPEG-2 Video Stream' } ( 0xE0..0xEF ) ),
    0xF0 => 'ECM Stream',
    0xF1 => 'EMM Stream',
    0xF2 => 'ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Annex A or ISO/IEC 13818-6_DSMCC_stream',
    0xF3 => 'ISO/IEC_13522_stream',
    0xF4 => 'ITU-T Rec. H.222.1 type A',
    0xF5 => 'ITU-T Rec. H.222.1 type B',
    0xF6 => 'ITU-T Rec. H.222.1 type C',
    0xF7 => 'ITU-T Rec. H.222.1 type D',
    0xF8 => 'ITU-T Rec. H.222.1 type E',
    0xF9 => 'Ancillary Stream',
    ( map { $_ => 'Reserved' } ( 0xFA..0xFE ) ),
    0xFF => 'Program Stream Directory',
};

##------------------------------------------------------------------------
## EXTENSION_CODE
##
##
##------------------------------------------------------------------------
our $EXTENSION_CODE = [
		       'Reserved',                               # 0000
		       'Sequence Extension ID',                  # 0001
		       'Sequence Display Extension ID',          # 0010
		       'Quant Matrix Extension ID',              # 0011
		       'Reserved',                               # 0100
		       'Sequence Scalable Extension ID',         # 0101
		       'Reserved',                               # 0110
		       'Picture Display Extension ID',           # 0111
		       'Picture Coding Extension ID',            # 1000
		       'Picture Spatial Scalable Extension ID',  # 1001
		       'Picture Temporal Scalable Extension ID', # 1010
		       'Reserved' x 5    # 1011, 1100, 1101, 1110, 1111
];

##------------------------------------------------------------------------
## IMAGE FORMATS
##
## Names of various image/video resolutions.
##------------------------------------------------------------------------
our $IMAGE_FORMATS = {
    352 => { 240 => 'SIF. CD WhiteBook Movies, video games.',
	     480 => 'HHR. VHS equivalent', },
    480 => { 480 => 'Bandlimited (4.2 Mhz) broadcast NTSC.', },
    544 => { 480 => 'Laserdisc, D-2, Bandlimited PAL/SECAM.', },
    640 => { 480 => 'Square pixel NTSC', },
    720 => { 480 => 'CCIR 601. Studio D-1. Upper limit of Main Level.' },
};



##------------------------------------------------------------------------
## Items to export into callers namespace by default. Note: do not export
## names by default without a very good reason. Use EXPORT_OK instead.
## Do not simply export all your public functions/methods/constants.
##------------------------------------------------------------------------
## This allows declaration	use Video::Info::MPEG::Constants ':all';
## If you do not need this, moving things directly into @EXPORT or 
## @EXPORT_OK will save memory.
##------------------------------------------------------------------------
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( SEQ_START_CODE $FRAME_RATE $ASPECT_RATIO 
		  $START_CODE $STREAM_ID 
		  $AUDIO_BITRATE $AUDIO_SAMPLING_RATE

		  PICTURE USERDATA SEQ_HEAD SEQ_ERR EXT_START SEQ_END GOP 
		  SEQ_START_CODE PACK_PKT SYS_PKT PADDING_PKT 
		  AUDIO_PKT VIDEO_PKT 
		  );

##------------------------------------------------------------------------
## Preloaded methods go here.
##------------------------------------------------------------------------
1;

__END__

=head1 AUTHORS

 Copyright (c) 2002
 Aladdin Free Public License (see LICENSE for details)
 Allen Day, <allenday@ucla.edu>
 Benjamin R. Ginter <bginter@asicommunications.com>


