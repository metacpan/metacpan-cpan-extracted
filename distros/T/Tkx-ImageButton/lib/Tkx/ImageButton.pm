package Tkx::ImageButton;

use strict;
use warnings;

our $VERSION = '0.14';

use Tkx;
use base qw(Tkx::widget Tkx::MegaConfig);

__PACKAGE__->_Mega('tkx_ImageButton');
__PACKAGE__->_Config(
    -imagedisplay  => ['METHOD'],
    -imageover     => ['METHOD'],
    -imageclick    => ['METHOD'],
    -imagedisabled => ['METHOD'],
    -blink         => ['METHOD'],
    -blinkdelay    => ['METHOD'],
    -state         => ['METHOD'],
    -command       => ['METHOD'],
);

# Locale variables
my $tile;
my $initialized;

#----------------------------------------------------------------------------
# Method  : _Populate
# Purpose : Create a new ImageButton
# Notes   :
#----------------------------------------------------------------------------
sub _Populate {
    my ($class, $widget, $path, %opt) = @_;
    my ($data);
    
    if (!$initialized) {
        $tile        = eval { Tkx::package_require('tile') };
        $initialized = 1;
    }
    
    my $self = $tile
        ? $class->new($path)->_parent->new_ttk__label(-name => $path, -class => 'tkx_ImageButton')
        : $class->new($path)->_parent->new_label(-name => $path);

    $self->_class($class);

    # Data
    $data = $self->_data();
    $data->{-imagedisplay}  = delete $opt{-imagedisplay};
    $data->{-imageover}     = delete $opt{-imageover};
    $data->{-imageclick}    = delete $opt{-imageclick};
    $data->{-imagedisabled} = delete $opt{-imagedisabled};
    $data->{-state}         = delete $opt{-state};
    
    $data->{-blink}         = delete $opt{-blink};

    $data->{-blinkdelay}    = delete $opt{-blinkdelay} || 300;
    $data->{-command}       = delete $opt{-command};

    $data->{-blinkphase}    = 0;
    $data->{-state}         = 0;

    $data->{-over}          = 0;
    $data->{-toogled}       = 0;

    # Set image and blink if needed
    $self->_IBLeave();
    $self->_IBBlink();

    # Bindings
    Tkx::bind($self => '<Enter>'           => [\&_IBEnter,   $self]);
    Tkx::bind($self => '<Leave>'           => [\&_IBLeave,   $self]);
    Tkx::bind($self => '<ButtonPress-1>'   => [\&_IBPress,   $self]);
    Tkx::bind($self => '<ButtonRelease-1>' => [\&_IBRelease, $self]);

    # Widget
    return $self;
}


#----------------------------------------------------------------------------
# Method  : invoke
# Purpose : 
# Notes   :
#----------------------------------------------------------------------------
sub invoke {
    my ($self) = @_;

    if (defined(my $cb = $self->_data->{-command})) {
        Tkx::i::call($cb);
    }
}


#----------------------------------------------------------------------------
# Method  : _IBEnter
# Purpose : 
# Notes   :
#----------------------------------------------------------------------------
sub _IBEnter {
    my ($self) = @_;

    if ($self->_data->{-state} ne 'disabled') {
        if (defined(my $imageover = $self->_data->{-imageover})) {
            $self->configure( -image => $imageover );
        }

        $self->_data->{-over} = 1;
    }
}


#----------------------------------------------------------------------------
# Method  : _IBLeave
# Purpose : 
# Notes   :
#----------------------------------------------------------------------------
sub _IBLeave {
    my ($self) = @_;

    if ($self->_data->{-state} ne 'disabled') {
        if (defined(my $imagedisplay = $self->_data->{-imagedisplay})) {
            $self->configure( -image => $imagedisplay );
        }

        $self->_data->{-over} = 0;
    }
}


#----------------------------------------------------------------------------
# Method  : _IBPress
# Purpose : 
# Notes   :
#----------------------------------------------------------------------------
sub _IBPress {
    my ($self) = @_;
    
    if ($self->_data->{-state} ne 'disabled') {
        if (defined(my $imageclick = $self->_data->{-imageclick})) {
            $self->configure( -image => $imageclick );
        }
        
        $self->_data->{-toogled} = 1;
    }
}


#----------------------------------------------------------------------------
# Method  : _IBRelease
# Purpose : 
# Notes   :
#----------------------------------------------------------------------------
sub _IBRelease {
    my ($self) = @_;

    if ($self->_data->{-state} ne 'disabled') {
        my $imover    = $self->_data->{-imageover};
        my $imdisplay = $self->_data->{-imagedisplay};
    
        if    (defined $imover)    { $self->configure(-image => $imover)    }
        elsif (defined $imdisplay) { $self->configure(-image => $imdisplay) }
    
        if ($self->_data->{-over} && $self->_data->{-toogled}) {
            $self->invoke();
        }
    }

    $self->_data->{-toogled} = 0;
}


#----------------------------------------------------------------------------
# Method  : _IBBlink
# Purpose : 
# Notes   :
#----------------------------------------------------------------------------
sub _IBBlink {
    my ($self) = @_;
    
    if ($self->_data->{-blink}) {
        if ($self->_data->{-blinkphase}) {
            $self->_IBLeave();
            $self->_data->{-blinkphase} = 0;
        }
        else {
            $self->_IBEnter();
            $self->_data->{-blinkphase} = 1;
        }

        Tkx::after($self->_data->{-blinkdelay}, [\&_IBBlink, $self]);
    }
    else {
        $self->_IBLeave();
    }
}


#----------------------------------------------------------------------------
# Method  : _config_command
# Purpose : Handler for configure(-command => <value>)
# Notes   :
#----------------------------------------------------------------------------
sub _config_command {
    my ($self, $command) = @_;

    if ($#_ > 0) {
        $self->_data->{-command} = $command;
    }
    else {
        return $self->_data->{-command};
    }
}

#----------------------------------------------------------------------------
# Method  : _config_state
# Purpose : Handler for configure(-state => <value>)
# Notes   :
#----------------------------------------------------------------------------
sub _config_state {
    my ($self, $state) = @_;

    if ($#_ > 0) {
        $self->_data->{-state} = $state;
        
        if ($state eq 'disabled') {
            if (defined(my $imagedisabled = $self->_data->{-imagedisabled})) {
                $self->configure( -image => $imagedisabled );
            }
        }
        else {
            if (defined(my $imagedisplay = $self->_data->{-imagedisplay})) {
                $self->configure( -image => $imagedisplay );
            }
        }
    }
    else {
        return $self->_data->{-state};
    }
}


#----------------------------------------------------------------------------
# Method  : _config_imagedisplay
# Purpose : Handler for configure(-imagedisplay => <value>)
# Notes   :
#----------------------------------------------------------------------------
sub _config_imagedisplay {
    my ($self, $imagedisplay) = @_;

    if ($#_ > 0) {
        $self->_data->{-imagedisplay} = $imagedisplay;
        
        $self->_IBLeave() unless $self->_data->{-over};
    }
    else {
        return $self->_data->{-imagedisplay};
    } 
}


#----------------------------------------------------------------------------
# Method  : _config_imageover
# Purpose : Handler for configure(-imageover => <value>)
# Notes   :
#----------------------------------------------------------------------------
sub _config_imageover {
    my ($self, $imageover) = @_;

    if ($#_ > 0) {
        $self->_data->{-imageover} = $imageover;
        
        $self->_IBEnter() if $self->_data->{-over};
    }
    else {
        return $self->_data->{-imageover};
    } 
}


#----------------------------------------------------------------------------
# Method  : _config_imageclick
# Purpose : Handler for configure(-imageclick => <value>)
# Notes   :
#----------------------------------------------------------------------------
sub _config_imageclick {
    my ($self, $imageclick) = @_;

    if ($#_ > 0) {
        $self->_data->{-imageclick} = $imageclick;
    }
    else {
        return $self->_data->{-imageclick};
    }     
}


#----------------------------------------------------------------------------
# Method  : _config_imagedisabled
# Purpose : Handler for configure(-imagedisabled => <value>)
# Notes   :
#----------------------------------------------------------------------------
sub _config_imagedisabled {
    my ($self, $imagedisabled) = @_;

    if ($#_ > 0) {
        $self->_data->{-imagedisabled} = $imagedisabled;
    }
    else {
        return $self->_data->{-imagedisabled};
    }    
}


#----------------------------------------------------------------------------
# Method  : _config_blink
# Purpose : Handler for configure(-blink => <value>)
# Notes   :
#----------------------------------------------------------------------------
sub _config_blink {
    my ($self, $blink) = @_;

    if ($#_ > 0) {
        my $blinking = $self->_data->{-blink};
        $self->_data->{-blink} = $blink;
        
        $self->_IBBlink() unless $blinking;
    }
    else {
        return $self->_data->{-blink};
    }
}

#----------------------------------------------------------------------------
# Method  : _config_blinkdelay
# Purpose : Handler for configure(-blinkdelay => <value>)
# Notes   :
#----------------------------------------------------------------------------
sub _config_blinkdelay {
    my ($self, $delay) = @_;

    if ($#_ > 0) {
        $self->_data->{-blinkdelay} = $delay;
    }
    else {
        return $self->_data->{-blinkdelay};
    }
}




1;
__END__

=pod

=head1 NAME

Tkx::ImageButton - Graphic button megawidget for Tkx


=head1 VERSION

This documentation refers to Tkx::ImageButton version 0.14


=head1 SYNOPSIS

    use Tkx;
    use Tkx::ImageButton;
   
    my $mw = Tkx::widget->new('.');
    my $im_button_1 = $mw->new_tkx_ImageButton(
        -imagedisplay  => Tkx::image_create_photo(-file => 'button1.png'),
        -imageover     => Tkx::image_create_photo(-file => 'button2.png'),
        -imageclicked  => Tkx::image_create_photo(-file => 'button3.png'),
        -imagedisabled => Tkx::image_create_photo(-file => 'button4.png');
        -command       => sub { ... },
    );

    my $im_button_2 = $mw->new_tkx_ImageButton(
        -imagedisplay  => Tkx::image_create_photo(-file => 'button1.png'),
        -imageover     => Tkx::image_create_photo(-file => 'button2.png'),
        -command       => sub { ... },
    );

    ...


=head1 DESCRIPTION

Tkx::ImageButton is a megawidget that implementing graphical button with
some options.


=head1 OPTIONS

The options bellow are passed through the constructor of megawidget.

=head2 C<-imagedisplay =E<gt> I<image>>

Defines an image for the button. Image should be tk photo object.

=head2 C<-imageover =E<gt> I<image>>

Image that be showed when button is mouse overed.

=head2 C<-imageclicked =E<gt> I<image>>

Image for the clicked state.

=head2 C<-imagedisabled =E<gt> I<image>>

Image for the disabled state.

=head2 C<-command =E<gt> I<CODEREF>>

Command that be called when use has pressed the button

=head2 C<-blinkdelay =E<gt> I<delay>>

Blink delay.

=head2 C<-blink =E<gt> I<blink state>>

If the value is greater than 0, button will blinking every -blinkdelay.


=head1 METHODS

Tkx::ImageButton methods.

=head2 C<new>

Constructor.

=head2 C<configure>

Configure widget properties after constructing.

=head2 C<invoke>

Invokes the command associated with the button.


=head1 BUGS AND LIMITATIONS

None known at this time.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tkx::ImageButton


=head1 AUTHOR

Written by Alexander Nusov.
Inspired by Dave Hickling (Tk-ImageButton).


=head1 COPYRIGHTS AND LICENSE

Copyright (C) 2010, Alexander Nusov <alexander.nusov+cpan <at> gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut