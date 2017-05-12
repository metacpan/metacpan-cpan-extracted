###########################################
package Video::Capture::V4l::Imager;
###########################################
use Video::Capture::V4l;
use Log::Log4perl qw(:easy);
use Imager;
use strict;
use warnings;

our $VERSION = "0.01";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        width             => 320,
        height            => 240,
        avg_optimal       => 128,
        avg_tolerance     => 20,
        brightness_min    => 0,
        brightness_max    => 65535,
        calibration_tries => 5,
        %options,
    };

    $self->{video} =
        Video::Capture::V4l->new() or
            LOGDIE "Open video failed: $!";

    bless $self, $class;
}

###########################################
sub brightness {
###########################################
    my($self, $brightness) = @_;

    INFO "Setting brightness to $brightness";

    my $pic = $self->{video}->picture();
    $pic->brightness($brightness);
    $pic->set();
}

###########################################
sub capture {
###########################################
    my($self, $brightness) = @_;

    INFO "Capturing img";

    $self->brightness($brightness) if 
        defined $brightness;

    my $frame;

    for my $frameno (0, 1) {
       $frame = $self->{video}->capture(
              $frameno, $self->{width},
              $self->{height});

       if(!defined $frame) {
           ERROR "Video capture failed";
           return;
       }

       if(! $self->{video}->sync($frameno)) {
           ERROR "Unable to sync";
           return;
       }
    }

    my $i = Imager->new();
    $frame = reverse $frame;
    $i->read(
      type => "pnm",
      data => "P6\n$self->{width} " .
              "$self->{height}\n255\n" .
              $frame
    ) or do { ERROR "Reading image data failed";
              return; };

    DEBUG "Img captured ok";

    return $i;
}

###########################################
sub calibrate {
###########################################
  my($self) = @_;

  INFO "Calibrating cam";

  my $avg_low = img_avg($self->capture($self->{brightness_min}));
 
  DEBUG "avg_low=$avg_low";

  if($avg_low > $self->{avg_optimal}) {
      INFO "avg_low=$avg_low > avg_opt=$self->{avg_optimal} - ",
           "doesn't get any better";
      return $self->{brightness_min};
  }

  my $avg_high = img_avg($self->capture($self->{brightness_max}));

  DEBUG "avg_high=$avg_high";

  if($avg_high < $self->{avg_optimal}) {
      INFO "avg_high=$avg_high > avg_opt=$self->{avg_optimal} - ",
           "doesn't get any better";
      return $self->{brightness_max};
  }

      # Binary search
  my($low, $high) = ($self->{brightness_min}, 
                     $self->{brightness_max});

  my $try;

  for(my $max = $self->{calibration_tries}; 
      $low <= $high && $max; 
      $max--) {
     $try = int( ($low + $high) / 2);

    my $i  = $self->capture($try);
    my $br = img_avg($i);

    DEBUG "Tried brightness=$try got avg=$br";
    return $try if abs($br-$self->{avg_optimal}) <= 
              $self->{avg_tolerance};

    if($br < $self->{avg_optimal}) {
        $low = $try + 1;
    } else {
        $high = $try - 1;
    }
  }

  # Nothing found, use last setting
  return $try;
}

###########################################
sub img_avg {
###########################################
    my($img) = @_;

    my $avg = img_avg_c($img);

    DEBUG "img avg=$avg";
    return $avg;
}

use Inline C => <<'EOT' => WITH => 'Imager';

int
img_avg_c(Imager im) {
  int     x, y;
  i_color val;
  double  sum;
  int     br;
  int     avg;

  for(x = 0; x < im->xsize; x++) {
    for(y = 0; y < im->ysize; y++) {
      i_gpix(im, x, y, &val);
      br = (val.channel[0] + val.channel[1]
                     + val.channel[2]) / 3;
      sum += br;
    }
  }

  avg = sum / ((int) (im->xsize) * 
               (int) (im->ysize));
  return avg;
}

/* ===================================== */
int
img_changed(Imager im1, Imager im2, int diff) {
  int     x, y, z, chan;
  i_color val1, val2;
  int     diffcount = 0;

  for(x = 0; x < im1->xsize; x++) {
    for(y = 0; y < im1->ysize; y++) {

      i_gpix(im1, x, y, &val1);
      i_gpix(im2, x, y, &val2);

      for(z = 0; z < 3; z++) {
        if(abs(val1.channel[z] - 
               val2.channel[z]) > diff)
          diffcount++;
      }
    }
  }

  return diffcount;
}

EOT

1;

__END__

=head1 NAME

Video::Capture::V4l::Imager - Capture images from a video webcam

=head1 SYNOPSIS

    use Video::Capture::V4l::Imager;

    my $vcap = Video::Capture::V4l::Imager->new(
        width  => 320,
        height => 240,
    );

      # Adjust camera brightness if necessary
    $vcap->brightness(32_000);
       
      # Capture an image, back comes an Imager object
    my $img = $vcap->capture();

      # Save it as JPEG
    $img->write(file => 'mycapture.jpg')
      or die "Can't write: $!";

=head1 DESCRIPTION

Video::Capture::V4l::Imager captures still images from a USB video
cam connected to your Linux box. The pictures come back as Imager
objects (see the Imager module on CPAN for details) and can be easily
manipulated and saved to disk.

Video::Capture::V4l::Imager is a convenience wrapper around Marc
Lehmann's Video::Capture::V4l module. It uses the following procedure
to obtain the still images from the video stream:

    http://www.perlmonks.org/?node=474047

=head2 Capturing Images

To initialize V4l with your connected video camera, call the constructor
with the width and height setting according to what's supported
by the video camera:

    my $vcap = Video::Capture::V4l::Imager->new(
        width   => 320,
        height  => 240,
    );

Note that this call will fail if your video camera doesn't support
the specified width and height setting.

To capture a picture from the video stream, call

    $vcap->capture();

which will return an Imager object on success or C<undef> otherwise.

=head2 Adjusting the Camera

To adjust the brightness setting of the camera, use

    $vcap->brightness(32_000);

and pass the integer value of the desired brightness setting.

To calibrate the camera to obtain an image that has a given average
brightness, use C<calibrate>:

    my $vcap = Video::Capture::V4l::Imager->new(
        width             => 320,
        height            => 240,
        avg_optimal       => 128,
        avg_tolerance     => 20,
        brightness_min    => 0,
        brightness_max    => 65535,
        calibration_tries => 5,
    );

    $vcap->calibrate();

This will start a simple binary search by taking a picture, checking
its average brightness via C<img_avg()> (see below) and adjusting the
camera brightness to get to a desired optimal brightness C<avg_optimal>.
within a selectable tolerance C<avg_tolerance>. 

C<calibrate()> returns the best camera brightness setting found.

The minimum and maximum settings for camera brightness (which depend
on the camera used) are set in C<brightness_min> and C<brightness_max>.

The maximum number of test exposures is set in C<calibration_tries>,
after this number is reached, the camera brightness that worked best
so far gets returned.

=head2 Utility functions

The following utility methods for Imager objects have been included in 
this module:

=over 4

=item C<$i-E<gt>img_avg()>

Calculates the average brightness of an image by adding up all channels
of every pixel and then dividing it by 3 times the number of pixels. Handy
to get a feel if an image is over- or underexposed, by a very crude measure.

=item C<$i->E<gt>img_changed($other_img, $diff)>

Checks if two images are significantly different, used to tell if
two consecutive still images taken from a video stream show that
something's going on in the scene.

Calculates the difference in channel values of all pixels and compares
it to the number passed in C<$diff>. If the sum of all channel differences
is greater than C<$diff>, C<img_changed> returns true and false otherwise.

Note that the counter will be increased by up to 3 points per pixel 
(red, green, blue channels), so factor that into C<$diff>.

=back

=head2 NOTES

Note that this module contains inline C code and will take significantly
longer to start up on the first run. It will speed up significantly on
consecutive runs, because the object code will be preserved once it
has been compiled.

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <cpan@perlmeister.com>
