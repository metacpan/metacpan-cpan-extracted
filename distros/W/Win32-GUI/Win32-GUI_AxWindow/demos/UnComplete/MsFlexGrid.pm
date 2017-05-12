#
#  Win32::GUI::MsFlexGrid: wrapper package for MsFlexGrid ActiveX
#    by Laurent Rocher.
#
#

use strict;
use vars qw(@ISA $VERSION);
use Carp 'croak','carp';

use Win32::GUI::AxWindow;

@ISA = qw(Win32::GUI::AxWindow Exporter);

$VERSION = "1.0";

BEGIN {
        use Exporter();
        use vars qw(@EXPORT);
        @EXPORT = qw();
}

#########################################################################
#                                                                       #
#########################################################################

#
#  new : Create a new MsFlexGrid window
#
sub new {

  my $class = shift;
  my %param = @_;

  $param {-control} = "MSFlexGridLib.MSFlexGrid";

  my $self = new Win32::GUI::AxWindow ( %param );

  return bless $self, $class;
}


#  Constants for the OLEDragMode property (but not the DragMode or OLEDropMode properties).
#  enum {
#      flexOLEDragManual = 0,
#      flexOLEDragAutomatic = 1
#  } OLEDragConstants;
#
#  Constants for the OLEDropMode property (but not the DragMode or OLEDragMode properties).
#  enum {
#      flexOLEDropNone = 0,
#      flexOLEDropManual = 1
#  } OLEDropConstants;
#
#  State transition constants for the DragOver and OLEDragOver events.
#  enum {
#      flexEnter = 0,
#      flexLeave = 1,
#      flexOver = 2
#  } DragOverConstants;
#
#  Clipboard format constants.
#  enum {
#      flexCFText = 1,
#      flexCFBitmap = 2,
#      flexCFMetafile = 3,
#      flexCFDIB = 8,
#      flexCFPalette = 9,
#      flexCFEMetafile = 14,
#      flexCFFiles = 15,
#      flexCFRTF = -16639
#  } ClipBoardConstants;
#
#  Drop effect constants for OLE drag and drop events.
#  enum {
#      flexOLEDropEffectNone = 0,
#      flexOLEDropEffectCopy = 1,
#      flexOLEDropEffectMove = 2,
#      flexOLEDropEffectScroll = -2147483648
#  } OLEDropEffectConstants;
#
#  Error constants
#  enum {
#      flexerrIllegaFunctionCall = 5,
#      flexerrObjIllegalUse = 425,
#      flexerrClipInvalidFormat = 461,
#      flexerrDataObjectLocked = 672,
#      flexerrExpectedAnArgument = 673,
#      flexerrRecursiveOLEDrag = 674,
#      flexerrUserFormatNotBinArray = 675,
#      flexerrDataNotSetForFormat = 676,
#      flexerrUnknownError = 600,
#      flexerrSubscript = 381,
#      flexerrBadValue = 380,
#      flexerrGetNotSupported = 394,
#      flexerrSetNotPermitted = 387,
#      flexerrOutOfMemory = 7,
#      flexerrVB30000 = 30000,
#      flexerrVB30001 = 30001,
#      flexerrVB30002 = 30002,
#      flexerrVB30004 = 30004,
#      flexerrVB30005 = 30005,
#      flexerrVB30006 = 30006,
#      flexerrVB30008 = 30008,
#      flexerrVB30009 = 30009,
#      flexerrVB30010 = 30010,
#      flexerrVB30011 = 30011,
#      flexerrVB30013 = 30013,
#      flexerrVB30014 = 30014,
#      flexerrVB30015 = 30015,
#      flexerrVB30016 = 30016,
#      flexerrVB30017 = 30017
#  } ErrorConstants;
#
#  Appearance Constants
#  enum {
#      flexFlat = 0,
#      flex3D = 1
#  } AppearanceSettings;
#
#  BorderStyle Constants
#  enum {
#      flexBorderNone = 0,
#      flexBorderSingle = 1
#  } BorderStyleSettings;
#
#  FocusRect Constants
#  enum {
#      flexFocusNone = 0,
#      flexFocusLight = 1,
#      flexFocusHeavy = 2
#  } FocusRectSettings;
#
#  Highlight Constants
#  enum {
#      flexHighlightNever = 0,
#      flexHighlightAlways = 1,
#      flexHighlightWithFocus = 2
#  } HighLightSettings;
#
#  ScrollBars Constants
#  enum {
#      flexScrollBarNone = 0,
#      flexScrollBarHorizontal = 1,
#      flexScrollBarVertical = 2,
#      flexScrollBarBoth = 3
#  } ScrollBarsSettings;
#
#  TextStyle Constants
#  enum {
#      flexTextFlat = 0,
#      flexTextRaised = 1,
#      flexTextInset = 2,
#      flexTextRaisedLight = 3,
#      flexTextInsetLight = 4
#  } TextStyleSettings;
#
#  FillStyle Constants
#  enum {
#      flexFillSingle = 0,
#      flexFillRepeat = 1
#  } FillStyleSettings;
#
#  GridLines Constants
#  enum {
#      flexGridNone = 0,
#      flexGridFlat = 1,
#      flexGridInset = 2,
#      flexGridRaised = 3
#  } GridLineSettings;
#
#  SelectionMode Constants
#  enum {
#      flexSelectionFree = 0,
#      flexSelectionByRow = 1,
#      flexSelectionByColumn = 2
#  } SelectionModeSettings;
#
#  MergeCells Constants
#  enum {
#      flexMergeNever = 0,
#      flexMergeFree = 1,
#      flexMergeRestrictRows = 2,
#      flexMergeRestrictColumns = 3,
#      flexMergeRestrictAll = 4
#  } MergeCellsSettings;
#
#  PictureType Constants
#  enum {
#      flexPictureColor = 0,
#      flexPictureMonochrome = 1
#  } PictureTypeSettings;
#
#  AllowUserResizing Constants
#  enum {
#      flexResizeNone = 0,
#      flexResizeColumns = 1,
#      flexResizeRows = 2,
#      flexResizeBoth = 3
#  } AllowUserResizeSettings;
#
#  MousePointer Constants
#  enum {
#      flexDefault = 0,
#      flexArrow = 1,
#      flexCross = 2,
#      flexIBeam = 3,
#      flexIcon = 4,
#      flexSize = 5,
#      flexSizeNESW = 6,
#      flexSizeNS = 7,
#      flexSizeNWSE = 8,
#      flexSizeEW = 9,
#      flexUpArrow = 10,
#      flexHourglass = 11,
#      flexNoDrop = 12,
#      flexArrowHourGlass = 13,
#      flexArrowQuestion = 14,
#      flexSizeAll = 15,
#      flexCustom = 99
#  } MousePointerSettings;
#
#  Sort Constants
#  enum {
#      flexSortNone = 0,
#      flexSortGenericAscending = 1,
#      flexSortGenericDescending = 2,
#      flexSortNumericAscending = 3,
#      flexSortNumericDescending = 4,
#      flexSortStringNoCaseAscending = 5,
#      flexSortStringNoCaseDescending = 6,
#      flexSortStringAscending = 7,
#      flexSortStringDescending = 8
#  } SortSettings;
#
#  Alignment Constants
#  enum {
#      flexAlignLeftTop = 0,
#      flexAlignLeftCenter = 1,
#      flexAlignLeftBottom = 2,
#      flexAlignCenterTop = 3,
#      flexAlignCenterCenter = 4,
#      flexAlignCenterBottom = 5,
#      flexAlignRightTop = 6,
#      flexAlignRightCenter = 7,
#      flexAlignRightBottom = 8,
#      flexAlignGeneral = 9
#  } AlignmentSettings;
#
#
##      [id(0x0000004c), propget, bindable, helpstring("Returns/sets the data source for the control."), helpcontext(0x000591d9)]
##      IRowCursor* DataSource();
##      [id(0x0000004c), propput, bindable, helpstring("Returns/sets the data source for the control."), helpcontext(0x000591d9)]
##      void DataSource([in] IRowCursor* rhs);
##
##      [id(0x0000002a), propget, helpstring("Returns/sets an image to be displayed in the current cell or in a range of cells."), helpcontext(0x000591e9)]
##      IPictureDisp* CellPicture();
##      [id(0x0000002a), propputref, helpstring("Returns/sets an image to be displayed in the current cell or in a range of cells."), helpcontext(0x000591e9)]
##      void CellPicture([in] IPictureDisp* rhs);
##
##      [id(0x00000031), propget, helpstring("Returns a picture of the FlexGrid control, suitable for printing, saving to disk, copying to the clipboard, or assigning to a different control."), helpcontext(0x00059207)]
##      IPictureDisp* Picture();
##
##      [id(0x00000036), propget, helpstring("Returns/sets a custom mouse icon."), helpcontext(0x000591cd)]
##      IPictureDisp* MouseIcon();
##      [id(0x00000036), propputref, helpstring("Returns/sets a custom mouse icon."), helpcontext(0x000591cd)]
##      void MouseIcon([in] IPictureDisp* rhs);
##
##      [id(0xfffffe00), propget, bindable, requestedit, helpstring("Returns/sets the default font or the font for individual cells."), helpcontext(0x000591c8)]
##      IFontDisp* Font();
##      [id(0xfffffe00), propputref, bindable, requestedit, helpstring("Returns/sets the default font or the font for individual cells."), helpcontext(0x000591c8)]
##      void Font([in] IFontDisp* rhs);


#########################################################################
#                          I N T E R F A C E                            #
#########################################################################

# BSTR Text() / void Text([in] BSTR rhs)
# Returns/sets the text contents of a cell or range of cells.
sub Text {

  croak("Usage: BSTR Text() / void Text([in] BSTR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000000 , $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000000);
  }
}

# short Version();
# Returns the version of the FlexGrid control currently loaded in memory.
sub Version {

  croak("Usage: short Version()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::GetProperty (0x00000001);
}

# BSTR FormatString() / void FormatString([in] BSTR rhs)
# Allows you to set up a FlexGrid's column widths, alignments, and fixed row and column text at design time.
sub FormatString {

  croak("Usage: BSTR FormatString() / void FormatString([in] BSTR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000002, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000002);
  }
}

# long Rows() / void Rows([in] long rhs)
# Determines the total number of columns or rows in a FlexGrid.
sub Rows {

  croak("Usage: long Rows() / void Rows(long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000004, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000004);
  }
}

# long Cols() / void Cols([in] long rhs)
# Determines the total number of columns or cols in a FlexGrid.
sub Cols {

  croak("Usage: long Cols() / void Cols(long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000005, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000005);
  }
}

# long FixedRows() / void FixedRows([in] long rhs)
# Returns/sets the total number of fixed (non-scrollable) rows for a FlexGrid.
sub FixedRows {

  croak("Usage: long FixedRows() / void FixedRows([in] long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000006, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000006);
  }
}

# long FixedCols() / void FixedCols([in] long rhs)
# Returns/sets the total number of fixed (non-scrollable) cols for a FlexGrid.
sub FixedCols {

  croak("Usage: long FixedCols() / void FixedCols([in] long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000007, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000007);
  }
}

# long TopRow() / void TopRow([in] long rhs)
# Returns/sets the topmost visible row (other than a fixed row) in the FlexGrid.
sub TopRow {

  croak("Usage: long TopRow() / void TopRow([in] long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000008, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000008);
  }
}

# long LeftCol() / void LeftCol([in] long rhs)
# Returns/sets the leftmost visible column (other than a fixed column) in the FlexGrid.
sub LeftCol {

  croak("Usage: long LeftCol() / void LeftCol([in] long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000009, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000009);
  }
}

# long Row() / void Row([in] long rhs)
# Returns/sets the active cell in a FlexGrid.
sub Row {

  croak("Usage: long Row() / void Row([in] long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000000a, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000000a);
  }
}

# long Col() / void Col([in] long rhs)
# Returns/sets the active cell in a FlexGrid.
sub Col {

  croak("Usage: long Col() / void Col([in] long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000000b, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000000b);
  }
}

# long RowSel() / void RowSel([in] long rhs)
# Determines the starting or ending row or column for a range of cells.
sub RowSel {

  croak("Usage: long RowSel() / void RowSel([in] long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000000c, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000000c);
  }
}

# long ColSel() / void ColSel([in] long rhs)
# Determines the starting or ending row or column for a range of cells.
sub ColSel {

  croak("Usage: long ColSel() / void ColSel([in] long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000000d, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000000d);
  }
}

# OLE_COLOR BackColorFixed() / OLE_COLOR BackColorFixed()
# Returns/sets the background color of various elements of the FlexGrid.
sub BackColorFixed {

  croak("Usage: OLE_COLOR BackColorFixed() / OLE_COLOR BackColorFixed()") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000000e, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000000e);
  }
}

# OLE_COLOR ForeColorFixed() / OLE_COLOR ForeColorFixed()
# Determines the color used to draw text on each part of the FlexGrid..
sub ForeColorFixed {

  croak("Usage: OLE_COLOR ForeColorFixed() / OLE_COLOR ForeColorFixed()") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000000f, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000000f);
  }
}

# OLE_COLOR BackColorSel() / OLE_COLOR BackColorSel()
# Returns/sets the background color of various elements of the FlexGrid.
sub BackColorSel {

  croak("Usage: OLE_COLOR BackColorSel() / OLE_COLOR BackColorSel()") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000010, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000010);
  }
}

# OLE_COLOR ForeColorSel() / OLE_COLOR ForeColorSel()
# Determines the color used to draw text on each part of the FlexGrid.
sub ForeColorSel {

  croak("Usage: OLE_COLOR ForeColorSel() / OLE_COLOR ForeColorSel()") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000011, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000011);
  }
}

# OLE_COLOR BackColorBkg() / OLE_COLOR BackColorBkg()
# Returns/sets the background color of various elements of the FlexGrid.
sub BackColorBkg {

  croak("Usage: OLE_COLOR BackColorBkg() / OLE_COLOR BackColorBkg()") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000012, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000012);
  }
}

# VARIANT_BOOL WordWrap() / void WordWrap([in] VARIANT_BOOL rhs)
# Returns/sets whether text within a cell should be allowed to wrap.
sub WordWrap {

  croak("Usage: VARIANT_BOOL WordWrap() / void WordWrap([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000013, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000013);
  }
}

# TextStyleSettings TextStyle() / void TextStyle([in] TextStyleSettings rhs)
# Returns/sets 3D effects for displaying text.
sub TextStyle {

  croak("Usage: TextStyleSettings TextStyle() / void TextStyle([in] TextStyleSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000014, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000014);
  }
}

# TextStyleSettings TextStyleFixed() / void TextStyleFixed([in] TextStyleSettings rhs)
# Returns/sets 3D effects for displaying text.
sub TextStyleFixed {

  croak("Usage: TextStyleSettings TextStyleFixed() / void TextStyleFixed([in] TextStyleSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000015, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000015);
  }
}

# VARIANT_BOOL ScrollTrack() / void ScrollTrack([in] VARIANT_BOOL rhs)
# Returns/sets whether FlexGrid should scroll its contents while the user moves the scroll box along the scroll bars.
sub ScrollTrack {

  croak("Usage: VARIANT_BOOL ScrollTrack() / void ScrollTrack([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000016, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000016);
  }
}

# FocusRectSettings FocusRect() / void FocusRect([in] FocusRectSettings rhs)
# Determines whether the FlexGrid control should draw a focus rectangle around the current cell.
sub FocusRect {

  croak("Usage: FocusRectSettings FocusRect() / void FocusRect([in] FocusRectSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000017, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000017);
  }
}

# HighLightSettings HighLight() / void HighLight([in] HighLightSettings rhs)
# Returns/sets whether selected cells appear highlighted.
sub HighLight {

  croak("Usage: HighLightSettings HighLight() / void HighLight([in] HighLightSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000018, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000018);
  }
}

# VARIANT_BOOL Redraw() / void Redraw([in] VARIANT_BOOL rhs)
# Enables or disables redrawing of the FlexGrid control.
sub Redraw {

  croak("Usage: VARIANT_BOOL Redraw() / void Redraw([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000019, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000019);
  }
}

# ScrollBarsSettings ScrollBars() / void ScrollBars([in] ScrollBarsSettings rhs)
# Returns/sets whether a FlexGrid has horizontal or vertical scroll bars.
sub ScrollBars {

  croak("Usage: ScrollBarsSettings ScrollBars() / void ScrollBars([in] ScrollBarsSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000001a, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000001a);
  }
}

# long MouseRow()
# Returns over which row (column) the mouse pointer is.
sub MouseRow {

  croak("Usage: long MouseRow()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::GetProperty (0x0000001b);
}

# long MouseCol()
# Returns over which row (column) the mouse pointer is.
sub MouseCol {

  croak("Usage: long MouseCol()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::GetProperty (0x0000001c);
}

# long CellLeft()
# Returns the left position of the current cell, in twips.
sub CellLeft {

  croak("Usage: long CellLeft()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::GetProperty (0x0000001d);
}

# long CellTop()
# Returns the top position of the current cell, in twips.
sub CellTop {

  croak("Usage: long CellTop()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::GetProperty (0x0000001e);
}

# long CellWidth()
# Returns the width of the current cell, in twips
sub CellWidth {

  croak("Usage: long CellWidth()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::GetProperty (0x0000001f);
}

# long CellHeight()
# Returns the height of the current cell, in twips.
sub CellHeight {

  croak("Usage: long CellHeight()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::GetProperty (0x00000020);
}

# long RowHeightMin() / void RowHeightMin([in] long rhs)
# Returns/sets a minimum row height for the entire control, in twips.
sub RowHeightMin {

  croak("Usage: long RowHeightMin() / void RowHeightMin([in] long rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000021, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000021);
  }
}

# GridLineSettings GridLines() / void GridLines([in] GridLineSettings rhs)
# Returns/sets the type of lines that should be drawn between cells.
sub GridLines {

  croak("Usage: GridLineSettings GridLines() / void GridLines([in] GridLineSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000022, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000022);
  }
}

# GridLineSettings GridLinesFixed() / void GridLinesFixed([in] GridLineSettings rhs)
# Returns/sets the type of lines that should be drawn between cells.
sub GridLinesFixed {

  croak("Usage: GridLineSettings GridLinesFixed() / void GridLinesFixed([in] GridLineSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000023, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000023);
  }
}

# OLE_COLOR GridColor() / void GridColor([in] OLE_COLOR rhs)
# Returns/sets the color used to draw the lines between FlexGrid cells.
sub GridColor {

  croak("Usage: OLE_COLOR GridColor() / void GridColor([in] OLE_COLOR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000024, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000024);
  }
}

# OLE_COLOR GridColorFixed() / void GridColorFixed([in] OLE_COLOR rhs)
# Returns/sets the color used to draw the lines between FlexGrid cells.
sub GridColorFixed {

  croak("Usage: OLE_COLOR GridColorFixed() / void GridColorFixed([in] OLE_COLOR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000025, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000025);
  }
}

# OLE_COLOR CellBackColor() / void CellBackColor([in] OLE_COLOR rhs)
# Returns/sets the background and foreground colors of individual cells or ranges of cells.
sub CellBackColor {

  croak("Usage: OLE_COLOR CellBackColor() / void CellBackColor([in] OLE_COLOR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000026, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000026);
  }
}

# OLE_COLOR CellForeColor() / void CellForeColor([in] OLE_COLOR rhs)
# Returns/sets the background and foreground colors of individual cells or ranges of cells.
sub CellForeColor {

  croak("Usage: OLE_COLOR CellForeColor() / void CellForeColor([in] OLE_COLOR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000027, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000027);
  }
}

# short CellAlignment() / void CellAlignment([in] short rhs)
# Returns/sets the alignment of data in a cell or range of selected cells.
sub CellAlignment {

  croak("Usage: short CellAlignment() / void CellAlignment([in] short rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000028, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000028);
  }
}

# TextStyleSettings CellTextStyle() / void CellTextStyle([in] TextStyleSettings rhs)
# Returns/sets 3D effects for text on a specific cell or range of cells.
sub CellTextStyle {

  croak("Usage: TextStyleSettings CellTextStyle() / void CellTextStyle([in] TextStyleSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000029, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000029);
  }
}

# short CellPictureAlignment() / void CellPictureAlignment([in] short rhs)
# Returns/sets the alignment of pictures in a cell or range of selected cells.
sub CellPictureAlignment {

  croak("Usage: short CellPictureAlignment() / void CellPictureAlignment([in] short rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000002b, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000002b);
  }
}

# BSTR Clip() / void Clip([in] BSTR rhs)
# Returns/sets the contents of the cells in a FlexGrid's selected region.
sub Clip {

  croak("Usage: BSTR Clip() / void Clip([in] BSTR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000002d, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000002d);
  }
}

# void Sort([in] short rhs)
# Action-type property that sorts selected rows according to selected criteria.
sub Sort {

  croak("Usage: void Sort([in] short rhs)") if (@_ != 2);

  my ($self, $value) = @_;

  return $self->SUPER::SetProperty (0x0000002e, $value);
}

# SelectionModeSettings SelectionMode() / void SelectionMode([in] SelectionModeSettings rhs)
# Returns/sets whether a FlexGrid should allow regular cell selection, selection by rows, or selection by columns.
sub SelectionMode {

  croak("Usage: SelectionModeSettings SelectionMode() / void SelectionMode([in] SelectionModeSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000002f, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000002f);
  }
}

# MergeCellsSettings MergeCells() / void MergeCells([in] MergeCellsSettings rhs)
# Returns/sets whether cells with the same contents should be grouped in a single cell spanning multiple rows or columns.
sub MergeCells {

  croak("Usage: MergeCellsSettings MergeCells() / void MergeCells([in] MergeCellsSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000030, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000030);
  }
}

# PictureTypeSettings PictureType() / void PictureType([in] PictureTypeSettings rhs)
# Returns/sets the type of picture that should be generated by the Picture property.
sub PictureType {

  croak("Usage: PictureTypeSettings PictureType() / void PictureType([in] PictureTypeSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000032, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000032);
  }
}

# VARIANT_BOOL AllowBigSelection() / void AllowBigSelection([in] VARIANT_BOOL rhs)
# Returns/sets whether clicking on a column or row header should cause the entire column or row to be selected.
sub AllowBigSelection {

  croak("Usage: VARIANT_BOOL AllowBigSelection() / void AllowBigSelection([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000033, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000033);
  }
}

# AllowUserResizeSettings AllowUserResizing() / void AllowUserResizing([in] AllowUserResizeSettings rhs)
# Returns/sets whether the user should be allowed to resize rows and columns with the mouse.
sub AllowUserResizing {

  croak("Usage: AllowUserResizeSettings AllowUserResizing() / void AllowUserResizing([in] AllowUserResizeSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000034, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000034);
  }
}

# MousePointerSettings MousePointer() / void MousePointer([in] MousePointerSettings rhs)
# Returns/sets the type of mouse pointer displayed when over part of an object.
sub MousePointer {

  croak("Usage: MousePointerSettings MousePointer() / void MousePointer([in] MousePointerSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000035, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000035);
  }
}

# BSTR TextArray([in] long index) / void TextArray([in] long index, [in] BSTR rhs)
# Returns/sets the text contents of an arbitrary cell (single subscript).
sub TextArray {

  croak("Usage: BSTR TextArray([in] long index) / void TextArray([in] long index, [in] BSTR rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000037, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x00000037, $value);
  }
}

# short ColAlignment([in] long index) / void ColAlignment([in] long index, [in] short rhs)
# Returns/sets the alignment of data in a column.
sub ColAlignment {

  croak("Usage: short ColAlignment([in] long index) / void ColAlignment([in] long index, [in] short rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000038, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x00000038, $value);
  }
}


# long ColWidth([in] long index) / void ColWidth([in] long index, [in] long rhs)
# Determines the width of the specified column in Twips.
sub ColWidth {

  croak("Usage: long ColWidth([in] long index) / void ColWidth([in] long index, [in] long rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000039, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x00000039, $value);
  }
}

# long RowHeight([in] long index) / void RowHeight([in] long index, [in] long rhs)
# Returns/sets the height of the specified row in Twips.
sub RowHeight {

  croak("Usage: long RowHeight([in] long index) / void RowHeight([in] long index, [in] long rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000003a, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x0000003a, $value);
  }
}

# VARIANT_BOOL MergeRow([in] long index) / void MergeRow([in] long index, [in] VARIANT_BOOL rhs)
# Returns/sets which rows (columns) should have their contents merged when the MergeCells property is set to a value other than 0 - Never.
sub MergeRow {

  croak("Usage: VARIANT_BOOL MergeRow([in] long index) / void MergeRow([in] long index, [in] VARIANT_BOOL rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000003b, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x0000003b, $value);
  }
}

# VARIANT_BOOL MergeCol([in] long index) / void MergeCol([in] long index, [in] VARIANT_BOOL rhs)
# Returns/sets which rows (columns) should have their contents merged when the MergeCells property is set to a value other than 0 - Never.
sub MergeCol {

  croak("Usage: VARIANT_BOOL MergeCol([in] long index) / void MergeCol([in] long index, [in] VARIANT_BOOL rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000003c, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x0000003c, $value);
  }
}

# void RowPosition([in] long index, [in] long rhs)
# Returns the distance in Twips between the upper-left corner of the control and the upper-left corner of a specified row.
sub RowPosition {

  croak("Usage: void RowPosition([in] long index, [in] long rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  return $self->SUPER::SetProperty (0x0000003d, $value, $value2);
}

# void ColPosition([in] long index, [in] long rhs)
# Returns the distance in Twips between the upper-left corner of the control and the upper-left corner of a specified column.
sub ColPosition {

  croak("Usage: void ColPosition([in] long index, [in] long rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  return $self->SUPER::SetProperty (0x0000003e, $value, $value2);
}


# long RowData([in] long index) / void RowData([in] long index, [in] long rhs)
# Array of long integer values with one item for each row (RowData) and for each column (ColData) of the FlexGrid.
sub RowData {

  croak("Usage: long RowData([in] long index) / void RowData([in] long index, [in] long rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000003f, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x0000003f, $value);
  }
}

# long ColData([in] long index) / void ColData([in] long index, [in] long rhs)
# Array of long integer values with one item for each row (RowData) and for each column (ColData) of the FlexGrid.
sub ColData {

  croak("Usage: long ColData([in] long index) / void ColData([in] long index, [in] long rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000040, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x00000040, $value);
  }
}

# BSTR TextMatrix([in] long Row,[in] long Col) / void TextMatrix([in] long Row,[in] long Col,[in] BSTR)
# Returns/sets the text contents of an arbitrary cell (row/col subscripts).
sub TextMatrix {

  croak("Usage: BSTR TextMatrix([in] long Row,[in] long Col) / void TextMatrix([in] long Row,[in] long Col,[in] BSTR)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000041, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x00000041, $value);
  }
}

# void AddItem([in] BSTR Item,[in, optional] VARIANT index)
# Adds a new row to a FlexGrid control at run time.
sub AddItem {

  croak("Usage: void AddItem([in] BSTR Item,[in, optional] VARIANT index)") if (@_ == 0 || @_ > 3);

  my ($self, $value, $value2) = @_;

  if (defined $value2) {
    return $self->SUPER::CallMethod (0x00000042, $value, $value2);
  }
  else {
    return $self->SUPER::CallMethod (0x00000042, $value);
  }
}

# void RemoveItem([in] long index)
# Removes a row from a FlexGrid control at run time.
sub RemoveItem {

  croak("Usage: void RemoveItem([in] long index)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  return $self->SUPER::CallMethod (0x00000043, $value);
}

# void Clear()
# Clears the contents of the FlexGrid. This includes all text, pictures, and cell formatting.
sub Clear {

  croak("Usage: void Clear()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::CallMethod (0x00000044);
}


# OLE_COLOR BackColor() / void BackColor([in] OLE_COLOR rhs)
# Returns/sets the background color of various elements of the FlexGrid.
sub BackColor {

  croak("Usage: OLE_COLOR BackColor() / void BackColor([in] OLE_COLOR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0xfffffe0b, $value);
  }
  else {
    return $self->SUPER::GetProperty (0xfffffe0b);
  }
}

# OLE_COLOR ForeColor() / void ForeColor([in] OLE_COLOR rhs)
# Determines the color used to draw text on each part of the FlexGrid.
sub ForeColor {

  croak("Usage: OLE_COLOR ForeColor() / void ForeColor([in] OLE_COLOR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0xfffffdff, $value);
  }
  else {
    return $self->SUPER::GetProperty (0xfffffdff);
  }
}

# single FontWidth() / void FontWidth([in] single rhs)
# Returns or sets the width, in points, of the font to be used for text displayed.
sub FontWidth {

  croak("Usage: single FontWidth() / void FontWidth([in] single rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000054, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000054);
  }
}

# BSTR CellFontName() / void CellFontName([in] BSTR rhs)
# Returns/sets the font to be used for individual cells or ranges of cells.
sub CellFontName {

  croak("Usage: BSTR CellFontName() / void CellFontName([in] BSTR rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000004d, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000004d);
  }
}

# single CellFontSize() / void CellFontSize([in] single rhs)
# Returns or sets the size, in points, for the current cell text.
sub CellFontSize {

  croak("Usage: single CellFontSize() / void CellFontSize([in] single rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000004e, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000004e);
  }
}

# VARIANT_BOOL CellFontBold() / void CellFontBold([in] VARIANT_BOOL rhs)
# Returns or sets the bold style for the current cell text.
sub CellFontBold {

  croak("Usage: VARIANT_BOOL CellFontBold() / void CellFontBold([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000004f, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000004f);
  }
}

# VARIANT_BOOL CellFontItalic() / void CellFontItalic([in] VARIANT_BOOL rhs)
# Returns or sets the italic style for the current cell text.
sub CellFontItalic {

  croak("Usage: VARIANT_BOOL CellFontItalic() / void CellFontItalic([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000050, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000050);
  }
}

# VARIANT_BOOL CellFontUnderline() / void CellFontUnderline([in] VARIANT_BOOL rhs)
# Returns or sets the underline style for the current cell text.
sub CellFontUnderline {

  croak("Usage: VARIANT_BOOL CellFontUnderline() / void CellFontUnderline([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000051, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000051);
  }
}

# VARIANT_BOOL CellFontStrikeThrough() / void CellFontStrikeThrough([in] VARIANT_BOOL rhs)
# Returns or sets the strikethrough style for the current cell text.
sub CellFontStrikeThrough {

  croak("Usage: VARIANT_BOOL CellFontStrikeThrough() / void CellFontStrikeThrough([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000052, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000052);
  }
}

# single CellFontWidth() / void CellFontWidth([in] single rhs)
# Returns or sets the font width for the current cell text.
sub CellFontWidth {

  croak("Usage: single CellFontWidth() / void CellFontWidth([in] single rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000053, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000053);
  }
}

# VARIANT_BOOL RowIsVisible([in] long index)
# Returns True if the specified row is visible.
sub RowIsVisible {

  croak("Usage: VARIANT_BOOL RowIsVisible([in] long index)") if (@_ != 2);

  my ($self, $value) = @_;

  return $self->SUPER::GetProperty (0x00000055, $value);
}

# VARIANT_BOOL ColIsVisible([in] long index)
# Returns True if the specified column is visible.
sub ColIsVisible {

  croak("Usage: VARIANT_BOOL ColIsVisible([in] long index)") if (@_ != 2);

  my ($self, $value) = @_;

  return $self->SUPER::GetProperty (0x00000056, $value);
}

# long RowPos([in] long index)
# Returns the distance in Twips between the upper-left corner of the control and the upper-left corner of a specified row.
sub RowPos {

  croak("Usage: long RowPos([in] long index)") if (@_ != 2);

  my ($self, $value) = @_;

  return $self->SUPER::GetProperty (0x00000057, $value);
}

# long ColPos([in] long index)
# Returns the distance in Twips between the upper-left corner of the control and the upper-left corner of a specified column.
sub ColPos {

  croak("Usage: long ColPos([in] long index)") if (@_ != 2);

  my ($self, $value) = @_;

  return $self->SUPER::GetProperty (0x00000058, $value);
}

# short GridLineWidth() / void GridLineWidth([in] short rhs)
# Returns/sets the width in Pixels of the gridlines for the control.
sub GridLineWidth {

  croak("Usage: short GridLineWidth() / void GridLineWidth([in] short rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000059, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000059);
  }
}

# short FixedAlignment([in] long index) / void FixedAlignment([in] long index,[in] short rhs)
# Returns/sets the alignment of data in the fixed cells of a column.
sub FixedAlignment {

  croak("Usage: short FixedAlignment([in] long index) / void FixedAlignment([in] long index,[in] short rhs)") if (@_ != 2 && @_ != 3);

  my ($self, $value, $value2) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000005a, $value, $value2);
  }
  else {
    return $self->SUPER::GetProperty (0x0000005a, $value);
  }
}

# BSTR FontName() / void FontName([in] BSTR rhs) HIDDEN
# ???
sub FontName {

  croak("Usage: BSTR FontName() / void FontName([in] BSTR rhs) ") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000005b, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000005b);
  }
}

# single FontSize() / void FontSize([in] single rhs) HIDDEN
# ???
sub FontSize {

  croak("Usage: single FontSize() / void FontSize([in] single rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000005c, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000005c);
  }
}

# VARIANT_BOOL FontBold() / VARIANT_BOOL FontBold() HIDDEN
# ???
sub FontBold {

  croak("Usage: VARIANT_BOOL FontBold() / VARIANT_BOOL FontBold()") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000005d, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000005d);
  }
}

# VARIANT_BOOL FontItalic() / VARIANT_BOOL FontItalic() HIDDEN
# ???
sub FontItalic {

  croak("Usage: VARIANT_BOOL FontItalic() / VARIANT_BOOL FontItalic()") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000005e, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000005e);
  }
}

# VARIANT_BOOL FontStrikethru() / VARIANT_BOOL FontStrikethru() HIDDEN
# ???
sub FontStrikethru {

  croak("Usage: VARIANT_BOOL FontStrikethru() / VARIANT_BOOL FontStrikethru()") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000005f, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000005f);
  }
}

# VARIANT_BOOL FontUnderline() / VARIANT_BOOL FontUnderline() HIDDEN
# ???
sub FontUnderline {

  croak("Usage: VARIANT_BOOL FontUnderline() / VARIANT_BOOL FontUnderline()") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x00000060, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x00000060);
  }
}

# OLEDropConstants OLEDropMode() / void OLEDropMode([in] OLEDropConstants rhs)
# Returns/Sets whether this control can act as an OLE drop target.
sub OLEDropMode {

  croak("Usage: OLEDropConstants OLEDropMode() / void OLEDropMode([in] OLEDropConstants rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0x0000060f, $value);
  }
  else {
    return $self->SUPER::GetProperty (0x0000060f);
  }
}

# void OLEDrag()
# Starts an OLE drag/drop event with the given control as the source.
sub OLEDrag {

  croak("Usage: void OLEDrag()") if (@_ != 1);

  my $self = shift;
  return $self->SUPER::CallMethod (0x00000610);
}

# FillStyleSettings FillStyle() / void FillStyle([in] FillStyleSettings rhs)
# Determines whether setting the Text property or one of the Cell formatting properties of a FlexGrid applies the change to all selected cells.
sub FillStyle {

  croak("Usage: FillStyleSettings FillStyle() / void FillStyle([in] FillStyleSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0xfffffe01, $value);
  }
  else {
    return $self->SUPER::GetProperty (0xfffffe01);
  }
}

# BorderStyleSettings BorderStyle() / void BorderStyle([in] BorderStyleSettings rhs)
# Returns/sets the border style for an object.
sub BorderStyle {

  croak("Usage: BorderStyleSettings BorderStyle() / void BorderStyle([in] BorderStyleSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0xfffffe08, $value);
  }
  else {
    return $self->SUPER::GetProperty (0xfffffe08);
  }
}

# AppearanceSettings Appearance() / void Appearance([in] AppearanceSettings rhs)
# Returns/sets whether a control should be painted with 3-D effects.
sub Appearance {

  croak("Usage: AppearanceSettings Appearance() / void Appearance([in] AppearanceSettings rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0xfffffdf8, $value);
  }
  else {
    return $self->SUPER::GetProperty (0xfffffdf8);
  }
}

# long hWnd()
# Returns a handle to a form or control.
sub hWnd {

  croak("Usage: long hWnd()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::GetProperty (0xfffffdfd);
}

# VARIANT_BOOL Enabled() / void Enabled([in] VARIANT_BOOL rhs)  bindable, requestedit
# Returns/sets a value that determines whether a form or control can respond to user-generated events.
sub Enabled {

  croak("Usage: VARIANT_BOOL Enabled() / void Enabled([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0xfffffdfe, $value);
  }
  else {
    return $self->SUPER::GetProperty (0xfffffdfe);
  }
}

# void AboutBox()  HIDDEN
# Displays an About box with version and copyright information.
sub AboutBox {

  croak("Usage: void AboutBox()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::CallMethod (0xfffffdd8);
}

# void Refresh()
# Forces a complete repaint of a form or control.
sub Refresh {

  croak("Usage: void Refresh()") if (@_ != 1);

  my $self = shift;

  return $self->SUPER::CallMethod (0xfffffdda);
}

# VARIANT_BOOL RightToLeft() / void RightToLeft([in] VARIANT_BOOL rhs)
# Determines text display direction and control visual appearance on a bidirectional system.
sub RightToLeft {

  croak("Usage: VARIANT_BOOL RightToLeft() / void RightToLeft([in] VARIANT_BOOL rhs)") if (@_ != 1 && @_ != 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty (0xfffffd9d, $value);
  }
  else {
    return $self->SUPER::GetProperty (0xfffffd9d);
  }
}

1;

__END__
