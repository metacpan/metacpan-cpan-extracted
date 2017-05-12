#############################################################################
## Name:        lib/Wx/DemoModules/wxPrintPaperDatabase.pm
## Purpose:     wxPerl demo helper for Wx::PrintPaperDatabase
## Author:      Mark Dootson
## Modified by:
## Created:     19/05/2012
## RCS-ID:      $Id: wxPrintPaperDatabase.pm 3301 2012-05-31 01:16:40Z mdootson $
## Copyright:   (c) 2012 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Wx::DemoModules::wxPrintPaperDatabase;

use strict;
use Wx qw( :listctrl :id :sizer wxThePrintPaperDatabase );
use base qw(Wx::Panel);
use Wx::Print;
use Wx::Event qw(EVT_LIST_ITEM_SELECTED);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( $_[0], -1 );
   
    # paper list setup
    my $list = Wx::ListView->new($self, wxID_ANY, [-1,-1],[-1,-1], wxLC_REPORT|wxLC_SINGLE_SEL );
    $list->InsertColumn(0, "Paper Names", wxLIST_FORMAT_LEFT, 300);
    
    # add all papers to the list;
    
    my $numpapers = wxThePrintPaperDatabase->GetCount;
    for (my $i = 0; $i < $numpapers; $i++){
        # get a Wx::PrintPaperType for each paper
        my $paper = wxThePrintPaperDatabase->Item($i);
        $list->InsertStringItem( $i, $paper->GetName );
        # add the PaperId (wxPAPER_A4, wxPAPER_LETTER etc) as itemdata
        $list->SetItemData($i, $paper->GetId);
    }
    
    # events
    EVT_LIST_ITEM_SELECTED($self, $list, \&OnPaperSelected);

    # layout
    my $mainsizer = Wx::BoxSizer->new(wxVERTICAL);
    $mainsizer->Add($list,1,wxEXPAND|wxALL,0);
    $self->SetSizer($mainsizer);
    return $self;
}

sub OnPaperSelected {
    my($self, $event) = @_;
    
    my $paperid   = $event->GetItem->GetData;
    my $papername = $event->GetItem->GetText;
    
    # given a paperid (wxPAPER_A4 etc) we can get the paper details
    my $paper = wxThePrintPaperDatabase->FindPaperType($paperid);
    return unless $paper;
    
    my $pname  = $paper->GetName;
    my $width  = $paper->GetWidth;           # mm/10
    my $height = $paper->GetHeight;          # mm/10
    my $size   = $paper->GetSize;            # mm/10
    my $sizemm = $paper->GetSizeMM;          # mm
    my $sizedu = $paper->GetSizeDeviceUnits; # points - 1/72 inch
    
    Wx::LogMessage('Paper Name %s, Width %s, Height %s, Size %sx%s, Size MM %sx%s, Size Device %sx%s',
                   $paper->GetName, $width, $height, $size->GetWidth, $size->GetHeight,
                   $sizemm->GetWidth, $sizemm->GetHeight,
                   $sizedu->GetWidth, $sizedu->GetHeight);
    
    # we can also find a paper given its name
    my $samepaper = wxThePrintPaperDatabase->FindPaperType($papername);
    return unless $samepaper;
    
    Wx::LogMessage('And Again Width %s, Height %s', $samepaper->GetWidth, $samepaper->GetHeight);
    
    # utility methods
    my $nameagain = wxThePrintPaperDatabase->ConvertIdToName( $paperid );
    my $idagain   = wxThePrintPaperDatabase->ConvertNameToId( $papername );
    
    Wx::LogMessage(qq($nameagain : $paperid == $idagain : $papername));
    
}


sub add_to_tags { qw(new misc) }
sub title { 'wxPrintPaperDatabase' }

#Skip loading 
return defined(&Wx::PrintPaperDatabase::FindPaperTypeById);
