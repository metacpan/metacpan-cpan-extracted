#! perl -w
#
# - Custom Cell Type
# - Sort function
#

use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::Grid;

# main Window
my $Window = new Win32::GUI::Window (
    -title    => "Win32::GUI::Grid test 5",
    -pos      => [100, 100],
    -size     => [400, 400],
    -name     => "Window",
	-addstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Grid Window
my $Grid = new Win32::GUI::Grid (
    -parent => $Window,
    -name   => "Grid",
    -pos    => [0, 0],
) or die "new Grid";

# Grid cell base
$Grid->SetDefCellType(GVIT_NUMERIC);  # Preset Cell type before cell creation

# Init Grid
$Grid->SetEditable(1);
$Grid->SetRows(10);
$Grid->SetColumns(10);
$Grid->SetFixedRows(1);
$Grid->SetFixedColumns(1);

# Fill Grid
for my $row (0..$Grid->GetRows()) {
    for my $col (0..$Grid->GetColumns()) {
        if ($row == 0) {
            $Grid->SetCellText($row, $col,"Column : $col");
        }
        elsif ($col == 0) {
            $Grid->SetCellText($row, $col, "Row : $row");
        }
        else {
            # $Grid->SetCellType($row, $col, GVIT_NUMERIC);  # Set cell type after creation.
            $Grid->SetCellText($row, $col, $row*$col);
        }
    }
}

# Set Date edit control in cell (1,1)
$Grid->SetCellText(1, 1, "");
$Grid->SetCellType(1, 1, GVIT_DATE);

# Set Date edit control in cell (2,1)
$Grid->SetCellText(2, 1, "");
$Grid->SetCellType(2, 1, GVIT_DATECAL);

# Set Time edit control in cell (1,2)
$Grid->SetCellText(1, 2, "");
$Grid->SetCellType(1, 2, GVIT_TIME);

# Set Check edit control in cell (1,3)
$Grid->SetCellText(1, 3, "");
$Grid->SetCellType(1, 3, GVIT_CHECK);
$Grid->SetCellCheck(1, 3, 1);
print "Cell Check : ", $Grid->GetCellCheck(1, 3), "\n";

# Set Combobox edit control in cell (1,4)
$Grid->SetCellText(1, 4, "");
$Grid->SetCellType(1, 4, GVIT_COMBO);
$Grid->SetCellOptions(1, 4, ["Option 1", "Option 2", "Option 3"]);

# Set Listbox control in cell (1,5)
$Grid->SetCellText(1, 5, "");
$Grid->SetCellType(1, 5, GVIT_LIST);
$Grid->SetCellOptions(1, 5, ["Option 1", "Option 2", "Option 3"]);

# Set Url control in cell (1,6)
$Grid->SetCellText(1, 6, "www.perl.com");
$Grid->SetCellType(1, 6, GVIT_URL);
$Grid->SetCellOptions(1, 6, -autolaunch => 0);

# Set Url control in cell (2,6)
$Grid->SetCellText(2, 6, "www.perl.com");
$Grid->SetCellType(2, 6, GVIT_URL);
# Set uneditable cell (2,6)
$Grid->SetCellEditable(2, 6, 0);

# Sort Numeric reverse order  (Method 1)
# $Grid->SortNumericCells(5, 0);
# Sort Numeric reverse order (Method 2)
# $Grid->SortCells(5, 0, sub { my ($e1, $e2) = @_; return (int($e1) - int ($e2)); } );
# Sort Numeric reverse order (Method 3)
# $Grid->SetSortFunction (sub { my ($e1, $e2) = @_; return (int($e1) - int ($e2)); } );
# $Grid->SortCells(7, 0);
# $Grid->SetSortFunction (); # remove sort method

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

sub Grid_BeginEdit {
    my ($col, $row) = @_;
    print "Begin Edit ($col, $row)\n";
}

sub Grid_ChangedEdit {
    my ($col, $row, $str) = @_;
    print "Changed Edit ($col, $row, $str)\n";
}

sub Grid_EndEdit {
    my ($col, $row) = @_;
    print "End Edit ($col, $row)\n";
}
