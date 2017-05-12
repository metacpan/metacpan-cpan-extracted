#############################################################################
## Name:        lib/Wx/ActiveX/IE.pm
## Purpose:     Wx::ActiveX::IE (Internet Explorer)
## Author:      Graciliano M. P.
## Created:     01/09/2002
## SVN-ID:      $Id: IE.pm 2846 2010-03-16 09:15:49Z mdootson $
## Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::ActiveX::IE;
use strict ;
use Wx::ActiveX;
use base qw( Wx::IEHtmlWin  Wx::ActiveX );

our $VERSION = '0.15'; # Wx::ActiveX Version

our (@EXPORT_OK, %EXPORT_TAGS);
$EXPORT_TAGS{everything} = \@EXPORT_OK;

# my $PROGID = 'Internet.Explorer';

my $exporttag = 'iexplorer';
my $eventname = 'IE';

# events below implemented as EVT_ACTIVEX_EVENTNAME ($$$)
# e.g EVT_ACTIVEX_IE_ONQUIT($eventhandler, $control, \&event_function);
# The Event ID will be exported as EVENTID_AX_IE_ONQUIT

our @activexevents = qw (
    BeforeNavigate2
    ClientToHostWindow
    CommandStateChange
    DocumentComplete
    DownloadBegin
    DownloadComplete
    FileDownload
    NavigateComplete2
    NewWindow2
    OnFullScreen
    OnMenuBar
    OnQuit
    OnStatusBar
    OnTheaterMode
    OnToolBar
    OnVisible
    ProgressChange
    PropertyChange
    SetSecureLockIcon
    StatusTextChange
    TitleChange
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

Wx::ActiveX::IE - ActiveX interface for Internet Explorer. (Win32)

=head1 SYNOPSIS

    use Wx::ActiveX::IE qw(:iexplorer);
    
    ............

    my $browser = Wx::ActiveX::IE->new( $parent , -1 , wxDefaultPosition , wxDefaultSize );
    EVT_ACTIVEX_IE_BEFORENAVIGATE2($this,$browser,\&on_evt_beforenavigate);
    
    ............
    
    $browser->LoadUrl("http://wxperl.sf.net");
    
    #OR
    
    use Wx::ActiveX::IE;
    use Wx::ActiveX::Mozilla;
    use Wx::ActiveX::Browser qw(:browser);
    
    ............
    
    my $browserclass = $ShouldIUseIE ? 'Wx::ActiveX::IE' : 'Wx::ActiveX::Mozilla';
    my $browser = $browserclass->new( $parent , -1 , wxDefaultPosition , wxDefaultSize );
    EVT_ACTIVEX_BROWSER_BEFORENAVIGATE2($this,$browser,\&on_evt_beforenavigate);
    
    ............
    
    $browser->LoadUrl("http://wxperl.sf.net");

=head1 DESCRIPTION

This will implement the web browser Internet Explorer in your App, using the
interface Wx::ActiveX.

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

  EVT_ACTIVEX($parent , $IE , "BeforeNavigate2" , sub{...} ) ;

or using the ACTIVEX_IE event table:

  EVT_ACTIVEX_IE_BEFORENAVIGATE2($parent , $IE , sub{...} ) ;

To import the events use:

  use Wx::ActiveX qw( EVT_ACTIVEX );

  use Wx::ActiveX::IE qw(EVT_ACTIVEX EVT_ACTIVEX_IE_NEWWINDOW2 EVT_ACTIVEX_IE_STATUSTEXTCHANGE) ;
  ... or ...
  use Wx::ActiveX::IE qw(:iexplorer) ;
  
You can use a common event table for both Mozilla and IE

  use Wx::ActiveX::Browser qw(:browser);

Here is the event table for Wx::ActiveX::IE:

    EVT_ACTIVEX_IE_STATUSTEXTCHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_DOWNLOADCOMPLETE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_COMMANDSTATECHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_DOWNLOADBEGIN($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_PROGRESSCHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_PROPERTYCHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_TITLECHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_PRINTTEMPLATEINSTANTIATION($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_PRINTTEMPLATETEARDOWN($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_UPDATEPAGESTATUS($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_BEFORENAVIGATE2($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_NEWWINDOW2($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_NAVIGATECOMPLETE2($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_ONQUIT($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_ONVISIBLE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_ONTOOLBAR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_ONMENUBAR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_ONSTATUSBAR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_ONFULLSCREEN($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_DOCUMENTCOMPLETE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_ONTHEATERMODE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_WINDOWSETRESIZABLE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_WINDOWCLOSING($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_WINDOWSETLEFT($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_WINDOWSETTOP($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_WINDOWSETWIDTH($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_WINDOWSETHEIGHT($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_CLIENTTOHOSTWINDOW($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_SETSECURELOCKICON($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_FILEDOWNLOAD($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_NAVIGATEERROR($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_PRIVACYIMPACTEDSTATECHANGE($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_NEWWINDOW3($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_SETPHISHINGFILTERSTATUS($handler, $axcontrol, \&event_sub);
    EVT_ACTIVEX_IE_WINDOWSTATECHANGED($handler, $axcontrol, \&event_sub);
    
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
    PrintTemplateInstantiation
    PrintTemplateTeardown
    UpdatePageStatus
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
    WindowSetResizable
    WindowClosing
    WindowSetLeft
    WindowSetTop
    WindowSetWidth
    WindowSetHeight
    ClientToHostWindow
    SetSecureLockIcon
    FileDownload
    NavigateError
    PrivacyImpactedStateChange
    NewWindow3
    SetPhishingFilterStatus
    WindowStateChanged

=head1 NOTE

This package only works for Win32, since it use AtiveX.

=head1 SEE ALSO

L<Wx::ActiveX> L<Wx>
L<Wx::ActiveX::Mozilla> L<Wx>

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

Thanks to wxWindows people and Mattia Barbon for wxPerl! :P

Thanks to Justin Bradford <justin@maxwell.ucsf.edu> and Lindsay Mathieson <lmathieson@optusnet.com.au>, that wrote the original C++ classes for wxActiveX and wxIEHtmlWin.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 CURRENT MAINTAINER

Mark Dootson <mdootson@cpan.org> 

=cut

# Local variables: #
# mode: cperl #
# End: #
