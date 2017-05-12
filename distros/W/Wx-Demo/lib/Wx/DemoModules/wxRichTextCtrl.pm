#############################################################################
## Name:        lib/Wx/DemoModules/wxRichTextCtrl.pm
## Purpose:     wxPerl demo helper for Wx::SpinCtrl
## Author:      Mattia Barbon
## Modified by:
## Created:     11/11/2006
## RCS-ID:      $Id: wxRichTextCtrl.pm 3043 2011-03-21 17:25:36Z mdootson $
## Copyright:   (c) 2006, 2010 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxRichTextCtrl;

use strict;
BEGIN { eval { require Wx::RichText; } }
use base qw(Wx::DemoModules::lib::BaseModule Class::Accessor::Fast);

use Wx qw(:richtextctrl :textctrl :font :sizer :color);
# use Wx::Event qw(EVT_SPINCTRL EVT_SPIN EVT_SPIN_DOWN EVT_SPIN_UP);

__PACKAGE__->mk_accessors( qw(richtext stylesheet control preview) );

sub DESTROY {
    my( $self ) = @_;

    $self->stylesheet( undef );
}

sub expandinsizer { 1 };

sub commands {
    my( $self ) = @_;

    my @commands =  ( { with_value  => 0,
               label       => 'Add styled text',
               action      => \&add_styled_text,
               },
                    );
    
    push(@commands,
             ( { with_value  => 0,
               label       => 'Print Preview',
               action      => \&print_preview,
               },
               { with_value  => 0,
               label       => 'Page Setup',
               action      => \&page_setup,
               },
             )
               
    ) if defined(&Wx::RichTextPrinting::new);
    
    return @commands;
}

sub create_control {
    my( $self ) = @_;

    my $panel = Wx::Panel->new( $self, -1 );
    my $richtext = Wx::RichTextCtrl->new( $panel, -1, 'Rich text', [-1, -1],
                                          [400, 300] );
    my $stylectrl = Wx::RichTextStyleListCtrl->new( $panel, -1, [-1, -1],
                                                    [100, -1]);
    $self->richtext( $richtext );
    
    if(defined(&Wx::RichTextPrinting::new)) {
        my $parent = Wx::GetTopLevelParent($self);
        my $preview = Wx::RichTextPrinting->new('Wx::Demo Printing', $parent);
        $self->preview( $preview );
    }
    

    my $sizer = Wx::BoxSizer->new( wxHORIZONTAL );

    $sizer->Add( $stylectrl, 0, wxGROW|wxALL, 5 );
    $sizer->Add( $richtext, 1, wxGROW|wxALL, 5 );

    $panel->SetSizerAndFit( $sizer );

    $self->stylesheet( $self->create_style_sheet );
    $stylectrl->SetRichTextCtrl( $richtext );
    $stylectrl->SetStyleSheet( $self->stylesheet );
    $stylectrl->GetStyleListBox->SetApplyOnSelection( 1 );
    $stylectrl->UpdateStyles;

    $self->control( $panel );

    return $panel;
}

sub create_style_sheet {
    my( $self ) = @_;

    my $charstyle1 = Wx::RichTextCharacterStyleDefinition->new( "red" );
    my $charstyle2 = Wx::RichTextCharacterStyleDefinition->new( "italic blue" );
    my $parstyle1 = Wx::RichTextParagraphStyleDefinition->new( "bold red" );
    my $parstyle2 = Wx::RichTextParagraphStyleDefinition->new( "indented" );
    my $liststyle1 = Wx::RichTextListStyleDefinition->new( "numbered" );
    my $liststyle2 = Wx::RichTextListStyleDefinition->new( "symbols" );

    my $stylesheet = Wx::RichTextStyleSheet->new;

    my $attr;

    $attr = Wx::RichTextAttr->new;
    $attr->SetTextColour( wxRED );
    $charstyle1->SetStyle( $attr );

    $attr = Wx::RichTextAttr->new;
    $attr->SetTextColour( wxBLUE );
    $attr->SetFontStyle( wxITALIC );
    $charstyle2->SetStyle( $attr );

    $attr = Wx::RichTextAttr->new;
    $attr->SetTextColour( wxRED );
    $attr->SetFontStyle( wxBOLD );
    $parstyle1->SetStyle( $attr );

    $attr = Wx::RichTextAttr->new;
    $attr->SetLeftIndent( 100, 200 );
    $attr->SetRightIndent( 200 );
    $parstyle2->SetStyle( $attr );

    $attr = Wx::RichTextAttr->new;
    $attr->SetTextColour( wxRED );
    $liststyle1->SetStyle( $attr );
    $liststyle1->SetAttributes( 0, 50, 70, wxTEXT_ATTR_BULLET_STYLE_ARABIC );
    $liststyle1->SetAttributes( 1, 50, 70, wxTEXT_ATTR_BULLET_STYLE_ROMAN_UPPER );
    $liststyle1->SetAttributes( 2, 50, 70, wxTEXT_ATTR_BULLET_STYLE_ROMAN_LOWER );

    $liststyle2->SetAttributes( 0, 50, 70, wxTEXT_ATTR_BULLET_STYLE_SYMBOL, "*" );
    $liststyle2->SetAttributes( 1, 50, 70, wxTEXT_ATTR_BULLET_STYLE_SYMBOL, "-" );
    $liststyle2->SetAttributes( 2, 50, 70, wxTEXT_ATTR_BULLET_STYLE_SYMBOL, "+" );
    $liststyle2->SetAttributes( 3, 50, 70, wxTEXT_ATTR_BULLET_STYLE_SYMBOL, "*" );
    $liststyle2->SetAttributes( 4, 50, 70, wxTEXT_ATTR_BULLET_STYLE_SYMBOL, "-" );

    $stylesheet->AddCharacterStyle( $charstyle1 );
    $stylesheet->AddCharacterStyle( $charstyle2 );
    $stylesheet->AddParagraphStyle( $parstyle1 );
    $stylesheet->AddParagraphStyle( $parstyle2 );
    $stylesheet->AddListStyle( $liststyle1 );
    $stylesheet->AddListStyle( $liststyle2 );

    return $stylesheet;
}

sub add_styled_text {
    my( $self ) = @_;
    my $r = $self->richtext;

    my $textFont = Wx::Font->new( 12, wxROMAN, wxNORMAL, wxNORMAL );
    my $boldFont = Wx::Font->new( 12, wxROMAN, wxNORMAL, wxBOLD );
    my $italicFont = Wx::Font->new( 12, wxROMAN, wxITALIC, wxNORMAL );
    my $font = Wx::Font->new( 12, wxROMAN, wxNORMAL, wxNORMAL );

    $r->BeginSuppressUndo;
    $r->BeginParagraphSpacing(0, 20);
    $r->BeginAlignment(wxTEXT_ALIGNMENT_CENTRE);
    $r->BeginBold;
    $r->BeginFontSize(14);
    $r->WriteText("Welcome to wxRichTextCtrl, a wxWidgets control for editing and presenting styled text and images");
    $r->EndFontSize;
    $r->Newline;
    $r->BeginItalic;
    $r->WriteText("by Julian Smart");
    $r->EndItalic;
    $r->EndBold;
    $r->Newline;
#    $r->WriteImage(wxBitmap(zebra_xpm));
    $r->EndAlignment;
    $r->Newline;
    $r->Newline;
    $r->WriteText("What can you do with this thing? ");
#    $r->WriteImage(wxBitmap(smiley_xpm));
    $r->WriteText(" Well, you can change text ");
    $r->BeginTextColour(Wx::Colour->new(255, 0, 0));
    $r->WriteText("colour, like this red bit.");
    $r->EndTextColour;
    $r->BeginTextColour(Wx::Colour->new(0, 0, 255));
    $r->WriteText(" And this blue bit.");
    $r->EndTextColour;
    $r->WriteText(" Naturally you can make things ");
    $r->BeginBold;
    $r->WriteText("bold ");
    $r->EndBold;
    $r->BeginItalic;
    $r->WriteText("or italic ");
    $r->EndItalic;
    $r->BeginUnderline;
    $r->WriteText("or underlined.");
    $r->EndUnderline;
    $r->BeginFontSize(14);
    $r->WriteText(" Different font sizes on the same line is allowed, too.");
    $r->EndFontSize;
    $r->WriteText(" Next we'll show an indented paragraph.");
    $r->BeginLeftIndent(60);
    $r->Newline;
    $r->WriteText("Indented paragraph.");
    $r->EndLeftIndent;
    $r->Newline;
    $r->WriteText("Next, we'll show a first-line indent, achieved using BeginLeftIndent(100, -40).");
    $r->BeginLeftIndent(100, -40);
    $r->Newline;
    $r->WriteText("It was in January, the most down-trodden month of an Edinburgh winter.");
    $r->EndLeftIndent;
    $r->Newline;
    $r->WriteText("Numbered bullets are possible, again using subindents:");
    $r->BeginNumberedBullet(1, 100, 60);
    $r->Newline;
    $r->WriteText("This is my first item. Note that wxRichTextCtrl doesn't automatically do numbering, but this will be added later.");
    $r->EndNumberedBullet;
    $r->BeginNumberedBullet(2, 100, 60);
    $r->Newline;
    $r->WriteText("This is my second item.");
    $r->EndNumberedBullet;
    $r->Newline;
    $r->WriteText("The following paragraph is right-indented:");
    $r->BeginRightIndent(200);
    $r->Newline;
    $r->WriteText("It was in January, the most down-trodden month of an Edinburgh winter. An attractive woman came into the cafe, which is nothing remarkable.");
    $r->EndRightIndent;
    $r->Newline;
    my $attr = Wx::TextAttrEx->new;;
    $attr->SetFlags( wxTEXT_ATTR_TABS );
    $attr->SetTabs( [ 400, 600, 800, 1000 ] );
    $r->SetDefaultStyle($attr);

    $r->WriteText("This line contains tabs:\tFirst tab\tSecond tab\tThird tab");
    $r->Newline;
    $r->WriteText("Other notable features of wxRichTextCtrl include:");
    $r->BeginSymbolBullet('*', 100, 60);
    $r->Newline;
    $r->WriteText("Compatibility with wxTextCtrl API");
    $r->EndSymbolBullet;
    $r->EndSuppressUndo;
}

sub print_preview {
    my($self) = @_;
    
    my $pv = $self->preview;
    $pv->SetHeaderText('Wx::Demo Richtext Printing',  wxRICHTEXT_PAGE_ALL,  wxRICHTEXT_PAGE_LEFT);
    $pv->SetFooterText('Page @PAGENUM@ of @PAGESCNT@',  wxRICHTEXT_PAGE_ALL,  wxRICHTEXT_PAGE_RIGHT);
    $pv->SetShowOnFirstPage(0);
    
    # we can only set header / footer margins using wxRichTextHeaderFooterData
    my $hfdata = $pv->GetHeaderFooterData;
    $hfdata->SetMargins(100,100);
    $pv->SetHeaderFooterData($hfdata);
    $self->preview->PreviewBuffer($self->richtext->GetBuffer());
}

sub page_setup {
    my($self) = @_;
    $self->preview->PageSetup;
}

sub add_to_tags { qw(controls) }
sub title { 'wxRichTextCtrl' }

defined &Wx::RichTextCtrl::new ? 1 : 0;
