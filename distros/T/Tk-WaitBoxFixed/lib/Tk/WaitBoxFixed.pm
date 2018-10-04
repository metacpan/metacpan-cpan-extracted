##########################################
##########################################
##                                      ##
##  WaitBoxFixed - a reusable Tk-widget ##
##                 Wait Dialog          ##
##                                      ##
##  Version 1.6                         ##
##                                      ##
##  Brent B. Powers	(B2Pi)              ##
##  Powers@B2Pi.com                     ##
##                                      ##
##########################################
##########################################

###############################################################################
###############################################################################
## WaitBoxFixed
##    Object Oriented Wait Dialog for TkPerl
##    (Apologies to John Stoffel and Stephen O. Lidie)
##
## Changes:
## Ver 1.1 Changed show to Show, unshow to unShow, and general
##         cleanup for perl5.002 gamma
## Ver 1.2 Changed to general distribution, add VERSION and Version
## Ver 1.3 Added -takefocus param, on suggestion of Ben Hochstedler
##	   <benh@med.ge.com>, some other stuff
## Ver 1.4 Cavac: Added some fixes
## Ver 1.5 Cavac: Added some fixes
## Ver 1.6 Cavac, ASB: fixes and cleanup of POD
## Ver 1.7 Cavac, added use warnings, increased kwalitee
## Ver 1.8 Cavac and Alex Becker, Updated documentation
##
###############################################################################
###############################################################################

package Tk::WaitBoxFixed;

use strict;
use warnings;
use Tk::Toplevel;

@Tk::WaitBoxFixed::ISA = qw (Tk::Toplevel);

Tk::Widget->Construct('WaitBoxFixed');

$Tk::WaitBoxFixed::VERSION = '1.8';

### A couple of convenience variables
my(@wd_fullpack) = (-expand => 1, -fill => 'both');
my(@wd_packtop) = (-side => 'top');
my(@wd_packleft) = (-side => 'left');

sub Populate {
    ### Wait box constructor.  Uses new inherited from base class
    my($cw, $wdtop, $fm, $bitmap, $txt1, $uframe, $txt2);
    $cw = shift;
    $cw->SUPER::Populate(@_);

    ## Create the toplevel window
    $cw->withdraw;
    $cw->protocol('WM_DELETE_WINDOW' => sub {});

    # See http://cpanratings.perl.org/dist/Tk-WaitBox
    #$cw->transient($cw->toplevel);

    ### Set up the status
    $cw->{Shown} = 0;

    ### Set up the cancel button and text
    $cw->{cancelroutine} = undef if !defined($cw->{cancelroutine});
    $cw->{canceltext} = 'Cancel' if !defined($cw->{canceltext});

    ### OK, create the dialog
    ### Start with the upper frame (which contains two messages)
    ## And maybe more....
    $wdtop = $cw->Frame->pack(@wd_fullpack, @wd_packtop);

    $fm = $wdtop->Frame(-borderwidth => 2, -relief => 'raised')
	    ->pack(@wd_packleft, -ipadx => 20, @wd_fullpack);

    $bitmap = $fm->Label(Name => 'bitmap')
	    ->pack(@wd_packleft, -ipadx => 36, @wd_fullpack);

    ## Text Frame
    $fm = $wdtop->Frame(-borderwidth => 2, -relief => 'raised')
	    ->pack(@wd_packleft, -ipadx => 20, @wd_fullpack);

    $txt1 = $fm->Label(-wraplength => '3i', -justify => 'center',
		       -textvariable => \$cw->{Configure}{-txt1})
	    ->pack(@wd_packtop, -pady => 3, @wd_fullpack);

    ### Eventually, I want to create a user configurable frame
    ### in between the two frames
    $uframe = $fm->Frame
	    ->pack(@wd_packtop);
    $cw->Advertise(uframe => $uframe);

    $cw->{Configure}{-txt2} = "Please Wait"
	    unless defined($cw->{Configure}{-txt2});

    $txt2 = $fm->Label(-textvariable => \$cw->{Configure}{-txt2})
	    ->pack(@wd_packtop, @wd_fullpack, -pady => 9);

    ### We'll let the cancel frame and button wait until Show time

    ### Set up configuration
    $cw->ConfigSpecs(-bitmap	=> [$bitmap, undef, undef, 'hourglass'],
		     -foreground=> [[$txt1,$txt2], 'foreground','Foreground','black'],
		     -background=> ['DESCENDANTS', 'background', 'Background',undef],
		     -font	=> [$txt1,'font','Font','-Adobe-Helvetica-Bold-R-Normal--*-180-*'],
		     -canceltext=> ['PASSIVE', undef, undef, 'Cancel'],
		     -cancelroutine=> ['PASSIVE', undef, undef, undef],
		     -txt1	=> ['PASSIVE', undef, undef, undef],
		     -txt2	=> ['PASSIVE',undef,undef,undef],
		     -resizeable => ['PASSIVE',undef,undef,1],
		     -takefocus => ['SELF', undef, undef, 1]);

    return;
}

sub Version {return $Tk::WaitBoxFixed::VERSION;}

sub Show {
    ## Do last minute configuration and Show the dialog
    my($wd, @args) = @_;

    if ( defined($wd->{Configure}{-cancelroutine}) &&
	!defined($wd->{CanFrame})) {
	my($canFrame) = $wd->Frame (-background => $wd->cget('-background'));
	$wd->{CanFrame} = $canFrame;
	$canFrame->pack(-side => 'top', @wd_packtop, -fill => 'both');
	$canFrame->configure(-cursor => 'top_left_arrow');
	$canFrame->Button(-text => $wd->{Configure}{-canceltext},
			  -command => $wd->{Configure}{-cancelroutine})
		->pack(-padx => 5, -pady => 5,
		       -ipadx => 5, -ipady => 5);
    }

    ## Grab the input queue and focus
    $wd->parent->configure(-cursor => 'watch') if $wd->{Configure}{-takefocus};
    $wd->configure(-cursor => 'watch');
    $wd->update;

    my($x) = int( ($wd->screenwidth
		 - $wd->reqwidth)/2
		 - $wd->vrootx);

    my($y) = int( ($wd->screenheight
		 - $wd->reqheight)/2
		 - $wd->vrooty);

    $wd->geometry("+$x+$y");

    $wd->{Shown} = 1;

    $wd->deiconify;
    $wd->tkwait('visibility', $wd);

    if ($wd->{Configure}{-takefocus}) {
	$wd->grab();
	$wd->focus();
    }
    $wd->update;

    return $wd;

}

sub unShow {
    my($wd) = @_;

    return unless $wd->{Shown};
    $wd->{CanFrame}->destroy if defined($wd->{CanFrame});
    $wd->{CanFrame} = undef;
    $wd->parent->configure(-cursor => 'top_left_arrow');

    $wd->grab('release');
    $wd->withdraw;
    $wd->parent->update;
    $wd->{Shown} = 0;

    return;
}

1;

__END__

=head1 NAME

Tk::WaitBoxFixed - An Object Oriented Wait Dialog for Perl/Tk, of the Please Wait variety.

=head1 DESCRIPTION

A WaitBoxFixed consists of a number of subwidgets:

=head2 bitmap

A bitmap (configurable via the I<-bitmap> command, the default is an hourglass) on the left side of the WaitBoxFixed

=head2 label

A label (configurable via the I<-txt1> command), with text in the upper portion of the right hand frame

=head2 secondary label

Another label (configurable via the I<-txt2> command, the default is 'Please Wait'), with text in the lower portion of the right hand frame

=head2 userframe

A frame displayed, if required, between the label and the secondary label.  For details, see the example code and the Advertised Widget section

=head2 cancel button

If a cancelroutine (configured via the I<-cancelroutine> command) is defined, a frame will be packed below the labels and bitmap, with a single button.  The text of the button will be 'Cancel' (configurable via the I<-canceltext> command), and the button will call the supplied subroutine when pressed.

=head1 SYNOPSIS

=head2 Usage Description

=head3 Basic Usage

To use, create your WaitDialog objects during initialization, or at least before a Show.  When you wish to display the WaitDialog object, invoke the 'Show' method on the WaitDialog object; when you wish to cease displaying the WaitDialog object, invoke the 'unShow' method on the object.

=head3 Configuration

Configuration may be done at creation or via the configure method.  

=head3 Example Code

    #!/usr/local/bin/perl -w 

    ## Dependent on Graham Barr's Tk::ProgressBar
    use strict;

    use Tk;
    use Tk::WaitBoxFixed;
    use Tk::ProgressBar;

    my($root) = MainWindow->new;
    $root->withdraw;
    my($utxt) = "Initializing...";
    my($percent);

    my($wd);
    $wd = $root->WaitBoxFixed(
			 -bitmap =>'questhead', # Default would be 'hourglass'
			 -txt2 => 'tick-tick-tick', #default would be 'Please Wait'
			 -title => 'Takes forever to get service around here',
			 -cancelroutine => sub {
			     print "\nI'm canceling....\n";
			     $wd->unShow;
			     $utxt = undef;
			 });
    $wd->configure(-txt1 => "Hurry up and Wait, my Drill Sergeant told me");
    $wd->configure(-foreground => 'blue',-background => 'white');

    ### Do something quite boring with the user frame
    my($u) = $wd->{SubWidget}{uframe};
    $u->pack(-expand => 1, -fill => 'both');
    $u->Label(-textvariable => \$utxt)->pack(-expand => 1, -fill => 'both');

    ## It would definitely be better to do this with a canvas... this is dumb
    my($bar) = $u->ProgressBar(
			       -variable => \$percent,
			       -blocks => 0,
			       -width => 20,
			       -colors => [  0 => 'green',
					     30 => 'yellow',
					     50 => 'orange',
					     80 => 'red'],
			      )
	    ->pack(-expand =>1, -fill =>'both');

    $wd->configure(-canceltext => 'Halt, Cease, Desist'); # default is 'Cancel'

    $wd->Show;

    my($diff) = 240;
    for (1..$diff) {
	$percent = int($_/$diff*100);
	$utxt = sprintf("%5.2f%% Complete",$percent);
	$bar->update;
	last if !defined($utxt);
    }

    sleep(2);
    $wd->unShow;


=head1 Advertised Subwidgets

=over 4

=item uframe

uframe is a frame created between the two messages.  It may be used for anything the user has in mind... including exciting cycle wasting displays of sand dropping through an hour glass, Zippy riding either a Gnu or a bronc, et cetera.

Assuming that the WaitBoxFixed is referenced by C<$w>, the uframe may be addressed as C<$w-E<gt>subwidget{uframe}>.  Having gotten the address, you can do anything (I think) you would like with it

=back

=head1 Miscellaneous Methods

=over 4

=item -takefocus

Specifying C<-takeFocus =E<gt> 0> will prevent the WaitBoxFixed widget from taking focus. Default is to take focus and do an application grab. I'm not sure why, but someone told me it was necessary.

=back

=head1 Authors

B<Brent B. Powers, (B2Pi)> Powers@B2Pi.com

Copyright(c) 1996-2000 Brent B. Powers. All rights reserved.
This program is free software, you may redistribute it and/or modify
it under the same terms as Perl itself.

B<Rene Schickbauer> cavac@cpan.org

(C) 2013-2018, Rene Schickbauer, same license

B<Alexander Becker>, asb@cpan.org

(C) 2016-2018 Alexander Becker, same license

=cut
