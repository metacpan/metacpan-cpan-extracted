#############################################################################
## Name:        lib/Wx/ActiveX/ScriptControl.pm
## Purpose:     Alternative control for MSScriptControl
## Author:      Mark Dootson.
## Created:     2008-04-04
## SVN-ID:      $Id: ScriptControl.pm 2846 2010-03-16 09:15:49Z mdootson $
## Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

#----------------------------------------------------------------------
 package Wx::ActiveX::ScriptControl;
#----------------------------------------------------------------------

use strict;
use Wx qw( :misc );
use Wx::ActiveX;
use base qw( Wx::ActiveX );

our $VERSION = '0.15';

our (@EXPORT_OK, %EXPORT_TAGS);
$EXPORT_TAGS{everything} = \@EXPORT_OK;

my $PROGID = 'MSScriptControl.ScriptControl';


# Local Event IDs

my $wxEVENTID_AX_SCRIPTCONTROL_ERROR = Wx::NewEventType;
my $wxEVENTID_AX_SCRIPTCONTROL_TIMEOUT = Wx::NewEventType;

# Event ID Sub Functions

sub EVENTID_AX_SCRIPTCONTROL_ERROR () { $wxEVENTID_AX_SCRIPTCONTROL_ERROR }
sub EVENTID_AX_SCRIPTCONTROL_TIMEOUT () { $wxEVENTID_AX_SCRIPTCONTROL_TIMEOUT }

# Event Sub Functions

sub EVT_ACTIVEX_SCRIPTCONTROL_ERROR { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"Error",$_[2]) ;}
sub EVT_ACTIVEX_SCRIPTCONTROL_TIMEOUT { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"Timeout",$_[2]) ;}

# Exports & Tags

{
    my @eventexports = qw(
            EVENTID_AX_SCRIPTCONTROL_ERROR
            EVENTID_AX_SCRIPTCONTROL_TIMEOUT
            EVT_ACTIVEX_SCRIPTCONTROL_ERROR
            EVT_ACTIVEX_SCRIPTCONTROL_TIMEOUT
    );

    $EXPORT_TAGS{"scriptcontrol"} = [] if not exists $EXPORT_TAGS{"scriptcontrol"};
    push @EXPORT_OK, ( @eventexports ) ;
    push @{ $EXPORT_TAGS{"scriptcontrol"} }, ( @eventexports );
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

Wx::ActiveX::ScriptControl - interface to MSScriptControl.ScriptControl ActiveX Control

=head1 SYNOPSIS

    use Wx::ActiveX::ScriptControl qw( :everything );
    
    ..........
    
    my $activex = Wx::ActiveX::ScriptControl->new( $parent );
    
    OR
    
    my $activex = Wx::ActiveX::ScriptControl->newVersion( 1, $parent );
    
    EVT_ACTIVEX_SCRIPTCONTROL_ERROR( $handler, $activex, \&on_event_error );

=head1 DESCRIPTION

Interface to MSScriptControl.ScriptControl ActiveX Control

=head1 METHODS

=head2 new

    my $activex = Wx::ActiveX::ScriptControl->new(
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of Wx::ActiveX::ScriptControl. Only $parent is mandatory.
$parent must be derived from Wx::Window (e.g. Wx::Frame, Wx::Panel etc).
This constructor creates an instance using the latest version available
of MSScriptControl.ScriptControl.

=head2 newVersion

    my $activex = Wx::ActiveX::ScriptControl->newVersion(
                        $version
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of Wx::ActiveX::ScriptControl. $version and $parent are
mandatory. $parent must be derived from Wx::Window (e.g. Wx::Frame,
Wx::Panel etc). This constructor creates an instance using the specific
type library specified in $version of MSScriptControl.ScriptControl.

e.g. $version = 4;

will produce an instance based on the type library for

MSScriptControl.ScriptControl.4

=head1 EVENTS

The module provides the following exportable event subs

    EVT_ACTIVEX_SCRIPTCONTROL_ERROR( $evthandler, $activexcontrol, \&on_event_scriptcontrol_sub );
    EVT_ACTIVEX_SCRIPTCONTROL_TIMEOUT( $evthandler, $activexcontrol, \&on_event_scriptcontrol_sub );


=head1 ACTIVEX INFO

=head2 Events

    Error
    Timeout

=head2 Methods

    _AboutBox()
    AddCode(Code)
    AddObject(Name , Object , AddMembers)
    AddRef()
    Eval(Expression)
    ExecuteStatement(Statement)
    GetIDsOfNames(riid , rgszNames , cNames , lcid , rgdispid)
    GetTypeInfo(itinfo , lcid , pptinfo)
    GetTypeInfoCount(pctinfo)
    Invoke(dispidMember , riid , lcid , wFlags , pdispparams , pvarResult , pexcepinfo , puArgErr)
    QueryInterface(riid , ppvObj)
    Release()
    Reset()
    Run(ProcedureName , Parameters)

=head2 Properties

    AllowUI
    CodeObject
    Error
    Language
    Modules
    Procedures
    SitehWnd
    State
    Timeout
    UseSafeSubset

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008  Mark Dootson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# end file
#
