#############################################################################
## Name:        lib/Wx/DemoModules/wxLocal.pm
## Purpose:     wxPerl demo helper for Wx::Locale
## Author:      Mark Dootson
## Modified by:
## Created:     2008-04-14
## svn-ID:      $Id: $
## Copyright:   (c) 2008 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxLocale;

use strict;
use Wx qw( :window :misc :id :sizer :locale :dialog :textctrl);
use Wx::Event qw( EVT_MENU );
use base qw(Wx::Panel);
use Wx::Locale( gettext => 't');


sub new {
    my( $class, $parent ) = @_;
    my $self = $class->SUPER::new( $parent, wxID_ANY, wxDefaultPosition,
                                   wxDefaultSize, wxBORDER_SUNKEN );
                                   
    $self->{lblText} = Wx::StaticText->new(
        $self, 
        wxID_ANY, 
        'Default', # write actual labels elsewhere
        wxDefaultPosition,
        wxDefaultSize);
        
    $self->{lblNumber} = Wx::StaticText->new(
        $self, 
        wxID_ANY, 
        'Number', # write actual labels elsewhere
        wxDefaultPosition,
        wxDefaultSize);        
        
    $self->{txtNumber} = Wx::TextCtrl->new($self, 
        wxID_ANY, 
        '1000000.00', # write actual labels elsewhere
        wxDefaultPosition,
        wxDefaultSize,
        wxTE_READONLY|wxTE_CENTRE);        
        
    $self->{lblDate} = Wx::StaticText->new(
        $self, 
        wxID_ANY, 
        'Time Now', # write actual labels elsewhere
        wxDefaultPosition,
        wxDefaultSize);        
        
    $self->{txtDate} = Wx::TextCtrl->new($self, 
        wxID_ANY, 
        'Date', # write actual labels elsewhere
        wxDefaultPosition,
        wxDefaultSize,
        wxTE_READONLY|wxTE_CENTRE);
    
        
    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    my $fsizer = Wx::FlexGridSizer->new(2,2,5,5);
    $fsizer->AddGrowableCol(1,1);
    $fsizer->Add($self->{lblNumber}, 0, wxALL|wxEXPAND, 5);
    $fsizer->Add($self->{txtNumber}, 1, wxALL|wxEXPAND, 5);
    
    $fsizer->Add($self->{lblDate}, 0, wxALL|wxEXPAND, 5);
    $fsizer->Add($self->{txtDate}, 1, wxALL|wxEXPAND, 5);
    
    
    $sizer->Add($self->{lblText}, 1, wxALL|wxEXPAND, 20);
    $sizer->Add($fsizer, 0, wxALL|wxEXPAND, 20);
    $self->SetSizer($sizer);
    $self->create_menu;
    
    # get the default language
    my $langid = Wx::Locale::GetSystemLanguage;
    
    $self->refresh_locale($langid);
    
    return $self;
}


sub refresh_locale {
    my($self, $langid) = @_;
    
    my $locale = Wx::Locale->new($langid);
    my $pathcheck = Wx::Demo->get_data_file( 'locale' );
    $locale->AddCatalogLookupPathPrefix( $pathcheck );
    my $langname = $locale->GetCanonicalName();
    
    my $shortname = $langname ? substr($langname,0,2) : 'en'; # we are only providing default sublangs
    
    my $filename = qq($pathcheck/$shortname.mo);
      
    
    $locale->AddCatalog( $shortname ) if -f $filename;
    
    # all menu labels and currently loaded strings
    
    # menu items
    
    $self->{menu}->[1]->SetLabel(
        $self->{menuitems}->{'Locale/Select Language'},
        t("Select Language\tCtrl+S") );
    
    # menu labels
    
    my $top = Wx::GetTopLevelParent( $self );
    
    my $menuindex = $top->GetMenuBar()->FindMenu($self->{menutitles}->{'Locale'});
    my $menulabel = t("&Locale");
    $top->GetMenuBar()->SetLabelTop( $menuindex, $menulabel );
    $self->{menutitles}->{'Locale'} = $menulabel;
    
    
    # currently loaded labels
    
    $self->{lblText}->SetLabel(t("Translations from English provided by Google. Please use the menu to select a different locale."));
    $self->{lblDate}->SetLabel(t("Time Now"));
    $self->{lblNumber}->SetLabel(t("Number"));


    # language dialog strings
    
    $self->{langdialogstrs} = { 
        title => t('Wx::Locale Example'),
        msg => t('Select the required application language'),
        choices => [ t('English'),
                    t('French'),
                    t('Italian'),
                    t('German'),
                    t('Spanish'),
                    ],
        data => [ wxLANGUAGE_ENGLISH, wxLANGUAGE_FRENCH, wxLANGUAGE_ITALIAN, wxLANGUAGE_GERMAN, wxLANGUAGE_SPANISH ],
    };
    
    
    # the date
    
    my $date = Wx::DateTime::Now();
    $self->{txtDate}->ChangeValue( $date->FormatDate() . '  ' .  $date->FormatTime());
    
    # the number
    
    $self->{txtNumber}->ChangeValue( sprintf("%.2f", 100.45) );
    
    $self->Layout;
 
}

sub on_event_language {
    my( $self, $event) = @_;
    
    # single select dialog for en, fr, de, it, es
    
    my $langid = Wx::GetSingleChoiceData(
        $self->{langdialogstrs}->{msg},
        $self->{langdialogstrs}->{title},
        $self->{langdialogstrs}->{choices},
        $self->{langdialogstrs}->{data},
        $self );
    
    
    
    $self->refresh_locale($langid) if $langid;
    
}

sub create_menu {
    my( $self ) = @_;

    my $top = Wx::GetTopLevelParent( $self );
    my $menu = Wx::Menu->new;
    
    $self->{menuitems}->{'Locale/Select Language'} = 
        $menu->Append( -1, 'Item1' )->GetId;
    
    
    EVT_MENU( 
        $top, 
        $self->{menuitems}->{'Locale/Select Language'},
        sub { $self->on_event_language($_[1]); } );
        
    my $menutitle = t("&Locale");
     
    $self->{menu} = [ $menutitle, $menu ];
    $self->{menutitles}->{'Locale'} = $menutitle;
}

sub menu { @{$_[0]->{menu}} }

sub noop {
    # get some translations for wxWidgets internal strings
    t("ok");
    t("cancel");
    t("ctrl");
}

sub add_to_tags { qw(misc) }
sub title { 'wxLocale' }

1;
