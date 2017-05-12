#############################################################################
## Name:        lib/Wx/ActiveX/Template.pm
## Purpose:     Template Builder for ActiveX Control
## Author:      Mark Dootson
## Created:     2008-04-7
## SVN-ID:      $Id: Template.pm 2839 2010-03-11 09:14:17Z mdootson $
## Copyright:   (c) 2008 - 2010 Mark Dootson
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

#----------------------------------------------------------------------------
package Wx::ActiveX::Template;
#----------------------------------------------------------------------------
use strict;
use Exporter;
use base qw( Exporter );
use Wx;

our $VERSION = '0.15';

our @EXPORT = qw( run_wxactivex_template );

sub run_wxactivex_template {
    
    my $app = Wx::ActiveX::Template::App->new();
    $app->MainLoop();
    
}

#----------------------------------------------------------------------------
package Wx::ActiveX::Template::App;
#----------------------------------------------------------------------------
use strict;
use Wx qw( :everything );
use base qw( Wx::App );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    return $self;
}

sub OnInit {
    my $self = shift;
    
    # on init runs before our overridden class returns from new
    # so none of our class methods are available.
    # ( we are still in $self = $class->SUPER::new( @_ );  call )
    # Store stuff in hash.
    # i.e.
    # we must do $self->{_myconfig} = Wx::ConfigBase::Get;
    # we cannot do $self->SetConfig( Wx::ConfigBase::Get );
    # until new returns later.
    
    $self->SetAppName('Wx::ActiveX Control Class Templates');
    $self->SetVendorName('Mark Dootson');
    $self->SetClassName(  $self->GetVendorName() . '-' .  $self->GetAppName() );
    $self->{_myconfig} = Wx::ConfigBase::Get;

    my $mainwindow = Wx::ActiveX::Template::MainWindow->new();
    $self->SetTopWindow($mainwindow);
    $mainwindow->Show(1);
    return 1;
}

sub OnExit {
    my $self = shift;
    $self->GetConfig()->Flush;
}

sub GetConfig { shift->{_myconfig}; }

sub SetConfig { shift->{_myconfig} = @_; }

sub GetStandardTitle {
    my $self = shift;
    $self->GetAppName() . ' - Version ' .  $Wx::ActiveX::Template::VERSION;
}

#----------------------------------------------------------------------------
package Wx::ActiveX::Template::MainWindow;
#----------------------------------------------------------------------------
use strict;
use Wx qw( :everything );
use base qw ( Wx::Frame );

use Wx::Event qw( :everything );
use Wx::ActiveX;
use Wx::Perl::TextValidator;

sub new {
    my $class = shift;
    
    # construct
    my $self = $class->SUPER::new(
        undef,
        wxID_ANY,
        wxTheApp->GetStandardTitle,
        wxDefaultPosition,
        wxDefaultSize,
        wxDEFAULT_FRAME_STYLE
    );
    
    # menus
    {
        # - File Menu
        $self->add_menu('File', '&File');
        $self->add_menuitem('File', 'Query', '&Run Query', 'Run query against ActiveX interface',  \&on_menu_file_query, 'CTRL+R');
        $self->add_menuseparator('File');
        $self->add_menuitem('File', 'Exit', 'E&xit', 'Close Application',  \&on_menu_file_exit, '');
        
        # - Options Menu
        $self->add_menu('Options', '&Options');
        $self->add_menuitem('Options', 'Language', 'Select Lan&guage', 'Select language for application',  \&on_menu_options_lang, '');
        
        # - Help Menu
        $self->add_menu('Help', '&Help');
        $self->add_menuitem('Help', 'Contents', '&Help Contents',  'Display Help Contents', \&on_menu_help_contents, '');
        $self->add_menuseparator('Help');
        $self->add_menuitem('Help', 'About', '&About', 'Show Application About Box',  \&on_menu_help_about, '');
    }
    
    #controls
    {
        $self->{pnlMain} = Wx::Panel->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxNO_BORDER|wxTAB_TRAVERSAL );
        $self->{lblModuleName} = Wx::StaticText->new($self->{pnlMain}, wxID_ANY, 'Required Module Name', wxDefaultPosition, wxDefaultSize);
        $self->{txtModuleName} = Wx::TextCtrl->new($self->{pnlMain}, wxID_ANY, 'Wx::ActiveX::ACME', wxDefaultPosition, wxDefaultSize);
        $self->{lblPROGID} = Wx::StaticText->new($self->{pnlMain}, wxID_ANY, 'ActiveX Class To Query', wxDefaultPosition, wxDefaultSize);
        $self->{txtPROGID} = Wx::TextCtrl->new($self->{pnlMain}, wxID_ANY, 'ACMEWonderControls.DWIMControl', wxDefaultPosition, wxDefaultSize);
        $self->{lblCodeID} = Wx::StaticText->new($self->{pnlMain}, wxID_ANY, 'Code Identifier', wxDefaultPosition, wxDefaultSize);
        $self->{txtCodeID} = Wx::TextCtrl->new($self->{pnlMain}, wxID_ANY, 'ACME', wxDefaultPosition, wxDefaultSize);
        $self->{btnQuery} = Wx::Button->new($self->{pnlMain}, wxID_DEFAULT, 'Query', wxDefaultPosition, wxDefaultSize );
        $self->{nbkMain} = Wx::Notebook->new($self->{pnlMain}, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxNO_BORDER);
        $self->{pnlList} = Wx::Panel->new($self->{nbkMain}, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxNO_BORDER|wxTAB_TRAVERSAL );
        $self->{txtList} = Wx::TextCtrl->new($self->{pnlList}, wxID_ANY, '', wxDefaultPosition, wxDefaultSize, wxTE_READONLY|wxTE_MULTILINE);
        $self->{pnlStatic} = Wx::ActiveX::Template::CodePanel->new($self->{nbkMain});
        $self->{pnlDynamic} = Wx::ActiveX::Template::CodePanel->new($self->{nbkMain});
        $self->{nbkMain}->AddPage($self->{pnlList}, 'Interface Query');
        $self->{nbkMain}->AddPage($self->{pnlStatic}, 'Module Static Code Template' );
        $self->{nbkMain}->AddPage($self->{pnlDynamic}, 'Dynamic Event Template' );
    }
 
    # - layout & sizers
    {
        my $frameSizer = Wx::BoxSizer->new(wxVERTICAL);
        my $pnlMainSizer = Wx::BoxSizer->new(wxVERTICAL);
        my $pnlListSizer = Wx::BoxSizer->new(wxVERTICAL);
        my $querysizer = Wx::FlexGridSizer->new(2,4,3,3); #rows,cols,hgap,vgap
    
        # - size query controls at the top of frame{
        # row 0
        $querysizer->Add($self->{lblModuleName}, 0, wxALL, 3);
        $querysizer->Add($self->{lblPROGID}, 0, wxALL, 3);
        $querysizer->Add($self->{lblCodeID}, 0, wxALL, 3);
        $querysizer->AddSpacer(1);
        # row 1
        $querysizer->Add($self->{txtModuleName}, 0, wxALL|wxEXPAND, 3);
        $querysizer->Add($self->{txtPROGID}, 0, wxALL|wxEXPAND, 3);
        $querysizer->Add($self->{txtCodeID}, 0, wxALL, 3);
        $querysizer->Add($self->{btnQuery}, 0, wxALL, 3);
        
        $querysizer->AddGrowableCol(0,1);
        $querysizer->AddGrowableCol(1,1);
    
        # - size query list panel
        $pnlListSizer->Add($self->{txtList}, 1, wxALL|wxEXPAND, 3);
        $self->{pnlList}->SetSizer($pnlListSizer);
    
        # - main sizers for frame & main panel
        $pnlMainSizer->Add($querysizer, 0, wxALL|wxEXPAND, 5);
        $pnlMainSizer->Add($self->{nbkMain}, 1, wxALL|wxEXPAND, 5);
        $self->{pnlMain}->SetSizer($pnlMainSizer);
        $frameSizer->Add($self->{pnlMain},1, wxALL|wxEXPAND, 0);
    }

    # - frame size
    {
        # - min for Wx::TopLevelWindow
        $self->SetSizeHints(400,300);
        
        my $left   = wxTheApp->GetConfig()->Read('MainWindow/size/left',  'DEFAULT');
        my $top    = wxTheApp->GetConfig()->Read('MainWindow/size/top',   'DEFAULT');
        my $width  = wxTheApp->GetConfig()->Read('MainWindow/size/width', '640');
        my $height = wxTheApp->GetConfig()->Read('MainWindow/size/height','480');
        
        if($left eq 'DEFAULT') {
            # default
            $self->SetSize(0,0,$width,$height);
            $self->Centre;
        } else {
            $self->SetSize($left,$top,$width,$height);
        }
    }
    
    
    # Events
    {
        EVT_CLOSE($self, \&on_event_close);
        EVT_BUTTON($self, $self->{btnQuery}, \&on_button_query);
    }
    
    # Frame Setup
    {
        $self->SetIcon( Wx::GetWxPerlIcon() );
        $self->CreateStatusBar(2, wxST_SIZEGRIP, wxID_ANY );
    }
    
    return $self;
}

sub on_button_query {
    my ($self, $event) = @_;
    
    $self->run_query;
}


sub on_menu_file_query {
    my ($self, $event) = @_;
    
    $self->run_query;
}

sub on_menu_file_exit {
    my ($self, $event) = @_;
    
    $self->Close;
}

sub on_menu_options_lang {
    my ($self, $event) = @_;
    
    $self->__not_implemented;
}

sub on_menu_help_contents {
    my ($self, $event) = @_;
    
    $self->__not_implemented;
}

sub on_menu_help_about {
    my ($self, $event) = @_;
    
    my $info = Wx::AboutDialogInfo->new;

    $info->SetName( 'Wx::ActiveX Templates' );
    $info->SetVersion( $VERSION );
    $info->SetDescription( 'Code template creation for ActiveX modules.' );
    $info->SetCopyright( '(c) 2000 Mark Dootson <mdootson@cpan.org>' );

    Wx::AboutBox( $info );
}

sub __not_implemented {
    my $self = shift;
    Wx::MessageBox( 'This action is not yet implemented in the application.',
                 wxTheApp->GetStandardTitle(),
                  wxCENTRE,
                  $self
                );
}

sub on_event_close {
    my ($self, $event ) = @_;
    
    if(!$self->question_message(
        'Are you sure you wish to exit the application?'
            )
      )
    {
        $event->Skip(0);
        return;
    } 

    # propagate command event
    $event->Skip(1);
    # save size
    my($left,$top) = $self->GetPositionXY;
    my($width,$height) = $self->GetSizeWH;
    wxTheApp->GetConfig->Write('MainWindow/size/left',  $left);
    wxTheApp->GetConfig->Write('MainWindow/size/top',   $top);
    wxTheApp->GetConfig->Write('MainWindow/size/width', $width);
    wxTheApp->GetConfig->Write('MainWindow/size/height',$height);
}

sub add_menu {
    my( $self, $menuname, $labelno ) = @_;
    
    if( !$self->GetMenuBar() ) { $self->SetMenuBar( Wx::MenuBar->new() );  }
    
    $self->{menus}->{$menuname} = { items   => {},
                                    labelno => $labelno,
                                    menu    => Wx::Menu->new(),
                                };
    
    $self->GetMenuBar()->Append(
        $self->{menus}->{$menuname}->{menu},
        $self->{menus}->{$menuname}->{labelno}
    ); 
}

sub add_menuseparator {
    my( $self, $menuname ) = @_;
    $self->{menus}->{$menuname}->{menu}->AppendSeparator();
}

sub add_menuitem {
    my( $self, $menuname, $itemname, $labelno, $helpno, $coderef, $shortkeys ) = @_;
    
    my $menulabel = $labelno;
    $menulabel .= "\t" . $shortkeys if $shortkeys;
    
    my $helpstring = $helpno;
    my $menu = $self->{menus}->{$menuname}->{menu};
    
    my $menuitem = Wx::MenuItem->new($menu, -1, $menulabel, $helpstring, 0);
    
    $self->{menus}->{$menuname}->{items}->{$itemname} = { item => $menuitem,
                                                          labelno => $labelno,
                                                          helpno => $helpno,
                                                          shortkeys => $shortkeys,
                                                          };
    
    $menu->AppendItem($menuitem);
    EVT_MENU($self, $menuitem->GetId, $coderef );
    
}

sub info_message {
    my $self = shift;
    my $msg = shift;
    my $title = shift || wxTheApp->GetStandardTitle();
    Wx::MessageBox($msg,
                   $title, 
                   wxOK|wxICON_INFORMATION|wxCENTRE, $self);
}

sub question_message {
    my $self = shift;
    my $msg = shift;
    my $title = shift || wxTheApp->GetStandardTitle();
    if(Wx::MessageBox($msg,
                   $title, 
                   wxYES_NO|wxICON_QUESTION|wxCENTRE, $self) == wxYES) {
        return 1;
    } else {
        return 0;
    }
}

sub run_query {
    my $self = shift;
    
    my $busy = Wx::BusyCursor->new();
    
    my $modulename = $self->{txtModuleName}->GetValue();
    my $progid = $self->{txtPROGID}->GetValue();
    my $eventid = $self->{txtCodeID}->GetValue();
    $eventid ||= 'DEFMODNAME';
    $eventid = uc($eventid);
    my $exporttag = lc($eventid);
    
    # clear wins
    $self->{txtList}->SetValue('');
    $self->{pnlStatic}->set_text('');
    $self->{pnlDynamic}->set_text('');
    
    # get activex
    my ($activex, @events, @methods, @props);
    eval {
        $self->{activex} = undef;
        $self->{activex} = Wx::ActiveX->new($self, $progid, wxID_ANY, wxDefaultPosition, wxDefaultSize );
        @events = $self->{activex}->ListEvents;
        @methods = $self->{activex}->ListMethods_and_Args;
        @props = $self->{activex}->ListProps;
        $self->{activex}->Close;
        $self->{activex}->Destroy;
        $self->{activex} = undef;
    };
    if($@) {
        Wx::LogError("%s", $@);
        Wx::LogError('Unable to access ActiveX interface for' . '%s', $progid);
        
        return;
    }
    
    # got anything
    if( (@events == 0) && (@methods == 0) && (@props == 0) ) {
        $busy = undef;
        Wx::LogError('Unable to access ActiveX interface for' . '%s', $progid);
        return 1;
    }
    
    my @output = ();
    
    push @output, 'Events For' . ' ' . $progid;
    push @output, '';
    
    for (@events) {
        push @output, "\t" . $_;
    }
    
    push @output, '';
    push @output, 'Methods For' . ' ' . $progid;
    push @output, '';
    
    for (@methods) {
        push @output, "\t" . $_;
    }
    
    push @output, '';
    push @output, 'Properties For' . ' ' . $progid;
    push @output, '';
    
    for (@props) {
        push @output, "\t" . $_;
    }
    
    
    for (@output) {
        $self->{txtList}->AppendText( $_ . "\n" );
    }
    
    
    
    # STATIC CODE
    
    # create the event output code
    # proc expects a hash
    
    my $passeventlist = {};
    
    for my $activexname ( @events ) {
        
        my $key = $eventid . '_' . uc($activexname);
        $passeventlist->{$key} = $activexname;
    }
    
    my @eventcodelines = &Wx::ActiveX::activex_get_event_code(
                                        $modulename,
                                        $modulename,
                                        $eventid,
                                        $exporttag,
                                        'activex',
                                        1,
                                        $passeventlist, 1, 0 );
    
    my $staticcode = $self->standard_code_header();
    
    my $user = getlogin();
    my $dateyear = 0;
    {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        $dateyear = $year + 1900;
        $mon ++;
        my $date = $dateyear . '-' . sprintf("%02d", $mon ) . '-' . sprintf("%02d", $mday);
        my $packagefile = $modulename;
        $packagefile =~ s/::/\//g;
        $staticcode =~ s/HeadERamENDPAckAgeNAMe/$packagefile/g;
        $staticcode =~ s/HEAderLoginNaME/$user/g;
        $staticcode =~ s/HeadEARdateFormatEdYear/$dateyear/g;
        $staticcode =~ s/HeadEARdateFormatEdCreated/$date/g;
    }
 
    $staticcode =~ s/ModUlEPacKAgENaME/$modulename/g;
    $staticcode =~ s/ModuLEPROgiD/$progid/g;
    $staticcode =~ s/STOPCONFUSION//g;
    $staticcode =~ s/REPLpackageINST/package/g;
    
    my $dynamiccode = $staticcode;
    
    my $dynasubcode = $self->dynamic_code_subheader;
    
    my $dynamiceventlist = "\t" . join("\n\t", @events);
    
    $dynasubcode =~ s/ModUlExPORTtaG/$exporttag/g;
    $dynasubcode =~ s/ModUlEeVENTname/$eventid/g;
    $dynasubcode =~ s/INSERTDYNAMICEVENLIST/$dynamiceventlist/;
    
    $staticcode .= join("\n", @eventcodelines);
    
    my $staticfootercode = $self->standard_code_footer();
    
    $staticfootercode =~ s/ModUlEPacKAgENaME/$modulename/g;
    $staticfootercode =~ s/ModuLEPROgiD/$progid/g;
    $staticfootercode =~ s/ModUlEeVENTname/$eventid/g;
    
    my $exampleevent = uc($events[0]) || 'EXAMPLE';
    
    $staticfootercode =~ s/UCSamPLEeventNAme/$exampleevent/g;
    $exampleevent = lc($exampleevent);
    $staticfootercode =~ s/SamPLEeventNAme/$exampleevent/g;
    $staticfootercode =~ s/STOPCONFUSION//g;
    
    my $prneventlist = "\t" . join("\n\t", @events);
    my $prnmethodlist = "\t" . join("\n\t", @methods);
    my $prnpropertylist = "\t" . join("\n\t", @props);
    
    $staticfootercode =~ s/INSERTMODULEEVENTS/$prneventlist/g;
    $staticfootercode =~ s/INSERTMODULEMETHODS/$prnmethodlist/g;
    $staticfootercode =~ s/INSERTMODULEPROPERTIES/$prnpropertylist/g;
    
    # make up the event subs
    my $eventsubpod = '';
    for (@events) {
        $eventsubpod .= "\t" . 'EVT_ACTIVEX_' . $eventid . '_' . uc($_) . '( $evthandler, $activexcontrol, \&on_event_' . lc($eventid) . '_sub );' . "\n";
    }
    
    $staticfootercode =~ s/INSERTMODULEEVENTPOD/$eventsubpod/g;
    
    $staticfootercode =~ s/RePLAceModuleCOPYright/$dateyear  $user/g;
    
    
    $self->{pnlStatic}->set_text($staticcode . $staticfootercode );
    $self->{pnlDynamic}->set_text($dynamiccode . $dynasubcode . $staticfootercode );
    
}

sub standard_code_header {
    my $self = shift;
    # needs to go in a data file. This is horrible
    my $code = q(#######################################################################
## Name:        HeadERamENDPAckAgeNAMe.pm
## Purpose:     ActiveX Interface for ModuLEPROgiD
## Author:      HEAderLoginNaME
## Created:     HeadEARdateFormatEdCreated
## Copyright:   (c) HeadEARdateFormatEdYear  HEAderLoginNaME
## Licence:     This program is free software; you can redistribute it
##              and/or modify it under the same terms as Perl itself
#######################################################################

#----------------------------------------------------------------------
STOPCONFUSION REPLpackageINST ModUlEPacKAgENaME;
#----------------------------------------------------------------------

use strict;
use Wx qw( :misc );
use Wx::ActiveX;
use base qw( Wx::ActiveX );

our $VERSION = '0.01';

our (@EXPORT_OK, %EXPORT_TAGS);
$EXPORT_TAGS{everything} = \@EXPORT_OK;

my $PROGID = 'ModuLEPROgiD';);
    return $code;
}

sub dynamic_code_subheader {
    my $self = shift;
    # needs to go in a data file. This is horrible
    my $code = q(
my $exporttag = 'ModUlExPORTtaG';
my $eventname = 'ModUlEeVENTname';

#-----------------------------------------------
# Export event classes
#-----------------------------------------------

our @activexevents = qw (
INSERTDYNAMICEVENLIST
);

our %standardevents = ();

# __PACKAGE__->activex_load_standard_event_types( $export_to_namespace, $eventidentifier, $exporttag, $elisthashref );
# __PACKAGE__->activex_load_activex_event_types( $export_to_namespace, $eventidentifier, $exporttag, $elistarrayref );

__PACKAGE__->activex_load_activex_event_types( __PACKAGE__, $eventname, $exporttag, \@activexevents );
);
    
    return $code;

}


sub standard_code_footer {
    my $self = shift;
    # needs to go in a data file. This is horrible
    my $code = q(

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


STOPCONFUSION__END__

STOPCONFUSION=head1 NAME

ModUlEPacKAgENaME - interface to ModuLEPROgiD ActiveX Control

STOPCONFUSION=head1 SYNOPSIS

    use ModUlEPacKAgENaME qw( :everything );
    
    ..........
    
    my $activex = ModUlEPacKAgENaME->new( $parent );
    
    OR
    
    my $activex = ModUlEPacKAgENaME->newVersion( 1, $parent );
    
    EVT_ACTIVEX_ModUlEeVENTname_UCSamPLEeventNAme( $handler, $activex, \&on_event_SamPLEeventNAme );

STOPCONFUSION=head1 DESCRIPTION

Interface to ModuLEPROgiD ActiveX Control

STOPCONFUSION=head1 METHODS

STOPCONFUSION=head2 new

    my $activex = ModUlEPacKAgENaME->new(
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of ModUlEPacKAgENaME. Only $parent is mandatory.
$parent must be derived from Wx::Window (e.g. Wx::Frame, Wx::Panel etc).
This constructor creates an instance using the latest version available
of ModuLEPROgiD.

STOPCONFUSION=head2 newVersion

    my $activex = ModUlEPacKAgENaME->newVersion(
                        $version
                        $parent,
                        $windowid,
                        $position,
                        $size,
                        $style,
                        $name);

Returns a new instance of ModUlEPacKAgENaME. $version and $parent are
mandatory. $parent must be derived from Wx::Window (e.g. Wx::Frame,
Wx::Panel etc). This constructor creates an instance using the specific
type library specified in $version of ModuLEPROgiD.

e.g. $version = 4;

will produce an instance based on the type library for

ModuLEPROgiD.4

STOPCONFUSION=head1 EVENTS

The module provides the following exportable event subs

INSERTMODULEEVENTPOD

STOPCONFUSION=head1 ACTIVEX INFO

STOPCONFUSION=head2 Events

INSERTMODULEEVENTS

STOPCONFUSION=head2 Methods

INSERTMODULEMETHODS

STOPCONFUSION=head2 Properties

INSERTMODULEPROPERTIES

STOPCONFUSION=head1 COPYRIGHT & LICENSE

Copyright (C) RePLAceModuleCOPYright

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

STOPCONFUSION=cut

# end file
);
    return $code;
}

#----------------------------------------------------------------------------
package Wx::ActiveX::Template::CodePanel;
#----------------------------------------------------------------------------

use strict;
use Wx qw( :everything );
use base qw( Wx::Panel );


sub new {
    my $class = shift;
    my $parent = shift;
    my $self = $class->SUPER::new($parent, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxNO_BORDER|wxTAB_TRAVERSAL);
    
    $self->{stcScript} = Wx::ActiveX::Template::CodeControl->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, wxSIMPLE_BORDER );
    
    my $panelsizer = Wx::BoxSizer->new(wxVERTICAL);
    $panelsizer->Add($self->{stcScript},1,wxALL|wxEXPAND, 3);
    
    $self->SetSizer($panelsizer);
    $self->Layout;
    
    return $self;
}

sub set_script {
    my( $self, $script ) = @_;
    $self->{_scriptname} = $script->{name};
    $self->{_scriptid} = $script->{id};
    $self->{_scriptnotes} = $script->{notes};
    $self->{_scriptgroups} = $script->{groups};
    $self->{_scripttext} = $script->{script};
    $self->{stcScript}->ClearAll;
    $self->{_scriptloading} = 1;
    $self->{stcScript}->AddText($self->{_scripttext});
    $self->{_scriptloading} = 0;
}

sub script_name {
    return shift->{_scriptname};
}

sub script_id {
    return shift->{_scriptid};
}

sub script_notes {
    return shift->{_scriptnotes};
}

sub script_groups {
    return shift->{_scriptnotes};
}

sub get_text {
    my $self = shift;
    $self->{stcScript}->ConvertEOLs(wxSTC_EOL_CRLF);
    my $scripttext = $self->{stcScript}->GetText();
    return $scripttext;
}

sub set_text {
    my $self = shift;
    my $text = shift;
    $self->{stcScript}->ClearAll;
    $self->{stcScript}->AddText($text);
    $self->{stcScript}->ConvertEOLs(wxSTC_EOL_CRLF);
}

#----------------------------------------------------------------------------
package Wx::ActiveX::Template::CodeControl;
#----------------------------------------------------------------------------

use strict;
use Wx::STC;
use Wx qw( :font :stc );

use base qw( Wx::StyledTextCtrl );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    
    $self->SetLexer( wxSTC_LEX_PERL );
    $self->SetUseTabs(0);
    $self->SetTabWidth(4);
    $self->StyleSetFont(wxSTC_STYLE_DEFAULT, Wx::Font->new(10,wxMODERN,wxNORMAL,wxNORMAL,0));
    $self->StyleSetForeground(wxSTC_PL_COMMENTLINE,  Wx::Colour->new(0x00, 0x7f, 0x00));
    $self->StyleSetForeground(wxSTC_PL_POD,  Wx::Colour->new(0x00, 0x7f, 0x00));
    $self->StyleSetForeground(wxSTC_PL_WORD,  Wx::Colour->new(0x00, 0x00, 0x7f));
    $self->StyleSetForeground(wxSTC_PL_NUMBER,  Wx::Colour->new(0x7f, 0x00, 0x00));
    $self->StyleSetForeground(wxSTC_PL_STRING,  Wx::Colour->new(0x7f, 0x00, 0x00));
    $self->StyleSetForeground(wxSTC_PL_OPERATOR,  Wx::Colour->new(0, 127, 255));
    $self->SetEOLMode(wxSTC_EOL_CRLF );
    return $self;
}


1;

__END__


=head1 NAME

Wx::ActiveX::Template - ActiveX Control Module Creation Utility

=head1 VERSION

Version 0.15

=head1 SYNOPSIS

    wxactivex_template
    
    or
    
    perl -MWx::ActiveX::Template -e"run_wxactivex_template();"

=head1 DESCRIPTION

Utility to create module code for new ActiveX control interfaces.
The module for QuickTime was created using this utility.

Start the GUI using one of the above methods, enter the required
module name, ActiveX Control ProgID and a code identifier, and
query the interface to produce module code.

The code identifier is used to uniquely name the subroutines.

For example, if your ActiveX control has an event called
'OnRefresh' and you specify 'MYCONTROL' as the code identifier,
this would produce template code for:

EVT_ACTIVEX_MYCONTROL_ONREFRESH

If you query an interface that cannot be used within an ActiveX
Container, (it is not an ActiveX Control) then this will most likely
cause the Perl Interpreter to crash. This is harmless, if annoying.

=head1 TODO

Enumerate available ActiveX Controls on the system and present a
pick list rather than accepting freeform input.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008 - 2010 Mark Dootson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

# end of file




