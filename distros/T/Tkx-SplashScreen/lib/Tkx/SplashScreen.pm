package Tkx::SplashScreen;

use strict;
use warnings;

our $VERSION = '0.16';

use Tkx;
use base qw(Tkx::widget Tkx::MegaConfig);

__PACKAGE__->_Mega('tkx_SplashScreen');
__PACKAGE__->_Config();


#----------------------------------------------------------------------------
# Method  : _Populate
# Purpose : Create a new splash screen
# Notes   :
#----------------------------------------------------------------------------
sub _Populate {
    my ($class, $widget, $path, %opt) = @_;

    my $self = $class->new($path)->_parent->new_toplevel(
        -name  => $path,
        -class => 'tkx_SplashScreen'
    );

    $self->_class($class);
    
    # Withdraw window
    $self->g_wm_withdraw();
    
    # Data
    my $data = $self->_data();
    $data->{-title}       = delete  $opt{-title};
    $data->{-image}       = delete  $opt{-image};

    $data->{-override}    = defined $opt{-override}    ? $opt{-override}    : 1;
    $data->{-width}       = defined $opt{-width }      ? $opt{-width}       : 400;
    $data->{-height}      = defined $opt{-height}      ? $opt{-height}      : 300;
    $data->{-alpha}       = defined $opt{-alpha}       ? $opt{-alpha}       : 1.0;
    $data->{-show}        = defined $opt{-show}        ? $opt{-show}        : 1;
    $data->{-posx}        = defined $opt{-posx}        ? $opt{-posx}        : -1;
    $data->{-posy}        = defined $opt{-posy}        ? $opt{-posy}        : -1;
    $data->{-hideonclick} = defined $opt{-hideonclick} ? $opt{-hideonclick} : 0;
    $data->{-topmost}     = defined $opt{-topmost}     ? $opt{-topmost}     : 0;
    $data->{-delay}       = defined $opt{-delay}       ? $opt{-delay}       : 0;

    # Initialize
    $self->_obj_init();

    # Widget
    return $self;
}


#----------------------------------------------------------------------------
# Method  : _obj_init
# Purpose : Initializes splashscreen
# Notes   :
#----------------------------------------------------------------------------
sub _obj_init {
    my ($self) = @_;

    my $data = $self->_data();

    # Title
    if (defined $data->{-title}) {
        $self->g_wm_title($data->{-title});
    }

    # Override redirect
    if ($data->{-override}) {
        $self->g_wm_overrideredirect(1);
    }

    # Alpha channel
    if ($data->{-alpha}) {
        if (Tkx::tk_windowingsystem() eq 'win32') {
            $self->g_wm_attributes(-alpha => $data->{-alpha});
        }
    }

    # Topmost
    if ($data->{-topmost}) {
        $self->g_wm_attributes(-topmost => $data->{-topmost});
    }

    # Fullscreen
    if ($data->{-fullscreen}) {
        $self->g_wm_attributes(-fullscreen => $data->{-fullscreen});
    }

    # Set width/height
    my ($image_width, $image_height);
    my ($width, $height);
    
    if ($data->{-image}) {
        $image_width  = Tkx::image_width($data->{-image});
        $image_height = Tkx::image_height($data->{-image});
    }
    else {
        $image_width  = 400;
        $image_height = 300;
    }
 
    if (($data->{-width} eq 'auto') or ($data->{-width} < 0)) {
        $width = $image_width;
    }
    else {
        $width = $data->{-width};
    }

    if (($data->{-height} eq 'auto') or ($data->{-height} < 0)) {
        $height = $image_height;
    }
    else {
        $height = $data->{-height};
    }

    # Set position
    my ($posx, $posy);
    
    if (($data->{-posx} eq 'auto') or ($data->{-posx} < 0)) {
        $posx = int(($self->g_winfo_screenwidth() - $width) / 2);
    }
    else {
        $posx = $data->{-posx};
    }

    if (($data->{-posy} eq 'auto') or ($data->{-posy} < 0)) {
        $posy = int(($self->g_winfo_screenheight() - $height) / 2);
    }
    else {
        $posy = $data->{-posy};
    }

    # Set image
    my $canvas = $data->{canvas} = $self->new_canvas(
        -width              => $width,
        -height             => $height,
        -highlightthickness => 0,
    );

    $canvas->g_pack();
    
    if ($data->{-image}) {
        $canvas->create_image(qw(0 0), -anchor => 'nw', -image => $data->{-image});
    }

    # Hide on click
    if ($data->{-hideonclick}) {
        Tkx::bind($canvas, '<ButtonPress-1>', sub {
            $self->hide();
        });
    }

    # Hide on delay
    if ($data->{-delay}) {
        Tkx::after($data->{-delay}, sub {
            $self->hide();
        })
    }

    # Set geometry 
    $self->g_wm_geometry("${width}x${height}+${posx}+${posy}");

    # Show window
    if ($data->{-show}) {
        $self->show();
    }    
}


#----------------------------------------------------------------------------
# Method  : show
# Purpose : Show splashscreen toplevel
# Notes   :
#----------------------------------------------------------------------------
sub show {
    my ($self) = @_;
    $self->g_wm_deiconify();
    $self->g_raise();
    $self->g_focus();
}


#----------------------------------------------------------------------------
# Method  : hide
# Purpose : Hide splashscreen
# Notes   :
#----------------------------------------------------------------------------
sub hide {
    my ($self) = @_;
    $self->g_wm_withdraw();
}


#----------------------------------------------------------------------------
# Method  : canvas
# Purpose : Return canvas
# Notes   :
#----------------------------------------------------------------------------
sub canvas {
    my ($self) = @_;
    return $self->_data->{canvas};
}

1;
__END__

=pod

=head1 NAME

Tkx::SplashScreen - splashscreen megawidget for Tkx.

=head1 VERSION

This documentation referers to Tkx::SplashScreen version 0.16

=head1 SYNOPSIS

    use Tkx;
    use Tkx::SplashScreen;
    
    Tkx::package_require('img::png');
    
    my $mw = Tkx::widget->new('.');
       $mw->g_wm_withdraw();
    
    my $sr = $mw->new_tkx_SplashScreen(
        -image      => Tkx::image_create_photo(-file => './image.png'),
        -width      => 'auto',
        -height     => 'auto',
        -show       => 1,
        -topmost    => 1,
    );
    
    my $cv = $sr->canvas();
       $cv->create_text(qw(10 10), -text => 'Loading...', -anchor => 'w');
    
    # Do some stuff.
    
    # Destroy splash screen and show main window.
    Tkx::after(5000 => sub {
        $sr->g_destroy();
        $mw->g_wm_deiconify();
    });


=head1 DESCRIPTION

Tkx::SplashScreen is a megawidget that describes an image that
appears while application is loading.

=head1 OPTIONS

The options bellow are passed through the constructor of megawidget.

=head2 C<-image =E<gt> I<image>>

Background image.

=head2 C<-width =E<gt> I<width>>

Width. Default is 400.

=head2 C<-height =E<gt> I<height>>

Height. Default is 300.

=head2 C<-posx =E<gt> I<x>>

Position X of top left corner.
By default window fits center the screen.

=head2 C<-posy =E<gt> I<y>>

Position Y of top left corner.
By default window fits center the screen.

=head2 C<-delay =E<gt> I<ms>>

Delay in milliseconds after window will be hidden.

=head2 C<-alpha =E<gt> I<level>>

Alpha transparency level of the window (only win32).
Default is 1.0

=head2 C<-override =E<gt> I<overrideredirect>>

Override redirect flag. Enable by default.

=head2 C<-show =E<gt> I<show>>

Show splash screen after construction.

=head2 C<-hideonclick =E<gt> I<hideonclick>>

Hide splash screen on mouse click

=head1 METHODS

Tkx::SplashScreen methods.

=head2 C<new>

Constructor.

=head2 C<configure>

Configure widget properties after constructing.

=head2 C<show>

Show splash screen.

=head2 C<hide>

Hide splash screen.

=head2 C<canvas>

Returns canvas for the splash screen.

=head1 BUGS AND LIMITATIONS

None known at this time.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tkx::SplashScreen

=head1 AUTHOR

Alexander Nusov <alexander.nusov+cpan <at> gmail.com>

=head1 COPYRIGHTS AND LICENSE

Copyright (C) 2009-2010 Alexander Nusov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
