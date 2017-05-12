##------------------------------------------------------------------------
##  Package: Video::Info::MPEG::Video
##   Author: Benjamin R. Ginter
##   Notice: Copyright (c) 2001 Benjamin R. Ginter
##  Purpose: Parse video streams
## Comments: None
##      CVS: $Id: Video.pm,v 1.4 2003/07/08 07:35:33 allenday Exp $
##------------------------------------------------------------------------

package Video::Info::MPEG::Video;
use strict;
use Video::Info::MPEG;
use Video::Info::MPEG::Constants;

use constant DEBUG => 0;
use base qw(Video::Info::MPEG);

sub init {
  my $self = shift;
  my %param = @_;
  $self->init_attributes(@_);
  $self->handle($self->filename);
  $self->context($param{-context} || 'video');
}

##------------------------------------------------------------------------
## parse()
##
## Parse a video stream
##------------------------------------------------------------------------
sub parse {
    my $self   = shift;
    my $offset = shift;

    $offset = 0 if !defined $offset;

    $self->{offset} = $self->{last_offset} || $offset;

    print "Video::Info::MPEG::Video::parse( $offset )\n" if DEBUG;
    # print "\n", '-' x 74, "\n", "Parse Video: $offset\n", '-' x 74, "\n";

    ## Make sure we have video
    $self->is_video() or return 0;
    #if we made it this far, assume a bona fide MPEG
    $self->type('MPEG');
    $self->get_size();
    $self->get_frame_rate();
    $self->get_aspect_ratio();
	$self->get_bitrate();
    $self->get_duration();
    $self->get_extensions();
    $self->get_gop();
    $self->get_header_size();

    if ( DEBUG ) {
	print  "   DIMENSIONS: ", $self->width, 'x', $self->height, "\n";
	printf "   FRAME RATE: %0.2f fps\n", $self->fps;
	printf " ASPECT RATIO: %s ( %d )\n", $self->aspect, $self->aspect_raw;
	print  "      BITRATE: ", $self->vrate, "\n";
	print  "     DURATION: ", $self->duration, "\n";
	print "   HEADER SIZE: $self->{video_header_size}\n";
    }	

    return 1;
}

##------------------------------------------------------------------------
## get_size()
##
## Get the width and height
##------------------------------------------------------------------------
sub get_size {
    my $self = shift;

    $self->{offset} += 4;

    $self->width( $self->grab( 2, $self->{offset} ) >> 4 );
    $self->height( $self->grab( 2, $self->{offset} + 1 ) & 0x0FFF );
    if ( !defined $self->width || !defined $self->height ) {
	return 0;
    }
    return 1;
}

##------------------------------------------------------------------------
## is_video()
##
## Verify we're really dealing with a video packet
##
## This method searches up to eof for the start code in case there is
## junk at the beginning of the file.  Should we limit this somehow?
##------------------------------------------------------------------------
sub is_video {
    my $self = shift;

    print "is_video: offset $self->{offset}\n" if DEBUG;

    # return 0 if !$self->next_start_code( SEQ_START_CODE, $self->{offset} );

    while ( $self->{offset} <= $self->filesize - 4 ) {
	my $a = $self->get_byte( $self->{offset} );
	if ( $a != 0x00 ) { $self->{offset}++; next; }
	
	my $b = $self->get_byte( $self->{offset} + 1 );
	if ( $b != 0x00 ) { $self->{offset} += 2; next; };

	my $c = $self->get_byte( $self->{offset} + 2 );
	if ( $c != 0x01 ) { $self->{offset} += 3; next; };

	my $d = $self->get_byte( $self->{offset} + 3 );

	printf "Found 0x%02x @ %d\n", $d, $self->{offset} + 3 if DEBUG;
	# sleep 1;

	if ( $d == SEQ_START_CODE ) {
	    return 1;
	}
	elsif ( $self->{context} eq 'video' && $d == SYS_PKT ) {
	    print "Returning because video context\n" if DEBUG;
	    return 0;
	}
	$self->{offset}++;
    }

    $self->{offset} = $self->{last_offset};

    return 1;
}

##------------------------------------------------------------------------
## get_frame_rate()
##
## Extract the frame_rate index and do the lookup
##------------------------------------------------------------------------
sub get_frame_rate {
    my $self = shift;

    $self->{offset} += 3;

    my $frame_rate_index = $self->grab( 1, $self->{offset} ) & 0x0f;

    if ( $frame_rate_index > 8 ) {
	print "Invalid frame rate index: $frame_rate_index\n" if DEBUG;
	## $self->fps( 0.0 );
	return 0;
    }

    $self->fps( $FRAME_RATE->[ $frame_rate_index ] );
    
    return 1;
}

##------------------------------------------------------------------------
## get_aspect_ratio()
##
## Extract the aspect ratio index and do the lookup.
##
## NOTE: Don't die() on invalid aspect ratios as they are fairly common 
##       For example, 320x240 is invalid. :)
##------------------------------------------------------------------------
sub get_aspect_ratio {
    my $self = shift;

    my $aspect = ( $self->grab( 1, $self->{offset} ) & 0xF0 ) >> 4;
    if ( !$aspect ) {
	# print "Invalid aspect ratio: $aspect\n";
	return 0;
    }
    if ( $aspect > $#{ $ASPECT_RATIO } ) {
	# print "Reserved aspect ratio: $aspect\n";
	$self->aspect( 'Reserved' );
    }
    else {
	# print "Aspect Ratio: ", $ASPECT_RATIO->[ $aspect ], "\n";
	$self->aspect( $ASPECT_RATIO->[ $aspect ] );
    }

    $self->aspect_raw( $aspect );

    return 1;
}

##------------------------------------------------------------------------
## get_bitrate()
##
## From the MPEG-2.2 spec:
##
##   bit_rate -- This is a 30-bit integer.  The lower 18 bits of the 
##   integer are in bit_rate_value and the upper 12 bits are in 
##   bit_rate_extension.  The 30-bit integer specifies the bitrate of the 
##   bitstream measured in units of 400 bits/second, rounded upwards. 
##   The value zero is forbidden.
##
## So ignoring all the variable bitrate stuff for now, this 30 bit integer
## multiplied times 400 bits/sec should give the rate in bits/sec.
##  
## TODO: Variable bitrates?  I need one that implements this.
## 
## Continued from the MPEG-2.2 spec:
##
##   If the bitstream is a constant bitrate stream, the bitrate specified 
##   is the actual rate of operation of the VBV specified in annex C.  If 
##   the bitstream is a variable bitrate stream, the STD specifications in 
##   ISO/IEC 13818-1 supersede the VBV, and the bitrate specified here is 
##   used to dimension the transport stream STD (2.4.2 in ITU-T Rec. xxx | 
##   ISO/IEC 13818-1), or the program stream STD (2.4.5 in ITU-T Rec. xxx | 
##   ISO/IEC 13818-1).
## 
##   If the bitstream is not a constant rate bitstream the vbv_delay 
##   field shall have the value FFFF in hexadecimal.
##
##   Given the value encoded in the bitrate field, the bitstream shall be 
##   generated so that the video encoding and the worst case multiplex 
##   jitter do not cause STD buffer overflow or underflow.
##
##
##------------------------------------------------------------------------
sub get_bitrate {
    my $self = shift;

    $self->{offset}++;

    ## grab a short
    my $bitrate = $self->grab( 2, $self->{offset} ) << 2;
    my $lasttwo = $self->get_byte( $self->{offset} + 2 ) >> 6;

	if(!$self->vrate){
	  $self->vrate( ( $bitrate | $lasttwo ) * 400);
	} else {
	}
}

##------------------------------------------------------------------------
## get_duration()
##
## 
##------------------------------------------------------------------------
sub get_duration {
    my $self = shift;
    $self->duration ( ( $self->filesize * 8 ) / ( $self->vrate * 400 ) );
}

##------------------------------------------------------------------------
## get_extensions()
##
## TODO: make the $START_CODE->{$code} description the actual method name
##       for the extension handler.
##------------------------------------------------------------------------
sub get_extensions {
  my $self = shift;
  
  while (1) {
	my $code = $self->next_start_code( undef, $self->{offset}, 1 );
	last if $code == 0xB8;
	$self->{offset} = $self->{last_offset};
	
	$code     = $self->get_byte( $self->{offset} + 3 );
	my $descr = $START_CODE->{$code};
	
	if ( defined $descr ) {
	  ## printf "EXTENSION: %s\n", $START_CODE->{$code};
	  
	  if ( $descr eq 'extension_start_code' ) {
		$self->parse_extension( $self->{offset} );
		next;
	  }
	  elsif ( $descr eq 'user_data_start_code' ) {
		$self->parse_user_data( $self->{offset} );
		last;
	  }
	  else {
		print "No methods to handle $descr\n" if DEBUG;
		last;
	  }
	}
	
	$self->{offset}++;	
  }
}

##------------------------------------------------------------------------
## get_gop()
##
## Find first GOP header after video sequence header
##------------------------------------------------------------------------
sub get_gop {
    my $self = shift;

    if ( !$self->next_start_code( 0xb8, $self->{offset} ) ) {
	  ##Ben: should we return 0 here?
	  ##Allen: yes, i suppose so.
	  return 0;
	  ##Allen: let's not do this:	die "Couldn't find first GOP after Video Sequence start!\n";
    }
    print "Found GOP Header (0xB8) at $self->{last_offset} $self->{offset}\n" if DEBUG;
}

##------------------------------------------------------------------------
## get_header_size()
##
## Video header size
##------------------------------------------------------------------------
sub get_header_size {
    my $self = shift;

    print "OFFSETS: $self->{last_offset} $self->{offset}\n" if DEBUG;

    $self->header_size( $self->{last_offset} - $self->{offset} );
    print "HEADER_SIZE: ", $self->header_size, "\n" if DEBUG; 
}

1;

__END__

=head1 AUTHORS

 Copyright (c) 2002
 Aladdin Free Public License (see LICENSE for details)
 Allen Day, <allenday@ucla.edu>
 Benjamin R. Ginter <bginter@asicommunications.com>


