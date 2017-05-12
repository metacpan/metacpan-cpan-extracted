##------------------------------------------------------------------------
##  Package: Video::Info::MPEG::Audio
##   Author: Benjamin R. Ginter
##   Notice: Copyright (c) 2001 Benjamin R. Ginter
##  Purpose: Parse audio streams
## Comments: None
##      CVS: $Id: Audio.pm,v 1.3 2002/11/12 07:19:34 allenday Exp $
##------------------------------------------------------------------------

package Video::Info::MPEG::Audio;
use strict;
use Video::Info::MPEG qw( $AUDIO_BITRATE );
use Video::Info::MPEG::Constants;

use constant DEBUG => 0;
use base qw(Video::Info::MPEG);

our $AUDIO_BITRATE;
our $AUDIO_SAMPLING_RATE;

##------------------------------------------------------------------------
## Preloaded methods go here.
##------------------------------------------------------------------------
1;

sub init {
  my $self = shift;
  my %param = @_;
  $self->handle($self->filename($param{-file}));
  $self->init_attributes;
  $self->version(0);
}

##------------------------------------------------------------------------
## parse()
##
## Parse an audio packet.  Since this is in the context of a video stream,
## we only care about the MPEG version, layer, bitrate, sampling rate,
## channels, and emphasis.  
##
##------------------------------------------------------------------------
sub parse {
    my($self,$offset) = @_;

    $offset = 0 if !defined $offset;
    $self->{offset} = $offset;

    $self->{_bytes} = $self->get_header();
    # printf "0x%08x\n", unpack( "N", pack( "C*", @{$self->{_bytes}} ) );

    print "Video::Info::MPEG::Audio::parse( $offset )\n" if DEBUG;

    #print "parse audio: $offset\n";
    $self->is_audio() or return 0;

    $self->get_version && $self->get_layer         or return 0;
    $self->get_bitrate && $self->get_sampling_freq or return 0;
#    $self->get_protect;
    $self->get_audio_mode();
#    $self->get_copyright();
#    $self->get_padding();
#    $self->get_emphasis();
     #$self->get_frame_length();

    #if we made it this far, assume a bona fide MPEG
    $self->type('MPEG');

    if ( DEBUG ) {
	  print '-' x 74, "\n", 'Parse Audio', "\n", '-' x 74, "\n";

	  print "MPEG-$self->{version} Layer $self->{layer}\n";
	  print "         MODE: $self->{mode}\n";
	  print "      BITRATE: $self->{bitrate}\n";
	  print "     BYTERATE: $self->{byterate}\n";
	  print "SAMPLING RATE: $self->{sampling}\n";
	  print "      PADDING: $self->{padding}\n";
	  print "     EMPHASIS: $self->{emphasis}\n";
	  print "    COPYRIGHT: $self->{copyright}\n";
	  print "      PROTECT: $self->{protect}\n";
	  # print " FRAME_LENGTH: $self->{frame_length}\n";
	  print "Audio : Mpeg $self->{version} layer $self->{layer}\n";
	  print "$self->{bitrate} kbps  $self->{sampling} Hz\n";
	  print "$self->{mode}, $self->{emphasis}\n";
    }
	
    ## Save off some information to a format Video::Info expects.
    ## The $self-> hash remains available for the user if needed.

    $self->arate    ( $self->{byterate} * 8 );
    $self->copyright( $self->{copyright} );

    return 1;
}

##------------------------------------------------------------------------
## is_audio()
##
## Verify we have the proper MPEG audio packet start codes
##------------------------------------------------------------------------
sub is_audio {
    my $self  = shift;
    my $bytes = $self->{_bytes};

    ## ensure that the first two bytes are FFFx
    return 0 if $bytes->[0] != 0xFF;

    if ( ( $bytes->[1] & 0xF0 ) != 0xF0 ) {
	## Doesn't start with 12 bits set
	
	if ( ( $bytes->[1] & 0xE0 ) != 0xE0 ) {
	    ## Doesn't start with 11 bits set either -- give up
	    return 0;
	}
#	else {
	    ## starts with 11 bits set
	    $self->{version} = 2.5;
#	}
    }
    return 1;

}

##------------------------------------------------------------------------
## get_version()
##
## Determine the MPEG Version
##------------------------------------------------------------------------
sub get_version {
  my $self = shift;

  ## find mpeg version 1.0 or 2.0
  if ( $self->{_bytes}->[1] & 0x08 ) {
	if ( $self->{version} != 2.5 ) {
	  $self->{version} = 1;
	  $self->acodecraw(0x50);
	}
	else {
	  ## invalid 01 encountered
	  return 0;
	}
  } else {
	if ( $self->{version} != 2.5 ) {
	  $self->{version} = 2;
	  $self->acodecraw(0x50);
	} else {
	  ## err, isn't this set?
	  $self->{version} = 3; 
	  $self->acodecraw(0x55);
	}
  }
  return 1;
}

##------------------------------------------------------------------------
## get_layer()
##
## Determine the MPEG layer
##------------------------------------------------------------------------
sub get_layer {
    my $self = shift;

    ## Find layer
    my $layer = ( $self->{_bytes}->[1] & 0x06 ) >> 1;
    if ( $layer == 0 ) {
	$self->{layer} = -1;
	return 0;	
    }
    elsif ( $layer == 1 ) {
	$self->{layer} = 3;
    }
    elsif ( $layer == 2 ) {
	$self->{layer} = 2;
    }
    elsif ( $layer == 3 ) {
	$self->{layer} = 1;
    }
    else {
	$self->{layer} = $layer;
	print "Unknown audio layer index: $layer\n";
	return 0;
    }
    # undef $layer;

    return 1;
}

##------------------------------------------------------------------------
## get_audio_mode()
##
## Determine the audio mode (channels, etc.)
##------------------------------------------------------------------------
sub get_audio_mode {
    my $self = shift;

    ## Get the raw audio mode
    $self->{mode_raw} = $self->{_bytes}->[3] >> 6;
    $self->{mode_raw} == 1 ? $self->{modext} = ( $self->{_bytes}->[3] >> 4 ) & 0x03 : $self->{modext} = 1;

    $self->achans( 2 );

    ## Now decode it
    if ( $self->{mode_raw} == 0 ) {
	  $self->{mode} = 'Stereo';
	  $self->achans(2);
    }
    elsif ( $self->{mode_raw} == 1 ) {
	if ( $self->{layer} == 1 || $self->{layer} == 2 ) {
	    if ( $self->{modext} == 0 ) {
		$self->{mode} = 'Intensity stereo on bands 4-31/32';
	    }
	    elsif ( $self->{modext} == 1 ) {
		$self->{mode} = 'Intensity stereo on bands 8-31/32';
	    }
	    elsif ( $self->{modext} == 2 ) {
		$self->{mode} = 'Intensity stereo on bands 12-31/32';
	    }
	    elsif ( $self->{modext} == 3 ) {
		$self->{mode} = 'Intensity stereo on bands 16-31/32';
	    }
	    else {
		$self->{mode} = "Unknown audio mode extension.  Mode=$self->{mode_raw}  Ext: $self->{modext}";
		return 0;
	    }
	}
	else {
	    ## mp3
	    if ( $self->{modext} == 0 ) { 
		$self->{mode} = 'Intensity stereo off, M/S stereo off';
	    } 
	    elsif ( $self->{modext} == 1 ) { 
		$self->{mode} = 'Intensity stereo on, M/S stereo off';
	    } 
	    elsif ( $self->{modext} == 2 ) { 
		$self->{mode} = 'Intensity stereo off, M/S stereo on';
	    } 
	    elsif ( $self->{modext} == 3 ) {
		$self->{mode} = 'Intensity stereo on, M/S stereo on';
	    } 
	    else {
		$self->{mode} = "Unknown audio mode extension.  Mode=$self->{mode_raw}  Ext: $self->{modext}";
		return 0;
	    }
	    
        }
    }
    elsif ( $self->{mode_raw} == 2 ) {
	  $self->{mode} = 'Dual Channel';
	  $self->achans(2); #not stereo, but still 2, right?  brg: yes
    }
    elsif ( $self->{mode_raw} == 3 ) {
	  $self->{mode} = 'Mono';
	  $self->achans(1);
    }
    else {
	$self->{mode} = "Unknown audio mode.  Mode=$self->{mode_raw}  Ext: $self->{modext}";
	$self->achans(0);
	return 0;
    }

    return 1;
}

##------------------------------------------------------------------------
## get_copyright()
##------------------------------------------------------------------------
sub get_copyright {
    my $self = shift;

    ## Set original/copyright bit
    $self->{_bytes}->[3] & 0x04 ? $self->{copyright} = 1 : $self->{copyright} = 0;
}

##------------------------------------------------------------------------
## get_protect()
##
## Extract the protection bit
##------------------------------------------------------------------------
sub get_protect {
    my $self = shift;

    ## Get protection bit
    $self->{_bytes}->[1] & 0x01 ? $self->{protect} = 0 : $self->{protect} = 1;

}

##------------------------------------------------------------------------
## get_bitrate()
##------------------------------------------------------------------------
sub get_bitrate {
    my $self = shift;

    ## Bitrate index and sampling index to pass through the array
    my $bitrate_index  = $self->{_bytes}->[2] >> 4;
    return 0 if $bitrate_index == 15;

    $self->{bitrate}  = $AUDIO_BITRATE->{ $self->{version} }->{ $self->{layer} }->[ $bitrate_index ];
    $self->{byterate} = ( $self->{bitrate} * 1000 ) / 8.0;

    return 1;
}

##------------------------------------------------------------------------
## get_sampling_freq()
##------------------------------------------------------------------------
sub get_sampling_freq {
    my $self = shift;

    my $sampling_index = ( $self->{_bytes}->[2] & 0x0F ) >> 2;
    # print "sampling_index: $sampling_index\n";

    return 0 if $sampling_index == 3;

    $self->{sampling} = $AUDIO_SAMPLING_RATE->{ $self->{version} }->[ $sampling_index ];
    return 1;
}

##------------------------------------------------------------------------
## get_padding()
##------------------------------------------------------------------------
sub get_padding {
    my $self = shift;

    ## Get padding bit
    $self->{_bytes}->[2] & 0x02 ? $self->{padding} = 1 : $self->{padding} = 0;
}

##------------------------------------------------------------------------
## get_emphasis()
##------------------------------------------------------------------------
sub get_emphasis {
    my $self = shift;

    ## Get emphasis
    my $emphasis_index = $self->{_bytes}->[3] & 0x03;

    if ( $emphasis_index == 0 ) {
	$self->{emphasis} = 'No Emphasis';
    }
    elsif ( $emphasis_index == 1 ) {
	$self->{emphasis} = '50/15us';
    }
    elsif ( $emphasis_index == 2 ) {
	$self->{emphasis} = 'Unknown';
    }
    elsif ( $emphasis_index == 3 ) {
	$self->{emphasis} = 'CCITT J 17';
    }
    else {
	$self->{emphasis} = 'Undefined';
    }

}

##------------------------------------------------------------------------
## get_frame_length()
##------------------------------------------------------------------------
sub get_frame_length {
    my $self = shift;

    ## Get frame-length
    if ( $self->{version} == 1 ) {
	if ( $self->{layer} == 1 ) {
	    $self->{frame_length} = int( ( 48000 * $self->{bitrate} ) / $self->{sampling} ) + 4 * $self->{padding};
	}
	else {
	    $self->{frame_length} = int( ( 72000 * $self->{bitrate} ) / $self->{sampling} ) + $self->{padding};
	}
    }
    else {
	print "Audio layer invalid : should be 1 or 2\n";
	return 0;
    }

    if ( $self->{protect} ) {
	$self->{frame_length} += 2;
    }
}

1;

__END__

=head1 AUTHORS

 Copyright (c) 2002
 Aladdin Free Public License (see LICENSE for details)
 Allen Day, <allenday@ucla.edu>
 Benjamin R. Ginter <bginter@asicommunications.com>


