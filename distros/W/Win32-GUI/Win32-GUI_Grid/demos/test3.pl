#! perl -w
# 
# Test Grid method
#   - Default cell setting
#   - font method
#

use strict;
use warnings;

use FindBin();

use Win32::GUI();
use Win32::GUI::Grid;

# main Window
my $Window = new Win32::GUI::Window (
    -title => "Win32::GUI::Grid test 3",
    -pos   => [100, 100],
    -size  => [400, 400],
    -name  => "Window",
) or die "new Window";

# Grid Window
my $Grid = $Window->AddGrid (
    -name => "Grid",
    -pos  => [0, 0],
) or die "new Grid";

# Image list
my $IL = new Win32::GUI::ImageList(16, 16, 24, 3, 10);
$IL->Add("$FindBin::Bin/one.bmp");
$IL->Add("$FindBin::Bin/two.bmp");
$IL->Add("$FindBin::Bin/three.bmp");

# Attach ImageList to grid
$Grid->SetImageList($IL);

# Set default cell style
$Grid->SetDefCellTextColor(0,0, '#FF0000');
$Grid->SetDefCellTextColor(1,0, '#00FF00');
$Grid->SetDefCellTextColor(0,1, '#0000FF');

$Grid->SetDefCellBackColor(0,0, '#0000FF');
$Grid->SetDefCellBackColor(1,0, '#FF0000');
$Grid->SetDefCellBackColor(0,1, '#00FF00');

$Grid->SetDefCellFormat(0, 0, DT_RIGHT|DT_VCENTER|DT_SINGLELINE|DT_END_ELLIPSIS|DT_NOPREFIX);
$Grid->SetDefCellFormat(0, 1, DT_RIGHT|DT_VCENTER|DT_SINGLELINE|DT_END_ELLIPSIS|DT_NOPREFIX);
$Grid->SetDefCellFormat(1, 0, DT_LEFT|DT_WORDBREAK);

# Change default font
my %font = $Grid->GetDefCellFont(0,0);
$font {-bold} = 1;
$font {-height} = 10;
$Grid->SetDefCellFont(0,0, %font);

# Create Cells after set default style. (required for format ONLY)
$Grid->SetRows(50);
$Grid->SetColumns(10);
$Grid->SetFixedRows(1);
$Grid->SetFixedColumns(1);

# Fill Grid
for my $row (0..$Grid->GetRows()) {
    for my $col (0..$Grid->GetColumns()) {
        if ($row == 0) {
            $Grid->SetCellText($row, $col,"Column : $col");
            $Grid->SetCellImage($row, $col, 0); # Add bitmap
        }
        elsif ($col == 0) {
            $Grid->SetCellText($row, $col, "Row : $row");
            $Grid->SetCellImage($row, $col, 1); # Add bitmap
        }
        else {
            $Grid->SetCellText($row, $col, "Cell : ($row,$col)");
            $Grid->SetCellImage($row, $col, 2); # Add bitmap
        }
    }
}

# Set Cell font
$Grid->SetCellFont(0, 0, -name   => 'Arial' ,
                         -size   => 12,
                         -italic => 1,
                         -bold   => 1);

# Set font from a Win32::GUI::Font
my $F = new Win32::GUI::Font(
    -name => "MS Sans Serif",
    -size => 10,
    -bold => 1,
);
$Grid->SetCellFont(0, 1, $F->Info());

# Resize Grid Cell
$Grid->AutoSize();

# Event loop
$Window->Show();
Win32::GUI::Dialog();
exit(0);

# Main window event handler
sub Window_Terminate {
    return -1;
}

sub Window_Resize {
    my ($width, $height) = ($Window->GetClientRect)[2..3];
    $Grid->Resize ($width, $height);
}

sub Grid_Click {
    my ($row, $col) = @_;

    # Get font information
    print "\nFont for cell ($row, $col) :\n";
    my %font = $Grid->GetCellFont($row, $col);
    for my $key (keys %font) {
        print $key, " => ", $font{$key}, "\n";
    }
}
