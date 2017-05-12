#! perl -w
# 
# Test Grid method
#   - create option
#   - Color method
#   - ImageList support
#   - Event
#   - POINT, RECT method.

use strict;
use warnings;

use FindBin();

use Win32::GUI qw(WS_CLIPCHILDREN);
use Win32::GUI::Grid;

# main Window
my $Window = new Win32::GUI::Window (
    -title    => "Win32::GUI::Grid test 2",
    -pos      => [100, 100],
    -size     => [400, 400],
    -name     => "Window",
	-addstyle => WS_CLIPCHILDREN,
) or die "new Window";

# Grid Window
my $Grid = $Window->AddGrid (
    -name         => "Grid",
    -pos          => [0, 0],
    -rows         => 50,
    -columns      => 10,
    -fixedrows    => 1,
    -fixedcolumns => 1,
    -editable     => 1,
) or die "new Grid";

# Image list
my $IL = new Win32::GUI::ImageList(16, 16, 24, 3, 10);
$IL->Add("$FindBin::Bin/one.bmp");
$IL->Add("$FindBin::Bin/two.bmp");
$IL->Add("$FindBin::Bin/three.bmp");

# Attach ImageList to grid
$Grid->SetImageList($IL);

# Change some color (different color format)
$Grid->SetGridBkColor([66,66,66]);
$Grid->SetGridLineColor('#0000ff');
$Grid->SetTitleTipBackClr('#00ff00');
$Grid->SetDefCellTextColor(0,0, 0x9F9F9F);
$Grid->SetDefCellBackColor(0,0, 0x003300);

# Some test
my ($x, $y) = $Grid->GetCellOrigin(1, 1);
print "CellOrigin(1,1) = ($x, $y)\n";
my ($left, $top, $right, $bottom) = $Grid->GetCellRect(1,1);
print "GetCellRect(1,1) ($left, $top, $right, $bottom)\n";
($left, $top, $right, $bottom) = $Grid->GetTextRect(1,1);
print "GetTextRect(1,1) ($left, $top, $right, $bottom)\n";
($x, $y) = $Grid->GetCellFromPt(85, 50);
print "GetCellFromPt(85,50) = ($x, $y)\n";

# Fill Grid
for my $row (0..$Grid->GetRows()) {
  for my $col (0..$Grid->GetColumns()) {
    if ($row == 0) {
      $Grid->SetCellFormat($row, $col, DT_LEFT|DT_WORDBREAK);
      $Grid->SetCellText($row, $col,"Column : $col");
      $Grid->SetCellImage($row, $col, 0); # Add bitmap
    }
    elsif ($col == 0) {
      $Grid->SetCellFormat($row, $col, DT_RIGHT|DT_VCENTER|DT_SINGLELINE|DT_END_ELLIPSIS|DT_NOPREFIX);
      $Grid->SetCellText($row, $col, "Row : $row");
      $Grid->SetCellImage($row, $col, 1); # Add bitmap
    }
    else {
      $Grid->SetCellFormat($row, $col, DT_RIGHT|DT_VCENTER|DT_SINGLELINE|DT_END_ELLIPSIS|DT_NOPREFIX);
      $Grid->SetCellText($row, $col, "Cell : ($row,$col)");
      $Grid->SetCellImage($row, $col, 2); # Add bitmap
    }
  }
}

# Resize Grid Cell
$Grid->AutoSize();

# Some test
($x, $y) = $Grid->GetCellOrigin(1, 1);
print "CellOrigin(1,1) = ($x, $y)\n";
($left, $top, $right, $bottom) =  $Grid->GetCellRect(1,1);
print "GetCellRect(1,1) ($left, $top, $right, $bottom)\n";
($left, $top, $right, $bottom) = $Grid->GetTextRect(1,1);
print "GetTextRect(1,1) ($left, $top, $right, $bottom)\n";
($x, $y) = $Grid->GetCellFromPt(85, 50);
print "GetCellFromPt(85,50) = ($x, $y)\n";

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
  my ($col, $row) = @_;
  print "Click ($col, $row)\n";
}

sub Grid_RClick {
  my ($col, $row) = @_;
  print "Right Click ($col, $row)\n";
}

sub Grid_DblClick {
  my ($col, $row) = @_;
  print "Double Click ($col, $row)\n";
}

sub Grid_Changing {
  my ($col, $row) = @_;
  print "Selection Changing ($col, $row)\n";
}

sub Grid_Changed {
  my ($col, $row) = @_;
  print "Selection Changed ($col, $row)\n";
}

sub Grid_BeginEdit {
  my ($col, $row) = @_;
  print "Begin Edit ($col, $row)\n";
}

sub Grid_EndEdit {
  my ($col, $row) = @_;
  print "End Edit ($col, $row)\n";
}

sub Grid_BeginDrag {
  my ($col, $row) = @_;
  print "Begin Drag ($col, $row)\n";
}
