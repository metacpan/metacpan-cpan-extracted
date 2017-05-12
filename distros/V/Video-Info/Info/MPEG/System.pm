##------------------------------------------------------------------------
##  Package: Video::Info::MPEG::System
##   Author: Benjamin R. Ginter
##   Notice: Copyright (c) 2002 Benjamin R. Ginter
##  Purpose: Parse system streams
## Comments: None
##      CVS: $Id: System.pm,v 1.3 2002/11/12 07:19:34 allenday Exp $
##------------------------------------------------------------------------

package Video::Info::MPEG::System;
use strict;
use Video::Info::MPEG;
use Video::Info::MPEG::Constants;

use constant DEBUG => 0;
use base qw(Video::Info::MPEG);

##------------------------------------------------------------------------
## Preloaded methods go here.
##------------------------------------------------------------------------
1;

##------------------------------------------------------------------------
## new()
##
## override superclass constructor
##------------------------------------------------------------------------
sub init {
  my $self = shift;
  my %param = @_;
  $self->init_attributes(@_);
  $self->handle($self->filename);
  $self->version(0);
  $self->offset(0);
  $self->last_offset(0);
  $self->{audio} = Video::Info::MPEG::Audio->new(-file => $self->filename);
  $self->{video} = Video::Info::MPEG::Video->new(-context => 'system',
												 -file => $self->filename
												);
}

sub audio { return shift->{audio} }
sub video { return shift->{video} }

##------------------------------------------------------------------------
## parse()
##
## Parse a system packet.
##
## Strategy:
##   - Find the first PACK sequence start code
##   - Search for additional packs ( process_packs() )
##   - 
##------------------------------------------------------------------------
sub parse {
  my ($self,$offset) = @_;

  my $fh             = $self->handle;
  $offset = 0 if !defined $offset;

  my ( $pack_start, $pack_len, $pack_head, $packet_size, $packet_type );

  print "Video::Info::MPEG::System::parse( $offset )\n" if DEBUG;

  ##--------------------------------------------------------------------
  ## Verify we're dealing with a system stream by trying to fetch the 
  ## first sequence start code (ssc).  Save the offset if we succeed.
  ##--------------------------------------------------------------------
  $self->is_system( $offset ) or return 0;
  # $offset = $self->_last_offset if defined $self->_last_offset;
  $offset = 12;

  ##--------------------------------------------------------------------
  ## Find the remaining packs and process them, returning if we find any
  ## audio or video tracks.  We handle padding packets here too.
  ##--------------------------------------------------------------------
  $self->process_packs( $offset ) or return 0;

  # print "OFFSET: $offset $self->{last_offset}\n";
  $offset = $self->_last_offset - 13;

  ## okay, this is a miracle but we have what we wanted here
  ## video!
  if ( !$self->video->parse( $offset ) ) {
	print "parse_system: call to parse_video() failed\n" if DEBUG;
	return 0;
  }
  ## now get the pack and the packet header just before the video sequence
  my $main_offset = $offset;
  print "Finding audio\n" if DEBUG;
  if ( $self->next_start_code( AUDIO_PKT, $offset + $self->header_size ) ) {
	print "Found it at ", $self->_last_offset, "\n" if DEBUG;
	my $audio_offset = $self->skip_packet_header( $self->{last_offset} );
	print "AUDIO OFFSET: $audio_offset $self->{last_offset} \n" if DEBUG;
	
	if ( !$self->audio->parse( $audio_offset ) ) {
	  while ( $audio_offset < $self->filesize - 10 ) {
		## mm, audio packet doesn't begin with FFF
		# print "OFFSET: $audio_offset\n" if DEBUG;
		if ( $self->audio->parse( $audio_offset ) ) {
		  last;
		}
		
		$audio_offset++; ## is this ok?
	  }
	}
	# print "Parsed audio OK!\n";

  }        

  ## seek the file duration by fetching the last PACK
  ## and reading its timestamp
  if ( $self->next_start_code( PACK_PKT, $self->filesize - 2500 ) ) {
	# print "Found final PACK at $self->{last_offset}\n";
  }
  my $byte = $self->get_byte( $self->{last_offset} + 4 );
  
  ## see if it's a standard MPEG1
  if ( $byte & 0xF0 == 0x20 ) {
	$self->duration( $self->read_ts( 1, $self->{last_offset} + 4 ) );
  }
  ## no?
  else {
	## Is it MPEG2?
	if ( $byte & 0xC0 == 0x40 ) {
	  print "TS: ", $self->read_ts( 2, $self->{last_offset} + 4 ), "\n" if DEBUG;
	}
	## try mpeg1 anyway
	else {
	  $self->duration( $self->read_ts( 1, $self->{last_offset} + 4) );
	}
  }
  
  return 1;
}

##------------------------------------------------------------------------
## process_packs()
##
## Step through the bitstream and process each type of pack encountered, 
## stopping if we find any audio or video tracks.
##------------------------------------------------------------------------
sub process_packs {
    my ( $self, $offset ) = @_;
    my $fh                = $self->handle;

    print "\n", '-' x 74, "\nSearching for start code packets\n", '-' x 74, "\n" if DEBUG;

    while ( $offset <= $self->filesize ) {
	## print '-' x 20, '[ LOOP ]', '-' x 20, "\n" if DEBUG;
	## print "OFFSET: $offset\n" if DEBUG;
	
	## Find next start code
	my $code = $self->next_start_code( undef, $offset );

	$offset = $self->_last_offset;
	printf( "Found marker '%s' (0x%02x) at %d\n", 
		$STREAM_ID->{$code}, ## Note the uppercase.  This is defined in Constants.pm
		$code, 
        	$offset ) if DEBUG;

	
	##----------------------------------------------------------------
	## We found what we're looking for (VIDEO or AUDIO)
	##----------------------------------------------------------------
	last if $code == VIDEO_PKT || $code == AUDIO_PKT;

	##----------------------------------------------------------------
	## if this is a PADDING packet for byte alignment
	##----------------------------------------------------------------
	if ( $code == PADDING_PKT ) {
	    # print "\t\tFound Padding Packet at $offset\n";
	    $offset += $self->grab( 2, $offset + 4 );
	    # print "Skipped to $offset\n";
	    next;
	}

	##----------------------------------------------------------------
	## if this is a PACK
	##----------------------------------------------------------------
	elsif ( $code == PACK_PKT ) {
	    $self->{muxrate} = $self->get_mux_rate( $offset + 4);
	    $offset += 12;
	    next;
	}
	
	##----------------------------------------------------------------
	## It has to be a system packet
	##----------------------------------------------------------------
	elsif ( $code == SYS_PKT ) {
	    my $len = $self->parse_sys_pkt( $offset );
	    
	    if ( $len ) {
		$offset = $len;
		next;
	    }	    
	}

	##----------------------------------------------------------------
	## No more guessing
	##----------------------------------------------------------------
	else {
	    printf( "1: Unhandled packet encountered '%s' ( 0x%02x ) at offset %d\n", 
	    	    $STREAM_ID->{$code},
	    	    $code, 
	    	    $offset ) if DEBUG;
#	    $offset += 4;
#	    next;
	}

	$offset += 4;
    }

    return 1;
}

##------------------------------------------------------------------------
## is_system()
##
## Verify this is a system stream.
##------------------------------------------------------------------------
sub is_system {
    my ( $self, $offset ) = @_;

    print "\n", '-' x 74, "\nLooking for System Start Packet\n", '-' x 74, "\n" if DEBUG;


    if ( !$self->next_start_code( PACK_PKT, 0 ) ) {
	print "Couldn't find packet start code\n" if DEBUG;
	return 0;
    }

    print "Warning: junk at the beginning!\n" if DEBUG && $self->_last_offset;
    return 1;
}

##------------------------------------------------------------------------
## get_streams
##
## Parse a system packet and extract the number of streams.
##------------------------------------------------------------------------
sub get_streams {
    my ( $self, $offset ) = @_;
   
    print "\n", '-' x 74, "\nGetting Stream Counts\n", '-' x 74, "\n" if DEBUG;

    my $stream_count_token = $self->grab( 2, $offset + 4 ) - 6;

    return 0 if $stream_count_token % 3 != 0;

    for ( my $i = 0; $i < $stream_count_token / 3; $i++ ) {
	my $code = $self->get_byte( $offset + 12 + $i * 3 );
	
	if ( ( $code & 0xf0 ) == AUDIO_PKT ) {
	    # print "Audio Stream\n" if DEBUG;
	    $self->{astreams}++;
	}
	elsif ( ( $code & 0xf0 ) == VIDEO_PKT || ( $code & 0xf0 ) == 0xD0 ) {
	    # print "Video Stream\n" if DEBUG;
	    $self->{vstreams}++;
	}
    }

    $self->astreams( $self->{astreams} );
    $self->vstreams( $self->{vstreams} );
    # print "\t", $self->astreams, " audio\n";
    # print "\t", $self->vstreams, " video\n";

    return 1 if $self->vstreams;

    return 0;
}

##------------------------------------------------------------------------
## get_version()
##
## Sets the MPEG version.
##------------------------------------------------------------------------
sub get_version {
    my ( $self, $offset ) = @_;

    print "\n", '-' x 74, "\nGetting Version\n", '-' x 74, "\n" if DEBUG;

    ##--------------------------------------------------------------------
    ## Check for variable length PACK in mpeg2
    ##--------------------------------------------------------------------
    $offset           = 0;
    $self->{pack_len} = 0;
    my $pack_head     = $self->get_byte( $offset + 4 );
    
    if ( ( $pack_head & 0xF0 ) == 0x20 ) {
	$self->vcodec('MPEG1');
	print "MPEG1\n" if DEBUG;
	$self->{pack_len} = 12;
    }
    else {
	if ( ( $pack_head & 0xC0 ) == 0x40 ) {
	    ## new mpeg2 pack : 14 bytes + stuffing
	    $self->vcodec('MPEG2');
	    print "MPEG2\n" if DEBUG;
	    $self->{pack_len} = 14 + $self->get_byte( $offset + 13 ) & 0x07;
	}
	else {
	    ## whazzup?!
	    printf "Weird pack encountered! 0x%02x\n", $pack_head if DEBUG;
	    $self->{pack_len} = 12;
	    return 0;
	}
    }
    
    return 1;
}

##------------------------------------------------------------------------
## parse_sys_pkt()
##
## Parse a system packet
##------------------------------------------------------------------------
sub parse_sys_pkt {
    my ( $self, $offset ) = @_;
    my $fh                = $self->handle;

    print "\n", '-' x 74, "\nParsing System Packet\n", '-' x 74, "\n" if DEBUG;

    ## Get the MPEG version then the number of audio and video streams.
    $self->get_version( $offset ) or die "Can't get MPEG version\n";
    $self->get_streams( $offset ) or die "Strange number of packets!\n";

    # print "Getting packet size\n" if DEBUG;
    my $packet_size = $self->grab( 2, $offset + 4 );

    # print "Getting packet type\n" if DEBUG;
    my $packet_type = $self->get_byte( $offset + 12 );

    my $byte = $self->get_byte( $offset + 15 );
    # printf "PACKET_TYPE: %02x\n", $packet_type;
    # printf "BYTE: %02x\n", $byte;

    my $header_len = 0;

    if ( $byte == AUDIO_PKT || $byte == VIDEO_PKT ) {
	# print "System packet with both audio and video\n" if DEBUG;
	$packet_type = VIDEO_PKT; ## since video is mandatory
	
	$header_len = $self->{pack_len} + 6 + $packet_size;

	## We could grab the entire video header here and pass it off
	## to MPEG::Info::Video to avoid the seek/read penalties
    }
    
    ##--------------------------------------------------------------------
    ## If we ever encounter a packet with multiple audio or video streams,
    ## we can implement this.
    ##--------------------------------------------------------------------
    if ( $packet_type != AUDIO_PKT && $packet_type != VIDEO_PKT ) {
	printf "Unknown system packet '%s', %x @ $offset\n", $STREAM_ID->{$packet_type},
	$packet_type if DEBUG;
	return 0;
    }

    print "\n", '-' x 74, "\nEnd System Packet Parse\n", '-' x 74, "\n" if DEBUG;
    return $header_len;
}

##------------------------------------------------------------------------
## read_ts()
##
## Read an MPEG-1 or MPEG-2 timestamp
##------------------------------------------------------------------------
sub read_ts {
    my $self   = shift;
    my $type   = shift;
    my $offset = shift;

    my $ts = 0;

    if ( $type == 1 ) {
	my $highbit   = (   $self->get_byte( $offset     ) >> 3  ) & 0x01;
	my $low4bytes = ( ( $self->get_byte( $offset     ) >> 1  ) & 0x30 ) << 30;
	$low4bytes   |= (   $self->get_byte( $offset + 1 ) << 22 );
	$low4bytes   |= ( ( $self->get_byte( $offset + 2 ) >> 1  ) << 15 );
	$low4bytes   |= (   $self->get_byte( $offset + 3 ) << 7  );
	$low4bytes   |= (   $self->get_byte( $offset + 4 ) >> 1  );

	$ts = $highbit * ( 1 << 16 );
	$ts += $low4bytes;
	$ts /= 90000;
    }
    elsif ( $type == 2 ) {
	print "Define mpeg-2 timestamps\n" if DEBUG;
    }
    return $ts;

}

##------------------------------------------------------------------------
## skip_packet_header()
##
## Skip a packet header
##------------------------------------------------------------------------
sub skip_packet_header {
    my $self   = shift;
    my $offset = shift;

    if ( $self->version == 1 ) {
	## skip startcode and packet size
	$offset += 6;

	## remove stuffing bytes
	my $byte = $self->get_byte( $offset );

	while ( $byte & 0x80 ) {
	    $byte = $self->get_byte( ++$offset );
	}

	## next two bytes are 01
	if ( ( $byte & 0xC0 ) == 0x40 ) {
	    $offset += 2;
	}
	
	$byte = $self->get_byte( $offset );

	if ( ( $byte & 0xF0 ) == 0x20 ) {
	    $offset += 5;
	}
	elsif ( ( $byte & 0xF0 ) == 0x30 ) {
	    $offset += 10;
	}
	else {
	    $offset++;
	}

	# print "1. Returning offset of $offset\n" if DEBUG;
	
	return $offset;
    }
    elsif ( $self->version == 2 ) {
	## this is a PES, easyer
	## offset + 9 is the header length (-9)

	# print "2. Returning offset of ", $offset + 9 + ( $self->get_byte + 8 ), "\n" if DEBUG;
	return $offset + 9 + ( $self->get_byte + 8 );
    }
    else {
	# print "3. Returning offset of ", $offset + 10, "\n" if DEBUG;
	return $offset + 10;
    }
}

##------------------------------------------------------------------------
## get_mux_rate()
##
## Calculate the mux rate
##------------------------------------------------------------------------
sub get_mux_rate {
    my $self   = shift;
    my $offset = shift || $self->{offset};

    print "\n", '-' x 74, "\nGetting Muxrate @ $offset\n", '-' x 74, "\n" if DEBUG;

    my $muxrate = 0;

    my $byte = $self->get_byte( $offset );

    if ( ( $byte & 0xC0 ) == 0x40 ) {
	$muxrate  = $self->get_byte( $offset + 6 ) << 14;
	$muxrate |= $self->get_byte( $offset + 7 ) << 6;
	$muxrate |= $self->get_byte( $offset + 8 ) >> 2;
    }
    else {
	## maybe mpeg1
	if ( ( $byte & 0xf0 ) != 0x20 ) {
	    print "Weird pack header while parsing muxrate (offset ", $offset, ")\n" if DEBUG;
	    # die;
	}

	$muxrate  = ( $self->get_byte( $offset + 5 ) & 0x7f ) << 15;
	$muxrate |=   $self->get_byte( $offset + 6 ) << 7;
	$muxrate |=   $self->get_byte( $offset + 7 ) >> 1;
    }
    
    $muxrate *= 50;
    return $muxrate;
}



__END__

=head1 AUTHORS

 Copyright (c) 2002
 Aladdin Free Public License (see LICENSE for details)
 Allen Day, <allenday@ucla.edu>
 Benjamin R. Ginter <bginter@asicommunications.com>


