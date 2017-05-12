#! perl -w
#
# Test Grid method
#   - Virtual mode
#   - EndEdit event in virtual mode
#

use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::Grid;

# main Window
my $Window = new Win32::GUI::Window (
    -title    => "Win32::GUI::Grid test 4",
    -pos      => [100, 100],
    -size     => [400, 400],
    -name     => "Window",
	-addstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Grid Window
my $Grid = $Window->AddGrid (
    -name         => "Grid",
    -pos          => [0, 0],
    -rows         => 50,      # Use create option
    -columns      => 10,
    -fixedrows    => 1,
    -fixedcolumns => 1,
    -editable     => 1,
    -virtual      => 1,
) or die "new Grid";

# $Grid->SetVirtualMode(1);   # Set virtual before set rows and columns
# $Grid->SetRows(50);
# $Grid->SetColumns(10);
# $Grid->SetFixedRows(1);
# $Grid->SetFixedColumns(1);
# $Grid->SetEditable(1);

$Grid->SetCellBkColor(2, 2, 0xFF0000);

# Event loop
$Window->Show();
Win32::GUI::Dialog();

# Main window event handler
sub Window_Terminate {
    return -1;
}

sub Window_Resize {
    my ($width, $height) = ($Window->GetClientRect)[2..3];
    $Grid->Resize ($width, $height);
}

# Virtual Grid request data
sub Grid_GetData {
    my ($row, $col) = @_;
    return "Cell ($row, $col)";
}

sub Grid_EndEdit {
    my ($col, $row, $str) = @_;
    print "End Edit ($col, $row) = $str\n";
    return 1;
}
