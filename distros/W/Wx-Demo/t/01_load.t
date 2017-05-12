#!/usr/bin/perl -w

use strict;
use Test::More tests => 50;

use_ok( 'Wx::Demo' );
use_ok( 'Wx::DemoModules::lib::BaseModule' );
use_ok( 'Wx::DemoModules::lib::DataObjects' );
use_ok( 'Wx::DemoModules::wxBitmapButton' );
use_ok( 'Wx::DemoModules::wxBoxSizer' );
use_ok( 'Wx::DemoModules::wxCalendarCtrl' );
use_ok( 'Wx::DemoModules::wxCheckListBox' );
use_ok( 'Wx::DemoModules::wxChoice' );
use_ok( 'Wx::DemoModules::wxClipboard' );
use_ok( 'Wx::DemoModules::wxColourDialog' );
use_ok( 'Wx::DemoModules::wxComboBox' );
use_ok( 'Wx::DemoModules::wxDND' );
use_ok( 'Wx::DemoModules::wxDatePickerCtrl' );
use_ok( 'Wx::DemoModules::wxDirDialog' );
use_ok( 'Wx::DemoModules::wxFileDialog' );
use_ok( 'Wx::DemoModules::wxFlexGridSizer' );
use_ok( 'Wx::DemoModules::wxFontDialog' );
use_ok( 'Wx::DemoModules::wxGauge' );
use_ok( 'Wx::DemoModules::wxGrid' );
use_ok( 'Wx::DemoModules::wxGridCER' );
use_ok( 'Wx::DemoModules::wxGridER' );
use_ok( 'Wx::DemoModules::wxGridSizer' );
use_ok( 'Wx::DemoModules::wxGridTable' );
use_ok( 'Wx::DemoModules::wxHtmlDynamic' );
use_ok( 'Wx::DemoModules::wxHtmlTag' );
use_ok( 'Wx::DemoModules::wxHtmlWindow' );
use_ok( 'Wx::DemoModules::wxListBox' );
use_ok( 'Wx::DemoModules::wxListCtrl' );
use_ok( 'Wx::DemoModules::wxMDI' );

# naughty me...
defined &Wx::MediaCtrl::new || eval 'sub Wx::MediaCtrl::new { }';
# above line tells us in gui if Wx::MediaCtrl is missing
# SKIP below allows us to pass tests if it is missing or 
# has problems - (maybe wxWidgets doesnt have working 
# wxMediaCtrl support)

SKIP: {
    eval { require Wx::Media; };
    skip 'Wx::MediaCtrl load failed: '. $@, 1 if $@;
    use_ok( 'Wx::DemoModules::wxMediaCtrl' );
}

use_ok( 'Wx::DemoModules::wxMultiChoiceDialog' );
use_ok( 'Wx::DemoModules::wxPrinting' );
use_ok( 'Wx::DemoModules::wxProgressDialog' );
use_ok( 'Wx::DemoModules::wxRadioBox' );
use_ok( 'Wx::DemoModules::wxRadioButton' );
use_ok( 'Wx::DemoModules::wxScrollBar' );
use_ok( 'Wx::DemoModules::wxScrolledWindow' );
use_ok( 'Wx::DemoModules::wxSingleChoiceDialog' );
use_ok( 'Wx::DemoModules::wxSlider' );
use_ok( 'Wx::DemoModules::wxSpinButton' );
use_ok( 'Wx::DemoModules::wxSpinCtrl' );
use_ok( 'Wx::DemoModules::wxSplashScreen' );
use_ok( 'Wx::DemoModules::wxStaticBitmap' );
use_ok( 'Wx::DemoModules::wxStaticText' );
use_ok( 'Wx::DemoModules::wxTextEntryDialog' );
use_ok( 'Wx::DemoModules::wxTreeCtrl' );
use_ok( 'Wx::DemoModules::wxValidator' );
use_ok( 'Wx::DemoModules::wxWizard' );
use_ok( 'Wx::DemoModules::wxXrc' );
use_ok( 'Wx::DemoModules::wxXrcCustom' );
