#!/usr/bin/perl -w
#############################################################################
## Name:        example/psexample.pl
## Purpose:     example for Wx::Perl::ProcessStream
## Author:      Mark Dootson
## Modified by:
## Created:     25/03/2007
## Copyright:   (c) 2007 Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################
package ExecApp;
use Wx qw( :everything );
use base qw( Wx::App );

sub OnInit {
    my $self = shift;
    
    #----------------------------------------------------------------------
    # some non specific initialisation
    #----------------------------------------------------------------------

    Wx::InitAllImageHandlers;
    
    #----------------------------------------------------------------------
    # set application details
    #----------------------------------------------------------------------
    
    $self->SetAppName('My Exec Process Test Application');
    $self->SetVendorName('My Name');
    $self->SetClassName( $self->GetVendorName() . ' - ' . $self->GetAppName()  );
    
    #----------------------------------------------------------------------
    # create and show mainwindow
    #----------------------------------------------------------------------
    
    my $mwin = MainWindow->new(undef, -1); # parent = undef, ID = auto generated (-1)
    $self->SetTopWindow($mwin);
    $mwin->Centre;
    $mwin->Show(1);
    
    return 1;  
    
}

##########################

package main;

my $app = ExecApp->new();
$app->MainLoop;

########################## 

package MainWindow;
use Wx qw( :everything );
use Wx::Event qw( :everything );
use base qw( Wx::Frame );

use Wx::Perl::ProcessStream qw(
    EVT_WXP_PROCESS_STREAM_STDOUT
    EVT_WXP_PROCESS_STREAM_STDERR
    EVT_WXP_PROCESS_STREAM_EXIT
    wxpSIGKILL
    );

sub new {
    
    #----------------------------------------------------------------------
    # some defaults & SUPER constructor
    #----------------------------------------------------------------------
    
    $_[1] = undef                  if not exists $_[1];      # parent
    $_[2] = -1                     if not exists $_[2];      # id
    $_[3] = wxTheApp->GetAppName() if not exists $_[3];      # title
    $_[4] = wxDefaultPosition      if not exists $_[4];      # position
    $_[5] = wxDefaultSize          if not exists $_[5];      # size
    $_[6] = wxDEFAULT_FRAME_STYLE if not exists $_[6];      # style
   
    my $self = shift->SUPER::new(@_);
    
    $self->{menuindex} = {};
    $self->{menucount} = 0;
    $self->{controls} = {};
        
    #----------------------------------------------------------------------
    # menus with some keyboard shortcuts
    #----------------------------------------------------------------------
    
    my ($menu, $menuitem);
        
    # FILE MENU
    $menu = $self->add_menu('File', '&File');
    
    $menu->AppendSeparator();
    
    $menuitem = $self->add_menu_item('File', 'Exit', 'E&xit', \&evt_menu_file_exit);

    #----------------------------------------------------------------------
    # controls
    #----------------------------------------------------------------------
    
    # a panel as a parent for everything
    
    my $panelmain =  Wx::Panel->new($self, -1, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL|wxNO_BORDER);
    # Wx::Panel->new(parent, id, position, size, flags);
     
    # add a TextCtrl to enter command line plus a label
    my $commandlbl = Wx::StaticText->new($panelmain, -1, 'Command Line', wxDefaultPosition, wxDefaultSize );
    my $commandtext = Wx::TextCtrl->new($panelmain, -1, '', wxDefaultPosition, wxDefaultSize );
    my $pointsize = $commandtext->GetFont->GetPointSize();
    $commandtext->SetFont(Wx::Font->new($pointsize, wxMODERN, wxNORMAL, wxNORMAL )); # fixed pitch
        
    # add an 'Execute' button
    my $execbutton = Wx::Button->new($panelmain, -1, 'Execute', wxDefaultPosition, wxDefaultSize );
    
    # add a TextCtrl to display results
    my $resulttext = Wx::TextCtrl->new($panelmain, -1, '', wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE|wxTE_READONLY|wxTE_DONTWRAP);
    $pointsize = $resulttext->GetFont->GetPointSize();
    $resulttext->SetFont(Wx::Font->new($pointsize, wxMODERN, wxNORMAL, wxNORMAL )); # fixed pitch
    
    # store refs to the controls
    $self->add_control('PnlMain', $panelmain);
    $self->add_control('LblCommand', $commandlbl);
    $self->add_control('TxtCommand', $commandtext);
    $self->add_control('BtnExecute', $execbutton);
    $self->add_control('TxtResults', $resulttext);
    
    #------------------------------------------------------------------
    # Events
    #------------------------------------------------------------------
    
    EVT_BUTTON( $self, $self->get_control('BtnExecute'), \&evt_button_execute );
    EVT_WXP_PROCESS_STREAM_STDOUT( $self, \&evt_process_stdout);
    EVT_WXP_PROCESS_STREAM_STDERR( $self, \&evt_process_stderr);
    EVT_WXP_PROCESS_STREAM_EXIT( $self, \&evt_process_exit);
    
    Wx::Perl::ProcessStream->SetDefaultAppCloseAction( wxpSIGKILL );
    
    #----------------------------------------------------------------------
    # layout
    #----------------------------------------------------------------------
    
    my ($fillproportion, $flags, $bordersize);
    
    # create a main sizer for the frame
    $self->SetSizer( Wx::BoxSizer->new(wxVERTICAL) );
    
    $fillproportion = 1;
    $bordersize = 0;
    $flags = wxALL|wxEXPAND;
    
    $self->GetSizer->Add($panelmain, $fillproportion, $flags, $bordersize);
    
    # create a main sizer for the panel
    
    $panelmain->SetSizer( Wx::BoxSizer->new(wxVERTICAL) );
    
    # StaticBoxSizer for result text (framed box sizer with title)
    my $sizer_results = Wx::StaticBoxSizer->new(Wx::StaticBox->new($panelmain,-1,'Command Results'),wxVERTICAL);
    
    # FlexGridSizer for command text and label
    my $sizer_command = Wx::FlexGridSizer->new(0,2,0,10); # (rows, cols, vertical-spacing, horizontal-spacing)
                                                          # zero rows indicates grow dynamically
    $sizer_command->AddGrowableCol(1,1); # (column, proportion) - column index is zero based
    
    # BoxSizer for command buttons
    my $sizer_buttons = Wx::BoxSizer->new(wxHORIZONTAL);
    
        
    $fillproportion = 1;
    $bordersize = 3;
    $flags = wxALL|wxEXPAND;
    
    $sizer_command->Add($commandlbl, $fillproportion, $flags, $bordersize);
    $sizer_command->Add($commandtext, $fillproportion, $flags, $bordersize);
    $sizer_buttons->Add($execbutton, $fillproportion, $flags, $bordersize);
    $sizer_results->Add($resulttext, $fillproportion, $flags, $bordersize);
    
    $bordersize = 5;
    $panelmain->GetSizer->Add($sizer_command, 0, $flags, $bordersize);   
    
    $flags = wxALL|wxALIGN_RIGHT;
    $panelmain->GetSizer->Add($sizer_buttons, 0, $flags, $bordersize);
    
    $flags = wxALL|wxEXPAND;
    $panelmain->GetSizer->Add($sizer_results, $fillproportion, $flags, $bordersize);
    
    # layout the controls
    
    $self->SetAutoLayout(1);
    $self->Layout;
    
    # reference the panel using our method instead of scalar ref
    $self->get_control('PnlMain')->SetAutoLayout(1);
    $self->get_control('PnlMain')->Layout;
        
    # set a minimum size
    $self->SetSizeHints(500,400);
    
    # set default button
    $self->get_control('BtnExecute')->SetDefault();    
    
    # -- constructor complete
    return $self;
    
}


#----------------------------------------------------------------------
# Event Handlers
#----------------------------------------------------------------------

sub evt_menu_file_exit {
    my ($self, $event) = @_;
    $event->Skip(1);    # allow event to be processed by further handlers
    $self->Close;                    
}

sub evt_button_execute {
    my ($self, $event) = @_;
    $event->Skip(1);    # allow event to be processed by further handlers
    my $cmd = $self->get_control('TxtCommand')->GetValue();
    my $process = Wx::Perl::ProcessStream::Process->new($cmd, 'Perl Version', $self)->Run;
}

sub evt_process_stdout {
    my ($self, $event) = @_;
    $event->Skip(1);    # allow event to be processed by further handlers
    my $procname = $event->GetProcess->GetProcessName();
    my $line = $event->GetLine;
    my $apptext = '';
    $apptext .= qq(STDOUT: $procname: $line\n);
    $self->get_control('TxtResults')->AppendText($apptext);
}

sub evt_process_stderr {
    my ($self, $event) = @_;
    $event->Skip(1);    # allow event to be processed by further handlers
    my $procname = $event->GetProcess->GetProcessName();
    my $line = $event->GetLine;
    my $apptext = '';
    $apptext .= qq(STDERR: $procname: $line\n);
    $self->get_control('TxtResults')->AppendText($apptext);    
}

sub evt_process_exit {
    my ($self, $event) = @_;
    $event->Skip(1);    # allow event to be processed by further handlers
    
    my $exitcode = $event->GetProcess->GetExitCode();
    my $procname = $event->GetProcess->GetProcessName();
    $event->GetProcess->Destroy;
    my $apptext = qq(EXIT: $procname: $exitcode\n);
    $self->get_control('TxtResults')->AppendText($apptext);
}
    

#----------------------------------------------------------------------
# some crufty menu subs that save access to menus and controls for me
#----------------------------------------------------------------------

sub add_menu_item {
    my $self = shift;
    my ($menuname, $itemname, $itemstring, $coderef) = @_;
    $self->{menuitems}->{$menuname}->{$itemname} = Wx::MenuItem->new($self->{menus}->{$menuname}, -1, $itemstring, '', 0);
    $self->{menus}->{$menuname}->AppendItem($self->{menuitems}->{$menuname}->{$itemname});
    EVT_MENU($self, $self->{menuitems}->{$menuname}->{$itemname}->GetId(), $coderef);
    return $self->{menuitems}->{$menuname}->{$itemname};
}

sub add_menu {
    my $self = shift;
    my($menuname, $menustring) = @_;
    my $setmenubar = 0;
    if(!defined($self->{menubar})) {
        $self->{menubar}= Wx::MenuBar->new;
        $setmenubar = 1;
    }
    $self->{menus}->{$menuname} = Wx::Menu->new;
    $self->{menubar}->Append($self->{menus}->{$menuname},$menustring);  
    if($setmenubar) { $self->SetMenuBar($self->{menubar}); }
    $self->{menuindex}->{$menuname} = $self->{menucount};
    $self->{menucount} ++;
    return $self->{menus}->{$menuname};
}

sub add_submenu {
    my $self = shift;
    my($menuname, $submenuname, $submenustring) = @_;
    $self->{menus}->{$submenuname} = Wx::Menu->new;
    $self->{menus}->{$menuname}->AppendSubMenu($self->{menus}->{$submenuname}, $submenustring );
    $self->{menuindex}->{$menuname} = $self->{menucount};
    $self->{menucount} ++;
    return $self->{menus}->{$menuname};
}

sub add_control {
    my $self = shift;
    my ($controlname, $control) = @_;
    $self->{controls}->{$controlname} = $control;
}

sub get_control {
    my($self, $controlname) = @_;
    $self->{controls}->{$controlname};
}

1;
