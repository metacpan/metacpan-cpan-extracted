#############################################################################
## Name:        lib/Wx/ActiveX/WMPlayer.pm
## Purpose:     Wx::ActiveX::WMPlayer (Windows Media Player)
## Author:      Thiago S. V.
## Created:     14/04/2003
## SVN-ID:      $Id: WMPlayer.pm 2846 2010-03-16 09:15:49Z mdootson $
## Copyright:   (c) 2002 - 2008 Thiago S. V., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

#----------------------------------------------------------------------
 package Wx::ActiveX::WMPlayer;
#----------------------------------------------------------------------

use strict;
use Wx qw( :misc );
use Wx::ActiveX;
use base qw( Wx::ActiveX );

our $VERSION = '0.15';

our (@EXPORT_OK, %EXPORT_TAGS);
$EXPORT_TAGS{everything} = \@EXPORT_OK;

my $PROGID = 'WMPlayer.OCX';


# Local Event IDs

my $wxEVENTID_AX_MEDIAPLAYER_ENDOFSTREAM = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGREMOVED = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_DEVICESTATUSCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_CURRENTPLAYLISTITEMAVAILABLE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_BUFFERING = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGCHANGED = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_SCRIPTCOMMAND = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_PLAYSTATECHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_CURRENTMEDIAITEMAVAILABLE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_AUDIOLANGUAGECHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_DEVICESYNCERROR = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_POSITIONCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MOUSEDOWN = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_DOUBLECLICK = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_OPENSTATECHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_CREATEPARTNERSHIPCOMPLETE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MODECHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGADDED = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_KEYUP = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_DISCONNECT = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MOUSEUP = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_STATUSCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_CLICK = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_DEVICESYNCSTATECHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_PLAYERRECONNECT = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_DURATIONUNITCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_KEYDOWN = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_KEYPRESS = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_OPENPLAYLISTSWITCH = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_DEVICEDISCONNECT = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTSETASDELETED = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTREMOVED = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MEDIAERROR = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_WARNING = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_CURRENTPLAYLISTCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MARKERHIT = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_SWITCHEDTOCONTROL = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_CDROMMEDIACHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_CURRENTITEMCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_DEVICECONNECT = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MOUSEMOVE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_MEDIACHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_ERROR = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTADDED = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_PLAYERDOCKEDSTATECHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_NEWSTREAM = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_DOMAINCHANGE = Wx::NewEventType;
my $wxEVENTID_AX_MEDIAPLAYER_SWITCHEDTOPLAYERAPPLICATION = Wx::NewEventType;

# Event ID Sub Functions

sub EVENTID_AX_MEDIAPLAYER_ENDOFSTREAM () { $wxEVENTID_AX_MEDIAPLAYER_ENDOFSTREAM }
sub EVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGREMOVED () { $wxEVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGREMOVED }
sub EVENTID_AX_MEDIAPLAYER_DEVICESTATUSCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_DEVICESTATUSCHANGE }
sub EVENTID_AX_MEDIAPLAYER_CURRENTPLAYLISTITEMAVAILABLE () { $wxEVENTID_AX_MEDIAPLAYER_CURRENTPLAYLISTITEMAVAILABLE }
sub EVENTID_AX_MEDIAPLAYER_BUFFERING () { $wxEVENTID_AX_MEDIAPLAYER_BUFFERING }
sub EVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGCHANGED () { $wxEVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGCHANGED }
sub EVENTID_AX_MEDIAPLAYER_SCRIPTCOMMAND () { $wxEVENTID_AX_MEDIAPLAYER_SCRIPTCOMMAND }
sub EVENTID_AX_MEDIAPLAYER_PLAYSTATECHANGE () { $wxEVENTID_AX_MEDIAPLAYER_PLAYSTATECHANGE }
sub EVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONCHANGE }
sub EVENTID_AX_MEDIAPLAYER_CURRENTMEDIAITEMAVAILABLE () { $wxEVENTID_AX_MEDIAPLAYER_CURRENTMEDIAITEMAVAILABLE }
sub EVENTID_AX_MEDIAPLAYER_AUDIOLANGUAGECHANGE () { $wxEVENTID_AX_MEDIAPLAYER_AUDIOLANGUAGECHANGE }
sub EVENTID_AX_MEDIAPLAYER_DEVICESYNCERROR () { $wxEVENTID_AX_MEDIAPLAYER_DEVICESYNCERROR }
sub EVENTID_AX_MEDIAPLAYER_POSITIONCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_POSITIONCHANGE }
sub EVENTID_AX_MEDIAPLAYER_MOUSEDOWN () { $wxEVENTID_AX_MEDIAPLAYER_MOUSEDOWN }
sub EVENTID_AX_MEDIAPLAYER_DOUBLECLICK () { $wxEVENTID_AX_MEDIAPLAYER_DOUBLECLICK }
sub EVENTID_AX_MEDIAPLAYER_OPENSTATECHANGE () { $wxEVENTID_AX_MEDIAPLAYER_OPENSTATECHANGE }
sub EVENTID_AX_MEDIAPLAYER_CREATEPARTNERSHIPCOMPLETE () { $wxEVENTID_AX_MEDIAPLAYER_CREATEPARTNERSHIPCOMPLETE }
sub EVENTID_AX_MEDIAPLAYER_MODECHANGE () { $wxEVENTID_AX_MEDIAPLAYER_MODECHANGE }
sub EVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGADDED () { $wxEVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGADDED }
sub EVENTID_AX_MEDIAPLAYER_KEYUP () { $wxEVENTID_AX_MEDIAPLAYER_KEYUP }
sub EVENTID_AX_MEDIAPLAYER_DISCONNECT () { $wxEVENTID_AX_MEDIAPLAYER_DISCONNECT }
sub EVENTID_AX_MEDIAPLAYER_MOUSEUP () { $wxEVENTID_AX_MEDIAPLAYER_MOUSEUP }
sub EVENTID_AX_MEDIAPLAYER_STATUSCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_STATUSCHANGE }
sub EVENTID_AX_MEDIAPLAYER_CLICK () { $wxEVENTID_AX_MEDIAPLAYER_CLICK }
sub EVENTID_AX_MEDIAPLAYER_DEVICESYNCSTATECHANGE () { $wxEVENTID_AX_MEDIAPLAYER_DEVICESYNCSTATECHANGE }
sub EVENTID_AX_MEDIAPLAYER_PLAYERRECONNECT () { $wxEVENTID_AX_MEDIAPLAYER_PLAYERRECONNECT }
sub EVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONCHANGE }
sub EVENTID_AX_MEDIAPLAYER_DURATIONUNITCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_DURATIONUNITCHANGE }
sub EVENTID_AX_MEDIAPLAYER_KEYDOWN () { $wxEVENTID_AX_MEDIAPLAYER_KEYDOWN }
sub EVENTID_AX_MEDIAPLAYER_KEYPRESS () { $wxEVENTID_AX_MEDIAPLAYER_KEYPRESS }
sub EVENTID_AX_MEDIAPLAYER_OPENPLAYLISTSWITCH () { $wxEVENTID_AX_MEDIAPLAYER_OPENPLAYLISTSWITCH }
sub EVENTID_AX_MEDIAPLAYER_DEVICEDISCONNECT () { $wxEVENTID_AX_MEDIAPLAYER_DEVICEDISCONNECT }
sub EVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTSETASDELETED () { $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTSETASDELETED }
sub EVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTREMOVED () { $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTREMOVED }
sub EVENTID_AX_MEDIAPLAYER_MEDIAERROR () { $wxEVENTID_AX_MEDIAPLAYER_MEDIAERROR }
sub EVENTID_AX_MEDIAPLAYER_WARNING () { $wxEVENTID_AX_MEDIAPLAYER_WARNING }
sub EVENTID_AX_MEDIAPLAYER_CURRENTPLAYLISTCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_CURRENTPLAYLISTCHANGE }
sub EVENTID_AX_MEDIAPLAYER_MARKERHIT () { $wxEVENTID_AX_MEDIAPLAYER_MARKERHIT }
sub EVENTID_AX_MEDIAPLAYER_SWITCHEDTOCONTROL () { $wxEVENTID_AX_MEDIAPLAYER_SWITCHEDTOCONTROL }
sub EVENTID_AX_MEDIAPLAYER_CDROMMEDIACHANGE () { $wxEVENTID_AX_MEDIAPLAYER_CDROMMEDIACHANGE }
sub EVENTID_AX_MEDIAPLAYER_CURRENTITEMCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_CURRENTITEMCHANGE }
sub EVENTID_AX_MEDIAPLAYER_DEVICECONNECT () { $wxEVENTID_AX_MEDIAPLAYER_DEVICECONNECT }
sub EVENTID_AX_MEDIAPLAYER_MOUSEMOVE () { $wxEVENTID_AX_MEDIAPLAYER_MOUSEMOVE }
sub EVENTID_AX_MEDIAPLAYER_MEDIACHANGE () { $wxEVENTID_AX_MEDIAPLAYER_MEDIACHANGE }
sub EVENTID_AX_MEDIAPLAYER_ERROR () { $wxEVENTID_AX_MEDIAPLAYER_ERROR }
sub EVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTADDED () { $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTADDED }
sub EVENTID_AX_MEDIAPLAYER_PLAYERDOCKEDSTATECHANGE () { $wxEVENTID_AX_MEDIAPLAYER_PLAYERDOCKEDSTATECHANGE }
sub EVENTID_AX_MEDIAPLAYER_PLAYLISTCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_PLAYLISTCHANGE }
sub EVENTID_AX_MEDIAPLAYER_NEWSTREAM () { $wxEVENTID_AX_MEDIAPLAYER_NEWSTREAM }
sub EVENTID_AX_MEDIAPLAYER_DOMAINCHANGE () { $wxEVENTID_AX_MEDIAPLAYER_DOMAINCHANGE }
sub EVENTID_AX_MEDIAPLAYER_SWITCHEDTOPLAYERAPPLICATION () { $wxEVENTID_AX_MEDIAPLAYER_SWITCHEDTOPLAYERAPPLICATION }

# Event Sub Functions

sub EVT_ACTIVEX_MEDIAPLAYER_ENDOFSTREAM { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"EndOfStream",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGREMOVED { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MediaCollectionAttributeStringRemoved",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_DEVICESTATUSCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"DeviceStatusChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_CURRENTPLAYLISTITEMAVAILABLE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"CurrentPlaylistItemAvailable",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_BUFFERING { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"Buffering",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGCHANGED { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MediaCollectionAttributeStringChanged",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_SCRIPTCOMMAND { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"ScriptCommand",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_PLAYSTATECHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"PlayStateChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MediaCollectionChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_CURRENTMEDIAITEMAVAILABLE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"CurrentMediaItemAvailable",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_AUDIOLANGUAGECHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"AudioLanguageChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_DEVICESYNCERROR { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"DeviceSyncError",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_POSITIONCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"PositionChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MOUSEDOWN { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MouseDown",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_DOUBLECLICK { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"DoubleClick",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_OPENSTATECHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"OpenStateChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_CREATEPARTNERSHIPCOMPLETE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"CreatePartnershipComplete",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MODECHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"ModeChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGADDED { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MediaCollectionAttributeStringAdded",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_KEYUP { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"KeyUp",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_DISCONNECT { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"Disconnect",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MOUSEUP { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MouseUp",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_STATUSCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"StatusChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_CLICK { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"Click",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_DEVICESYNCSTATECHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"DeviceSyncStateChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_PLAYERRECONNECT { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"PlayerReconnect",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"PlaylistCollectionChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_DURATIONUNITCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"DurationUnitChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_KEYDOWN { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"KeyDown",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_KEYPRESS { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"KeyPress",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_OPENPLAYLISTSWITCH { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"OpenPlaylistSwitch",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_DEVICEDISCONNECT { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"DeviceDisconnect",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTSETASDELETED { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"PlaylistCollectionPlaylistSetAsDeleted",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTREMOVED { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"PlaylistCollectionPlaylistRemoved",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MEDIAERROR { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MediaError",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_WARNING { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"Warning",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_CURRENTPLAYLISTCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"CurrentPlaylistChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MARKERHIT { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MarkerHit",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_SWITCHEDTOCONTROL { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"SwitchedToControl",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_CDROMMEDIACHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"CdromMediaChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_CURRENTITEMCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"CurrentItemChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_DEVICECONNECT { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"DeviceConnect",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MOUSEMOVE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MouseMove",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_MEDIACHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"MediaChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_ERROR { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"Error",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTADDED { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"PlaylistCollectionPlaylistAdded",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_PLAYERDOCKEDSTATECHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"PlayerDockedStateChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"PlaylistChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_NEWSTREAM { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"NewStream",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_DOMAINCHANGE { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"DomainChange",$_[2]) ;}
sub EVT_ACTIVEX_MEDIAPLAYER_SWITCHEDTOPLAYERAPPLICATION { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"SwitchedToPlayerApplication",$_[2]) ;}

# Exports & Tags

{
    my @eventexports = qw(
            EVENTID_AX_MEDIAPLAYER_ENDOFSTREAM
            EVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGREMOVED
            EVENTID_AX_MEDIAPLAYER_DEVICESTATUSCHANGE
            EVENTID_AX_MEDIAPLAYER_CURRENTPLAYLISTITEMAVAILABLE
            EVENTID_AX_MEDIAPLAYER_BUFFERING
            EVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGCHANGED
            EVENTID_AX_MEDIAPLAYER_SCRIPTCOMMAND
            EVENTID_AX_MEDIAPLAYER_PLAYSTATECHANGE
            EVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONCHANGE
            EVENTID_AX_MEDIAPLAYER_CURRENTMEDIAITEMAVAILABLE
            EVENTID_AX_MEDIAPLAYER_AUDIOLANGUAGECHANGE
            EVENTID_AX_MEDIAPLAYER_DEVICESYNCERROR
            EVENTID_AX_MEDIAPLAYER_POSITIONCHANGE
            EVENTID_AX_MEDIAPLAYER_MOUSEDOWN
            EVENTID_AX_MEDIAPLAYER_DOUBLECLICK
            EVENTID_AX_MEDIAPLAYER_OPENSTATECHANGE
            EVENTID_AX_MEDIAPLAYER_CREATEPARTNERSHIPCOMPLETE
            EVENTID_AX_MEDIAPLAYER_MODECHANGE
            EVENTID_AX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGADDED
            EVENTID_AX_MEDIAPLAYER_KEYUP
            EVENTID_AX_MEDIAPLAYER_DISCONNECT
            EVENTID_AX_MEDIAPLAYER_MOUSEUP
            EVENTID_AX_MEDIAPLAYER_STATUSCHANGE
            EVENTID_AX_MEDIAPLAYER_CLICK
            EVENTID_AX_MEDIAPLAYER_DEVICESYNCSTATECHANGE
            EVENTID_AX_MEDIAPLAYER_PLAYERRECONNECT
            EVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONCHANGE
            EVENTID_AX_MEDIAPLAYER_DURATIONUNITCHANGE
            EVENTID_AX_MEDIAPLAYER_KEYDOWN
            EVENTID_AX_MEDIAPLAYER_KEYPRESS
            EVENTID_AX_MEDIAPLAYER_OPENPLAYLISTSWITCH
            EVENTID_AX_MEDIAPLAYER_DEVICEDISCONNECT
            EVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTSETASDELETED
            EVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTREMOVED
            EVENTID_AX_MEDIAPLAYER_MEDIAERROR
            EVENTID_AX_MEDIAPLAYER_WARNING
            EVENTID_AX_MEDIAPLAYER_CURRENTPLAYLISTCHANGE
            EVENTID_AX_MEDIAPLAYER_MARKERHIT
            EVENTID_AX_MEDIAPLAYER_SWITCHEDTOCONTROL
            EVENTID_AX_MEDIAPLAYER_CDROMMEDIACHANGE
            EVENTID_AX_MEDIAPLAYER_CURRENTITEMCHANGE
            EVENTID_AX_MEDIAPLAYER_DEVICECONNECT
            EVENTID_AX_MEDIAPLAYER_MOUSEMOVE
            EVENTID_AX_MEDIAPLAYER_MEDIACHANGE
            EVENTID_AX_MEDIAPLAYER_ERROR
            EVENTID_AX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTADDED
            EVENTID_AX_MEDIAPLAYER_PLAYERDOCKEDSTATECHANGE
            EVENTID_AX_MEDIAPLAYER_PLAYLISTCHANGE
            EVENTID_AX_MEDIAPLAYER_NEWSTREAM
            EVENTID_AX_MEDIAPLAYER_DOMAINCHANGE
            EVENTID_AX_MEDIAPLAYER_SWITCHEDTOPLAYERAPPLICATION
            EVT_ACTIVEX_MEDIAPLAYER_ENDOFSTREAM
            EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGREMOVED
            EVT_ACTIVEX_MEDIAPLAYER_DEVICESTATUSCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_CURRENTPLAYLISTITEMAVAILABLE
            EVT_ACTIVEX_MEDIAPLAYER_BUFFERING
            EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGCHANGED
            EVT_ACTIVEX_MEDIAPLAYER_SCRIPTCOMMAND
            EVT_ACTIVEX_MEDIAPLAYER_PLAYSTATECHANGE
            EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_CURRENTMEDIAITEMAVAILABLE
            EVT_ACTIVEX_MEDIAPLAYER_AUDIOLANGUAGECHANGE
            EVT_ACTIVEX_MEDIAPLAYER_DEVICESYNCERROR
            EVT_ACTIVEX_MEDIAPLAYER_POSITIONCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_MOUSEDOWN
            EVT_ACTIVEX_MEDIAPLAYER_DOUBLECLICK
            EVT_ACTIVEX_MEDIAPLAYER_OPENSTATECHANGE
            EVT_ACTIVEX_MEDIAPLAYER_CREATEPARTNERSHIPCOMPLETE
            EVT_ACTIVEX_MEDIAPLAYER_MODECHANGE
            EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGADDED
            EVT_ACTIVEX_MEDIAPLAYER_KEYUP
            EVT_ACTIVEX_MEDIAPLAYER_DISCONNECT
            EVT_ACTIVEX_MEDIAPLAYER_MOUSEUP
            EVT_ACTIVEX_MEDIAPLAYER_STATUSCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_CLICK
            EVT_ACTIVEX_MEDIAPLAYER_DEVICESYNCSTATECHANGE
            EVT_ACTIVEX_MEDIAPLAYER_PLAYERRECONNECT
            EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_DURATIONUNITCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_KEYDOWN
            EVT_ACTIVEX_MEDIAPLAYER_KEYPRESS
            EVT_ACTIVEX_MEDIAPLAYER_OPENPLAYLISTSWITCH
            EVT_ACTIVEX_MEDIAPLAYER_DEVICEDISCONNECT
            EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTSETASDELETED
            EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTREMOVED
            EVT_ACTIVEX_MEDIAPLAYER_MEDIAERROR
            EVT_ACTIVEX_MEDIAPLAYER_WARNING
            EVT_ACTIVEX_MEDIAPLAYER_CURRENTPLAYLISTCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_MARKERHIT
            EVT_ACTIVEX_MEDIAPLAYER_SWITCHEDTOCONTROL
            EVT_ACTIVEX_MEDIAPLAYER_CDROMMEDIACHANGE
            EVT_ACTIVEX_MEDIAPLAYER_CURRENTITEMCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_DEVICECONNECT
            EVT_ACTIVEX_MEDIAPLAYER_MOUSEMOVE
            EVT_ACTIVEX_MEDIAPLAYER_MEDIACHANGE
            EVT_ACTIVEX_MEDIAPLAYER_ERROR
            EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTADDED
            EVT_ACTIVEX_MEDIAPLAYER_PLAYERDOCKEDSTATECHANGE
            EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_NEWSTREAM
            EVT_ACTIVEX_MEDIAPLAYER_DOMAINCHANGE
            EVT_ACTIVEX_MEDIAPLAYER_SWITCHEDTOPLAYERAPPLICATION
    );

    $EXPORT_TAGS{"mediaplayer"} = [] if not exists $EXPORT_TAGS{"mediaplayer"};
    push @EXPORT_OK, ( @eventexports ) ;
    push @{ $EXPORT_TAGS{"mediaplayer"} }, ( @eventexports );
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

Wx::ActiveX::WMPlayer - interface to WMPlayer.OCX ActiveX Control

=head1 SYNOPSIS

    use Wx::ActiveX::WMPlayer qw( :everything );
    
    ..........
    
    my $activex = Wx::ActiveX::WMPlayer->new( $parent );
    
    OR
    
    my $activex = Wx::ActiveX::WMPlayer->newVersion( 1, $parent );
    
    EVT_ACTIVEX_MEDIAPLAYER_OPENSTATECHANGE( $handler, $activex, \&on_event_openstatechange );
    
    use Win32::OLE;
    
    my $filename = 'c:/path/to/mediafile';
    
    $activex->PropSet( 'URL', $filename);
    my $winole = $activex->GetOLE;
    $winole->controls->play; 
    

=head1 DESCRIPTION

Interface to WMPlayer.OCX ActiveX Control

=head1 METHODS

=head2 new

    my $activex = Wx::ActiveX::WMPlayer->new(
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of Wx::ActiveX::WMPlayer. Only $parent is mandatory.
$parent must be derived from Wx::Window (e.g. Wx::Frame, Wx::Panel etc).
This constructor creates an instance using the latest version available
of WMPlayer.OCX.

=head2 newVersion

    my $activex = Wx::ActiveX::WMPlayer->newVersion(
                        $version
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of Wx::ActiveX::WMPlayer. $version and $parent are
mandatory. $parent must be derived from Wx::Window (e.g. Wx::Frame,
Wx::Panel etc). This constructor creates an instance using the specific
type library specified in $version of WMPlayer.OCX.

e.g. $version = 4;

will produce an instance based on the type library for

WMPlayer.OCX.4

=head1 EVENTS

The module provides the following exportable event subs

    EVT_ACTIVEX_MEDIAPLAYER_OPENSTATECHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_STATUSCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_PLAYSTATECHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_AUDIOLANGUAGECHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_ENDOFSTREAM( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_POSITIONCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MARKERHIT( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_DURATIONUNITCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_SCRIPTCOMMAND( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_DISCONNECT( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_BUFFERING( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_NEWSTREAM( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_ERROR( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_WARNING( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_CDROMMEDIACHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MEDIACHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_CURRENTMEDIAITEMAVAILABLE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_CURRENTPLAYLISTCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_CURRENTPLAYLISTITEMAVAILABLE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_CURRENTITEMCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGADDED( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGREMOVED( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTADDED( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTREMOVED( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_PLAYLISTCOLLECTIONPLAYLISTSETASDELETED( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MODECHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MEDIACOLLECTIONATTRIBUTESTRINGCHANGED( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MEDIAERROR( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_DOMAINCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_OPENPLAYLISTSWITCH( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_SWITCHEDTOPLAYERAPPLICATION( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_SWITCHEDTOCONTROL( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_PLAYERDOCKEDSTATECHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_PLAYERRECONNECT( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_CLICK( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_DOUBLECLICK( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_KEYDOWN( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_KEYPRESS( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_KEYUP( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MOUSEDOWN( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MOUSEMOVE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_MOUSEUP( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_DEVICECONNECT( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_DEVICEDISCONNECT( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_DEVICESTATUSCHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_DEVICESYNCSTATECHANGE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_DEVICESYNCERROR( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );
    EVT_ACTIVEX_MEDIAPLAYER_CREATEPARTNERSHIPCOMPLETE( $evthandler, $activexcontrol, \&on_event_mediaplayer_sub );


=head1 ACTIVEX INFO

=head2 Events

    OpenStateChange
    StatusChange
    PlayStateChange
    AudioLanguageChange
    EndOfStream
    PositionChange
    MarkerHit
    DurationUnitChange
    ScriptCommand
    Disconnect
    Buffering
    NewStream
    Error
    Warning
    CdromMediaChange
    PlaylistChange
    MediaChange
    CurrentMediaItemAvailable
    CurrentPlaylistChange
    CurrentPlaylistItemAvailable
    CurrentItemChange
    MediaCollectionChange
    MediaCollectionAttributeStringAdded
    MediaCollectionAttributeStringRemoved
    PlaylistCollectionChange
    PlaylistCollectionPlaylistAdded
    PlaylistCollectionPlaylistRemoved
    PlaylistCollectionPlaylistSetAsDeleted
    ModeChange
    MediaCollectionAttributeStringChanged
    MediaError
    DomainChange
    OpenPlaylistSwitch
    SwitchedToPlayerApplication
    SwitchedToControl
    PlayerDockedStateChange
    PlayerReconnect
    Click
    DoubleClick
    KeyDown
    KeyPress
    KeyUp
    MouseDown
    MouseMove
    MouseUp
    DeviceConnect
    DeviceDisconnect
    DeviceStatusChange
    DeviceSyncStateChange
    DeviceSyncError
    CreatePartnershipComplete

=head2 Methods

    AddRef()
    close()
    GetIDsOfNames(riid , rgszNames , cNames , lcid , rgdispid)
    GetTypeInfo(itinfo , lcid , pptinfo)
    GetTypeInfoCount(pctinfo)
    Invoke(dispidMember , riid , lcid , wFlags , pdispparams , pvarResult , pexcepinfo , puArgErr)
    launchURL(bstrURL)
    newMedia(bstrURL)
    newPlaylist(bstrName , bstrURL)
    openPlayer(bstrURL)
    QueryInterface(riid , ppvObj)
    Release()

=head2 Properties

    cdromCollection
    closedCaption
    controls
    currentMedia
    currentPlaylist
    dvd
    enableContextMenu
    enabled
    Error
    fullScreen
    isOnline
    isRemote
    mediaCollection
    network
    openState
    playerApplication
    playlistCollection
    playState
    settings
    status
    stretchToFit
    uiMode
    URL
    versionInfo
    windowlessVideo

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008  Mark Dootson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# end file


#
