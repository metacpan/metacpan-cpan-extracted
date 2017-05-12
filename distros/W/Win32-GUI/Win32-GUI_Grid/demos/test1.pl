#! perl -w
#
# Test Basic Grid method
#
use strict;
use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::Grid;

# main Window
my $Window = new Win32::GUI::Window (
    -title    => "Win32::GUI::Grid test 1",
    -pos     => [100, 100],
    -size    => [400, 400],
    -name     => "Window",
	-addstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Grid Window
my $Grid = new Win32::GUI::Grid (
    -parent  => $Window,
    -name    => "Grid",
    -pos     => [0, 0],
) or die "new Grid";

# Init Grid
$Grid->SetEditable(1);
$Grid->SetRows(50);
$Grid->SetColumns(10);
$Grid->SetFixedRows(1);
$Grid->SetFixedColumns(1);

# Fill Grid
for my $row (0..$Grid->GetRows()) {
  for my $col (0..$Grid->GetColumns()) {
    if ($row == 0) {
      $Grid->SetCellFormat($row, $col, DT_LEFT|DT_WORDBREAK);
      $Grid->SetCellText($row, $col,"Column : $col");
    }
    elsif ($col == 0) {
      $Grid->SetCellFormat($row, $col, DT_RIGHT|DT_VCENTER|DT_SINGLELINE|DT_END_ELLIPSIS|DT_NOPREFIX);
      $Grid->SetCellText($row, $col, "Row : $row");
    }
    else {
      $Grid->SetCellFormat($row, $col, DT_RIGHT|DT_VCENTER|DT_SINGLELINE|DT_END_ELLIPSIS|DT_NOPREFIX);
      $Grid->SetCellText($row, $col, "Cell : ($row,$col)");
    }
  }
}
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
