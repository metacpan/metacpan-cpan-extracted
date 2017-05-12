#############################################################################
## Name:        lib/Wx/DemoModules/wxWebview.pm
## Purpose:     wxPerl demo helper for Wx::WebView
## Author:      Mark Dootson
## Created:     17/03/2012
## RCS-ID:      $Id: wxWebView.pm 3223 2012-03-18 03:05:39Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxWebView;

use strict;
use Wx;
use Wx::WebView;
use base qw( Wx::Panel );
use Wx qw( :webview :misc :id :window :panel :sizer wxYES_NO wxNO :dialog :font);
use Wx::Event (Wx::wxVERSION >= 3.000000)
    ? qw(
	EVT_WEBVIEW_NAVIGATING  EVT_WEBVIEW_NAVIGATED
	EVT_WEBVIEW_LOADED  EVT_WEBVIEW_ERROR
	EVT_WEBVIEW_NEWWINDOW	EVT_WEBVIEW_TITLE_CHANGED
        EVT_BUTTON
    )
    : qw(
	EVT_WEB_VIEW_NAVIGATING  EVT_WEB_VIEW_NAVIGATED
	EVT_WEB_VIEW_LOADED  EVT_WEB_VIEW_ERROR
	EVT_WEB_VIEW_NEWWINDOW	EVT_WEB_VIEW_TITLE_CHANGED
        EVT_BUTTON
    );

our $VERSION = '0.01';

sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent );
	
    $self->{defaulturl} = 'http://wxperl.sourceforge.net';
    
    #controls
	$self->{webview} = Wx::WebView::New($self, wxID_ANY,  $self->{defaulturl} );
    
    my $btnurl  = Wx::Button->new($self, wxID_ANY, 'Load URL');
    my $btnback = Wx::Button->new($self, wxID_ANY, 'Back');
    my $btnforw = Wx::Button->new($self, wxID_ANY, 'Forward');
    my $btnhist = Wx::Button->new($self, wxID_ANY, 'History');
    my $btnscpt = Wx::Button->new($self, wxID_ANY, 'Run Script');
    my $btnhtml = Wx::Button->new($self, wxID_ANY, 'Load Html');
    my $btnsrc = Wx::Button->new($self, wxID_ANY, 'View Source');
    
    $self->{btnback} = $btnback;
    $self->{btnback}->Enable(0);
    $self->{btnforw} = $btnforw;
    $self->{btnforw}->Enable(0);
    
    # Events
    if(Wx::wxVERSION >= 3.000000)  {
	EVT_WEBVIEW_NAVIGATING( $self, $self->{webview}, sub { shift->OnWVNavigating( @_ ); });
	EVT_WEBVIEW_NAVIGATED( $self, $self->{webview}, sub { shift->OnWVNavigated( @_ ); });
	EVT_WEBVIEW_LOADED( $self, $self->{webview}, sub { shift->OnWVLoaded( @_ ); });
	EVT_WEBVIEW_ERROR( $self, $self->{webview}, sub { shift->OnWVError( @_ ); });
	EVT_WEBVIEW_NEWWINDOW( $self, $self->{webview}, sub { shift->OnWVNewWindow( @_ ); });
	EVT_WEBVIEW_TITLE_CHANGED( $self, $self->{webview}, sub { shift->OnWVTitleChanged( @_ ); });
    } else {
	EVT_WEB_VIEW_NAVIGATING( $self, $self->{webview}, sub { shift->OnWVNavigating( @_ ); });
	EVT_WEB_VIEW_NAVIGATED( $self, $self->{webview}, sub { shift->OnWVNavigated( @_ ); });
	EVT_WEB_VIEW_LOADED( $self, $self->{webview}, sub { shift->OnWVLoaded( @_ ); });
	EVT_WEB_VIEW_ERROR( $self, $self->{webview}, sub { shift->OnWVError( @_ ); });
	EVT_WEB_VIEW_NEWWINDOW( $self, $self->{webview}, sub { shift->OnWVNewWindow( @_ ); });
	EVT_WEB_VIEW_TITLE_CHANGED( $self, $self->{webview}, sub { shift->OnWVTitleChanged( @_ ); });
    }
    EVT_BUTTON($self, $btnurl,  sub { shift->OnBtnURL( @_ ); });
    EVT_BUTTON($self, $btnback, sub { shift->OnBtnBack( @_ ); });
    EVT_BUTTON($self, $btnforw, sub { shift->OnBtnForward( @_ ); });
    EVT_BUTTON($self, $btnhist, sub { shift->OnBtnHistory( @_ ); });
    EVT_BUTTON($self, $btnscpt, sub { shift->OnBtnRunScript( @_ ); });
    EVT_BUTTON($self, $btnhtml, sub { shift->OnBtnLoadHtml( @_ ); });
    EVT_BUTTON($self, $btnsrc,  sub { shift->OnBtnSource( @_ ); });
	
	# layout
	
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $buttonsizer->Add($btnurl,  0, wxLEFT|wxRIGHT, 0);
    $buttonsizer->Add($btnback, 0, wxLEFT|wxRIGHT, 0);
    $buttonsizer->Add($btnforw, 0, wxLEFT|wxRIGHT, 0);
    $buttonsizer->Add($btnhist, 0, wxLEFT|wxRIGHT, 0);
    $buttonsizer->Add($btnscpt, 0, wxLEFT|wxRIGHT, 0);
    $buttonsizer->Add($btnhtml, 0, wxLEFT|wxRIGHT, 0);
    $buttonsizer->Add($btnsrc, 0, wxLEFT|wxRIGHT, 0);
    
    my $msizer = Wx::BoxSizer->new( wxVERTICAL );
    $msizer->Add($buttonsizer, 0, wxEXPAND|wxALL, 0);
	$msizer->Add($self->{webview}, 1, wxEXPAND|wxALL, 0);
    
	$self->SetSizer( $msizer );
	$self->Layout;
	$self->Refresh;

    return $self;
}

sub OnWVNavigating {
    my ($self, $event) = @_;
    my $url = $event->GetURL;
    my $target = $event->GetTarget;
    Wx::LogMessage('WebView requested new page "%s" : in target "%s"', $url, $target);
}

sub OnWVNavigated {
    my ($self, $event) = @_;
    
}

sub OnWVLoaded {
    my ($self, $event) = @_;
    # loading a resource is complete so set our back and forward button states
    $self->{btnback}->Enable( $self->{webview}->CanGoBack );
    $self->{btnforw}->Enable( $self->{webview}->CanGoForward );
}

sub OnWVError {
    my ($self, $event) = @_;
    my $errorstring = $event->GetString;
    my $url = $event->GetURL;
    
    my $errormap = (Wx::wxVERSION >= 3.000000)
       ? {
	    wxWEBVIEW_NAV_ERR_CONNECTION() => 'wxWEB_NAV_ERR_CONNECTION',
	    wxWEBVIEW_NAV_ERR_CERTIFICATE() => 'wxWEB_NAV_ERR_CERTIFICATE',
	    wxWEBVIEW_NAV_ERR_AUTH() => 'wxWEB_NAV_ERR_AUTH',
	    wxWEBVIEW_NAV_ERR_SECURITY() => 'wxWEB_NAV_ERR_SECURITY',
	    wxWEBVIEW_NAV_ERR_NOT_FOUND() => 'wxWEB_NAV_ERR_NOT_FOUND',
	    wxWEBVIEW_NAV_ERR_REQUEST() => 'wxWEB_NAV_ERR_REQUEST',
	    wxWEBVIEW_NAV_ERR_USER_CANCELLED() => 'wxWEB_NAV_ERR_USER_CANCELLED',
	    wxWEBVIEW_NAV_ERR_OTHER() => 'wxWEB_NAV_ERR_OTHER',
	}
       : {
	    wxWEB_NAV_ERR_CONNECTION() => 'wxWEB_NAV_ERR_CONNECTION',
	    wxWEB_NAV_ERR_CERTIFICATE() => 'wxWEB_NAV_ERR_CERTIFICATE',
	    wxWEB_NAV_ERR_AUTH() => 'wxWEB_NAV_ERR_AUTH',
	    wxWEB_NAV_ERR_SECURITY() => 'wxWEB_NAV_ERR_SECURITY',
	    wxWEB_NAV_ERR_NOT_FOUND() => 'wxWEB_NAV_ERR_NOT_FOUND',
	    wxWEB_NAV_ERR_REQUEST() => 'wxWEB_NAV_ERR_REQUEST',
	    wxWEB_NAV_ERR_USER_CANCELLED() => 'wxWEB_NAV_ERR_USER_CANCELLED',
	    wxWEB_NAV_ERR_OTHER() => 'wxWEB_NAV_ERR_OTHER',
	};
    
    my $errorid = $event->GetInt;
    my $errname = exists( $errormap->{$errorid} ) ? $errormap->{$errorid} : '<UNKNOWN ID>';
    
    Wx::LogMessage('Getting %s Webview reports the following error code and string : %s : %s', $url, $errname, $errorstring);

}

sub OnWVNewWindow {
    my ($self, $event) = @_;
    my $target = $event->GetTarget;
    my $url = $event->GetURL;
    # If we do nothing, nothing will happen
    my $message = qq(The WebView has requested that we load $url in a new page or frame.\n\nShould we allow it to be loaded to this page instead?);
    my $res = Wx::MessageBox($message, 'WebView Demo', wxYES_NO, $self);
    return if $res == wxNO;
    
    $self->{webview}->LoadURL($url);
    
}

sub OnWVTitleChanged {
    my ($self, $event) = @_;
    
}

sub OnBtnURL {
    my ($self, $event) = @_;
    
    my $dialog = Wx::TextEntryDialog->new
        ( $self, "Enter a URL to load", "Wx::WebView Demo",
        $self->{defaulturl} );
    my $res = $dialog->ShowModal;
    my $rvalue =  $dialog->GetValue;
    $dialog->Destroy;
    return if $res == wxID_CANCEL;
    $self->{defaulturl} = $rvalue;
    $self->{webview}->LoadURL( $rvalue );
}

sub OnBtnBack {
    my ($self, $event) = @_;
    $self->{webview}->GoBack if $self->{webview}->CanGoBack;
}

sub OnBtnForward {
    my ($self, $event) = @_;
    $self->{webview}->GoForward if $self->{webview}->CanGoForward;
}

sub OnBtnHistory {
    my ($self, $event) = @_;
    my @past = $self->{webview}->GetBackwardHistory;
    my @future = $self->{webview}->GetForwardHistory;
    
    my $ptext = '<h3>Backward History</h3><br>';
    $ptext .= $_->GetTitle . ' : ' .  $_->GetUrl . '<br>' for ( @past );
    $ptext .= '<h3>Forward History</h3><br>';
    $ptext .= $_->GetTitle . ' : ' .  $_->GetUrl . '<br>' for ( @future );
    $ptext .= '</font>';
    
    $self->{webview}->SelectAll;
    $self->{webview}->DeleteSelection;
    
    $self->{webview}->SetPage($ptext, 'http://localhost:54321/');
}

sub OnBtnRunScript {
    my ($self, $event) = @_;
    
    my $javascript ='
// You can write any javascript here and run it in the
// document.
document.write("<p>" + Date() + "</p>");
';
    
    my $style = wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER;
    
    my $dlg = Wx::DemoModules::wxWebView::HtmlDialog->new(
                $self, -1, 'Wx::WebView Run JavaScript',
                wxDefaultPosition, [600,400], $style );
    $dlg->set_text( $javascript );
    my $result = $dlg->ShowModal;
    $javascript = $dlg->get_text;
    $dlg->Destroy;
    
    return if $result == wxID_CANCEL;
    
    $self->{webview}->RunScript( $javascript);

}

sub OnBtnLoadHtml {
    my ($self, $event) = @_;
    
    my $html = q(
<html lang="en" xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<!-- You can edit or paste any html in this dialog to load it -->
</head>
<body>
<h1>Hello World</h1>
</body>
</html>

);
    my $style = wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER;
    
    my $dlg = Wx::DemoModules::wxWebView::HtmlDialog->new(
                $self, -1, 'Wx::WebView Load HTML',
                wxDefaultPosition, [600,400], $style );
    $dlg->set_text( $html );
    my $result = $dlg->ShowModal;
    my $htmlout = $dlg->get_text;
    $dlg->Destroy;
    
    return if $result == wxID_CANCEL;
    
    # we can add to page content using a string or a file handle
    # we will cear content first as on some platforms SetPage
    # appends
    $self->{webview}->SelectAll;
    $self->{webview}->DeleteSelection;
    
    $self->{webview}->SetPage($htmlout, 'http://localhost:54321/');
    
    # we could also have passed any open file handle using SetPageFH
    # open my $fh, '<', \$htmlout;
    # $self->{webview}->SetPageFH($fh, 'http://localhost:54321/');
    # close( $fh );
}

sub OnBtnSource {
    my ($self, $event) = @_;
    my $html = $self->{webview}->GetPageSource;
    
    my $style = wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER;
    
    my $dlg = Wx::DemoModules::wxWebView::HtmlDialog->new(
                $self, -1, 'Wx::WebView Page Source',
                wxDefaultPosition, [600,400], $style );
    $dlg->set_text( $html );
    $dlg->ShowModal;
    $dlg->Destroy;
}

sub add_to_tags { qw(new controls) }
sub title { 'wxWebView' }




package Wx::DemoModules::wxWebView::HtmlDialog;
use Wx::STC;
use Wx qw( :id :stc :sizer :font );
use base qw( Wx::Dialog );
use Wx::Event qw( EVT_BUTTON );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    my $text = Wx::StyledTextCtrl->new($self, wxID_ANY);
    
    my $ok = Wx::Button->new($self, wxID_OK, 'OK');
    my $cancel = Wx::Button->new($self, wxID_CANCEL, 'Cancel');
    $ok->SetDefault;

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($text, 1, wxEXPAND);
    my $bsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $bsizer->AddStretchSpacer(1);
    $bsizer->Add($ok, 0, wxALL, 0);
    $bsizer->Add($cancel, 0, wxALL, 0);
    
    $sizer->Add($bsizer, 0, wxEXPAND|wxALL, 0);
    $self->SetSizer($sizer);
    
    $self->{stc} = $text;
    $self->set_style_html;
    return $self;
}

sub set_style_html {
    my $self = shift;
    my $text = $self->{stc};
    my $font = Wx::wxMAC() 
                ? Wx::Font->new( 12, wxMODERN, wxNORMAL, wxNORMAL, 0, 'Monaco' )
                : Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL);
                
    $text->SetFont( $font );
    $text->StyleSetFont( wxSTC_STYLE_DEFAULT, $font );
    
    $text->SetMarginWidth(1, 30);
    $text->SetMarginType(1, wxSTC_MARGIN_NUMBER);
    
    $text->StyleClearAll();
    $text->SetLexer(wxSTC_LEX_HTML);
    $text->StyleSetForeground(wxSTC_H_DOUBLESTRING, Wx::Colour->new(255,0,0));
    $text->StyleSetForeground(wxSTC_H_SINGLESTRING, Wx::Colour->new(255,0,0));
    $text->StyleSetForeground(wxSTC_H_ENTITY, Wx::Colour->new(255,0,0));
    $text->StyleSetForeground(wxSTC_H_TAG, Wx::Colour->new(0,150,0));
    $text->StyleSetForeground(wxSTC_H_TAGUNKNOWN, Wx::Colour->new(0,150,0));
    $text->StyleSetForeground(wxSTC_H_ATTRIBUTE, Wx::Colour->new(0,0,150));
    $text->StyleSetForeground(wxSTC_H_ATTRIBUTEUNKNOWN, Wx::Colour->new(0,0,150));
    $text->StyleSetForeground(wxSTC_H_COMMENT, Wx::Colour->new(150,150,150));
}

sub ShowModal {
    my $self = shift;
    $self->CentreOnParent;
    $self->SUPER::ShowModal( @_ );
}

sub set_text { $_[0]->{stc}->SetText($_[1]); }
sub get_text { $_[0]->{stc}->GetText(); }

#Skip loading if no wxWebView
# return 1 or 0
eval { return Wx::_wx_optmod_webview(); };
