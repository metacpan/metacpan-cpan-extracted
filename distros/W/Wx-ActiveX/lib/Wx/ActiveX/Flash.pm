#############################################################################
## Name:        lib/Wx/ActiveX/Flash.pm
## Purpose:     Wx::ActiveX::Flash (Shockwave Flash)
## Author:      Graciliano M. P.
## Created:     14/04/2003
## SVN-ID:      $Id: Flash.pm 2846 2010-03-16 09:15:49Z mdootson $
## Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

#----------------------------------------------------------------------
 package Wx::ActiveX::Flash;
#----------------------------------------------------------------------

use strict;
use Wx qw( :misc );
use Wx::ActiveX;
use base qw( Wx::ActiveX );

our $VERSION = '0.15';

our (@EXPORT_OK, %EXPORT_TAGS);
$EXPORT_TAGS{everything} = \@EXPORT_OK;

my $PROGID = 'ShockwaveFlash.ShockwaveFlash';


# Local Event IDs

my $wxEVENTID_AX_FLASH_ONREADYSTATECHANGE = Wx::NewEventType;
my $wxEVENTID_AX_FLASH_FLASHCALL = Wx::NewEventType;
my $wxEVENTID_AX_FLASH_ONPROGRESS = Wx::NewEventType;
my $wxEVENTID_AX_FLASH_FSCOMMAND = Wx::NewEventType;

# Event ID Sub Functions

sub EVENTID_AX_FLASH_ONREADYSTATECHANGE () { $wxEVENTID_AX_FLASH_ONREADYSTATECHANGE }
sub EVENTID_AX_FLASH_FLASHCALL () { $wxEVENTID_AX_FLASH_FLASHCALL }
sub EVENTID_AX_FLASH_ONPROGRESS () { $wxEVENTID_AX_FLASH_ONPROGRESS }
sub EVENTID_AX_FLASH_FSCOMMAND () { $wxEVENTID_AX_FLASH_FSCOMMAND }

# Event Sub Functions

sub EVT_ACTIVEX_FLASH_ONREADYSTATECHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"OnReadyStateChange",$_[2]) ;}
sub EVT_ACTIVEX_FLASH_FLASHCALL { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"FlashCall",$_[2]) ;}
sub EVT_ACTIVEX_FLASH_ONPROGRESS { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"OnProgress",$_[2]) ;}
sub EVT_ACTIVEX_FLASH_FSCOMMAND { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"FSCommand",$_[2]) ;}

# Exports & Tags

{
    my @eventexports = qw(
            EVENTID_AX_FLASH_ONREADYSTATECHANGE
            EVENTID_AX_FLASH_FLASHCALL
            EVENTID_AX_FLASH_ONPROGRESS
            EVENTID_AX_FLASH_FSCOMMAND
            EVT_ACTIVEX_FLASH_ONREADYSTATECHANGE
            EVT_ACTIVEX_FLASH_FLASHCALL
            EVT_ACTIVEX_FLASH_ONPROGRESS
            EVT_ACTIVEX_FLASH_FSCOMMAND
    );

    $EXPORT_TAGS{"flash"} = [] if not exists $EXPORT_TAGS{"flash"};
    push @EXPORT_OK, ( @eventexports ) ;
    push @{ $EXPORT_TAGS{"flash"} }, ( @eventexports );
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

Wx::ActiveX::Flash - interface to ShockwaveFlash.ShockwaveFlash ActiveX Control

=head1 SYNOPSIS

    use Wx::ActiveX::Flash qw( :everything );
    
    ..........
    
    my $activex = Wx::ActiveX::Flash->new( $parent );
    
    OR
    
    my $activex = Wx::ActiveX::Flash->newVersion( 1, $parent );
    
    EVT_ACTIVEX_FLASH_ONREADYSTATECHANGE( $handler, $activex, \&on_event_onreadystatechange );

=head1 DESCRIPTION

Interface to ShockwaveFlash.ShockwaveFlash ActiveX Control

=head1 METHODS

=head2 new

    my $activex = Wx::ActiveX::Flash->new(
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of Wx::ActiveX::Flash. Only $parent is mandatory.
$parent must be derived from Wx::Window (e.g. Wx::Frame, Wx::Panel etc).
This constructor creates an instance using the latest version available
of ShockwaveFlash.ShockwaveFlash.

=head2 newVersion

    my $activex = Wx::ActiveX::Flash->newVersion(
                        $version
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of Wx::ActiveX::Flash. $version and $parent are
mandatory. $parent must be derived from Wx::Window (e.g. Wx::Frame,
Wx::Panel etc). This constructor creates an instance using the specific
type library specified in $version of ShockwaveFlash.ShockwaveFlash.

e.g. $version = 4;

will produce an instance based on the type library for

ShockwaveFlash.ShockwaveFlash.4

=head1 EVENTS

The module provides the following exportable event subs

    EVT_ACTIVEX_FLASH_ONREADYSTATECHANGE( $evthandler, $activexcontrol, \&on_event_flash_sub );
    EVT_ACTIVEX_FLASH_FSCOMMAND( $evthandler, $activexcontrol, \&on_event_flash_sub );
    EVT_ACTIVEX_FLASH_FLASHCALL( $evthandler, $activexcontrol, \&on_event_flash_sub );
    EVT_ACTIVEX_FLASH_ONPROGRESS( $evthandler, $activexcontrol, \&on_event_flash_sub );


=head1 ACTIVEX INFO

=head2 Events

    OnReadyStateChange
    FSCommand
    FlashCall
    OnProgress

=head2 Methods

    AddRef()
    Back()
    CallFunction(request)
    CurrentFrame()
    DisableLocalSecurity()
    EnforceLocalSecurity()
    FlashVersion()
    Forward()
    FrameLoaded(FrameNum)
    GetIDsOfNames(riid , rgszNames , cNames , lcid , rgdispid)
    GetTypeInfo(itinfo , lcid , pptinfo)
    GetTypeInfoCount(pctinfo)
    GetVariable(name)
    GotoFrame(FrameNum)
    Invoke(dispidMember , riid , lcid , wFlags , pdispparams , pvarResult , pexcepinfo , puArgErr)
    IsPlaying()
    LoadMovie(layer , url)
    Pan(x , y , mode)
    PercentLoaded()
    Play()
    QueryInterface(riid , ppvObj)
    Release()
    Rewind()
    SetReturnValue(returnValue)
    SetVariable(name , value)
    SetZoomRect(left , top , right , bottom)
    Stop()
    StopPlay()
    TCallFrame(target , FrameNum)
    TCallLabel(target , label)
    TCurrentFrame(target)
    TCurrentLabel(target)
    TGetProperty(target , property)
    TGetPropertyAsNumber(target , property)
    TGetPropertyNum(target , property)
    TGotoFrame(target , FrameNum)
    TGotoLabel(target , label)
    TPlay(target)
    TSetProperty(target , property , value)
    TSetPropertyNum(target , property , value)
    TStopPlay(target)
    Zoom(factor)

=head2 Properties

    AlignMode
    AllowFullScreen
    AllowNetworking
    AllowScriptAccess
    BackgroundColor
    Base
    BGColor
    DeviceFont
    EmbedMovie
    FlashVars
    FrameNum
    InlineData
    Loop
    Menu
    Movie
    MovieData
    Playing
    Profile
    ProfileAddress
    ProfilePort
    Quality
    Quality2
    ReadyState
    SAlign
    Scale
    ScaleMode
    SeamlessTabbing
    SWRemote
    TotalFrames
    WMode

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

Thanks to wxWindows peoples and Mattia Barbon for wxPerl! :P

Thanks to Justin Bradford <justin@maxwell.ucsf.edu> and Lindsay Mathieson <lmathieson@optusnet.com.au>, that wrote the original C++ classes for wxActiveX and wxIEHtmlWin.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


# Local variables: #
# mode: cperl #
# End: #
