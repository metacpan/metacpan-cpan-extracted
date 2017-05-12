#######################################################################
## Name:        Wx/ActiveX/QuickTime.pm
## Purpose:     ActiveX Interface for QTOControl.QTControl
## Author:      Mark Dootson
## Created:     108-04-12
## SVN-ID:      $Id: QuickTime.pm 2846 2010-03-16 09:15:49Z mdootson $
## Copyright:   (c) 108  Mark Dootson
## Licence:     This program is free software; you can redistribute it
##              and/or modify it under the same terms as Perl itself
#######################################################################

#----------------------------------------------------------------------
 package Wx::ActiveX::QuickTime;
#----------------------------------------------------------------------

use strict;
use Wx qw( :misc );
use Wx::ActiveX;
use base qw( Wx::ActiveX );

our $VERSION = '0.15';

our (@EXPORT_OK, %EXPORT_TAGS);
$EXPORT_TAGS{everything} = \@EXPORT_OK;

my $PROGID = 'QTOControl.QTControl';


# Local Event IDs

my $wxEVENTID_AX_QUICKTIME_MOUSEMOVE = Wx::NewEventType;
my $wxEVENTID_AX_QUICKTIME_MOUSEUP = Wx::NewEventType;
my $wxEVENTID_AX_QUICKTIME_STATUSUPDATE = Wx::NewEventType;
my $wxEVENTID_AX_QUICKTIME_ERROR = Wx::NewEventType;
my $wxEVENTID_AX_QUICKTIME_MOUSEDOWN = Wx::NewEventType;
my $wxEVENTID_AX_QUICKTIME_SIZECHANGED = Wx::NewEventType;
my $wxEVENTID_AX_QUICKTIME_QTEVENT = Wx::NewEventType;

# Event ID Sub Functions

sub EVENTID_AX_QUICKTIME_MOUSEMOVE () { $wxEVENTID_AX_QUICKTIME_MOUSEMOVE }
sub EVENTID_AX_QUICKTIME_MOUSEUP () { $wxEVENTID_AX_QUICKTIME_MOUSEUP }
sub EVENTID_AX_QUICKTIME_STATUSUPDATE () { $wxEVENTID_AX_QUICKTIME_STATUSUPDATE }
sub EVENTID_AX_QUICKTIME_ERROR () { $wxEVENTID_AX_QUICKTIME_ERROR }
sub EVENTID_AX_QUICKTIME_MOUSEDOWN () { $wxEVENTID_AX_QUICKTIME_MOUSEDOWN }
sub EVENTID_AX_QUICKTIME_SIZECHANGED () { $wxEVENTID_AX_QUICKTIME_SIZECHANGED }
sub EVENTID_AX_QUICKTIME_QTEVENT () { $wxEVENTID_AX_QUICKTIME_QTEVENT }

# Event Sub Functions

sub EVT_ACTIVEX_QUICKTIME_MOUSEMOVE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MouseMove",$_[2]) ;}
sub EVT_ACTIVEX_QUICKTIME_MOUSEUP { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MouseUp",$_[2]) ;}
sub EVT_ACTIVEX_QUICKTIME_STATUSUPDATE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"StatusUpdate",$_[2]) ;}
sub EVT_ACTIVEX_QUICKTIME_ERROR { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"Error",$_[2]) ;}
sub EVT_ACTIVEX_QUICKTIME_MOUSEDOWN { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MouseDown",$_[2]) ;}
sub EVT_ACTIVEX_QUICKTIME_SIZECHANGED { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"SizeChanged",$_[2]) ;}
sub EVT_ACTIVEX_QUICKTIME_QTEVENT { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"QTEvent",$_[2]) ;}

# Exports & Tags

{
    my @eventexports = qw(
            EVENTID_AX_QUICKTIME_MOUSEMOVE
            EVENTID_AX_QUICKTIME_MOUSEUP
            EVENTID_AX_QUICKTIME_STATUSUPDATE
            EVENTID_AX_QUICKTIME_ERROR
            EVENTID_AX_QUICKTIME_MOUSEDOWN
            EVENTID_AX_QUICKTIME_SIZECHANGED
            EVENTID_AX_QUICKTIME_QTEVENT
            EVT_ACTIVEX_QUICKTIME_MOUSEMOVE
            EVT_ACTIVEX_QUICKTIME_MOUSEUP
            EVT_ACTIVEX_QUICKTIME_STATUSUPDATE
            EVT_ACTIVEX_QUICKTIME_ERROR
            EVT_ACTIVEX_QUICKTIME_MOUSEDOWN
            EVT_ACTIVEX_QUICKTIME_SIZECHANGED
            EVT_ACTIVEX_QUICKTIME_QTEVENT
    );

    $EXPORT_TAGS{"quicktime"} = [] if not exists $EXPORT_TAGS{"quicktime"};
    push @EXPORT_OK, ( @eventexports ) ;
    push @{ $EXPORT_TAGS{"quicktime"} }, ( @eventexports );
}


sub new {
    my $class = shift;
    # parent must exist
    my $parent = shift;
    my $windowid = shift || -1;
    my $pos = shift || wxDefaultPosition;
    my $size = shift || wxDefaultSize;
    my $self = $class->SUPER::new( $parent, $PROGID, $windowid, $pos, $size, @_ );
    return $self;
}

sub newVersion {
    my $class = shift;
    # version must exist
    my $version = shift;
    # parent must exist
    my $parent = shift;
    my $windowid = shift || -1;
    my $pos = shift || wxDefaultPosition;
    my $size = shift || wxDefaultSize;
    my $self = $class->SUPER::new( $parent, $PROGID . '.' . $version, $windowid, $pos, $size, @_ );
    return $self;
}


1;


__END__

=head1 NAME

Wx::ActiveX::QuickTime - interface to QTOControl.QTControl ActiveX Control

=head1 SYNOPSIS

    use Wx::ActiveX::QuickTime qw( :everything );
    
    ..........
    
    my $activex = Wx::ActiveX::QuickTime->new( $parent );
    
    OR
    
    my $activex = Wx::ActiveX::QuickTime->newVersion( 1, $parent );
    
    EVT_ACTIVEX_QUICKTIME_QTEVENT( $handler, $activex, \&on_event_qtevent );

=head1 DESCRIPTION

Interface to QTOControl.QTControl ActiveX Control

=head1 METHODS

=head2 new

    my $activex = Wx::ActiveX::QuickTime->new(
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of Wx::ActiveX::QuickTime. Only $parent is mandatory.
$parent must be derived from Wx::Window (e.g. Wx::Frame, Wx::Panel etc).
This constructor creates an instance using the latest version available
of QTOControl.QTControl.

=head2 newVersion

    my $activex = Wx::ActiveX::QuickTime->newVersion(
                        $version
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of Wx::ActiveX::QuickTime. $version and $parent are
mandatory. $parent must be derived from Wx::Window (e.g. Wx::Frame,
Wx::Panel etc). This constructor creates an instance using the specific
type library specified in $version of QTOControl.QTControl.

e.g. $version = 4;

will produce an instance based on the type library for

QTOControl.QTControl.4

=head1 EVENTS

The module provides the following exportable event subs

    EVT_ACTIVEX_QUICKTIME_QTEVENT( $evthandler, $activexcontrol, \&on_event_quicktime_sub );
    EVT_ACTIVEX_QUICKTIME_SIZECHANGED( $evthandler, $activexcontrol, \&on_event_quicktime_sub );
    EVT_ACTIVEX_QUICKTIME_ERROR( $evthandler, $activexcontrol, \&on_event_quicktime_sub );
    EVT_ACTIVEX_QUICKTIME_STATUSUPDATE( $evthandler, $activexcontrol, \&on_event_quicktime_sub );
    EVT_ACTIVEX_QUICKTIME_MOUSEDOWN( $evthandler, $activexcontrol, \&on_event_quicktime_sub );
    EVT_ACTIVEX_QUICKTIME_MOUSEUP( $evthandler, $activexcontrol, \&on_event_quicktime_sub );
    EVT_ACTIVEX_QUICKTIME_MOUSEMOVE( $evthandler, $activexcontrol, \&on_event_quicktime_sub );


=head1 ACTIVEX INFO

=head2 Events

    QTEvent
    SizeChanged
    Error
    StatusUpdate
    MouseDown
    MouseUp
    MouseMove

=head2 Methods

    _get_DataRef(pDataRef , pDataRefType)
    _put_DataRef(inDataRef , inDataRefType , inNewMovieFlags)
    AddRef()
    CreateNewMovie(movieIsActive)
    CreateNewMovieFromImages(bstrFirstFilePath , rate , rateIsFramesPerSecond)
    GetIDsOfNames(riid , rgszNames , cNames , lcid , rgdispid)
    GetTypeInfo(itinfo , lcid , pptinfo)
    GetTypeInfoCount(pctinfo)
    Invoke(dispidMember , riid , lcid , wFlags , pdispparams , pvarResult , pexcepinfo , puArgErr)
    MovieResizingLock()
    MovieResizingUnlock()
    QueryInterface(riid , ppvObj)
    QuickTimeInitialize(InitOptions , InitFlags)
    QuickTimeTerminate()
    Release()
    SetScale(x , y)
    SetSizing(sizingOption , forceSizeUpdate)
    ShowAboutBox()

=head2 Properties

    _MovieControllerHandle
    _MovieHandle
    _Property
    AutoPlay
    BackColor
    BaseURL
    BorderColor
    BorderStyle
    ErrorCode
    ErrorHandling
    FileName
    FullScreen
    FullScreenEndKeyCode
    FullScreenFlags
    FullScreenHWND
    FullScreenMonitorNumber
    FullScreenSizing
    hWnd
    IsQuickTimeAvailable
    Movie
    MovieControllerVisible
    NewMovieFlags
    QuickTime
    QuickTimeVersion
    ScaleX
    ScaleY
    Sizing
    URL
    Version

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008  Mark Dootson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# end file


