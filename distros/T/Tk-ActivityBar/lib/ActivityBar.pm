package Tk::ActivityBar;

use vars qw($VERSION);
$VERSION = '0.01';

use strict;

use base qw(Tk::Derived Tk::ProgressBar);
Construct Tk::Widget 'ActivityBar';


### OVERRIDING FUNCTIONS

sub Populate {
    my ($c, $args) = @_;

    $c->SUPER::Populate($args);

    $c->configure( -borderwidth      => 1,
		   -xscrollincrement => 1,
		   -yscrollincrement => 1);

    $c->ConfigSpecs
      ('-interval'       => ['PASSIVE', 'interval', 'Interval', 100],
       '-increment'      => ['PASSIVE', 'increment', 'Increment', 2],
       '-image'          => ['PASSIVE', 'image', 'Image', undef],
       '-imageoffset'    => ['PASSIVE', 'imageOffset', 'ImageOffset', [0, 0]],
       '-bandlength'     => ['PASSIVE', 'bandLength', 'BandLength', 15],
       '-bandangle'      => ['PASSIVE', 'bandAngle', 'BandAngle', 45],
       '-bandforeground' => ['PASSIVE', 'bandForeground',
			     'BandForeground', 'SlateGray3'],
       '-bandbackground' => ['PASSIVE', 'bandBackground',
			     'BandBackground', 'SlateGray1']);
}


sub _layoutRequest {
    my $c = shift;

    return if $c->{'activityBar'};
    $c->SUPER::_layoutRequest(@_);
}


sub value {
    my $c = shift;

    $c->_resetProgressBar() if ($c->{'activityBar'} && @_);
    $c->SUPER::value(@_);
}


### PUBLIC FUNCTIONS

sub startActivity {
    my $c = shift;
    my $interval = $c->{Configure}{'-interval'};
    my $image = $c->{Configure}{'-image'};
    my $repeat_ID = $c->{'repeatID'};

    $c->afterCancel($repeat_ID) if ($repeat_ID);
    $c->delete('all');
    $c->_resetScroll;
    if (defined $image) {
	$c->_drawImageBar();
    } else {
	$c->_drawBandsBar();
    }

    $c->{'state'} = 0;
    $c->{'activityBar'} = 1;
    $c->{'repeatID'} = $c->repeat($interval, [$c => '_update_bar']);
}


### PRIVATE FUNCTIONS

sub _resetProgressBar {
    my $c = shift;
    my $repeat_ID = $c->{'repeatID'};

    $c->{'activityBar'} = 0;
    $c->_resetScroll();
    $c->delete('all');
    $c->afterCancel($repeat_ID) if ($repeat_ID);
    _layoutRequest($c,1);
}


sub _drawImageBar {
    my $c = shift;
    my $horz = $c->{Configure}{'-anchor'} =~ /[ew]/i ? 1 : 0;
    my $image = $c->{Configure}{'-image'};
    my $image_length = $horz ? $image->width : $image->height;
    my $image_offset = $c->{Configure}{'-imageoffset'};
    my $h = $c->Height;
    my $w = $c->Width;
    my $length = $horz ? $w : $h;
    my($n, @p);

    $c->{'tileLength'} = $image_length;
    my $tile_cnt = int($length / $image_length) + 1;
    for ($n=-1; $n < $tile_cnt; $n++) {
	@p = $c->_point($n * $image_length, 0);
	$c->createImage
	  ($p[0] + $$image_offset[0], $p[1] + $$image_offset[1],
	   -anchor => 'nw', -image => $image);
    }
}


sub _point {
    my $c = shift;
    my $horz = $c->{Configure}{'-anchor'} =~ /[ew]/i ? 1 : 0;
    my @point = @_;

    return $horz ? @point : reverse @point;
}


sub _drawBandsBar {
    my $c = shift;
    my $horz = $c->{Configure}{'-anchor'} =~ /[ew]/i ? 1 : 0;
    my $band_length = $c->{Configure}{'-bandlength'};
    my $pi = 3.14159265359;
    my $band_angle = $c->{Configure}{'-bandangle'} * $pi / 180;
    my @colors = ($c->{Configure}{'-bandforeground'},
		  $c->{Configure}{'-bandbackground'});
    my $h = $c->Height;
    my $w = $c->Width;
    my $length = $horz ? $w : $h;
    my $width  = $horz ? $h : $w;
    my($n, @p1, @p2, @p3, @p4);

    if ($c->{Configure}{'-bandangle'} < 1 ||
	$c->{Configure}{'-bandangle'} > 179) {
	die "Tk::ActivityBar: bandangle must be between 1 and 179.\n";
    }

    $c->{'tileLength'} = 2 * $band_length;

    my $polygon_cnt = int($length / $band_length) +1;

    my $offset = int(cos($band_angle) * $width / sin($band_angle));
    my $buffer_bands = int(abs($offset / $band_length)) + 1;
    my($pre_bands, $post_bands) =
      ($offset >= 0) ? ($buffer_bands, 0) : (0, $buffer_bands);

    for ($n=-($pre_bands+2); $n < $polygon_cnt + $post_bands; $n++) {
	@p1 = $c->_point($n * $band_length, $width);
	@p2 = $c->_point($n * $band_length + $offset, 0);
	@p3 = $c->_point(($n + 1) * $band_length + $offset, 0);
	@p4 = $c->_point(($n + 1) * $band_length, $width);
	$c->createPolygon(@p1, @p2, @p3, @p4,
			  -fill => $colors[$n % 2]);
    }
}


sub _resetScroll {
    my $c = shift;
    my $horz = $c->{Configure}{'-anchor'} =~ /[ew]/i ? 1 : 0;
    my $state = $c->{'state'};

    return unless $state;
    $horz ? $c->xviewScroll($state, 'units') :
      $c->yviewScroll($state, 'units');
    $c->{'state'} = 0;
}


sub _update_bar {
    my $c = shift;
    my $horz = $c->{Configure}{'-anchor'} =~ /[ew]/i ? 1 : 0;
    my $tile_length = $c->{'tileLength'};
    my $increment = $c->{Configure}{'-increment'};
    my $state = $c->{'state'};

    if ($state + $increment >= $tile_length) {
	$c->_resetScroll();
    } else {
	$horz ? $c->xviewScroll(-$increment, 'units') :
	  $c->yviewScroll(-$increment, 'units');
    }

    $c->{'state'} = ($state + $increment) % $tile_length;
}

1;
__END__

=head1 NAME

Tk::ActivityBar - Adds an indeterminate progress display
                  to Tk::ProgressBar.

=for category Derived Widgets

=head1 SYNOPSIS

    use Tk::ActivityBar;

    $progress = $parent->ActivityBar(
	-width => 200,
	-length => 20,
        -anchor => 's',
	-from => 0,
	-to => 100,
	-blocks => 10,
	-colors => [0, 'green', 50, 'yellow' , 80, 'red'],
	-variable => \$percent_done
    );

    $progress->value($position);

=head1 DESCRIPTION

B<Tk::ActivityBar> keeps all the functions of B<Tk::ProgressBar>
and adds a display indicating indeterminate progress: 
either a continuously cycling 'barberpole,' or a continuously
cycling B<Tk::Image>.

=head1 WIDGET-SPECIFIC OPTIONS

=item B<-bandangle>

Specifies the angle of the stripes in the barberpole display, in
degrees.  Defaults to 45.

=item B<-bandbackground>

Specifies the color of the 'background' stripes in the barberpole
display.  Defaults to 'SlateGray1'.

=item B<-bandforeground>

Specifies the color of the 'foreground' stripes in the barberpole
display.  Defaults to 'SlateGray3'.

=item B<-bandlength>

Specifies the distance in pixels taken up by individual barbershop
bands along the length of the bar.  Defaults to 15.

=item B<-image>

Specifies the B<Tk::Image> to be used for the cycling display. If the
B<-image> option is used, then the specified image will be used
instead of the barbershop display.

=item B<-imageoffset>

Specifies the offset of the image in X, Y pixels, as an anonymous
array. Defaults to [0, 0].

=item B<-increment>

Specifies the number of pixels the display will be shifted each time
it is updated. Defaults to 1.

=item B<-interval>

Specifies the number of milliseconds between display updates. Smaller
values will result in a faster cycling speed. Defaults to 100.

=head1 WIDGET METHODS

=over 4

=item I<$ProgressBar>-E<gt>B<startActivity>()

Activates a cycling indeterminate progress display. This display
will continue until the B<-value> method of B<Tk::ProgressBar> is
used, or until the variable set using the B<-variable> method is
changed.

=back

=head1 AUTHOR

Bret Aarden E<lt>F<aarden.1 at osu.edu>E<gt>

=cut
