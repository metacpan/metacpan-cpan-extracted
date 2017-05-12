#############################################################################
## Name:        lib/Wx/DemoModules/wxActiveX.pm
## Purpose:     wxPerl Wx::Demo module for Wx::ActiveX
## Author:      Mark Dootson
## Created:     13/11/2007
## SVN-ID:      $Id: wxActiveX.pm 2367 2008-04-12 14:05:11Z mdootson $
## Copyright:   (c) 2002 - 2008 Graciliano M. P., Mattia Barbon, Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

BEGIN {
    package Wx::ActiveX;
    our $__wxax_debug; # some info output
    package Wx::DemoModules::wxActiveX;
}

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX;
#----------------------------------------------------

use Wx qw( :sizer wxYES_NO wxICON_QUESTION wxCENTRE wxYES wxFD_OPEN wxFD_FILE_MUST_EXIST wxFD_OPEN wxID_CANCEL :misc);
use Wx::ActiveX;
use base qw( Wx::Panel );
use Wx::ActiveX::Document qw( :document );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    
    # get Wx::TopLevelWindow;
    my $toplevel = $self->GetParent;
    while(!$toplevel->isa('Wx::TopLevelWindow')) {
        $toplevel = $toplevel->GetParent;
        last if(!$toplevel); # we ended up undef somehow
    }
    $self->{_top_level_window} = $toplevel;
    
    EVT_ACTIVEX_DOCUMENT_FRAME_CLOSING($toplevel, \&OnDocumentFrameClosing);
    
    return $self;
}

sub test_activex {
    my ($self, $activex) = @_;
    
    my( @events, @methods, @props );
    
    eval {
        @events = $activex->ListEvents;
        @methods = $activex->ListMethods_and_Args;
        @props = $activex->ListProps;
    };
    if($@) {
        Wx::LogError('Unable to access ActiveX interface. %s', $@);
        $activex->Show(0);
        $self->set_panel_blank();
        return 0;
    }
    
    # got anything
    if( (@events == 0) && (@methods == 0) && (@props == 0) ) {
        Wx::LogError('Unable to access ActiveX interface for control. The control is not installed.');
        $activex->Show(0);
        $self->set_panel_blank();
        return 0;
    } else {
        Wx::LogMessage('ActiveX Events' . "\n" . join("\n", @events) );
        Wx::LogMessage('ActiveX Methods' . "\n" . join("\n", @methods) );
        Wx::LogMessage('ActiveX Properties' . "\n" . join("\n", @props) );
        return 1;
    }
}

sub set_panel_blank {
    my $self = shift;
    my $label = Wx::StaticText->new($self, -1, 'The ActiveX Control could not be loaded', wxDefaultPosition, wxDefaultSize);
    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($label, 1, wxALL|wxEXPAND, 25 );
    $self->SetSizer($sizer);
}

sub top_level_window {
    my $self = shift;
    return $self->{_top_level_window};
}

sub question_message {
    my($self, $msg) = @_;
    my $title = 'Wx::ActiveX - Wx::Demo - Module';
    if(Wx::MessageBox($msg,
                   $title, 
                   wxYES_NO|wxICON_QUESTION|wxCENTRE, $self) == wxYES) {
        return 1;
    } else {
        return 0;
    }
}

sub open_filename {
    my $self = shift;
    my ($prompt, $mustexist, $filters, $priorfile, $defaultpath) = @_;

    $prompt ||= 'Please Select a File';
    my $style = $mustexist ? (wxFD_OPEN|wxFD_FILE_MUST_EXIST) : wxFD_OPEN;
    
    $defaultpath ||= '';
    $priorfile ||= '';
    
    my $filemask = '';
    if($filters) {
        my @masks = ();
        for my $filter (@$filters) {
            push(@masks, qq($filter->{text} ($filter->{mask})|$filter->{mask}) );
        }
        $filemask = join('|', @masks);
    } else {
        $filemask = 'All Files (*.*)|*.*';
    }
    
    my $parent = $self->top_level_window;    
    my $dialog = Wx::FileDialog->new
        (
            $parent,
            $prompt,
            $defaultpath,
            $priorfile,
            $filemask,
            $style
        );
        
    my $filepath = '';

    if( $dialog->ShowModal == wxID_CANCEL ) {
        $filepath = '';
    } else {
        $filepath = $dialog->GetPath();
    }
    
    return $filepath ? $filepath : undef;   
}

sub OnDocumentFrameClosing {
    my ($parentwindow, $event) = @_ ;
    $event->Veto  if( ! Wx::DemoModules::wxActiveX::question_message(undef, 'Are you sure you wish to close the document frame?') );    
    $event->Skip(0);
}


sub tags { [ 'windows/activex' => 'Wx::ActiveX' ] }

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX::BrowserPanel;
#----------------------------------------------------
use strict;
use Wx qw(:sizer wxTE_MULTILINE wxYES_NO wxICON_QUESTION wxCENTRE wxYES wxFD_OPEN wxFD_FILE_MUST_EXIST
           wxID_CANCEL wxTE_READONLY wxDefaultPosition wxDefaultSize wxID_ANY wxID_OK );
use Wx::Event qw( EVT_BUTTON) ;
use Wx::ActiveX qw( EVT_ACTIVEX );           
use Wx::ActiveX::Browser qw( :browser );

use base qw(Wx::DemoModules::wxActiveX);

$Wx::ActiveX::__wxax_debug = 1;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub InitBrowser {
    my ($self, $browserclass) = @_;
    
    # before creating a Mozilla browser, we need to check if it is actually installed.
    # if it isn't, loading will crash the perl interpreter
    if($browserclass eq 'Wx::ActiveX::Mozilla') {
        # try default interface
        my $checkbrowser = Wx::ActiveX->new( $self , 'Mozilla.Browser', wxID_ANY, wxDefaultPosition, wxDefaultSize );
        $checkbrowser->Show(0);
        return $self if(!$self->test_activex( $checkbrowser ));
        $checkbrowser->Close;
        $checkbrowser = undef;
    }
    
    my $top_s = Wx::BoxSizer->new( wxVERTICAL );
    my $but_s = Wx::BoxSizer->new( wxHORIZONTAL );
    my $but_s2 = Wx::BoxSizer->new( wxHORIZONTAL );
    
    my $LoadUrl = Wx::Button->new( $self, -1, 'LoadUrl' );
    my $LoadString = Wx::Button->new( $self, -1, 'LoadString' );
    my $GoBack = Wx::Button->new( $self, -1, 'GoBack' );
    my $GoForward = Wx::Button->new( $self, -1, 'GoForward' );
    my $GoHome = Wx::Button->new( $self, -1, 'GoHome' );
    my $GoSearch = Wx::Button->new( $self, -1, 'GoSearch' );
    my $Refresh = Wx::Button->new( $self, -1, 'Refresh' );
    my $Stop = Wx::Button->new( $self, -1, 'Stop' );
    my $GetStringSelection = Wx::Button->new( $self, -1, 'GetStringSelection' );
    my $GetText = Wx::Button->new( $self, -1, 'GetText' );
    my $GetTextHTML = Wx::Button->new( $self, -1, 'GetTextHTML' );
    my $Print = Wx::Button->new( $self, -1, 'Print' );
    my $PrintPreview = Wx::Button->new( $self, -1, 'PrintPreview' );
    my $OpenDocument = Wx::Button->new( $self, -1, 'Open Document' );
    
    # controls
    my $status_txt = Wx::TextCtrl->new( $self , -1, "Browser Status", wxDefaultPosition, [200,-1] , wxTE_READONLY );
    
    my $browser = $browserclass->new( $self , wxID_ANY, wxDefaultPosition, wxDefaultSize );
    
    $self->{STATUS} = $status_txt ;
    $self->{BROWSER} = $browser;
  
    $but_s->Add( $LoadUrl );
    $but_s->Add( $LoadString );
    $but_s->Add( $GoBack );
    $but_s->Add( $GoForward );
    $but_s->Add( $GoHome );
    $but_s->Add( $Refresh );
    $but_s->Add( $Stop );
    $but_s2->Add( $GoSearch );
    $but_s2->Add( $GetStringSelection );
    $but_s2->Add( $GetText );
    $but_s2->Add( $GetTextHTML );
    $but_s2->Add( $Print );
    $but_s2->Add( $PrintPreview );
    $but_s2->Add( $OpenDocument );
  
    $top_s->Add( $browser, 1, wxGROW|wxALL, 5 );
    $top_s->Add( $status_txt , 0, wxGROW|wxALL, 0);
    $top_s->Add( $but_s, 0, wxALL, 5 );
    $top_s->Add( $but_s2, 0, wxALL, 5 );
  
    $self->SetSizer( $top_s );
    $self->SetAutoLayout( 1 );
  
    EVT_BUTTON( $self, $LoadUrl, \&OnLoadUrl );
    EVT_BUTTON( $self, $LoadString, \&OnLoadString );
    EVT_BUTTON( $self, $GoBack, \&OnGoBack );
    EVT_BUTTON( $self, $GoForward, \&OnGoForward );
    EVT_BUTTON( $self, $GoHome, \&OnGoHome );
    EVT_BUTTON( $self, $GoSearch, \&OnGoSearch );
    EVT_BUTTON( $self, $Refresh, \&OnRefresh );
    EVT_BUTTON( $self, $Stop, \&OnStop );
    EVT_BUTTON( $self, $GetStringSelection, \&OnGetStringSelection );
    EVT_BUTTON( $self, $GetText, \&OnGetText );
    EVT_BUTTON( $self, $GetTextHTML, \&OnGetTextHTML );
    EVT_BUTTON( $self, $Print, \&OnPrint );
    EVT_BUTTON( $self, $PrintPreview, \&OnPrintPreview );
    EVT_BUTTON( $self, $OpenDocument, \&OnOpenDocument );
    
    EVT_ACTIVEX_BROWSER_NAVIGATECOMPLETE2($self, $browser, sub{
        my ( $obj , $evt ) = @_ ;
        my $url = $evt->{URL} ;
        Wx::LogStatus( "ACTIVEX_BROWSER NavigateComplete2 >> $url" );
    } );
   
    EVT_ACTIVEX($self, $browser, "BeforeNavigate2", sub{
        my ( $obj , $evt ) = @_ ;
        my $url = $evt->{URL} ;
        Wx::LogStatus( "ACTIVEX BeforeNavigate2 >> $url" );
    } );
    
    EVT_ACTIVEX_BROWSER_NEWWINDOW2($self, $browser, sub{
        my ( $obj , $evt ) = @_ ;  
        $evt->Veto ;
        Wx::LogStatus( "ACTIVEX_BROWSER NewWindow2 >> **Vetoed**" );
    }) ;
    
    EVT_ACTIVEX_BROWSER_STATUSTEXTCHANGE($self, $browser, sub{
        my ( $obj , $evt ) = @_ ;
        my $status = $self->{STATUS} ;
        $status->SetValue($evt->{Text});
    });
    
    return 1;
}

sub Query {
  my ( $self, $text_init , $width , $height , $multy) = @_ ;
  
  $width = 200 if (defined($width) && ($width < 20)) ;
  $height = -1 if (defined($height) && ($height < 1)) ;
  
  $width ||= 200;
  $height ||= -1;
  
  my $dialog = Wx::Dialog->new($self , -1 , "Query" , wxDefaultPosition, wxDefaultSize,) ;
  my $sizer = Wx::BoxSizer->new( wxHORIZONTAL );
  
  my $txt_flag = 0;
  if ( $multy ) { $txt_flag = $txt_flag|wxTE_MULTILINE ;}
  
  my $txt = Wx::TextCtrl->new( $dialog , -1 , $text_init , wxDefaultPosition , [$width,$height] , $txt_flag ) ;
  my $ok = Wx::Button->new($dialog, wxID_OK , 'OK');

  $sizer->Add( $txt );
  $sizer->Add( $ok ) ;
  
  $dialog->SetSizer( $sizer );
  $dialog->SetAutoLayout( 1 );  
  
  $sizer->Fit( $dialog );
  $sizer->SetSizeHints( $dialog );
  
  $dialog->ShowModal() ;
  
  my $val = $txt->GetValue() ;
  
  $dialog->Destroy() ;

  return( $val ) ;
}

sub OnPrint {
  my ($self, $event) = @_ ;
  $self->{BROWSER}->Print(1) ;
}

sub OnPrintPreview {
  my ($self, $event) = @_ ;
  $self->{BROWSER}->PrintPreview ;
}

sub OnLoadUrl {
  my ($self, $event) = @_ ;
  my $url = $self->Query("http://wxperl.sourceforge.net") ;
  $self->{BROWSER}->LoadUrl($url) ;
}

sub OnLoadString {
  my ($self, $event) = @_ ;
  my $html = $self->Query(q`<html>
<body bgcolor="#FFFFFF">
  <center><b>wxActiveX Browser Test</b></center>
</body>
</html>
`,400,300,1) ;
  $self->{BROWSER}->LoadString($html) ;

}

sub OnGoBack {
  my ($self, $event) = @_ ;
  $self->{BROWSER}->GoBack() ;

}

sub OnGoForward {
  my ($self, $event) = @_ ;
  $self->{BROWSER}->GoForward() ;

}

sub OnGoHome {
  my ($self, $event) = @_ ;
  $self->{BROWSER}->GoHome() ;

}

sub OnGoSearch {
  my ($self, $event) = @_ ;
  $self->{BROWSER}->GoSearch() ;

}

sub OnRefresh {
  my ($self, $event) = @_ ;
  $self->{BROWSER}->Refresh() ;

}

sub OnStop {
  my ($self, $event) = @_ ;
  $self->{BROWSER}->Stop() ;

}

sub OnGetStringSelection {
  my ($self, $event) = @_ ;
  my $val = $self->{BROWSER}->GetStringSelection() ;
  Wx::LogMessage( "GetStringSelection: $val" );
}

sub OnGetText {
  my ($self, $event) = @_ ;
  my $val = $self->{BROWSER}->GetText() ;
  my $html = $self->Query($val,400,300,1) ;
}

sub OnGetTextHTML {
  my ($self, $event) = @_ ;
  my $val = $self->{BROWSER}->GetText(1) ;
  my $html = $self->Query($val,400,300,1) ;
}

sub OnOpenDocument {
    my ($self, $event) = @_ ;
    
    #open_filename($prompt, $mustexist, $filters, $priorfile, $defaultpath) = @_;
    my $prompt = 'Please select a document to load';
    
    my $filename = $self->open_filename($prompt, 1);
    return if !$filename;   
    
    my $document = Wx::ActiveX::Document->OpenDocument($self->top_level_window, $filename);
    $document->AllowNavigate(0);
    
}

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX::IE;
#----------------------------------------------------
use strict;
use Wx qw();
use Wx::ActiveX::IE;
use base qw( Wx::DemoModules::wxActiveX::BrowserPanel );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->InitBrowser('Wx::ActiveX::IE');
    $self->{BROWSER}->LoadUrl('http://wxperl.sourceforge.net');
    return $self;
}

sub add_to_tags { qw(windows/activex) }
sub title { 'IE Browser' }
sub file { __FILE__ }

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX::Mozilla;
#----------------------------------------------------
use strict;
use Wx qw();
use Wx::ActiveX::Mozilla;
use base qw( Wx::DemoModules::wxActiveX::BrowserPanel );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    my $refor1 = $self->InitBrowser('Wx::ActiveX::Mozilla');
    if( ref $refor1) {
        return $refor1;
    } else {
        $self->{BROWSER}->LoadUrl('http://wxperl.sourceforge.net');
        return $self;
    }
}

sub add_to_tags { qw(windows/activex) }
sub title { 'Mozilla Browser' }
sub file { __FILE__ }

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX::Acrobat;
#----------------------------------------------------
use strict;
use Wx qw( :sizer wxID_ANY wxDefaultPosition wxDefaultSize wxSYS_COLOUR_BTNFACE );
use Wx::ActiveX::Acrobat qw( :acrobat );;
use base qw( Wx::DemoModules::wxActiveX );
use Wx::Event qw( EVT_BUTTON );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    
    $self->{acropdf} = Wx::ActiveX::Acrobat->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize );
    return $self if(!$self->test_activex( $self->{acropdf} ));
    
    
    $self->{btnLoad} = Wx::Button->new($self,wxID_ANY,'Load PDF',wxDefaultPosition, wxDefaultSize);
    $self->{btnPrint} = Wx::Button->new($self,wxID_ANY,'Print Dialog',wxDefaultPosition, wxDefaultSize);
    $self->{btnToggle} = Wx::Button->new($self,wxID_ANY,'Toggle Toolbar',wxDefaultPosition, wxDefaultSize);
     
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    my $panelsizer = Wx::BoxSizer->new(wxVERTICAL);
    $panelsizer->Add($self->{acropdf}, 1, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnLoad}, 0, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnPrint}, 0, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnToggle}, 0, wxALL|wxEXPAND, 3);
    $panelsizer->Add($buttonsizer, 0, wxALL|wxALIGN_RIGHT, 3);
    
    $self->SetSizer($panelsizer);
    
    EVT_BUTTON($self,$self->{btnLoad},\&on_event_button_load);
    EVT_BUTTON($self,$self->{btnPrint}, sub { shift->{acropdf}->Print(); shift->Skip(1); } );
    EVT_BUTTON($self,$self->{btnToggle},\&on_event_button_toggle);
    
    # don't inherit nbook backcolour
    $self->SetBackgroundColour( Wx::SystemSettings::GetColour(wxSYS_COLOUR_BTNFACE ) ); 
    $self->{_toolbartoggle} = 1;
    
    my $filename = Wx::Demo->get_data_file( 'activex/test.pdf' );
    
    $self->{acropdf}->Freeze();
    $self->{acropdf}->LoadFile($filename);
    $self->{acropdf}->SetShowToolbar($self->{_toolbartoggle});
    $self->{acropdf}->Thaw();
    
    $self->Layout;
    return $self;
}

sub on_event_button_load {
    my ($self, $event) = @_;
    $event->Skip(1);
    
    #$obj->open_filename ($prompt, $mustexist, $filters, $priorfile, $defaultpath) = @_;
    my $filename = $self->open_filename( 'Please Select a PDF File to Load',
                                         1,
                                         [ { text => 'PDF Files', mask => '*.pdf'}, ]
                                        );
    return if(!$filename );
    
    # freezing reduces screen redraw nastiness
    $self->{acropdf}->Freeze();
    $self->{acropdf}->LoadFile($filename);
    $self->{acropdf}->SetShowToolbar($self->{_toolbartoggle});
    $self->{acropdf}->Thaw();
    
}

sub on_event_button_toggle {
    my ($self, $event) = @_;
    $event->Skip(1);
    $self->{_toolbartoggle} = $self->{_toolbartoggle} ? 0 : 1;
    $self->{acropdf}->Freeze();
    $self->{acropdf}->SetShowToolbar($self->{_toolbartoggle});
    $self->{acropdf}->Thaw();
}

sub add_to_tags { qw(windows/activex) }
sub title { 'Acrobat Reader' }
sub file { __FILE__ }

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX::MediaPlayer;
#----------------------------------------------------
use strict;
use Wx qw( :sizer wxID_ANY wxDefaultPosition wxDefaultSize wxSYS_COLOUR_BTNFACE );
use Wx::ActiveX::WMPlayer qw(:mediaplayer);
use base qw( Wx::DemoModules::wxActiveX );
use Wx::Event qw( EVT_BUTTON );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->{wmp} = Wx::ActiveX::WMPlayer->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize );
    return $self if(!$self->test_activex( $self->{wmp} ));
    
    $self->{btnLoad} = Wx::Button->new($self,wxID_ANY,'Load Media File',wxDefaultPosition, wxDefaultSize);
   
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    my $panelsizer = Wx::BoxSizer->new(wxVERTICAL);
    $panelsizer->Add($self->{wmp}, 1, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnLoad}, 0, wxALL|wxEXPAND, 3);
    $panelsizer->Add($buttonsizer, 0, wxALL|wxALIGN_RIGHT, 3);
    
    $self->SetSizer($panelsizer);
    
    EVT_BUTTON($self,$self->{btnLoad},\&on_event_button_load);
    
    # don't inherit nbook backcolour
    $self->SetBackgroundColour( Wx::SystemSettings::GetColour(wxSYS_COLOUR_BTNFACE ) ); 
    
    $self->Layout;
    return $self;
}

sub on_event_button_load {
    my ($self, $event) = @_;
    $event->Skip(1);
    
    #$obj->open_filename ($prompt, $mustexist, $filters, $priorfile, $defaultpath) = @_;
    my $filename = $self->open_filename( 'Please Select a Media File to Load',
                                         1,
                                         [ { text => 'All Files', mask => '*.*'}, ]
                                        );
    return if(!$filename );
    
    $self->{wmp}->PropSet('URL', $filename) ;
    
}

sub add_to_tags { qw(windows/activex) }
sub title { 'Media Player' }
sub file { __FILE__ }

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX::Document;
#----------------------------------------------------
use strict;
use Wx qw( :sizer wxID_ANY wxDefaultPosition wxDefaultSize );
use Wx::ActiveX;
use base qw( Wx::DemoModules::wxActiveX );
use Wx::Event qw(EVT_BUTTON);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    
    $self->SetSizer( Wx::BoxSizer->new(wxVERTICAL) );
    
    $self->{lbl} = Wx::StaticText->new($self,
                                       wxID_ANY,
                                       "The Document Wrapper provides a simple way to load any doc type loadable by Internet Explorer into a Wx::Frame",
                                       wxDefaultPosition,
                                       wxDefaultSize,
                                       wxALIGN_CENTRE);
    
    $self->GetSizer->Add($self->{lbl}, 1, wxALL|wxEXPAND, 50);
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{btnDoc} = Wx::Button->new($self,wxID_ANY,'Open Document',wxDefaultPosition, wxDefaultSize);
    $buttonsizer->Add($self->{btnDoc}, 0, wxALL|wxEXPAND, 3);
    $self->GetSizer->Add($buttonsizer, 0, wxALL|wxALIGN_RIGHT, 3);
    
    EVT_BUTTON($self, $self->{btnDoc}, \&on_event_button_open);
    
    $self->Layout;

    return $self;
}

sub on_event_button_open {
    my ($self, $event) = @_ ;
    
    #open_filename($prompt, $mustexist, $filters, $priorfile, $defaultpath) = @_;
    my $prompt = 'Please select a document to load';
    
    my $filename = $self->open_filename($prompt, 1);
    return if !$filename;   
    
    my $document = Wx::ActiveX::Document->OpenDocument($self->top_level_window, $filename);
    $document->AllowNavigate(0);
}

sub add_to_tags { qw(windows/activex) }
sub title { 'Document Wrapper' }
sub file { __FILE__ }

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX::Flash;
#----------------------------------------------------
use strict;
use Wx qw( :sizer wxID_ANY wxDefaultPosition wxDefaultSize wxSYS_COLOUR_BTNFACE );
use Wx::ActiveX::Flash qw(:flash);
use base qw( Wx::DemoModules::wxActiveX );
use Wx::Event qw( EVT_BUTTON );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->{flash} = Wx::ActiveX::Flash->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize );
    return $self if(!$self->test_activex( $self->{flash} ));
    
    $self->{btnLoad} = Wx::Button->new($self,wxID_ANY,'Load SWF File',wxDefaultPosition, wxDefaultSize);
   
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    my $panelsizer = Wx::BoxSizer->new(wxVERTICAL);
    $panelsizer->Add($self->{flash}, 1, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnLoad}, 0, wxALL|wxEXPAND, 3);
    $panelsizer->Add($buttonsizer, 0, wxALL|wxALIGN_RIGHT, 3);
    
    $self->SetSizer($panelsizer);
    
    EVT_BUTTON($self,$self->{btnLoad},\&on_event_button_load);
    EVT_ACTIVEX_FLASH_FSCOMMAND($self, $self->{flash},\&on_event_fscommand);
    
    # don't inherit nbook backcolour
    $self->SetBackgroundColour( Wx::SystemSettings::GetColour(wxSYS_COLOUR_BTNFACE ) ); 
    
    $self->Layout;
    
    my $file = Wx::Demo->get_data_file( 'activex/dumy.swf' );
    $self->{flash}->LoadMovie(0, $file) ;
    $self->{flash}->Play ;
    
    return $self;
}

sub on_event_button_load {
    my ($self, $event) = @_;
    $event->Skip(1);
    
    #$obj->open_filename ($prompt, $mustexist, $filters, $priorfile, $defaultpath) = @_;
    my $filename = $self->open_filename( 'Please Select a SWF File to Load',
                                         1,
                                         [ { text => 'Flash Files', mask => '*.swf' }, ]
                                        );
    return if(!$filename );
    
    $self->{flash}->LoadMovie(0, $filename) ;
    $self->{flash}->Play ;
}

sub on_event_fscommand {
    my ( $self , $event ) = @_ ;
    $event->Skip(1);
    my $cmd = $event->{command} ;
    my $args = $event->{args} ;
    
    Wx::LogMessage("Flash FSCOMMAND %s : arguments; %s", $cmd, $args);
    
}

sub add_to_tags { qw(windows/activex) }
sub title { 'Adobe Shockwave' }
sub file { __FILE__ }

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX::QuickTime;
#----------------------------------------------------
use strict;
use Wx qw( :sizer wxID_ANY wxDefaultPosition wxDefaultSize wxSYS_COLOUR_BTNFACE );
use Wx::ActiveX::QuickTime qw(:quicktime);
use base qw( Wx::DemoModules::wxActiveX );
use Wx::Event qw( EVT_BUTTON );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->{quicktime} = Wx::ActiveX::QuickTime->new( $self, wxID_ANY, wxDefaultPosition, wxDefaultSize );
    return $self if(!$self->test_activex( $self->{quicktime} ));
    
    $self->{btnAbout} = Wx::Button->new($self,wxID_ANY,'About Control',wxDefaultPosition, wxDefaultSize);
    $self->{btnClose} = Wx::Button->new($self,wxID_ANY,'Close File',wxDefaultPosition, wxDefaultSize);
    $self->{btnLoad} = Wx::Button->new($self,wxID_ANY,'Open File',wxDefaultPosition, wxDefaultSize);
    
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    my $panelsizer = Wx::BoxSizer->new(wxVERTICAL);
    $panelsizer->Add($self->{quicktime}, 1, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnAbout}, 0, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnClose}, 0, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnLoad}, 0, wxALL|wxEXPAND, 3);
    $panelsizer->Add($buttonsizer, 0, wxALL|wxALIGN_RIGHT, 3);
    
    $self->SetSizer($panelsizer);
    
    EVT_BUTTON($self,$self->{btnLoad},\&on_event_button_load);
    EVT_BUTTON($self,$self->{btnAbout},\&on_event_button_about);
    EVT_BUTTON($self,$self->{btnClose},\&on_event_button_close);
   
    
    # don't inherit nbook backcolour
    $self->SetBackgroundColour( Wx::SystemSettings::GetColour(wxSYS_COLOUR_BTNFACE ) ); 
    
    $self->Layout;
    
    my $file = Wx::Demo->get_data_file( 'activex/sample.mov' );
    
    
    $self->{quicktime}->PropSet('URL', $file);
    $self->{quicktime}->PropSet('AutoPlay', 1);
    #$self->{quicktime}->ShowAboutBox;
    
    return $self;
}

sub on_event_button_load {
    my ($self, $event) = @_;
    $event->Skip(1);
    
    #$obj->open_filename ($prompt, $mustexist, $filters, $priorfile, $defaultpath) = @_;
    my $filename = $self->open_filename( 'Please Select a QuickTime File to Load',
                                         1,
                                         [ { text => 'All QuickTime Files', mask => '*.mov' }, ]
                                        );
    return if(!$filename );
    
    $self->{quicktime}->PropSet('URL', $filename);
    
}

sub on_event_button_about{
    my ($self, $event) = @_;
    $event->Skip(1);
    $self->{quicktime}->ShowAboutBox();
    
}

sub on_event_button_close{
    my ($self, $event) = @_;
    $event->Skip(1);
    $self->{quicktime}->PropSet('URL', '');
    
}


sub add_to_tags { qw(windows/activex) }
sub title { 'QuickTime ActiveX Control' }
sub file { __FILE__ }

#----------------------------------------------------
 package Wx::DemoModules::wxActiveX::ScriptControl;
#----------------------------------------------------
use strict;
use Wx qw( :sizer wxID_ANY wxNO_BORDER wxSYS_COLOUR_BTNFACE
           wxDefaultPosition wxDefaultSize wxICON_INFORMATION
           wxCENTRE wxID_CANCEL
           );
use Wx::ActiveX::ScriptControl qw(:scriptcontrol);
use base qw( Wx::DemoModules::wxActiveX );
use Wx::Event qw( EVT_BUTTON );

# the only real point to this module is if you plan to distribute
# a package and don't want to pack Win32::OLE for some reason.
# If you are looking for a general scripting solution then:

# my $scriptenv = Win32::OLE->new('WScript.Shell');
#
# is your friend.

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    
    $self->{script} = Wx::ActiveX::ScriptControl->newVersion( 1, $self, wxID_ANY, wxDefaultPosition, wxDefaultSize );

    return $self if(!$self->test_activex( $self->{script} ) );
    
    $self->{script}->PropSet('Language','VBScript');
    
    $self->{editor} = Wx::DemoModules::wxActiveX::ScriptControl::ScriptBox->new(
                        $self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxNO_BORDER);
    
    $self->{editor}->set_default_code();
    
    $self->{lblType} = Wx::StaticText->new($self,wxID_ANY,'Select Scripting Language',wxDefaultPosition, wxDefaultSize);
    $self->{chcType} = Wx::Choice->new($self,wxID_ANY,wxDefaultPosition, wxDefaultSize, ['VBScript']);
    $self->{btnRestore} = Wx::Button->new($self,wxID_ANY,'Restore Default Code',wxDefaultPosition, wxDefaultSize);
    $self->{btnEval} = Wx::Button->new($self,wxID_ANY,'Eval',wxDefaultPosition, wxDefaultSize);
    $self->{btnExecute} = Wx::Button->new($self,wxID_ANY,'Execute',wxDefaultPosition, wxDefaultSize);
    $self->{btnRun} = Wx::Button->new($self,wxID_ANY,'Run Script',wxDefaultPosition, wxDefaultSize);
   
    my $buttonsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    
    my $panelsizer = Wx::BoxSizer->new(wxVERTICAL);
    $panelsizer->Add($self->{editor}, 1, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{lblType}, 0, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{chcType}, 0, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnRestore}, 0, wxALL|wxEXPAND, 3);
    $buttonsizer->AddStretchSpacer(1);
    $buttonsizer->Add($self->{btnEval}, 0, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnExecute}, 0, wxALL|wxEXPAND, 3);
    $buttonsizer->Add($self->{btnRun}, 0, wxALL|wxEXPAND, 3);
    $panelsizer->Add($buttonsizer, 0, wxALL|wxEXPAND, 3);
    
    $self->SetSizer($panelsizer);
    
    EVT_BUTTON($self,$self->{btnRestore},\&on_event_button_restore);
    EVT_BUTTON($self,$self->{btnEval},\&on_event_button_eval);
    EVT_BUTTON($self,$self->{btnExecute},\&on_event_button_execute);
    EVT_BUTTON($self,$self->{btnRun},\&on_event_button_run);
    EVT_ACTIVEX_SCRIPTCONTROL_ERROR($self, $self->{script},\&on_event_scripterror);
    
    # don't inherit nbook backcolour
    $self->SetBackgroundColour( Wx::SystemSettings::GetColour(wxSYS_COLOUR_BTNFACE ) );
    $self->{chcType}->SetStringSelection('VBScript');
    
    $self->Layout;
    return $self;
}

sub on_event_button_restore {
    my ($self, $event) = @_;
    $event->Skip(1);
    $self->{editor}->set_default_code();
}

sub on_event_button_eval {
    my ($self, $event) = @_;
    $event->Skip(1);
    my $dialog = Wx::TextEntryDialog->new
        ( $self,
          "Enter a VBScript statement to evaluate.",
          "Wx::ActiveX - ScriptControl Evaluate Statement",
          "MsgBox (3 + 5) * 65 - 4"
        );
    
    my $statements;
    if( $dialog->ShowModal != wxID_CANCEL ) {
        $statements = $dialog->GetValue;
    }
    $dialog->Destroy;
    if($statements) {
        $self->{script}->Reset;
        my $result = $self->{script}->Invoke('Eval', $statements);
        Wx::MessageBox(qq(The answer was : Unobtainable),
                   "Wx::ActiveX - ScriptControl Evaluate Statement", 
                   wxICON_INFORMATION|wxCENTRE, $self);
    }
    
}

sub on_event_button_execute {
    my ($self, $event) = @_;
    $event->Skip(1);
    $self->{script}->Reset;
    $self->{script}->AddCode( $self->{editor}->GetText() );
    $self->{script}->ExecuteStatement('MsgBox "The Answer Is " & Pointless(),vbInformation, "Xtreme Pointlessness"');
}

sub on_event_button_run {
    my ($self, $event) = @_;
    $event->Skip(1);
    $self->{script}->Reset;
    $self->{script}->AddCode( $self->{editor}->GetText() );
    $self->{script}->Run('Start');
}

sub on_event_scripterror {
    my ($self, $event) = @_;
    $event->Skip(1);
    
    Wx::LogError("There is a Microsoft Script Control Error. Perhaps we should learn how to access it? Perhaps we won't bother.");
}

sub add_to_tags { qw(windows/activex) }
sub title { 'Microsoft Script Control' }
sub file { __FILE__ }

#----------------------------------------------------------------------
package Wx::DemoModules::wxActiveX::ScriptControl::ScriptBox;
#----------------------------------------------------------------------
use strict;
use Wx qw( :stc wxMODERN wxNORMAL wxRED );
use Wx::STC;
use base qw( Wx::StyledTextCtrl );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    # just VBScript for now
    $self->SetLexer( wxSTC_LEX_VBSCRIPT );
    $self->SetUseTabs(0);
    $self->SetTabWidth(4);
    $self->SetMarginType(0,wxSTC_MARGIN_NUMBER);
    $self->SetMarginWidth(0,20);
    $self->StyleSetFont(wxSTC_STYLE_DEFAULT, Wx::Font->new(10,wxMODERN,wxNORMAL,wxNORMAL,0));
    $self->StyleSetForeground(wxSTC_B_COMMENT,  Wx::Colour->new(0x00, 0x7f, 0x00));
    $self->StyleSetForeground(wxSTC_B_KEYWORD,  Wx::Colour->new(0x00, 0x00, 0xff));
    $self->StyleSetForeground(wxSTC_B_NUMBER,  Wx::Colour->new(0x7f, 0x00, 0x00));
    $self->StyleSetForeground(wxSTC_B_STRING,  Wx::Colour->new(0x7f, 0x00, 0x00));
    # what is this
    $self->StyleSetForeground(16,  wxRED);
    $self->StyleSetForeground(wxSTC_B_OPERATOR,  Wx::Colour->new(0, 127, 255));
    $self->SetEOLMode(wxSTC_EOL_CRLF );
    
    $self->apply_configuration();

    return $self;
}

sub apply_configuration {
    my $self = shift;   
    $self->SetKeyWords(0, $self->vbscript_keywords() );
    $self->Refresh();

}

sub vbscript_keywords {
    my $self = shift;
    
    my @keywords = qw(addressof alias and as attribute base begin binary boolean byref byte byval call case compare
        const currency date decimal declare defbool defbyte defint deflng defcur defsng defdbl defdec
        defdate defstr defobj defvar dim do double each else elseif empty end enum eqv erase error
        event exit explicit false for friend function get gosub goto if imp implements in input integer
        is len let lib like load lock long loop lset me mid midb mod msgbox new next not nothing null object
        on option optional or paramarray preserve print private property public raiseevent randomize
        redim rem resume return round rset seek select set single static step stop string sub then time to
        true type typeof unload until variant wend while with withevents xor
        );
        
    return join(" ", @keywords);
    
}

sub set_default_code {
    my $self = shift;
    my $code = qq('------------------------------------------------------------
'A VBScript Example
'------------------------------------------------------------
'Button 'Run Script' runs 'Start'
'Button 'Execute' runs a function named 'Pointless'
'Button 'Eval' allows you to enter an expression to evaluate
'------------------------------------------------------------

Sub Start()
    Dim message
    message = \"Do you really think there is an all\" & vbCrLf
    message = message & \"powerfull all seeing language out\" & vbCrlf
    message = message & \"there controlling everything I do?\"
    MsgBox message, vbExclamation, \"Microsoft Script Control - VBScript\"
End Sub

Function Pointless()
    Dim answer
    answer = 8 * 3
    MsgBox \"I'm pointless but the answer is " & answer
    Start
    Pointless = answer
End Function
);
    
    $self->ClearAll;
    $self->AddText($code);
}

1;
