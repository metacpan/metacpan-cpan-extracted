package Time::Slideshow;
use strict;
use Time::HiRes qw(time);
use vars qw($VERSION);
$VERSION= '0.04';

=head1 NAME

Time::Slideshow - simple stateless slideshow with a fixed set of images

=head1 SYNOPSIS

    my $slideshow= Time::Slideshow->new(
        starttime => 0,
        slides => [ 'picture1.jpg', 'picture2.jpg' ],
        shuffle => 0, # pseudo-rng
        duration => 45, # show each slide for 45 seconds
    );
    my $current_slide= $slideshow->current_slide;           # picture1.jpg
    my $next_slide= $slideshow->next_slide;                 # picture2.jpg
    sleep $slideshow->seconds_to_next_slide;

=head1 OVERVIEW

This module abstracts the inner workings of a slideshow, selecting the
next slide to display and calculating the time until the next picture. It
is possible to use this object in an asynchronous manner across machines
as the complete slide sequence is precalculated from the wallclock time.

The module has no methods to advance the slideshow forwards or backwards
other than through the passage of time.

=head1 METHODS

=head2 C<< Time::Slideshow->new %options >>

  my $slideshow= Time::Slideshow->new(
      slides => [ glob '~/backgrounds/*.jpg' ],
      duration => 300, # five minutes per image
      shuffle => 1, # permute the order of images
  )

Creates a new slideshow object and returns it. The options are

=over 4

=item B<slides>

Array reference to the slides. These can be filenames
or URLs or whatever else helps your program to find and display
the appropriate image.

=item B<duration>

The time how long every image is displayed, in seconds. The default
value is 45.

=item B<shuffle>

If you want the order of the images to be shuffled, pass
a true value to this option. See the below discussion
on what different orders you can expect from shuffling.

=item B<starttime>

If you want to set up a different offset of the start time,
pass this option with the epoch value of the start time. Usually,
you want to leave this parameter at its default of 0.

=back

=cut

sub new {
    my( $class, %options )= @_;
    $options{ starttime }||= 0;
    $options{ shuffle }||= 0;
    $options{ duration }||= 45;
    $options{ slides }||= [];

    my $self= bless \%options, $class;

    $self
}

sub starttime { $_[0]->{ starttime }};
sub duration { $_[0]->{ duration }};
sub slides { $_[0]->{ slides }};

=head2 C<< $show->add_slide( @slides ) >>

  $show->add_slide( glob '~/new_backgrounds/*' );

If you want to add slides after object
creation, you can use this method.

=cut

sub add_slide {
    my( $self, @slides )= @_;
    push @{ $self->slides }, @slides
};

=head2 C<< $show->current_slide >>

  print "Now displaying ", $show->current_slide, "\n";

Returns the name of the slide that is currently displayed.

This method is the central method for your application to
get the filename or URL of the image that your application
needs to display.

=cut

sub current_slide {
    my( $self, $time )= @_;
    $self->slide_at( $self->current_slide_index( $time ))
}

=head2 C<< $show->next_slide >>

  print "Next up is ", $show->next_slide, "\n";

Returns the name of the slide that will be displayed after the
current slide.

You can use this method to preload the image data
for the upcoming slide.

=cut

sub next_slide {
    my( $self, $time )= @_;
    $self->slide_at( $self->current_slide_index( $time ) +1 )
}

=head2 C<< $show->seconds_to_next_slide >>

  my $wait= $show->seconds_to_next_slide;
  sleep $wait;

Returns the time remaining to the next slide
transition.

You can use this method to pause your program or perform
other tasks until the next image
needs to be displayed.

=cut

sub seconds_to_next_slide {
    my( $self, $time )= @_;
    if( ! defined $time ) {
        $time= Time::HiRes::time;
    };
    $time -= $self->{ starttime };
    #warn sprintf "At %d, window %d, in %d", $time, $self->duration, $self->duration - ($time % $self->duration);
    $self->duration - ($time % $self->duration)
};

=head2 C<< $show->current_slide_index >>

  my $current_slide_index= $show->current_slide_index;

This returns the index of the slide that is currently displayed.

Most likely, you want to use C<< $show->current_slide >> instead.

=cut

sub current_slide_index {
    my( $self, $time )= @_;
    $time = time
        unless defined $time;
    $time -= $self->{ starttime };

    my $items= 0+@{ $self->slides };
    return undef unless $items;

    my $index= int (($time % ($self->duration * $items)) / $self->duration);

    if( $self->{ shuffle } and $items > 1) {
        # Apply a permutation
        # We don't want permutation 0 and 1 as 0 and 1 are identical
        # Step is the distance between items
        # Incr is the shift we need to apply per round
        #           0 1 2 3 4 5
        # Shuffle 1: Step = 2
        #           0   1   2
        #             3   4   5
        # Shuffle 2: Step = 3
        #           0     1
        #             2     3
        #               4     5
        #
        # For 10 items, Permutation 8 (Step size 3)
        #           0 1 2 3 4 5 6 7 8 9
        #           0     1     2     3
        #             4     5     6
        #               7     8     9

        my $permutation= (int ($time / ($self->duration * $items)) % ($items-2));
        my $step= $permutation;
        $step++; # Increment between 1 and $items-1

        my $gcd= gcd( $items, $step );
        my $round_size= int( $items / $gcd );

        # The round counts from $round_size towards 1 to shuffle the order of loops a bit
        my $round= $round_size - int($index / $round_size) +1;

        my $old_index= $index;
        $index= ((($old_index *$step) % $items) + $round ) % $items;

        #warn sprintf "Old Index % 2d  Step: % 2d  Round: % 2d  Round size: % 2d  Index: % 2d  GCD: % 2d\n",
        #              $old_index,     $step,      $round,      $round_size,      $index,      $gcd;
    };

    $index
};

=head2 C<< $show->slide_at $index >>

    my $slide_count= @{ $show->slides };
    for my $slide ( 0..$slide_count-1 ) {
        print "Slide $slide: ", $show->slide_at( $slide ), "\n";
    };

Returns the name of the slide at the given index.

=cut

sub slide_at {
    my( $self, $index )= @_;
    $index %= 0+@{ $self->slides };
    $self->slides->[ $index ]
}

# Some math utilities to find the gcd, for the "random" shuffles
sub gcd {
    my( $gcd )= shift;
    for my $d ( @_ ) {
        my $div= $d;
        while( $div ) {
            ($gcd, $div) = ($div, $gcd % $div);
        };
    };
    $gcd
}

1;

__END__

=head1 SHUFFLING PERMUTATIONS

This module does not use the real permutations
of the slides. The module uses an approach to select non-neighbouring images
by first selecting a permutation from C<1..@items -2> according to the current
time and then selecting the C<n-th> slide from that permutation.

=head1 INTEGRATION

=head2 Console

This is the most basic slideshow display. It demonstrates
the functionality of the module but only outputs the text.
Displaying the image itself is left to you to implement
with your favourite image display method.

  use Time::Slideshow;

  my $s= Time::Slideshow->new(
      slides => [ glob 'slides/*.jpg' ],
  );

  while(1) {
      print sprintf "Now showing slide '%s'\n", $s->current_slide;
      print sprintf "Next up is '%s'\n', $s->next_slide;

      sleep( $s->seconds_to_next_slide );
  };

=head2 AnyEvent

This example uses L<AnyEvent> to show how you can
perform other tasks while also reacting to the
timer events to display a new image.

  use AnyEvent;
  use Time::Slideshow;

  my $s= Time::Slideshow->new(
      slides => [ glob 'slides/*.jpg' ],
  );

  my $slideshow_timer;
  my $display_and_reschedule; $display_and_reschedule= sub {
      print sprintf "Now showing slide '%s'\n", $s->current_slide;
      print sprintf "Next up is '%s'\n', $s->next_slide;
      $slideshow_timer= AnyEvent->timer(
          after => $s->seconds_to_next_slide,
          cb => $display_and_reschedule,
      );
  };
  $display_and_reschedule->();

  # Wait and do other stuff
  AnyEvent->condvar->recv;

=head2 CGI

This example assumes that your images are available
via your webserver under the URL C</slides>
and will display a page that shows the same image
to all users that load that page.

  use CGI;
  use Time::Slideshow;

  my $s= Time::Slideshow->new(
      slides => [ glob 'slides/*.jpg' ],
  );

  my $image= "/" . $s->current_slide;
  my $reload= $s->seconds_to_next_slide;
  my $q= CGI->new;
  print $q->header('text/html');
  print <<HTML;
      <html>
      <head>
          <meta http-equiv="refresh" content="$reload">
      </head>
      <body><img src="$image" /></body></html>
  HTML

=head2 Prima

Using L<Prima>, we can create an application with a native UI that displays
the images. Not implemented here are the resizing or zooming of the images
to the window size.

  use Prima qw(Application ImageViewer);
  use Time::Slideshow;

  my $s= Time::Slideshow->new(
      slides => [ glob 'demo/*.png' ],
  );
  my $window = Prima::MainWindow->new();
  my $image = $window->insert( ImageViewer =>
      growMode => gm::Client,
      rect => [0, 0, $window->width, $window->height],
      autoZoom => 1,
  );
  my $filename = $s->current_slide;
  $image->imageFile($filename);
  $window->insert( Timer =>
      timeout => 5000, # checking every 5 seconds is enough
      onTick  => sub {
          if( $s->current_slide ne $filename ) {
              $filename = $s->current_slide;
              $image->imageFile($filename);
          };
      }
  )->start;

  Prima->run;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/time-slideshow>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Time-Slideshow>
or via mail to L<time-slideshow@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut