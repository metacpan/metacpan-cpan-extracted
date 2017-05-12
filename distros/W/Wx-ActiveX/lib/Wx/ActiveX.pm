#############################################################################
## Name:        lib/Wx/ActiveX.pm
## Purpose:     Wx::ActiveX
## Author:      Graciliano M. P.
## Created:     25/08/2002
## SVN-ID:      $Id: ActiveX.pm 3130 2011-11-22 01:34:58Z mdootson $
## Copyright:   (c) 2002 - 2010 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

#----------------------------------------------------------------------------
 package Wx::ActiveX;
#----------------------------------------------------------------------------

# init
use strict;
use Wx;
use vars qw( $AUTOLOAD );
require Exporter;
our @ISA = qw( Wx::Window Exporter );
use XSLoader;

our $VERSION = '0.16'; # Wx::ActiveX Version

our $__wxax_debug;
our @EXPORT_OK = qw ( wxACTIVEX_CLSID_MOZILLA_BROWSER wxACTIVEX_CLSID_WEB_BROWSER );
our %EXPORT_TAGS = ( everything => \@EXPORT_OK  );
our %__wxax_dynamic_loadevent_data = ();

#Wx::wx_boot( 'Wx::ActiveX', $VERSION ) ;
XSLoader::load 'Wx::ActiveX', $VERSION;


# Base ActiveX Event
push @EXPORT_OK, ( 'EVENTID_ACTIVEX' );
push @{ $EXPORT_TAGS{'activex'} }, ( 'EVENTID_ACTIVEX' );
push @EXPORT_OK, ('EVT_ACTIVEX');
push @{ $EXPORT_TAGS{'activex'} }, ( 'EVT_ACTIVEX' );

sub EVENTID_ACTIVEX () { -1 }
sub EVT_ACTIVEX ($$$$) { $_[0]->Connect( $_[1], -1, &Wx::ActiveXEvent::RegisterActiveXEvent( $_[2] ), Wx::ActiveXEvent::ActiveXEventSub( $_[3] ) ) };

# Autoload
sub AUTOLOAD {
    my ($method) = ( $AUTOLOAD =~ /:(\w+)$/gs ) ;
    if ($method =~ /^DESTROY$/) { return ;}
    my $activex = shift;
    return( $activex->Invoke($method,@_) ) ;
}

# ActiveX Helper Methods

sub PropSet {
    my ( $activex , $name , $val ) = @_ ;
    
    my $pt = $activex->PropType($name) ;
    
    if ($pt eq 'bool') {
        $activex->PropSetBool($name , $val) ;
    }
    elsif ($pt eq 'long'||$pt eq 'int') {
        $activex->PropSetInt($name , $val) ;
    }
    else {
        $activex->PropSetString($name , $val) ;
    }
}

sub ListEvents {
    my $this = shift ;
    my @events ;
    
    for my $i (0..($this->GetEventCount-1)) {
        my $evt_name = $this->GetEventName($i) ;
        push(@events , $evt_name) if $evt_name ne '' ;
    }
    
    return( @events ) ;
}

sub ListProps {
    my $this = shift ;
    my @props ;
    
    for my $i (0..($this->GetPropCount-1)) {
        my $name = $this->GetPropName($i) ;
        push(@props , $name) if $name ne '' ;
    }
    
    return( @props ) ;
}

sub ListMethods {
    my $this = shift ;
    my @methods ;
    
    for my $i (0..($this->GetMethodCount-1)) {
        my $method = $this->GetMethodName($i) ;
        push(@methods , $method) if $method ne '' ;
    }
    
    return( @methods ) ;
}

sub ListMethods_and_Args {
    my $this = shift ;
    my @methods ;
    
    for my $i (0..($this->GetMethodCount-1)) {
        my $method = $this->GetMethodName($i) ;
        
        my @args ;
        for my $j (0..($this->GetMethodArgCount($i)-1)) {
            my $arg = $this->GetMethodArgName($i,$j) ;
            push(@args , $arg) if $arg ne '' ;
        }
        
        push(@methods , "$method(". join(" , ", @args) .")") if $method ne '' ;
    }
    
    return( @methods ) ;
}

sub ListMethods_and_Args_Hash {
    my $this = shift ;
    my @methods ;
    
    for my $i (0..($this->GetMethodCount-1)) {
        my $method = $this->GetMethodName($i) ;
        
        my @args ;
        for my $j (0..($this->GetMethodArgCount($i)-1)) {
            my $arg = $this->GetMethodArgName($i,$j) ;
            push(@args , $arg) if $arg ne '' ;
        }
        push(@methods , $method , [$method]) if $method ne '' ;
    }

    return( @methods ) ;
}


sub ActivexInfos {
    my $this = shift ;
    my @evts = $this->ListEvents ;
    my @props = $this->ListProps ;
    my @methods = $this->ListMethods_and_Args ;
    
    my $ret ;
    
    $ret .= "<EVENTS>\n" ;
    foreach my $i ( @evts ) { $ret .= "  $i\n" ;}
    $ret .= "</EVENTS>\n" ;
    
    $ret .= "\n<PROPS>\n" ;
    foreach my $i ( @props ) { $ret .= "  $i\n" ;}
    $ret .= "</PROPS>\n" ;
    
    $ret .= "\n<METHODS>\n" ;
    foreach my $i ( @methods ) { $ret .= "  $i\n" ;}
    $ret .= "</METHODS>\n" ;
    return( $ret ) ;
}

# load activex event functions
sub activex_load_activex_event_types {
    my ($packagename, $namespace, $eventname, $exporttag, $events) = @_;
    
    # convert activex events
    my $passeventlist = {};
    for my $activexname ( @$events ) {
        
        my $key = $eventname . '_' . uc($activexname);
        $passeventlist->{$key} = $activexname;
    }
    
    my @codelines = activex_get_event_code($packagename, $namespace, $eventname, $exporttag, 'activex', 1, $passeventlist, 1, 1 );
    my $code = join("\n", @codelines);
    Wx::LogMessage("Wx::ActiveX ActiveX Event Code:\n %s", $code ) if $Wx::ActiveX::__wxax_debug;
    
    #my $eventfile = 'c:\eventfile.txt';
    #open my $fh, '>>', $eventfile;
    #print $fh $code;
    
    eval $code;
    if( my $errors = $@ ) {
    #    print $fh qq(eval result for $packagename\n\n);
    #    print $fh $errors;
        Wx::LogError("Evaluation of Dynamic Event Code failed:\n %s", $errors);
    #    return undef;
    }
    #close($fh);
    return 1;
}

sub activex_load_standard_event_types {
    my ($packagename, $namespace, $eventname, $exporttag, $events) = @_;
    
    # convert standard events
    my $passeventlist = {};
    for my $shortkey ( keys(%$events) ) {
        
        my $key = $eventname . '_' . $shortkey;
        $passeventlist->{$key} = $events->{$shortkey};
    }
    
    my @codelines = activex_get_event_code($packagename, $namespace, $eventname, $exporttag, 'standard', 1, $passeventlist, 1, 1 );
    my $code = join("\n", @codelines);
    Wx::LogMessage("Wx::ActiveX Standard Event Code:\n %s", $code ) if $Wx::ActiveX::__wxax_debug;
    eval "$code";
    if( my $errors = $@ ) {
        Wx::LogError("Evaluation of Dynamic Event Code failed:\n %s", $errors);
        return undef;
    }
    return 1;
}

#---------------------------------
# activex_get_class_code
#---------------------------------

sub activex_get_class_code {
    my $callingclass = shift;
    
    my $axinfo = $__wxax_dynamic_loadevent_data{$callingclass}->{activex};
    my $stinfo = $__wxax_dynamic_loadevent_data{$callingclass}->{standard};
    
    my @standard = activex_get_event_code($callingclass,
                                        $stinfo->{namespace},
                                        $stinfo->{eventname},
                                        $stinfo->{exporttag},
                                        'standard',
                                        1,
                                        $stinfo->{events},
                                        0,
                                        1);
    
    my @activex = activex_get_event_code($callingclass,
                                        $axinfo->{namespace},
                                        $axinfo->{eventname},
                                        $axinfo->{exporttag},
                                        'activex',
                                        1,
                                        $axinfo->{events},
                                        0,
                                        1);
    my $code = join("\n", ( @activex, @standard ) );
    return $code;
}

#---------------------------------
# activex_get_event_code
#---------------------------------

sub activex_get_event_code {
    my ( $packagename, $namespace, $eventname, $exporttag, $eventtype, $commentcode, $events, $store, $foreval ) = @_;
    
    if ($store) {
        my %eventcopy = %$events;
        # store the data
        $__wxax_dynamic_loadevent_data{$packagename}->{$eventtype} = {
            namespace => $namespace,
            eventname => $eventname,
            exporttag => $exporttag,
            events => \%eventcopy,
        };
    }
    
    # code lines
    my @cl_id;          # create event id scalar
    my @cl_idsub;       # make export sub for event id scalar
    my @cl_idsub_ex;    # store the sub name for export
    my @cl_evsub;       # create an event subroutine
    my @cl_evsub_ex;    # store the event name for export
    
    my $idprefix = $namespace . '::';
    
    foreach my $eventname (keys(%$events)) {
        my $extraparam = $events->{$eventname}; # numargs or activex event name
        my $eventid = Wx::NewEventType;
        
        # basenames
        my $codeline;
        my $evt_id = '$wxEVENTID_AX_' . $eventname;
        my $evt_idsub_ex = 'EVENTID_AX_' . $eventname;
        my $evt_evsub_ex = 'EVT_ACTIVEX_' . $eventname;
        
        push @cl_idsub_ex, $evt_idsub_ex;
        push @cl_evsub_ex, $evt_evsub_ex;        
        
        # event id
        $codeline = 'my '. $evt_id . ' = Wx::NewEventType;';
        push @cl_id, $codeline;
        
        # event id sub
        $codeline = 'sub ' . $evt_idsub_ex . ' () { ' . $evt_id . ' }';
        push @cl_idsub, $codeline;
        
        # evt sub
        my $subcode;
        if ( $eventtype ne 'activex' ) {
            if ( $extraparam == 2 ) {
                $subcode = ' ($$) { $_[0]->Connect( -1, -1, &' . $idprefix . $evt_idsub_ex . ', $_[1] ) };';
            } elsif( $extraparam == 3 ) {
                $subcode = ' ($$$) { $_[0]->Connect( $_[1], -1, &' . $idprefix . $evt_idsub_ex . ', $_[2] ) };';
            } else {
                $subcode = ' ($$$$) { $_[0]->Connect( $_[1], $_[2], &' . $idprefix . $evt_idsub_ex . ', $_[3] ) };';
            } # 5 params would be EVT_COMMAND_RANGE
        } else {
            # activex
            $subcode = ' { &Wx::ActiveX::EVT_ACTIVEX($_[0],$_[1],"' . $extraparam . '",$_[2]) ;}';
        }
        $codeline = 'sub ' . $evt_evsub_ex . $subcode;
                
        push @cl_evsub, $codeline;
        Wx::LogMessage("Wx::ActiveX Creating Event: %s", $evt_evsub_ex ) if $Wx::ActiveX::__wxax_debug;
    }
    
    # combine
    my @output = ();
    
    push (@output, q() ) if $commentcode;
    push (@output, q(#-----------------------------------------------------) ) if $commentcode && $foreval;
    push (@output, q(package ) . $namespace . ';' ) if $foreval;
    push (@output, q(#-----------------------------------------------------) ) if $commentcode && $foreval;
    
    push (@output, q() ) if $commentcode;
    push (@output, q(our ( @EXPORT_OK, %EXPORT_TAGS );) ) if $foreval;
    push (@output, q() ) if $commentcode;
    push (@output, q(# Local Event IDs) ) if $commentcode;
    push (@output, q() ) if $commentcode;
          
    push (@output, @cl_id);
    
    push (@output, q() ) if $commentcode;
    push (@output, q(# Event ID Sub Functions) ) if $commentcode;
    push (@output, q() ) if $commentcode;
          
    push (@output, @cl_idsub);
    
    push (@output, q() ) if $commentcode;
    push (@output, q(# Event Sub Functions) ) if $commentcode;
    push (@output, q() ) if $commentcode;
    
    push (@output, @cl_evsub);
    push (@output, q() ) if $commentcode;
    push (@output, q(# Exports & Tags) ) if $commentcode;
    push (@output, q() ) if $commentcode;
          
    my $tabprefix = $commentcode ? qq(\t\t\t) : '';
    push (@output, '{' );
    push (@output, "\t" . 'my @eventexports = qw(' );
    
    for ( @cl_idsub_ex, @cl_evsub_ex ) {
        push ( @output, $tabprefix . $_ );
    }
    
    push (@output, "\t" . ');' );
    
    push (@output, q() ) if $commentcode;
    push (@output, "\t" . '$' . 'EXPORT_TAGS{"' . $exporttag . '"} = [] if not exists $EXPORT_TAGS{"' . $exporttag . '"};'  );
    push (@output, "\t" . 'push @' . 'EXPORT_OK, ( @eventexports ) ;'  );
    push (@output, "\t" . 'push @{ $' . 'EXPORT_TAGS{"' . $exporttag . '"} }, ( @eventexports );'  );
    
    if ($foreval) {
        for ( qw( all activex ) ) {
            my $subst = $_;
            next if $exporttag eq $subst; # don't import twice
            push (@output, "\t" . 'push (@{ $' . 'EXPORT_TAGS{"' . $subst . '"} }, ( @eventexports )) if exists $EXPORT_TAGS{"' . $subst . ' "};');
        }
    }
    
    push (@output, '}' );
    push (@output, q() ) if $commentcode;
    push (@output, q(package Wx::ActiveX; # return to base package) ) if $foreval;
    push (@output, q() ) if $commentcode && $foreval;
    
    return @output;
}

#----------------------------------------------------------------------------
# package Wx::IEHtmlWin;
#----------------------------------------------------------------------------

#our @ISA = qw( Wx::ActiveX );

#our $VERSION = '0.07'; # Wx::ActiveX Version

#----------------------------------------------------------------------------
# package Wx::MozillaHtmlWin;
#----------------------------------------------------------------------------

#our @ISA = qw( Wx::ActiveX );

#our $VERSION = '0.07'; # Wx::ActiveX Version

#----------------------------------------------------------------------------
 package Wx::ActiveXEvent;
#----------------------------------------------------------------------------

use base qw( Wx::CommandEvent Wx::EvtHandler );

our $VERSION = '0.16'; # Wx::ActiveX Version

my (%EVT_HANDLES) ;

no strict ;

sub ParamSet {
    my ( $evt , $idx , $val ) = @_ ;
    
    my $pt = $evt->ParamType($idx) ;
    
    if ($pt eq 'bool') {
        $evt->ParamSetBool($idx , $val) ;
    }
    elsif ($pt eq 'long'||$pt eq 'int') {
        $evt->ParamSetInt($idx , $val) ;
    }
    else {
        $evt->ParamSetString($idx , $val) ;
    }
}

sub ActiveXEventSub {
    my ( $sub ) = @_ ;
    
    return(
        sub {
            my $evt = $_[1] ;
            
            $evt = Wx::ActiveX::XS_convert_isa($evt,"Wx::ActiveXEvent") ;
            
            for(0..($evt->ParamCount)-1) {
                my $pn = $evt->ParamName($_);
                my $pv = $evt->ParamVal($_);
                $evt->{$pn} = $pv ;
                $evt->{ParamID}{$pn} = $_ ;
            }
            
            my @ret = &$sub( $_[0] , $evt ) ;
            
            for(0..($evt->ParamCount)-1) {
                my $pn = $evt->ParamName($_);
                my $pv = $evt->ParamVal($_);
                if ($pv ne $evt->{$pn}) { $evt->ParamSet($_, $evt->{$pn} ) ;}
            }    
            
            return( @ret ) ;
        }
    );

}

sub Veto {
    my ($event) = @_;
    $event->{Cancel} = 1;
}

sub DESTROY  { 1 };

#----------------------------------------------------------------------------
 package Wx::ActiveX;
#----------------------------------------------------------------------------

1;

__END__

=head1 NAME

Wx::ActiveX - ActiveX Control Interface for Wx

=head1 VERSION

Version 0.16

=head1 SYNOPSIS
    
    use Wx::ActiveX qw( EVT_ACTIVEX );
    use Wx qw( wxID_ANY wxDefaultPosition , wxDefaultSize );
   
    ........

    my $activex = Wx::ActiveX->new(
                  $parent,
                  "WMPlayer.OCX",
                  wxID_ANY,
                  wxDefaultPosition,
                  wxDefaultSize );
                  
    EVT_ACTIVEX( $this, $activex, "PlaylistCollectionChange", \&on_event_handler );
    
    $activex->PropSet("URL",'pathtomyfile.avi') ;
    
    ..........
    
    $activex->Invoke("launchURL", "http://my.url.com/file.movie") ;

    ... or ...

    $activex->launchURL("http://my.url.com/file.movie") ;
    
    ----------------------------------------------------------------
    
    package MyActiveXControl;
    use Wx::ActiveX;
    use base qw( Wx::ActiveX );
    
    our (@EXPORT_OK, %EXPORT_TAGS);
    $EXPORT_TAGS{everything} = \@EXPORT_OK;
    
    my @activexevents = qw(
        OnReadyStateChange
        FSCommand
        OnProgress
    );
    
    my $exporttag = 'elviscontrol';
    my $eventname = 'ELVIS'; 
    
    __PACKAGE__->activex_load_activex_event_types( __PACKAGE__,
                                                  $eventname,
                                                  $exporttag,
                                                  \@activexevents );
    
    ...
    
    EVT_ACTIVEX_ELVIS_ONPROGRESS( $this, $activex,\&on_event_handler );
    
    

=head1 DESCRIPTION

Load ActiveX controls for wxWindows.
The package installs a module in Wx::Demo for reference.

There are some wrapped controls included with the package:

    Wx::ActiveX::IE                  Internet Explorer Control
    Wx::ActiveX::Mozilla             Mozilla Browser Control
    Wx::ActiveX::WMPlayer            Windows Media Player
    Wx::ActiveX::ScriptControl       MS Script Control
    Wx::ActiveX::Document            Control Wrapper via Browser
    Wx::ActiveX::Acrobat             Acrobat ActiveX Control
    Wx::ActiveX::Flash               Adobe Flash Control
    Wx::ActiveX::Quicktime           Apple QuickTime ActiveX Control

See the POD for each indvidual control.

There is also a Template producer that will provide code for
a module given an ActiveX ProgID.

wxactivex_template

or

perl -MWx::ActiveX::Template -e"run_wxactivex_template();"


=head1 METHODS

=head2 new ( PARENT , CONTROL_ID , ID , POS , SIZE )

Create the ActiveX control.

  PARENT        need to be a Wx::Window object.
  CONTROL_ID    The control ID (PROGID/string).

=over

=item PropVal ( PROP_NAME )

Get the value of a propriety of the control.

=item PropSet ( PROP_NAME , VALUE )

Set a propriety of the control.

  PROP_NAME  The propriety name.
  VALUE      The value(s).

=item PropType ( PROP_NAME )

Return the type of the propriety.

=item GetEventCount

Returnt the number of events that the control have.

=item GetPropCount

Returnt the number of proprieties.

=item GetMethodCount

Returnt the number of control methods.

=item GetEventName( X )

Returnt the name of the event X, where X is a integer.

=item GetPropName( X )

Returnt the name of the propriety X, where X is a integer.

=item GetMethodName( X )

Returnt the name of the method X, where X is a integer.

=item GetMethodArgCount( MethodX )

Returnt the number of arguments of the MethodX.

=item GetMethodArgName( MethodX , ArgX )

Returnt the name of the ArgX of MethodX.

=item ListEvents()

Return an ARRAY with all the events names.

=item ListProps()

Return an ARRAY with all the proprieties names.

=item ListMethods()

Return an ARRAY with all the methods names.

=item ListMethods_and_Args()

Return an ARRAY with all the methods names and arguments. like:

  foo(argx, argy)

=item ListMethods_and_Args_Hash()

Return a HASH with all the methods names (keys) and arguments (values). The arguments are inside a ARRAY ref:

  my %methods = $activex->ListMethods_and_Args_Hash ;
  my @args = @{ $methods{foo} } ;

=item ActivexInfos()

Return a string with all the informations about the ActiveX Control:

  <EVENTS>
    MouseUp
    MouseMove
    MouseDown
  </EVENTS>
  
  <PROPS>
    FileName
  </PROPS>
  
  <METHODS>
    Close()
    Load(file)
  </METHODS>

=back

=head1 Win32::OLE

From version 0.5 Wx::ActiveX is compatible with Win32::OLE objects:

  use Wx::ActiveX ;
  use Win32::OLE ;
  
  my $activex = Wx::ActiveX->new( $this , "ShockwaveFlash.ShockwaveFlash" , 101 , wxDefaultPosition , wxDefaultSize ) ;

  my $OLE = $activex->GetOLE() ;
  $OLE->LoadMovie('0' , "file:///F:/swf/test.swf") ;
  $OLE->Play() ;


=head1 EVENTS

All the events use EVT_ACTIVEX.

  EVT_ACTIVEX($parent , $activex , "EventName" , sub{...} ) ;
  
** You can get the list of ActiveX event names using ListEvents():
  
Each ActiveX event has its own argument list (hash), and the method 'Veto' can be used to ignore the event.
In this example any new window will be canceled, seting $evt->IsAllowed to False:

  EVT_ACTIVEX($this,$activex, "EventX" , sub{
    my ( $obj , $evt ) = @_ ;
    $evt->Veto;
  }) ;


=head1 SEE ALSO

L<Wx::ActiveX::IE>, L<Wx::ActiveX::Mozilla>, L<Wx::ActiveX::WMPlayer>, L<Wx>

=head1 AUTHORS & ACKNOWLEDGEMENTS

Wx::ActiveX has benefited from many contributors:

Graciliano Monteiro Passos - original author

Contributions from:

Simon Flack
Mattia Barbon
Eric Wilhelm
Andy Levine
Mark Dootson

Thanks to Justin Bradford and Lindsay Mathieson
who wrote the C classes for wxActiveX and wxIEHtmlWin.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2002-2011 Authors & Contributors, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CURRENT MAINTAINER

Mark Dootson <mdootson@cpan.org>

=cut

# Local variables: #
# mode: cperl #
# End: #
