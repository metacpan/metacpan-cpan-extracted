#############################################################################
## Name:        Wx::Perl::Throbber
## Purpose:     An animated throbber/spinner
## Author:      Simon Flack
## Modified by: $Author: simonflack $ on $Date: 2005/03/25 13:38:55 $
## Created:     22/03/2004
## RCS-ID:      $Id: Throbber.pm,v 1.5 2005/03/25 13:38:55 simonflack Exp $
#############################################################################

package Wx::Perl::Throbber;

use strict;
use vars      qw/@ISA $VERSION @EXPORT_OK/;
use Wx        qw/:misc wxWHITE/;
use Wx::Event qw/EVT_PAINT EVT_TIMER/;
use Wx::Perl::Carp;
use Exporter;

$VERSION   = sprintf'%d.%02d', q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;
@ISA       = qw/Exporter Wx::Panel/;
@EXPORT_OK = qw/EVT_UPDATE_THROBBER/;

use constant DFLT_FRAMEDELAY => 75;
use constant THROBBER_EVENT  => Wx::NewEventType;

sub EVT_UPDATE_THROBBER { $_[0]->Connect(-1, -1, THROBBER_EVENT, $_[1]) }

sub UpdateThrobberEvent {
    my $event = new Wx::PlEvent($_[0]->GetId, THROBBER_EVENT);
}

sub new {
    my $class = shift;
    my ($parent, $id, $bitmap, $pos, $size, $frameDelay, $frames, $framesWidth,
        $label, $overlay, $reverse, $style, $name) = @_;

    $id      = '-1' unless defined $id;
    $name    = 'throbber' unless defined $name;
    $pos     = wxDefaultPosition unless defined $pos;
    $size    = wxDefaultSize unless defined $size;
    $label   = '' unless defined $label;
    $reverse = 0 unless defined $reverse;

    my $self = $class -> SUPER::new ($parent, $id, $pos, $size, $style, $name);

    $self -> SetClientSize  ($size);
    $self -> SetFrameDelay  ($frameDelay ? $frameDelay : DFLT_FRAMEDELAY);
    $self -> SetAutoReverse ($reverse);

    if (defined $bitmap) {
        $self -> SetBitmap  ($bitmap, $frames, $framesWidth);
        $self -> SetLabel   ($label) if defined $label;
        $self -> SetOverlay ($overlay) if defined $overlay;
        $self -> ShowLabel  (defined $label);
    }
    $self -> _init($reverse, defined $label);

    EVT_UPDATE_THROBBER ($self, \&Rotate);
    EVT_PAINT ($self, \&OnPaint);
    EVT_TIMER ($self, $self -> {timerID}, \&OnTimer);
    bless $self, $class;
}

sub _init {
    my $self = shift;
    my ($reverse, $show_label) = @_;
    $self -> {running}     = 0;
    $self -> {current}     = 0;
    $self -> {direction}   = 1;
    $self -> {timerID} = Wx::NewId;
    $self -> {timer} = Wx::Timer -> new ($self, $self -> {timerID});
}

sub OnTimer {
    my $self = shift;
    $self -> ProcessEvent ($self -> UpdateThrobberEvent());
}

sub DESTROY {
    my $self = shift;
    $self -> Stop;
}

# Draw the throbber
sub Draw {
    my $self = shift;
    my ($dc) = @_;

    $dc -> DrawBitmap (
                       $self -> {submaps} [$self -> {current}],
                       0,
                       0,
                       1
                      );
    if ($self -> {overlay} && $self -> {showOverlay}) {
        $dc->DrawBitmap (
                         $self -> {overlay},
                         $self -> {overlayX},
                         $self -> {overlayY},
                         1
                        );
    }
    if ($self -> {label} && $self -> {showLabel}) {
        $dc->DrawText (
                       $self -> {label},
                       $self -> {labelX},
                       $self -> {labelY}
                      );
        $dc->SetTextForeground (wxWHITE);
        $dc->DrawText(
                      $self -> {label},
                      $self -> {labelX} - 1,
                      $self -> {labelY} - 1
                     );
    }
}

sub OnPaint {
    my $self = shift;
    my ($event) = @_;
    $self -> Draw(new Wx::PaintDC($self));
    $event -> Skip();
}

# Change the frame
sub Rotate {
    my $self = shift;
    my ($event) = @_;

    $self -> {current} += $self -> {direction};

    # Have we reached the last frame
    if ($self -> {current} == scalar @{$self -> {sequence}}) {
        if ($self -> {autoReverse}) {
            $self -> Reverse();
            $self -> {current} = scalar @{$self -> {sequence}} - 1;
        } else {
            $self -> {current} = 1;
        }
    }

    # Have we reached the first frame
    if ($self -> {current} == 0) {
        if ($self -> {autoReverse}) {
            $self -> Reverse();
            $self -> {current} = 1;
        } else {
            $self -> {current} = scalar @{$self -> {sequence}} - 1;
        }
    }

    $self -> Draw(new Wx::ClientDC($self));
}

##############################################################################
# Public Methods

sub SetBitmap {
    my $self = shift;
    my ($bitmap, $frames, $framesWidth) = @_;

    croak "SetBitmap: requires a bitmap" unless ref $bitmap;
    croak "SetBitmap: Not a valid bitmap"
            unless ref $bitmap eq 'ARRAY'
         || UNIVERSAL::isa($bitmap,'Wx::Bitmap');

    $frames      = 1 unless defined $frames;
    $framesWidth = 0 unless defined $framesWidth;
    $self -> _set_bitmap_size ($bitmap, $framesWidth);

    if (ref $bitmap eq 'ARRAY') {
        $self -> {submaps} = $bitmap;
        $self -> {frames}  = scalar @$bitmap;
    } elsif ($bitmap -> isa ('Wx::Bitmap')) {
        $self -> {frames}  = $frames;
        $self -> {submaps} = [];

        # Slice the bitmap into 0 + $frames frames
        # Wx::Bitmap->GetSubBitmap is broken in wxMSW 2.4, so we convert to an
	# image, and convert each SubImage back to a Wx::Bitmap
        my $image = new Wx::Image($bitmap);
        for (0 .. $frames - 1) {
            my $rect = new Wx::Rect(
                                    $_ * $framesWidth,
                                    0,
                                    $self -> {width},
                                    $self -> {height}
                                   );
           my $subimage = $image -> GetSubImage ($rect);
           my $submap   = new Wx::Bitmap ($subimage);
           push @{$self -> {submaps}}, $submap;
        }
    }

    # Set the sequence
    $self -> {sequence} = [1 .. $self -> {frames}];
    return 1;
}

sub SetFrameDelay {
    my $self = shift;
    my ($frameDelay) = @_;

    croak "USAGE: SetFrameDelay(miliseconds)"
            unless defined $frameDelay && !ref $frameDelay;

    $self->{frameDelay} = int $frameDelay;
    if ($self -> IsRunning) {
        $self -> Stop;
        $self -> Start;
    }
    return 1;
}

sub GetFrameDelay {
    my $self = shift;
    return $self -> {frameDelay};
}

sub GetCurrentFrame {
    my $self = shift;
    return $self -> {current};
}

sub GetFrameCount {
    my $self = shift;
    return $self -> {frames} - 1;
}

sub Start {
    my $self = shift;
    unless ($self -> {running}) {
        $self -> {running} = 1;
        $self -> {timer} -> Start (int $self -> {frameDelay});
    }
    return 1;
}

sub Stop {
    my $self = shift;
    if ($self -> {running}) {
        $self -> {timer} -> Stop;
        $self -> {running} = 0;
    }
    return 1;
}

sub Rest {
    my $self = shift;
    $self -> Stop ();
    $self -> {current} = 0;
    $self -> Draw(new Wx::ClientDC($self));
    return 1;
}

sub IsRunning {
    my $self = shift;
    return $self -> {running};
}

sub Reverse {
    my $self = shift;
    $self -> {direction} = - $self -> {direction};
    return 1;
}

sub SetAutoReverse {
    my $self = shift;
    my ($state) = @_;

    $self -> {autoReverse} = not (defined $state && !$state);
    return 1;
}

sub GetAutoReverse {
    my $self = shift;
    return $self -> {autoReverse};
}

sub SetOverlay {
    my $self = shift;
    my $overlay = shift;

    croak "SetOverlay: requires a bitmap"
            unless ref $overlay && UNIVERSAL::isa($overlay, 'Wx::Bitmap');

    return unless $self -> {sequence} && scalar $self -> {sequence};
    if ($overlay) {
        $self -> {overlay} = $overlay;
        $self -> {overlayX} = int(($self->{width} - $overlay -> GetWidth)/2);
        $self -> {overlayY} = int(($self->{height} - $overlay -> GetHeight)/2);
        return 1;
    }
}

sub GetOverlay {
    my $self = shift;
    return unless $self -> {overlay};
    return new Wx::Bitmap ($self -> {overlay});
}

sub ShowOverlay {
    my $self = shift;
    my ($state) = @_;

    $self -> {showOverlay} = not (defined $state && !$state);
    $self -> Draw(new Wx::ClientDC($self));
    return 1;
}

sub GetLabel {
    my $self = shift;
    return $self -> {label};
}

sub ShowLabel {
    my $self = shift;
    my ($state) = @_;

    $self -> {showLabel} = not (defined $state && !$state);
    $self -> Draw(new Wx::ClientDC($self));
    return $self -> {label};
}

sub SetLabel {
    my $self = shift;
    my ($label) = @_;

    croak "USAGE: SetLabel (label)"
            unless defined $label && !ref $label;

    return unless $self -> {sequence} && scalar $self -> {sequence};
    if (defined $label) {
        $self -> {label} = $label;
        my ($extentx, $extenty) = $self -> GetTextExtent ($label);
        $self -> {labelX} = int(($self -> {width} - $extentx)  / 2);
        $self -> {labelY} = int(($self -> {height} - $extenty) / 2);
        return 1
    }
}

sub SetFont {
    my $self = shift;
    my ($font) = @_;
    croak "SetFont: requires a Wx::Font"
            unless ref $font && UNIVERSAL::isa($font, 'Wx::Font');

    $self -> SetFont ($font);
    $self -> SetLabel ($self -> {label});
    $self -> Draw(new Wx::ClientDC($self));
    return 1;
}

# Private

# Set the bitmap with and size (for use by overlay/label)
sub _set_bitmap_size {
    my $self = shift;
    my ($bitmap, $framesWidth) = @_;

    my ($width, $height) = $self -> GetSizeWH();
    if ($width == -1) {
        if (ref $bitmap && ref $bitmap eq 'ARRAY') {
            $width = $bitmap -> [0] -> GetWidth;
        } else {
            $width = $framesWidth ? $framesWidth : $width
        }
    }
    if ($height == -1) {
        if (ref $bitmap && ref $bitmap eq 'ARRAY') {
            $width = $bitmap -> [0] -> GetHeight;
        } else {
            $width = $bitmap -> GetHeight;
        }
    }
    if ($width == -1 || $height == -1) {
        croak "Unable to determine size";
    }

    $self -> {width}  = $width;
    $self -> {height} = $height;
}

=pod

=head1 NAME

Wx::Perl::Throbber - An animated throbber/spinner

=head1 SYNOPSIS

    use Wx::Perl::Throbber;

    my @frames;
    foreach ('1.gif', '2.gif', '3.gif') {
        push @frames, new Wx::Bitmap($_, wxBITMAP_TYPE_ANY);
    }

    my $throbber = new Wx::Perl::Throbber($parent, -1, \@frames, $pos, $size);
    $throbber->SetLabel('Please Wait');
    $throbber->ShowLabel(1);
    $throbber->Start();

    ...
    $throbber->Rest(); # or Stop()

=head1 DESCRIPTION

This control is based on the Python library wx.throbber.

A throbber displays an animated image that can be started, stopped, reversed,
etc.  Useful for showing an ongoing process (like most web browsers use) or
simply for adding eye-candy to an application.

Throbbers utilize a Wx::Timer so that normal processing can continue
unencumbered.

=head1 METHODS

=over 4

=item $throbber = new($parent, $id, $bitmap, $position, $size, $frameDelay, $frames, $framesWidth, $label, $overlay, $reverse, $style, $name)

  $parent                          (parent window)
  $id          = -1                (window identifier)
  $bitmap      = undef             (throbber bitmap. see SetBitmap())
  $position    = wxDefaultPosition (window position)
  $size        = wxDefaultSize     (window size)
  $frameDelay  = 75                (milliseconds. See SetFrameDelay)
  $frames      = undef             (number of frames. see SetBitmap())
  $framesWidth = undef             (width of frames. see SetBitmap())
  $label       = ''                (text label. see SetLabel())
  $overlay     = undef             (overlay bitmap. see SetOverlay())
  $reverse     = 0                 (auto-reverse)
  $style       = undef             (window style)
  $name        = "throbber"        (window name)

=item SetBitmap($bitmap, $frames, $framesWidth)

C<$bitmap> is either a single C<Wx::Bitmap> that will be split into frames (a
composite image) or a list of C<Wx::Bitmap> objects that will be treated as
individual frames.

If a single (composite) image is given, then additional information must be
provided: the number of frames in the image (C<$frames>) and the width of each
frame (C<$framesWidth>).

The first frame is treated as the "at rest" frame (it is not shown during
animation, but only when C<Rest()> is called.

=item SetFrameDelay($milliseconds)

Set the delay between frames I<in milliseconds>

Default is 75 milliseconds

=item GetFrameDelay()

Returns the frame delay

=item Start()

Start the animation

=item Stop()

Stop the animation

=item Rest()

Stop the animation and return to the I<rest frame> (frame 0)

=item IsRunning()

Returns C<true> if the animation is running

=item GetCurrentFrame()

Returns the frame index that is currently displayed. Starts at 0 (the I<rest 
frame>)

=item GetFrameCount()

Returns the number of frames in the animation (excluding the I<rest frame>)

=item Reverse()

Change the direction of the animation

=item SetAutoReverse($bool)

Turn on/off auto-reverse. When auto-reverse is set, the throbber will change
direction when it reaches the start/end of the animation. Otherwise it jumps
back to the beginning.

=item GetAutoReverse()

Get the auto-reverse state

=item SetOverlay($bitmap)

Sets an overlay bitmap to be displayed above the throbber animation

=item GetOverlay()

Returns a copy of the overlay bitmap set for the throbber

=item ShowOverlay($state)

Set true/false whether the overlay bitmap is shown

=item SetLabel($label)

Set the text of the label. The text label appears above the throbber animation
and overlay (if applicable)

=item GetLabel()

Returns the label set for the throbber

=item ShowLabel($state)

Set true/false whether the text label is shown

=item SetFont ($font)

Set the font for the label. Expects a Wx::Font object.

=back

=head1 EVENTS

=over 4

=item EVT_UPDATE_THROBBER($throbber, \&func)

This event is processed while the throbber is running, every $frameDelay
milliseconds

This function is exported on request:

    use Wx::Perl::Throbber 'EVT_UPDATE_THROBBER';

=back

=head1 AUTHOR

Simon Flack

=head1 COPYRIGHT

This module is released under the wxWindows/GPL license

=head1 ACKNOWLEDGEMENTS

Wx::Perl::Throbber is based on the Python library wx.throbber by Cliff Wells

=cut
