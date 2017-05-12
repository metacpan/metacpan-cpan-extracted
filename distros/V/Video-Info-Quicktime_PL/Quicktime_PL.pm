package Video::Info::Quicktime_PL;

use strict;
use Video::Info;

use base qw(Video::Info);

our $VERSION = '0.07';
use constant DEBUG => 0;

use Compress::Zlib;

use Class::MakeMethods::Emulator::MethodMaker
    get_set => [ qw( version rsrc_id pict acodec raw_headers )],
    ;


sub init {
    my $self = shift;
    my %param = @_;
    $self->init_attributes(@_);
    return $self;
}

sub my_read
{
    my($source, $len) = @_;
    my $buf;
    my $n = read($source, $buf, $len);
    die "read failed: $!" unless defined $n;
    die caller()." short read ($len/$n)" unless $n == $len;
    $buf;
}

sub time_to_date {
    my $self = shift;
    my ($tmp) = @_;
    
    # seconds difference between Mac epoch and Unix.
    my $mod = 2063824538 - 12530100;  
    my $date = ($^O =~ /mac/i) ? localtime($tmp) : localtime($tmp-$mod);
        
    return $date;
}

sub probe {
    my $self = shift;
    
    seek($self->handle,0,2);
    my($file_length) = tell($self->handle); seek($self->handle,0,0);
        
    my($len, $sig) = unpack("Na4", my_read($self->handle, 8));
    
    my %pnot;
    while ( ($sig !~ /moov$/) and (!eof($self->handle)) ) {
        if ($sig =~ m/pnot$/) {
            # optional preview data is present... go ahead and process it.
            my $prevue_atom = my_read( $self->handle, $len-8 );

            # print map{" $_ => $pnot{$_}\n" } sort keys %pnot;
            ($len, $sig) = unpack("Na4", my_read($self->handle, 8));
            if ($sig eq 'PICT') {
                $self->pict(my_read( $self->handle, $len-8 ));
                
                ### Test preview during debug by outputing here:
                # open(O,">out.pict");
                # print O "\x00" x 512;
                # print O $self->pict;
                # close(O);
            }
            $len=8;
        }
        seek( $self->handle, $len-8, 1 );
        ($len, $sig) = unpack("Na4", my_read($self->handle, 8));
        print "".($len-8)."\t".$sig."\n" if DEBUG;
    }
    die "Unable to find 'moov' MOV signature.' " unless ( $sig =~ m/moov$/ );
    
    # $self->date($self->time_to_date(unpack('Na4', substr($prevue_atom,0,4,''))));
    # $self->version(hex( substr($prevue_atom,0,2,'') ));
    $self->type( $sig );
    # $self->rsrc_id(unpack('H2',$prevue_atom));
    
    my $mov_atom = my_read( $self->handle, $len-8 );
    my %mov = construct_hash( $mov_atom );
    
    $self->process_mov_atom(%mov);
    
    return 1;
}

sub process_mov_atom {
    my $self = shift;
    my %mov = @_;

    my $cnt = 0;
    foreach my $key (keys %mov) {
        # print "Mov->key: ".$key."\n";
        if ($key eq 'cmov') { 
            # compressed movie atom --- should be the only atom
            my($len, $sig) = unpack("Na4", substr($mov{$key},0,8,''));
            
            # find out the compression method
            my $cmpr_mthd = substr($mov{$key},0,4,'');
            
            ($len, $sig) = unpack("Na4", substr($mov{$key},0,8,''));
            # and extract the compressed data.
            my ($uncmprlen) = unpack("Na4", substr($mov{$key},0,4,''));
            my $moov_rsrc = substr($mov{$key},0,$len-8);
            
            if ($cmpr_mthd eq 'zlib') {
                my ($dest) = uncompress($moov_rsrc);
                die "Error extracting compressed movie header data." if
                    ( $uncmprlen ne length($dest) );
                
                ($len,$sig) = unpack("Na4", substr($dest,0,8,''));
                
                # open(O,">cmov"); print O $dest; close(O);
                # print "== recursive call to parse mov header ==\n";
                $self->process_mov_atom( construct_hash( $dest ) );
                return;
            }
        } elsif ($key eq 'mvhd') { 
            my(%h);
            %h = get_mvhd( $mov{$key} );
            # converting duration to movie length in seconds...
            $self->duration( sprintf('%.2f',
                                     ($h{'Duration'}/$h{'Time_scale'}) ) );
            # print "\n   mvhd\n\n";
            # print map {"$_ => $h{$_}\n"} keys %h;
            
        } else {
            my (%hash) = construct_hash( $mov{$key} );
            if ($key =~ m/udta/) {
                # each of these atoms uses a 4-byte (long) length
                # offset before the ASCII text data... so strip it off
                # before pushing to the output.
                $self->copyright( substr($hash{"\xA9cpy"},4) )
                    if exists($hash{"\xA9cpy"});
                $self->title( substr($hash{"\xA9nam"},4) )
                    if exists($hash{"\xA9nam"});
            }
            elsif ($key =~ m/trak/) {
                my %tkhd = get_track_head( $hash{'tkhd'} );
                # print map {"$_ => $tkhd{$_}\n"} keys %tkhd;
                my %mdia = construct_hash( $hash{'mdia'} );
                # print map {"$_ => $mdia{$_}\n"} keys %mdia;
                my %minf = construct_hash( $mdia{'minf'} );
                # print map {"$_ => $minf{$_}\n"} keys %minf;
                my %stts;

                if ( exists $minf{'vmhd'} ) {
                    $self->width($tkhd{'Track width'});
                    $self->height($tkhd{'Track height'});

                    my $tmp = $self->vstreams + 1;
                    $self->vstreams( $tmp );
                    
                    my %stbl = construct_hash( $minf{'stbl'} );
                    my %stsd = get_stsd( $stbl{'stsd'} ); 
                    # print map {" $_=$stsd{$_}\n"} keys %stsd;
                    %stts = get_stts( $stbl{'stts'} );
                    $cnt = $cnt + $stts{'count'} if exists($stts{'count'});

                    # print map {" $_ = $stts{$_}\n"} keys %stts;
                    
                    $self->vcodec( $stsd{'compression type'} );
                    
                }
                if ( exists $minf{'smhd'} ) {
                    my %stbl = construct_hash( $minf{'stbl'} );
                    # print " stbl keys: ";
                    # print map {" $_\n"} keys %stbl;
                    my %stsd = get_stsd( $stbl{'stsd'} );
                    # print map {" $_=$stsd{$_}\n"} keys %stsd;
                    
                    my $tmp = $self->astreams + 1;
                    $self->astreams( $tmp );

                    $self->arate($stsd{'audio sample rate'});
                    $self->afrequency($stsd{'audio sample size'});
                    $self->achans($stsd{'audio channels'});
                    $self->acodec($stsd{'compression type'});
                }
            }
        }
    }
    $self->vframes( $cnt );
    $self->fps( $cnt / $self->duration );

}

sub construct_hash {
    my ( $input ) = @_;
    my %hash;
    while (length($input) > 0) {
        my($len)   = unpack("Na4",  substr( $input, 0, 4, '') );
        my($cntnt) = substr( $input, 0, $len-4, '');
        my($type)  = substr( $cntnt, 0, 4, '');
        # print $type."\t".$len."\n";
        if ( exists $hash{$type} ) {
            my @a = grep($type,keys %hash);
            $hash{$type.length(@a)} = $cntnt;
        } else {
            $hash{$type} = $cntnt;
        }
    }
    %hash;
}

sub get_stts {
    my ($cntnt) = @_;
    my (%h);
    
    $h{'Version'}          = hex(unpack("H*", substr($cntnt,0,2,'') ));
    $h{'Flags'}            = unpack("H*", substr($cntnt,0,6,'') );	
    ### number of image frames in this atom
    $h{'count'}            = hex(unpack("H*", substr($cntnt,0,4,'') ));
    ### number of tens-of-seconds per image
    $h{'duration'}         = hex(unpack("H*", substr($cntnt,0,4,'') ));
    ### count * duration / mvhd->Time_scale = length of movie (in seconds)
    %h;
}

sub get_stsd {
    # from pg 60:
    my ($cntnt) = @_;
    my (%h);
    $h{'Version'}          = unpack( "n2", substr($cntnt,0,2,'') );	
    $h{'Flags'}            = unpack("H*", substr($cntnt,0,6,'') );	
    my $len = unpack("Na",substr($cntnt,0,4,''));
    ($h{'compression type'} = substr($cntnt,0,8,'')) =~ s/\W(.*?)\W/$1/g;
    $h{'Version'}           = unpack( "n2", substr($cntnt,0,2,'') );
    $h{'Revision_level'}    = unpack( "n2", substr($cntnt,0,2,'') );
    ($h{'Vendor'}           = unpack("a8",substr($cntnt,0,8,'')))=~s/\W//g;
    
    if ( length($h{'Vendor'}) eq 0 ) {
        $h{'audio channels'} = hex(unpack( "H*", substr($cntnt,0,2,'')));  
        $h{'audio sample size'}  = hex(unpack( "H*", substr($cntnt,0,2,'')));  
        # $h{'audio compression'}  = unpack( "H*", substr($cntnt,0,2,''));  /
        $h{'audio packet size'}  = hex(unpack( "H*", substr($cntnt,0,2,'')));  
        $h{'audio sample rate'}  = hex(unpack( "H*", substr($cntnt,0,4,'')));  
        substr($cntnt,0,18,'');
    } else {
        $h{'Temporal_Quality'} = unpack( "Na", substr($cntnt,0,4,''));  
        $h{'Spatial_Quality'}  = unpack( "Na", substr($cntnt,0,4,''));  
        $h{'Width'}           = hex( unpack( "H4", substr($cntnt,0,2,'')));
        $h{'Height'}          = hex( unpack( "H4", substr($cntnt,0,2,'')));
        $h{'Horz_res'}        = hex( unpack("H4",substr($cntnt,0,4,'')));
        $h{'Vert_res'}        = hex( unpack("H4",substr($cntnt,0,4,'')));
        $h{'Data_size'}       = hex( unpack("H2",substr($cntnt,0,2,'')));
        $h{'Frames_per_sample'} = hex( unpack("H*",substr($cntnt,0,4,'')));
        $h{'Compressor_name'} = $1 if
            ( substr($cntnt,0,32,'') =~ m/\W(.+?)\x00+$/) ;
        $h{'Depth'}           = hex( unpack( "H4", substr($cntnt,0,2,'')));
        $h{'Color_table_ID'}  = unpack( "s", substr($cntnt,0,2,''));  
    }
    
    # Collect any table extensions:
    while (length($cntnt)>0) {
        my($len, $sig) = unpack("Na4", substr($cntnt,0,8,''));
        $h{$sig} = unpack("H".2*($len-4),substr($cntnt,0,$len-4,''));
    }
    # print length($cntnt)."\t".unpack("H".2*length($cntnt),$cntnt)."\n";
    # print map {" $_ => $h{$_}\n"} sort keys %h;
    %h;
}

sub get_mvhd {
    #  my $self = shift;
    my ($cntnt) = @_;
    my (%h);
    
    $h{'Version'}            = unpack( 'C', substr($cntnt,0,1,'') );
    $h{'Flags'}              = hex( substr($cntnt,0,3,'') );	
    $h{'Creation_time'}      = unpack( "Na4", substr($cntnt,0,4,''));   
    $h{'Modification_time'}  = unpack( "Na4", substr($cntnt,0,4,''));   
    $h{'Time_scale'}         = unpack( "Na4", substr($cntnt,0,4,''));  
    $h{'Duration'}           = unpack( "Na4", substr($cntnt,0,4,''));  
    $h{'Preferred_rate'}     = unpack( "n", substr($cntnt,0,4,''));
    $h{'Preferred_volume'}   = unpack( "n", substr($cntnt,0,2,''));
    $h{'Reserved'}           = unpack( "H20", substr($cntnt,0,10,''));
    $h{'Matrix_structure'}   = unpack( "H72", substr($cntnt,0,36,''));
    $h{'Preview_time'}       = unpack( "Na4", substr($cntnt,0,4,''));  
    $h{'Preview_duration'}   = unpack( "Na4", substr($cntnt,0,4,''));  
    $h{'Poster_time'}        = unpack( "Na4", substr($cntnt,0,4,''));  
    $h{'Selection_time'}     = unpack( "Na4", substr($cntnt,0,4,''));  
    $h{'Selection_duration'} = unpack( "Na4", substr($cntnt,0,4,''));  
    $h{'Current_time'}       = unpack( "Na4", substr($cntnt,0,4,''));  
    $h{'Next_track_ID'}      = unpack( "Na4", substr($cntnt,0,4,''));  
    # print map {" $_ => $h{$_}\n"} sort keys %h;
    %h;
}

sub get_track_head {
    my ($track) = @_;
    
    my (%tkhd);
    
    $tkhd{'Version'} = hex( unpack("H*",substr($track,0,1 ,'') ));
    $tkhd{'Flags'} = unpack( "Na4", substr($track,0,3,'') );
    $tkhd{'Creation time'} = unpack( "Na4", substr($track,0,4 ,''));
    $tkhd{'Modification time'} = unpack( "Na4", substr($track,0,4 ,''));
    $tkhd{'Track ID'} = unpack( "Na4", substr($track,0,4 ,''));
    $tkhd{'Reserved'} = unpack( "Na4", substr($track,0,4 ,''));
    $tkhd{'Duration'} = unpack( "Na4", substr($track,0,4 ,''));
    $tkhd{'Reserved'}  = unpack( "Na8", substr($track,0,8 ,''));
    $tkhd{'Layer'} = unpack( "Na2", substr($track,0,2 ,''));
    $tkhd{'Alternate group'} = unpack( "Na2", substr($track,0,2 ,''));
    $tkhd{'Volume'}= unpack( "Na2", substr($track,0,2 ,''));
    $tkhd{'Reserved'}= unpack( "Na2", substr($track,0,2 ,''));
    $tkhd{'Matrix structure'}= unpack( "H36", substr($track,0,36,''));
    $tkhd{'Track width'}  = hex unpack( "H4", substr($track,0,4,'') );
    $tkhd{'Track height'} = hex unpack( "H4", substr($track,0,4,'') );
    
    # print map {" $_ => $tkhd{$_}\n"} sort keys %tkhd;
    %tkhd;
}

1;

=head1 NAME
    
Video::Info::Quicktime_PL - pure Perl implementation to extract header info from Quicktime (TM) files.
    
=head1 SYNOPSIS
    
    use Video::Info::Quicktime;

    my $file = Video::Info::Quicktime_PL->new(-file=>'eg/rot_button.mov');
    $file->probe;
    printf("frame size: %d x %d\n", $file->width, $file->height );
    printf("fps: %d, total length: %d (sec)\n", $file->fps, $file->duration );


    ## some digital cameras which are able to record Quicktime videos
    ## include a preview picture:

    if (length($file->pict)>0) {
        print "Outputing PICT file\n";
        my $oi = 'eg/mov_preview.pict';
        open(O,">$oi") || warn("Couldn't open $oi: $!\n");
        binmode(O);  # set the file to binary mode in working on Windows
        # Image::Magick methods will only recognize this file as 
        # PICT if there exists a leading header of zeros:
        print O "\x00" x 512;
        print O $file->pict;
        close(O);
    }


=head1 DESCRIPTION

This module provides cursory access to the header information of
Quicktime Movie files.  The original motivation for the development of
this module was to aid in thumbnail generation for HTML index files.
Thus, only a limited amount of information is returned.  See the test
files for a complete list.

If the Video::OpenQuicktime package is installed, you may consider
using Video::Info::Quicktime instead of this module.  Based on the
OpenQuicktime library, more complete header information is available
but at the cost of increased module and library dependancy.


=head1 AUTHOR

Copyright (c) 2003
Released under the Aladdin Free Public License (see LICENSE for details)

Pure Perl Implementation by W. Scott Hoge <shoge at perl dot org>
Hooks for Video::Info access by Allen Day <allenday at ucla dot edu>

=head1 SEE ALSO

L<perl>
L<Video::Info>
L<Video::OpenQuicktime>

=cut

__END__

