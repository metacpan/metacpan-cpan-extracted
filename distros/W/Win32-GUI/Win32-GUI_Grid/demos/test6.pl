#! perl -w
#
# Test multiple Grid instance
#
use strict;
use warnings;

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::Grid;

# main Window
my $Window = new Win32::GUI::Window (
    -title     => "Win32::GUI::Grid test 6",
    -pos       => [100, 100],
    -size      => [400, 400],
    -name      => "Window",
    -pushstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Grid Window
my $Grid = new Win32::GUI::Grid (
    -parent       => $Window,
    -name         => "Grid",
    -pos          => [0, 0],
    -rows         => 10,
    -columns      => 10,
    -fixedrows    => 1,
    -fixedcolumns => 1,
) or die "new Grid";

my $Grid2 = new Win32::GUI::Grid (
    -parent       => $Window,
    -name         => "Grid2",
    -pos          => [0, 0],
    -rows         => 20,
    -columns      => 20,
    -fixedrows    => 1,
    -fixedcolumns => 1,
) or die "new Grid2";

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
            $Grid->SetCellText($row, $col, $row*$col);
        }
    }
}
for my $row (0..$Grid2->GetRows()) {
    for my $col (0..$Grid2->GetColumns()) {
        if ($row == 0) {
            $Grid2->SetCellText($row, $col,"Column : $col");
        }
        elsif ($col == 0) {
            $Grid2->SetCellText($row, $col, "Row : $row");
        }
        else {
            $Grid2->SetCellText($row, $col, $row*$col);
        }
    }
}


# Resize Grid Cell
$Grid->AutoSize();
$Grid2->AutoSize();

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
    $Grid->Resize ($width, $height/2);
    $Grid2->Move (0, $height/2);
    $Grid2->Resize ($width, $height/2);
}

sub Grid_Click {
    my ($row, $col) = @_;
    print "Grid cell ($row, $col)\n";
}

sub Grid2_Click {
    my ($row, $col) = @_;
    print "Grid2 cell ($row, $col)\n";
}
