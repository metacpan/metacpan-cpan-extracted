#!/usr/bin/perl -w

use strict;
use Wx;
use lib './t';
use Tests_Helper qw(in_frame);
use Test::More 'tests' => 28;
use strict;
use Wx::TreeListCtrl;

use Wx qw( :treelist :misc :id :sizer :listctrl);


sub run_load_tests {
    my $self = shift;
    
    my $flags = wxTL_MODE_NAV_FULLTREE | wxTL_MODE_NAV_EXPANDED | wxTL_MODE_NAV_VISIBLE | wxTL_MODE_NAV_LEVEL
                | wxTL_MODE_FIND_EXACT | wxTR_HAS_BUTTONS | wxTR_LINES_AT_ROOT | wxTR_TWIST_BUTTONS | wxTR_MULTIPLE
                | wxTR_EXTENDED | wxTR_HAS_VARIABLE_ROW_HEIGHT | wxTR_EDIT_LABELS | wxTR_ROW_LINES | wxTR_FULL_ROW_HIGHLIGHT
                | wxTR_COLUMN_LINES | wxTR_SHOW_ROOT_LABEL_ONLY;
                
    my $control = Wx::TreeListCtrl->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, $flags);
    
    ok(1, 'TreeListCtrl Created');
    
    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    
    $sizer->Add($control, 1, wxEXPAND|wxALL, 0);
    $self->SetSizer($sizer);
    $control->AddColumn( "Column One",   120, wxLIST_FORMAT_LEFT );
    ok(1, 'Column 1 Added');
    
    my $colinfo = $control->GetColumn(0);
    $colinfo->SetText('Column Two');
    $control->AddColumn( "Column Two" );
    ok(1, 'Column 2 Added');
    
    my $newcol = Wx::TreeListColumnInfo->new('Column Three');
    
    my $coltext = $newcol->GetText();
    is($coltext, 'Column Three', 'Check New Column Text');
    
    $control->AddColumn( $newcol );
    ok(1, 'Column 3 Added');
    
    $coltext = $control->GetColumnText(0);
    is($coltext, 'Column One', 'Check col one text');
    
    $coltext = $control->GetColumnText(1);
    is($coltext, 'Column Two', 'Check col two text');
    
    $coltext = $control->GetColumnText(2);
    is($coltext, 'Column Three', 'Check col three text');
    
    $newcol = Wx::TreeListColumnInfo->new('Column Four', 5, wxALIGN_RIGHT, 2, 0, 1);
    $newcol->SetSelectedImage(3);
    is($newcol->GetText, 'Column Four', 'new colinfo Text');
    is($newcol->GetWidth, 5, 'new colinfo Width');
    is($newcol->GetAlignment, wxALIGN_RIGHT, 'new colinfo flags');
    is($newcol->GetImage, 2, 'new colinfo image');
    ok(!$newcol->IsShown, 'new colinfo shown'); # bool
    ok($newcol->IsEditable, 'new colinfo editable'); # bool
    is($newcol->GetSelectedImage, 3, 'new colinfo selected image');
    
    $control->AddColumn( $newcol );
    is($control->GetColumnText(3), 'Column Four', 'control info Text');
    is($control->GetColumnWidth(3), 5, 'control info Width');
    is($control->GetColumnAlignment(3), wxALIGN_RIGHT, 'control info flags');
    is($control->GetColumnImage(3), 2, 'control info image');
    ok(!$control->IsColumnShown(3), 'control info shown');
    ok($control->IsColumnEditable(3), 'control info editable');
    
    $control->AddColumn('Column Five', 4, wxALIGN_CENTRE, 4, 1, 0);
    $newcol = Wx::TreeListColumnInfo->new('Column Six', 9, wxALIGN_CENTRE, 5, 0, 1);
    $newcol->SetSelectedImage(7);
    $control->AddColumn( $newcol );
    
    my $retcol = $control->GetColumn(3);
    is($retcol->GetText, 'Column Four', 'returned colinfo Text');
    is($retcol->GetWidth, 5, 'returned colinfo Width');
    is($retcol->GetAlignment, wxALIGN_RIGHT, 'returned colinfo flags');
    is($retcol->GetImage, 2, 'returned colinfo image');
    ok(!$retcol->IsShown, 'returned colinfo shown');
    ok($retcol->IsEditable, 'returned colinfo editable');
    is($retcol->GetSelectedImage, 3, 'returned colinfo editable');
    
}


in_frame(\&run_load_tests);





