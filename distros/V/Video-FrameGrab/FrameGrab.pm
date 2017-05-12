###########################################
package Video::FrameGrab;
###########################################

use strict;
use warnings;
use Sysadm::Install qw(bin_find tap slurp blurt);
use File::Temp qw(tempdir);
use DateTime;
use DateTime::Duration;
use DateTime::Format::Duration;
use Imager;

use Log::Log4perl qw(:easy);

our $VERSION = "0.07";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        mplayer   => undef,
        tmpdir    => tempdir(CLEANUP => 1),
        meta      => undef,
        video     => undef,
        aspects   => ['16:9', '4:3'],
        test_dont_snap => 0,
        %options,
    };

    if(! defined $self->{video}) {
        LOGDIE "Parameter missing: video";
    }

    if(! defined $self->{mplayer}) {
        $self->{mplayer} = bin_find("mplayer"),
    }

    if(!defined $self->{mplayer} or ! -x $self->{mplayer}) {
        LOGDIE "Fatal error: Can't find mplayer";
    }

    bless $self, $class;
}

###########################################
sub snap {
###########################################
    goto &frame_grab;
}

###########################################
sub frame_grab {
###########################################
    my($self, $time) = @_;

    if($self->{test_dont_snap}) {
        INFO "Test mode, no snap";
        return $self->{jpeg_data};
    }

    my $tmpdir = $self->{tmpdir};

    for (<$tmpdir/*>) {
        unlink $_;
    }

    my($stdout, $stderr, $rc) = 
        tap $self->{mplayer}, qw(-frames 1 -ss), $time, 
            "-vo", "jpeg:maxfiles=1:outdir=$self->{tmpdir}",
            "-ao", "null",
            $self->{video};

    if($rc != 0) {
        ERROR "$stderr";
        return undef;
    }

    my $frame = "$self->{tmpdir}/00000001.jpg";

    if(! -f $frame) {
        ERROR "$stderr";
        return undef;
    }

    $self->{jpeg} = slurp("$self->{tmpdir}/00000001.jpg");
    return $self->{jpeg}
}

###########################################
sub cropdetect {
###########################################
    my($self, $time, $opts) = @_;

    if(!defined $time) {
        LOGDIE "Missing parameter: time";
    }

    $opts = {} unless defined $opts;
    $opts->{algorithm} = "schilli" unless exists $opts->{algorithm};

    my $algo = $opts->{algorithm};

    my $method = "cropdetect_$algo";

    return $self->$method( $time, $opts );
}

###########################################
sub cropdetect_schilli {
###########################################
    my($self, $time, $opts) = @_;

    $opts = {} unless defined $opts;

    $opts->{min_intensity_average} = 20 unless 
        exists $opts->{min_intensity_average};

    $opts->{gaussian_blur_radius} = 3 unless 
        exists $opts->{gaussian_blur_radius};

    my $img;

    if(exists $opts->{image}) {
        $img = $opts->{image};
    } else {
        my $data = $self->snap( $time );
        $img = Imager->new();
        my $rc = $img->read( data => $data );
        die $img->errstr() unless $rc;
    }

    $img->filter( type => "gaussian", 
                  stddev => $opts->{gaussian_blur_radius} );

    my $width  = $img->getwidth();
    my $height = $img->getheight();

    my $borders = { left => 0, right => 0, lower => 0, upper => 0 };

    for my $traverse (
                       ["upper", 0,        0,         1, 0,  0,  1],
                       ["left",  0,        0,         0, 1,  1,  0],
                       ["right", $width-1, 0,         0, 1, -1,  0],
                       ["lower", 0,        $height-1, 1, 0,  0, -1],
                     ) {

        my($trav_name, $x, $y, $dx, $dy, $mdx, $mdy) = @$traverse;
        my $border_width = 0;

        while($x < $width and $x >= 0 and $y >= 0 and $y < $height) {
            my $avg = $self->intensity_average( 
                    $img, $width, $height, $x, $y, $dx, $dy );

            TRACE "Intensity[$trav_name,$x,$y]: $avg";

            if($avg < $opts->{min_intensity_average}) {
                $border_width++;
                $x += $mdx;
                $y += $mdy;
                next;
            }

            last;
        }

        DEBUG "Border[$trav_name]: $border_width";
        $borders->{$trav_name} = $border_width;
    }

    my $cw = $width - $borders->{left} - $borders->{right};
    my $ch = $height - $borders->{upper} - $borders->{lower};
    my $cx = $borders->{left};
    my $cy = $borders->{upper};

    DEBUG "Crop detect: $cw, $ch, $cx, $cy";
    return ($cw, $ch, $cx, $cy);
}

###########################################
sub intensity_average {
###########################################
    my($self, $img, $width, $height, $x, $y, $dx, $dy) = @_;

    DEBUG "intensity_average: $width, $height, $x, $y, $dx, $dy";

    my $intensity   = 0;
    my $data_points = 0;

    while($x < $width and $x >= 0 and $y >= 0 and $y < $height) {
        my $color = $img->getpixel( x => $x, y => $y );

        if(! defined $color) {
            LOGDIE "Failed to obtain pixel $x/$y";
        }

        my @comps = $color->rgba();

        $intensity += ($comps[0] + $comps[1] + $comps[2]) / 3.0;
        $data_points++;

        $x += $dx;
        $y += $dy;
    }

    return 0 if $data_points == 0;

    return int(1.0*$intensity/$data_points);
}

###########################################
sub cropdetect_mplayer {
###########################################
    my($self, $time) = @_;

    my($stdout, $stderr, $rc) = 
        tap $self->{mplayer}, qw(-vf cropdetect -ss), $time, 
            "-frames", 10,
            "-vo", "null",
            "-ao", "null",
            $self->{video};

    if(defined $stdout and
       $stdout =~ /-vf crop=(\d+):(\d+):(\d+):(\d+)/) {
        DEBUG "Suggested crop: $1, $2, $3, $4";
        return ($1, $2, $3, $4);
    }

    ERROR "$stderr";

    return undef;
}

###########################################
sub cropdetect_average {
###########################################
    my($self, $nof_probes, $opts) = @_;

    $opts = {} unless defined $opts;

    $self->result_clear();

    my @images = ();

    if(exists $opts->{images}) {
        for my $img (@{ $opts->{images} }) {
            push @images, $img;
        }
    } else {
        for my $probe ( 
            $self->equidistant_snap_times( $nof_probes, 
                $opts ) ) {

            my $data = $self->snap( $probe );
            my $img = Imager->new();
            my $rc = $img->read( data => $data );
            if(! $rc) {
                LOGWARN "Reading snapshop at time $probe failed ($!)";
                next;
            }
            push @images, $img;
        }
    }

    # average all snapshots to obtain a single overlay image
    my $overlay;

    my $i = 1;

    for my $img (@images) {
        $img->filter(type=>"gaussian", stddev=>10)
               or die $overlay->errstr;

        if(! defined $overlay) {
            $overlay = $img;
            next;
        }
        $overlay->compose( src => $img, combine => 'add' );
        $overlay->filter(type=>"postlevels", levels=>3) or
            die $overlay->errstr;

        if(get_logger()->is_trace()) {
            $overlay->write(file => "i-$i.jpg");
        }
        $i++;
    }

    my @params = $self->cropdetect( 0, { image => $overlay } );

    return @params;

#        my @params = $self->cropdetect( $probe, $opts );
#        if(! defined $params[0] ) {
#            ERROR "cropdetect returned an error";
#            next;
#        }
#        DEBUG "Cropdetect at $probe yielded (@params)";
#        $self->result_push( @params );
#    }
#
#    my @result = $self->result_majority_decision();
#    DEBUG "Majority decision: (@result)";
#    return @result;

}

###########################################
sub result_clear  {
###########################################
    my($self) = @_;

    $self->{result} = [];
}

###########################################
sub result_push {
###########################################
    my($self, @result) = @_;

    for(0..$#result) {
        $self->{result}->[$_]->{ $result[$_] }++;
    }
}

###########################################
sub result_majority_decision {
###########################################
    my($self) = @_;

    my @result = ();

    for my $sample (@{ $self->{result} }) {
        my($majority) = sort { $sample->{$b} <=> $sample->{$a} } keys %$sample;
        push @result, $majority;
    }

    return @result;
}

###########################################
sub jpeg_data {
###########################################
    my($self) = @_;
    return $self->{jpeg};
}

###########################################
sub jpeg_save {
###########################################
    my($self, $file) = @_;

    blurt $self->{jpeg}, $file;
}

###########################################
sub meta_data {
###########################################
    my($self) = @_;

    my($stdout, $stderr, $rc) = 
        tap $self->{mplayer}, 
            qw(-vo null -ao null -frames 0 -identify), 
            $self->{video};

    if($rc != 0) {
        ERROR "$stderr";
        return undef;
    }

    $self->{meta} = {};

    while($stdout =~ /^ID_(.*?)=(.*)/mg) {
        $self->{meta}->{ lc($1) } = $2;
    }

    return $self->{meta};
}

###########################################
sub equidistant_snap_times {
###########################################
    my($self, $nof_snaps, $opts) = @_;

    $opts = {} unless defined $opts;

    if(! defined $nof_snaps) {
        LOGDIE "Parameter missing: nof_snaps";
    }

    my @stamps = ();

    if(!defined $self->{meta}) {
        $self->meta_data();
    }

    my $length = $self->{meta}->{length};
    $length = $opts->{movie_length} if defined $opts->{movie_length};

    my $interval = $length / ($nof_snaps + 1.0);
    my $interval_seconds     = int( $interval );

    my $dur   = DateTime::Duration->new(seconds => $interval_seconds);
    my $point = DateTime::Duration->new(seconds => 0);

    my $format = DateTime::Format::Duration->new(pattern => "%r");
    $format->set_normalizing( "ISO" );

    for my $snap_no (1 .. $nof_snaps) {
        $point->add_duration( $dur );

        my $stamp = $format->format_duration( $point );
        push @stamps, $stamp;
    }

    return @stamps;
}

###########################################
sub dimensions {
###########################################
    my($self) = @_;

    if(defined $self->{width}) {
        return ($self->{width}, $self->{height});
    }

    my $time = "00:00:01";

    my $data = $self->frame_grab( $time );
    my $img = Imager->new();
    my $rc = $img->read( data => $data );

    my $width  = $img->getwidth();
    my $height = $img->getheight();

    $self->{width}  = $width;
    $self->{height} = $height;

    return($width, $height);
}

###########################################
sub aspect_ratio_guess {
###########################################
    my($self, $formats) = @_;

    if(! defined $formats) {
        $formats = $self->{aspects};
    }

    my($width, $height) = $self->dimensions();

    if(!$width or !$height) {
        ERROR "Can't get image dimensions data for width/height";
        return undef;
    }

    my %matches = ();

    for my $format (@$formats) {
        my($fw, $fh) = split /:/, $format;
        my $factor = 1.0*$width/$fw;
        my $fhguess = 1.0*$height/$factor;

        my $deviate = abs($fh-$fhguess)/$fh*100.0;
        INFO "$format deviates from $width:$height ", 
             sprintf("%.2f", $deviate), "%";
        
        $matches{ $format } = $deviate;
    }

    return (sort { $matches{$a} <=> $matches{$b} } keys %matches)[0];
}

1;

__END__

=head1 NAME

Video::FrameGrab - Grab a frame or metadata from a video

=head1 SYNOPSIS

    use Video::FrameGrab;

    my $grabber = Video::FrameGrab->new( video => "movie.avi" );

    my $jpg_data = $grabber->snap( "00:00:10" );
    $grabber->jpeg_save("snapshot.jpg");

    print "This movie is ", 
          $grabber->meta_data()->{length}, 
          " seconds long\n";

      # Snap 10 frames at constant intervals throughout the movie
    for my $p ( $grabber->equidistant_snap_times(10) ) {
        $grabber->snap( $p );
        $grabber->jpeg_save("frame-at-$p.jpg");
    }

=head1 DESCRIPTION

Video::FrameGrab grabs a frame at the specified point in time from the 
specified video file and returns its JPEG data.

It uses mplayer for the heavy lifting behind the scenes and therefore 
requires it to be installed somewhere in the PATH. If mplayer is somewhere
else, its location can be provided to the constructor:

    my $grabber = Video::FrameGrab->new( mplayer => "/path/to/mplayer",
                                         video   => "movie.avi"
                                       );

=head2 METHODS

=over 4

=item snap( $time )

Grabs a frame from the movie at time $time. Time is given as HH::MM::SS,
just as mplayer likes it. Returns the raw jpeg data of the captured frame
on success and undef if an error occurs.

=item jpeg_save( $jpg_file_name )

Save a grabbed frame as a jpeg image in $file on disk.

=item meta_data()

Runs mplayer's identify() function and returns a reference to a hash
containing something like

    demuxer          => MOV
    video_format     => AVC1
    video_bitrate    => 0
    video_width      => 320
    video_height     => 240
    video_fps        => 29.970
    video_aspect     => 0.0000
    audio_format     => MP4A
    audio_bitrate    => 0
    audio_rate       => 48000
    audio_nch        => 2
    length           => 9515.94

=item equidistant_snap_times( $howmany, [$opts] )

If you want to snap N frames at constant intervals throughout the movie,
use equidistant_snap_times( $n ) to get a list of timestamps you can use
later pass to snap(). For example, on a two hour movie, 
equidistant_snap_times( 5 ) will return

    00:20:00
    00:40:00
    01:00:00
    01:20:00
    01:40:00

as a list of strings. The movie length is determined by a call to meta
data, but some formats don't allow retrieving the movie length that way,
therefore the optional options hash can set the movie_length entry
to the movie length (or the length of the overall interval to perform
the snapshots in) in seconds.

    my @times =
      $fg->equidistant_snap_times( $howmany, { movie_length => 3600 } );

=item cropdetect( $time, [$opts] )

If this is a 16:9 movie converted to 4:3 format, the black bars at the bottom
and the top of the screen should be cropped out. To help with this task,
C<cropdetect> will return a list of ($width, $height, $x, $y) to be passed 
to mplayer/mencoder in the form C<-vf crop=w:h:x:y> to accomplish the 
suggested cropping.

The default algorithm is a homegrown detection mechanism 
C<{algorithm =E<gt> "schilli"}>, which first blurs the 
image with the Gaussian Blur algorithm with a radius of
C<$opts-E<gt>{gaussian_blur_radius}> (which defaults to 3),
and then measures if any of the left, right, upper or lower border
pixel lines of the snapped frame average an intensity of less than 
C<$opts-E<gt>{min_intensity_average}>, which defaults to 20.

Note that this is just a guess and might be incorrect at times. In a
dark scene, black pixels might protrude far into the video, making it
impossible to detect the border reliably. However, if you overlay a number
of frames, obtained at several times during the movie (e.g. by using
the equidistant_snap_times method described above), the result
is fairly predicatblye and accurate. C<cropdetect_average>, 
described below, does exactly that.

The alternative algorithm, C<"mplayer">,
asks mplayer to come up with a recommendation on how to crop the video.
This technique delivers incorrect results if there are sporadic white
spots within the dark bars.

=item cropdetect_average( $number_of_probes, [$opts] )

Takes C<$number_of_probes> from the movie at equidistant intervals,
overlays the frames and performs a border detection on the resulting
images, which is almost white in the viewing area.

See C<equidistant_snap_times> for setting the movie length in
the optional C<$opts> parameter.

=item aspect_ratio_guess( ["16:9", "4:3"] )

This function will take the width and height of the video and 
map it to the best matching aspect ratio given in a reference
to an array.

=item dimensions()

Snaps a frame in the middle of the movie, determines its width and
height and returns them in a list:

    my($width, $height) = $grabber->dimensions();

Dimensions are usually also available via the meta_data() call. 
dimensions() works even in absence of meta data.

=head1 CAVEATS

Note that the mplayer-based frame grabbing mechanism used in 
this module allows you to snap a picture about every 10 seconds into the 
movie, on shorter intervals, you'll get the same frame back.

=back

=head1 LEGALESE

Copyright 2009 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2009, Mike Schilli <cpan@perlmeister.com>
