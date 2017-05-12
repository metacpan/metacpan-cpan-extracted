#############################################################################
## Name:        lib/Wx/ActiveX/Mozilla.pm
## Purpose:     Wx::ActiveX::Browser (Mozilla)
## Author:      Graciliano M. P.
## Created:     01/09/2002
## SVN-ID:      $Id: Mozilla.pm 2846 2010-03-16 09:15:49Z mdootson $
## Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::ActiveX::Mozilla;
use strict ;
use Wx::ActiveX;
use base qw( Wx::MozillaHtmlWin Wx::ActiveX );

our $VERSION = '0.15'; # Wx::ActiveX Version

our (@EXPORT_OK, %EXPORT_TAGS);
$EXPORT_TAGS{everything} = \@EXPORT_OK;

#my $PROGID = 'Mozilla.Browser';

my $exporttag = 'mozilla';
my $eventname = 'MOZILLA';

our @activexevents = qw (
    StatusTextChange
    DownloadComplete
    CommandStateChange
    DownloadBegin
    ProgressChange
    PropertyChange
    TitleChange
    BeforeNavigate2
    NewWindow2
    NavigateComplete2
    OnQuit
    OnVisible
    OnToolBar
    OnMenuBar
    OnStatusBar
    OnFullScreen
    DocumentComplete
    OnTheaterMode
);

# list for reference
my @missingevents = qw(
    ClientToHostWindow   
    FileDownload
    SetSecureLockIcon    
    WindowClosing
    WindowSetHeight
    WindowSetLeft
    WindowSetResizable
    WindowSetTop
    WindowSetWidth
);


# __PACKAGE__->activex_load_standard_event_types( $export_to_namespace, $eventidentifier, $exporttag, $elisthashref );
# __PACKAGE__->activex_load_activex_event_types( $export_to_namespace, $eventidentifier, $exporttag, $elistarrayref );

__PACKAGE__->activex_load_activex_event_types( __PACKAGE__, $eventname, $exporttag, \@activexevents );


sub WxActiveXBrowserClass {
    return __PACKAGE__;
}

1;

__END__


=head1 NAME

Wx::ActiveX::Mozilla - ActiveX interface for Mozilla Browser ActiveX Control

=head1 SYNOPSIS

    use Wx::ActiveX::Mozilla qw(:mozilla);
    
    ............

    my $browser = Wx::ActiveX::Mozilla->new( $parent , -1 , wxDefaultPosition , wxDefaultSize );
    EVT_ACTIVEX_MOZILLA_BEFORENAVIGATE2($this,$browser,\&on_evt_beforenavigate);
    
    ............
    
    $browser->LoadUrl("http://wxperl.sf.net");
    
    #OR using common browser events
    
    use Wx::ActiveX::IE;
    use Wx::ActiveX::Mozilla;
    use Wx::ActiveX::Browser qw(:browser);
    
    ............
    
    my $browserclass = $ShouldIUseMozilla ? 'Wx::ActiveX::Mozilla' : 'Wx::ActiveX::IE';
    my $browser = $browserclass->new( $parent , -1 , wxDefaultPosition , wxDefaultSize );
    EVT_ACTIVEX_BROWSER_BEFORENAVIGATE2($this,$browser,\&on_evt_beforenavigate);
    
    ............
    
    $browser->LoadUrl("http://wxperl.sf.net");

=head1 DESCRIPTION

This will implement the Mozilla Browser ActiveX control in your App, using the
interface Wx::ActiveX.

The Mozilla Browser ActiveX Control is available from
http://www.wxperl.co.uk/MozillaControl1712.exe

You can also get it from the control's author at
http://www.iol.ie/~locka/mozilla/control.htm

The control may not be currently maintained, the last release being in 2005.
You should probably therefore not use it as a general browser.

=head1 METHODS

=head2 new ( PARENT , ID , POS , SIZE )

This will create and return the browser object.

=over 15

=item LoadUrl

Attempts to browse to the url, the control uses its internal network streams.

=item LoadString

Load the passed HTML string.

=item LoadStream

Load the passed HTML stream. The control takes ownership of the pointer, deleting when finished.

=item SetCharset

Sets the charset of the loaded document.

=item SetEditMode( BOOLEAN )

Set the EditMode ON/OFF.

=item GetEditMode

Return true if the EditMode as set on.

=item GetStringSelection( asHTML )

Get the text selected in the page. If asHTML is true it return the html codes too.

=item GetText( asHTML )

Get all the text of the page. If asHTML is true it return the html codes too.

=item GoBack

Go back in the History.

=item GoForward

Go forward in the History (if it goes back before).

=item GoHome

Go to the Home Page of the browser.

=item GoSearch

Go to the default search page of IE.

=item Refresh( LEVEL )

Refresh the URL. You can set the LEVELs, from 0 to 3, of the refresh:

  0 -> Normal*.
  1 -> If Expired.
  2 -> Continue.
  3 -> Completely.

=item Stop

Stop the download process.

=item Print(Prompt)

Print the page. If Prompt is TRUE, will prompt for configurations, if FALSE will print directly.

=item PrintPreview

Show the Print Preview window.

=back

=head1 EVENTS

All the events use EVT_ACTIVEX. For example, the event BeforeNavigate2 can be declared usgin EVT_ACTIVEX:

  EVT_ACTIVEX($parent , $mozilla , "BeforeNavigate2" , sub{...} ) ;

or using the ACTIVEX_MOZILLA event table:

  EVT_ACTIVEX_MOZILLA_BEFORENAVIGATE2($parent , $IE , sub{...} ) ;

To import the events use:

  use Wx::ActiveX qw( EVT_ACTIVEX );

  use Wx::ActiveX::Mozilla qw(EVT_ACTIVEX EVT_ACTIVEX_MOZILLA_NEWWINDOW2 EVT_ACTIVEX_MOZILLA_STATUSTEXTCHANGE) ;
  ... or ...
  use Wx::ActiveX::Mozilla qw(:mozilla) ;
  
You can use a common event table for both Mozilla and IE

  use Wx::ActiveX::Browser qw(:browser);

Here is the event table for Wx::ActiveX::Mozilla:

    EVT_ACTIVEX_MOZILLA_STATUSTEXTCHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_DOWNLOADCOMPLETE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_COMMANDSTATECHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_DOWNLOADBEGIN($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_PROGRESSCHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_PROPERTYCHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_TITLECHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_BEFORENAVIGATE2($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_NEWWINDOW2($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_NAVIGATECOMPLETE2($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_ONQUIT($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_ONVISIBLE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_ONTOOLBAR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_ONMENUBAR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_ONSTATUSBAR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_ONFULLSCREEN($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_DOCUMENTCOMPLETE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_MOZILLA_ONTHEATERMODE($handler, $axcontrol, \&event_sub);
    
Here is the event table for Wx::ActiveX::Browser:

    EVT_ACTIVEX_BROWSER_STATUSTEXTCHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_DOWNLOADCOMPLETE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_COMMANDSTATECHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_DOWNLOADBEGIN($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_PROGRESSCHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_PROPERTYCHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_TITLECHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_BEFORENAVIGATE2($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_NEWWINDOW2($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_NAVIGATECOMPLETE2($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_ONQUIT($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_ONVISIBLE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_ONTOOLBAR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_ONMENUBAR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_ONSTATUSBAR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_ONFULLSCREEN($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_DOCUMENTCOMPLETE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_BROWSER_ONTHEATERMODE($handler, $axcontrol, \&event_sub);    

=head1 DISPATCH METHODS

    $obj->MethodName( @args );
    
    or
    
    $obj->Invoke( 'MethodName', @args );

    AddRef()
    ClientToWindow(pcx , pcy)
    ExecWB(cmdID , cmdexecopt , pvaIn , pvaOut)
    GetIDsOfNames(riid , rgszNames , cNames , lcid , rgdispid)
    GetProperty(Property)
    GetTypeInfo(itinfo , lcid , pptinfo)
    GetTypeInfoCount(pctinfo)
    GoBack()
    GoForward()
    GoHome()
    GoSearch()
    Invoke(dispidMember , riid , lcid , wFlags , pdispparams , pvarResult , pexcepinfo , puArgErr)
    Navigate(URL , Flags , TargetFrameName , PostData , Headers)
    Navigate2(URL , Flags , TargetFrameName , PostData , Headers)
    PutProperty(Property , vtValue)
    QueryInterface(riid , ppvObj)
    QueryStatusWB(cmdID)
    Quit()
    Refresh()
    Refresh2(Level)
    Release()
    ShowBrowserBar(pvaClsid , pvarShow , pvarSize)
    Stop()   

=head1 PROPERTIES

    AddressBar                   (bool)
    Application                  (IDispatch)
    Busy                         (bool)
    Container                    (IDispatch)
    Document                     (IDispatch)
    FullName                     (wxString)
    FullScreen                   (bool)
    Height                       (long)
    HWND                         (long)
    Left                         (long)
    LocationName                 (wxString)
    LocationURL                  (wxString)
    MenuBar                      (bool)
    Name                         (wxString)
    Offline                      (bool)
    Parent                       (IDispatch)
    Path                         (wxString)
    ReadyState                   (*user defined*)
    RegisterAsBrowser            (bool)
    RegisterAsDropTarget         (bool)
    Resizable                    (bool)
    Silent                       (bool)
    StatusBar                    (bool)
    StatusText                   (wxString)
    TheaterMode                  (bool)
    ToolBar                      (int)
    Top                          (long)
    TopLevelContainer            (bool)
    Type                         (wxString)
    Visible                      (bool)
    Width                        (long)

=head1 ACTIVEX EVENT LIST

    StatusTextChange
    DownloadComplete
    CommandStateChange
    DownloadBegin
    ProgressChange
    PropertyChange
    TitleChange
    BeforeNavigate2
    NewWindow2
    NavigateComplete2
    OnQuit
    OnVisible
    OnToolBar
    OnMenuBar
    OnStatusBar
    OnFullScreen
    DocumentComplete
    OnTheaterMode

=head1 SEE ALSO

L<Wx::ActiveX> L<Wx>
L<Wx::ActiveX::IE> L<Wx>

=head1 AUTHOR

Mark Dootson <mdootson@cpan.org>

This is a virtual copy of Wx::ActiveX::IE so thanks to all who
contribute that module.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


#
