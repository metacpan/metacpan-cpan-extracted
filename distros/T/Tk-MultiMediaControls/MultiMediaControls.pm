$Tk::MultiMediaControls::VERSION = '1.0';

package Tk::MultiMediaControls;

# A mega-widget that implements controller buttons typically found on modern
# media programs (DVD player, iTunes, iMovie) and electronic devices such as
# iPods, DVD players, VCRs, etc.  The "buttons" are actually Label widgets
# with images and bindings that make them look and feel like Aqua buttons.

use Tk::widgets qw/ Balloon Photo PNG /;
use base qw/ Tk::Frame /;
use strict;

Construct Tk::Widget 'MultiMediaControls';

# Class data.

my $ballon;			# for Balloon help
my $root = Tk->findINC( 'MultiMediaControls/images/..' );

my %images;

# Conroller button images (@buttons) are created on demand, but only once.
# The %images hash has one key for each type of controller button indicating
# whether it's Photos have been created, and, for each button, three keys
# that at first specifiy the path names of the files for each Photo.  The
# first time a conroller button is created the keys then contain the actual
# Photo object references.

my @buttons = qw/ fastforward home play rewind stop /;
@images{ @buttons } = ( 0, 0, 0, 0, 0 );

( $images{fast_hi_b}, $images{fast_n_r}, $images{fast_n} )       =
    qw\ images/Fast-Hi-Blue.png images/Fast-N-R.png images/Fast-N.png       \;
( $images{home_hi_b}, $images{home_n_r}, $images{home_n} )       =
    qw\ images/Home-Hi-Blue.png images/Home-N-R.png images/Home-N.png       \;
( $images{pause_hi_b}, $images{pause_n_r}, $images{pause_n} )    =
    qw\ images/Pause-Hi-Blue.png images/Pause-N-R.png images/Pause-N.png    \;
( $images{play_hi_b}, $images{play_n_r}, $images{play_n} )       =
    qw\ images/Play-Hi-Blue.png images/Play-N-R.png images/Play-N.png       \;
( $images{rewind_hi_b}, $images{rewind_n_r}, $images{rewind_n} ) =
    qw\ images/Rewind-Hi-Blue.png images/Rewind-N-R.png images/Rewind-N.png \;
( $images{stop_hi_b}, $images{stop_n_r}, $images{stop_n} )       =
    qw\ images/Stop-Hi-Blue.png images/Stop-N-R.png images/Stop-N.png       \;

sub ClassInit {

    my( $class, $mw ) = @_;

    $class->SUPER::ClassInit($mw);
    $ballon = $mw->Balloon;

} # end ClassInit

sub Populate {

    my( $self, $args ) = @_;

    my $buttons = delete $args->{ -buttons };
    die "Tk::MultiMediaControls: -buttons option is required." unless $buttons;
    
    $self->{ 'b1-valid' } = 0;
    my $cf = $self->Frame->pack;

    foreach my $b (@$buttons) {
	die "Tk::MultiMediaControls: unknown button '$b'" unless grep( /^$b$/, @buttons );
	$self->build_button( $cf, $b,       'fast', 'Fast Forward' ) if $b eq 'fastforward';
        $self->build_button( $cf, $b,           $b,         'Home' ) if $b eq 'home';
        $self->build_button( $cf, $b, [$b,'pause'],   'Play/Pause' ) if $b eq 'play';
        $self->build_button( $cf, $b,           $b, 'Fast Reverse' ) if $b eq 'rewind';
        $self->build_button( $cf, $b,           $b,         'Stop' ) if $b eq 'stop';
    }

    # Special appplication bindings: <space> toggles play/pause.
    # -leftcommand and -rightcommand must be bound to Toplevel also.

    $self->toplevel->bind( '<space>' => [ $self => 'playpause' ] );

    $self->ConfigSpecs (
        -fastcommand            => [ qw/ CALLBACK fastCommand            FastCommand            / ],
        -fasthighlightcommand   => [ qw/ CALLBACK fastHighlightCommand   FastHighlightCommand   / ],
        -homecommand            => [ qw/ CALLBACK homeCommand            HomeCommand            / ],
        -homehighlightcommand   => [ qw/ CALLBACK homeHighlightCommand   HomeHighlightCommand   / ],
        -leftcommand            => [ qw/ METHOD   leftCommand            LeftCommand            / ],
        -pausecommand           => [ qw/ CALLBACK pauseCommand           PauseCommand           / ],
        -pausehighlightcommand  => [ qw/ CALLBACK pauseHighlightCommand  PauseHighlightCommand  / ],
        -playcommand            => [ qw/ CALLBACK playCommand            PlayCommand            / ],
        -playhighlightcommand   => [ qw/ CALLBACK playHighlightCommand   PlayHighlightCommand   / ],
        -rewindcommand          => [ qw/ CALLBACK rewindCommand          RewindCommand          / ],
        -rewindhighlightcommand => [ qw/ CALLBACK rewindHighlightCommand RewindHighlightCommand / ],
        -rightcommand           => [ qw/ METHOD   rightCommand           RightCommand           / ],
        -stopcommand            => [ qw/ CALLBACK stopCommand            StopCommand            / ],
        -stophighlightcommand   => [ qw/ CALLBACK stopHighlightCommand   StopHighlightCommand   / ],
    );

    $self->ConfigAlias( '-fastforwardcommand'          => '-fastcommand' );
    $self->ConfigAlias( '-fastforwardhighlightcommand' => '-fasthighlightcommand' );

} # end Populate

sub build_button {

    # Build one controller button (really a Label widget with Aqua-like
    # bindings.
    #
    # $cf     = the parent controller Frame.
    #
    # $button = type of button; used as a hash key that:
    #           1) %images: indicates if a button's Photos have been created.
    #           2) %self  : stores the button's Label widget reference.
    #
    # $photos = a list of strings indicating the root name of three Photo
    #           file names associated with this button. The root name has 3
    #           possible suffixes distinguishing the different states of the
    #           button: "_n" for normal, "_n_r" for normal rollover (cursor
    #           over button), and "_hi_b" for highlight blue (B1 pressed
    #           over button). 
    #
    #           The first (or only) name is also used as the button Label's
    #           -text value, which identifies the button during callbacks.
    #
    # $ballon = the Balloon help text for the button.

    my( $self, $cf, $button, $photos, $balloon ) = @_;

    my $mw = $self->MainWindow;
    my $p = ref $photos ? $photos : [ $photos ];

    if ( $images{ $button } == 0 ) {
	$images{ $button }++;
	foreach my $i ( @$p ) {
	    $images{ "${i}_hi_b" } = $mw->Photo( -file => "$root/" . $images{ "${i}_hi_b" } );
            $images{ "${i}_n_r" }  = $mw->Photo( -file => "$root/" . $images{ "${i}_n_r" }  );
            $images{ "${i}_n" }    = $mw->Photo( -file => "$root/" . $images{ "${i}_n" }    );
        }
    } # ifend
    $p = $p->[ 0 ];
    my $l = $cf->Label(
        -image  => $images{ "${p}_n" },
        -text   => $p,
    )->pack( qw/ -side left / );
    $ballon->attach( $l, -balloonmsg => $balloon );
    $self->setbindings( $l );
    $self->{ $button } = $l;

} # end build_button

sub callback {			# execute the callback associated with a device button

    my ( $self, $l, $s ) = @_;

    my $t = $l->cget( -text );
    return unless $t eq $self->{ 'b1-valid' };

    my $c = $t;			# callback type

    if( $t eq 'play' ) {	# toggle play/pause
	$t = 'pause';
    } elsif( $t eq 'pause' ) {
	$t = 'play';
    }

    $l->configure( -image => $images{ "${t}${s}" }, -text => $t );

    if( $c eq 'stop' ) {	# force play/pause button into play mode
	my $play = $self->{ 'play' };
	if( $play ) {
	    $play->configure( -text => 'play' );
	    $self->newimage( $play, '_n' );
	}
    }

    $self->Callback( "-${c}command" ); # invoke button's callback

} # end callback

sub enter {			# hightlight a button, can invoke its callback

    my ( $self, $l, $s ) = @_;

    $self->{ 'b1-valid' } = $self->newimage( $l, $s );

} # end enter

sub leave {			# unhighlight a button, can't invoke its callback

    my ( $self, $l, $s ) = @_;

    $self->{ 'b1-valid' } = '';
    $self->newimage( $l, $s );

} # end leave

sub leftcommand {

    my ($self, $callback ) = @_;

    $self->toplevel->bind( '<Left>' => $callback );

} # end leftcommand

sub newimage {			# new image based on type and suffix

    my ( $self, $l, $s ) = @_;
    
    my $t = $l->cget( -text );
    $l->configure( -image => $images{ "${t}${s}" } );
 
    $self->Callback( "-${t}highlightcommand" ) if $s eq '_hi_b';
    
    return $t;

} # end newimage

sub playpause {			# space bar toggles play/pause

    my $self = shift;

    $self->{ 'play' }->eventGenerate( qw/ <Enter>           -when tail / );
    $self->{ 'play' }->eventGenerate( qw/ <ButtonPress-1>   -when tail / );
    $self->{ 'play' }->eventGenerate( qw/ <ButtonRelease-1> -when tail / );

} # end playpause

sub rightcommand {

    my ($self, $callback ) = @_;

    $self->toplevel->bind( '<Right>' => $callback );

} # end rightcommand

sub setbindings {		# set bindings similar to Apple's Aqua interface

    my( $self, $l ) = @_;
    
    $l->bind( '<Enter>'           => [ $self => 'enter',    $l, "_n_r"  ] );
    $l->bind( '<Leave>'           => [ $self => 'leave',    $l, "_n"    ] );
    $l->bind( '<ButtonPress-1>'   => [ $self => 'newimage', $l, "_hi_b" ] );
    $l->bind( '<ButtonRelease-1>' => [ $self => 'callback', $l, "_n"    ] );

} # end setbindings

1;
__END__

=head1 NAME

Tk::MultiMediaControls - Create media player control buttons.

=for pm Tk/MultiMediaControls.pm

=for category Animations

=head1 SYNOPSIS

 $mmc = $parent->MultiMediaControls(-option => value, ... );

=head1 DESCRIPTION

Create multimedia controls similar to that found on Apple applications
like QuickTime, iMovie, iDVD, iTunes, etcetera. This mega-widget accepts a
-buttons option that specifies a list of controller buttons, and a series
of specialized options that bind callbacks to those buttons.

=over 4

=item B<-buttons>

A list of controller buttons: C<[ qw/ home rewind play stop fastforward / ]>.
You supply the callbacks that implement the above buttons, which
nominally have this effect on the movie:

home - reset movie to first frame

rewind - play movie in fast reverse

play - a toggle: play movie at normal speed / pause movie
 
stop - stop movie (reset to first frame?)

fastforward - play movie in fast forward

=item B<-fastcommand>

=item B<-fasthighlightcommand>

=item B<-homecommand>

=item B<-homehighlightcommand>

=item B<-leftcommand>

=item B<-pausecommand>

=item B<-pausehighlightcommand>

=item B<-playcommand>

=item B<-playhighlightcommand>

=item B<-rewindcommand>

=item B<-rewindhighlightcommand>

=item B<-rightcommand>

=item B<-stopcommand>

=item B<-stophighlightcommand>

Callbacks that are invoked when control buttons are pressed or released.
Callbacks that include the string B<highlight> are invoked when Button-1
is pressed and held. With the exception of the I<-leftcommand> and
I<-rightcommand>, all other callbacks are invoked when Button-1 is released.

Three keys have special meanings that parallel Apple's bindings. The
space bar (space) is bound to toggle the play/pause button.  The
left-arrow (Left) and right-arrow (Right) should, if possible, display
the previous or next movie frame. Use I<-leftcommand> and
I<-rightcommand> for this.

=back

=head1 METHODS

A MultiMediaControls widget has no additional methods.

=head1 EXAMPLE

This example creates a MultiMediaControls widget appropriate for a
Tk::Animation widget:

 my $p   = $mw->Animation( -format => 'gif', -file => ' ... ' );
 my $mmc = $mw->MultiMediaControls(

     # Define, from left to right, the window's controller buttons.

     -buttons                     => [ qw/ home rewind play stop fastforward / ],

     # Define callbacks for the buttons' various states.

     -fastforwardhighlightcommand => [ $p => 'fast_forward',   4 ],
     -fastforwardcommand          => [ $p => 'fast_forward',   1 ],
     -homecommand                 => [ $p => 'set_image',      0 ],
     -pausecommand                => [ $p => 'pause_animation'   ],
     -playcommand                 => [ $p => 'resume_animation'  ],
     -rewindhighlightcommand      => [ $p => 'fast_reverse',  -4 ],
     -rewindcommand               => [ $p => 'fast_reverse',   1 ],
     -stopcommand                 => [ $p => 'stop_animation'    ],

     # Define callbacks for the left and right arrow keys.

     -leftcommand                 => [ $p => 'prev_image'        ],
     -rightcommand                => [ $p => 'next_image'        ],

 )->pack;

=head1 AUTHOR

sol0@Lehigh.EDU

Copyright (C) 2003 - 2004, Steve Lidie. All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 KEYWORDS

Apple, QuickTime, animation, multimedia, iMovie, iTunes

=head1 BUGS

I'm sure there are end cases and errors that I've neglected to catch.

=cut
