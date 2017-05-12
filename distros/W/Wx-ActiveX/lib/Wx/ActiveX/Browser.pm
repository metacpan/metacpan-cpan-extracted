#############################################################################
## Name:        lib/Wx/ActiveX/Browser.pm
## Purpose:     Allow Common IE and Mozilla interface
## Author:      Mark Dootson.
## Created:     2008-04-04
## SVN-ID:      $Id: Browser.pm 2846 2010-03-16 09:15:49Z mdootson $
## Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

#----------------------------------------------------------------------------
 package Wx::ActiveX::Browser;
#----------------------------------------------------------------------------
require Exporter;
use Wx::ActiveX;
use base qw( Exporter );

our $VERSION = '0.15'; # Wx::ActiveX Version

our (@EXPORT_OK, %EXPORT_TAGS);
$EXPORT_TAGS{everything} = \@EXPORT_OK;

my $exporttag = 'browser';
my $eventname = 'BROWSER';

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

&Wx::ActiveX::activex_load_activex_event_types( __PACKAGE__,
                                                __PACKAGE__,
                                                $eventname,
                                                $exporttag,
                                                \@activexevents );

1;

__END__

=head1 NAME

Wx::ActiveX::Browser - Export Common Event Constants for Wx::ActiveX::IE and Wx::ActiveX::Mozilla

=head1 SYNOPSIS

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

Exports common event subs for Wx::ActiveX::IE and Wx::ActiveX::Mozilla;

=head1 EVENTS

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

=cut

#
