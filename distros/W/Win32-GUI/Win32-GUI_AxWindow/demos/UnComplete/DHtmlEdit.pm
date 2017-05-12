#
#  Win32::GUI::DHtmlEdit : wrapper package for DHtmlEdit ActiveX
#    by Laurent Rocher.
#
#  TODO : Check ExecuteCommand (Some commande have parameters)
#  TODO : Check QueryStatus (Usefull for all)
#
package Win32::GUI::DHtmlEdit;

use strict;

use vars qw(@ISA $VERSION);
use Carp 'croak','carp';

use Win32::GUI::AxWindow;

@ISA = qw(Win32::GUI::AxWindow Exporter);

$VERSION = "1.0";

BEGIN {
        use Exporter();
        use vars qw(@EXPORT);
        @EXPORT = qw(&STATUS_NOTSUPPORTED
                     &STATUS_DISABLED
                     &STATUS_ENABLED
                     &STATUS_LATCHED
                     &STATUS_NINCHED
                    );
}

#
# Status Value (return of Query*)
#
sub STATUS_NOTSUPPORTED { return 0; }
sub STATUS_DISABLED     { return 1; }
sub STATUS_ENABLED      { return 3; }
sub STATUS_LATCHED      { return 7; }
sub STATUS_NINCHED      { return 11; }

#
#  new : Create a new DHTMLEdit object
#
sub new {

  my $class = shift;
  my %param = @_;

  $param {-control} = "{2D360200-FFF5-11D1-8D03-00A0C959BC0A}";

  my $self = new Win32::GUI::AxWindow ( %param );

  return bless $self, $class;
}

#
#  AttachControl : Do Nothing
#
sub AttachControl { }

#########################################################################
#                          M E T H O D                                  #
#########################################################################

#
# NewDocument :
#
sub NewDocument {

  croak("Usage: NewDocument") if @_ != 1;
  my $self = shift;

  return $self->SUPER::CallMethod ("NewDocument");
}

#
# LoadURL
#
sub LoadURL {

  croak("Usage: LoadURL (url)") if @_ != 2;

  my ($self, $url) = @_;

  return $self->SUPER::CallMethod ("LoadURL", $url);
}

#
# LoadDocument
#
sub LoadDocument {

  croak("Usage: LoadDocument (filepath, [promptuser = FALSE])") if (@_ != 2 && @_ != 3);

  my ($self, $filepath, $promptuser) = @_;

  $promptuser = 0 unless defined $promptuser;

  return $self->SUPER::CallMethod ("LoadDocument", $filepath, $promptuser);
}

#
# SaveDocument
#
sub SaveDocument {

  croak("Usage: SaveDocument (filepath, [promptuser = FALSE])") if (@_ != 2 && @_ != 3);

  my ($self, $filepath, $promptuser) = @_;

  $promptuser = 0 unless defined $promptuser;

  return $self->SUPER::CallMethod ("SaveDocument", $filepath, $promptuser);
}

#
# PrintDocument
#
sub PrintDocument {

  croak("Usage: PrintDocument ([withUI = FALSE])") if (@_ != 1 && @_ != 2);

  my ($self, $withUI) = @_;

  $withUI = 0 unless defined $withUI;

  return $self->SUPER::CallMethod ("PrintDocument", $withUI);
}


#
# Refresh
#
sub Refresh {

  croak("Usage: Refresh ()") if @_ != 1;

  my $self = shift;

  return $self->SUPER::CallMethod ("Refresh");
}

#
# ExecCommand
#

# TODO : Check Command with parametre

#  DECMD_BOLD = 5000,
sub Bold {
  croak("Usage: Bold ()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5000, 0);
}
#   DECMD_COPY = 5002,
sub Copy {
  croak("Usage: Copy ()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5002, 0);
}
#   DECMD_CUT = 5003,
sub Cut {
  croak("Usage: Cut ()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5003, 0);
}
#   DECMD_DELETE = 5004,
sub Delete {
  croak("Usage: Delete ()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5004, 0);
}
#   DECMD_DELETECELLS = 5005,
sub DeleteCells {
  croak("Usage: DeleteCells()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5005, 0);
}
#   DECMD_DELETECOLS = 5006,
sub DeleteCols {
  croak("Usage: DeleteCols()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5006, 0);
}
#   DECMD_DELETEROWS = 5007,
sub DeleteRows {
  croak("Usage: DeleteRows()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5007, 0);
}
#   DECMD_FINDTEXT = 5008,
sub FindText {
  croak("Usage: FindText()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5008, 1);
}
#   DECMD_FONT = 5009
sub Font {
  croak("Usage: Font()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5009, 1);
}
#   DECMD_GETBACKCOLOR = 5010 | Return a string #RRGGBB or empty string
sub GetBackColor {
  croak("Usage: GetBackColor()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5010, 0);
}
#   DECMD_GETBLOCKFMT = 5011 | Return a format block string
sub GetBlockFmt {
  croak("Usage: GetBlockFmt()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5011, 0);
}
#   DECMD_GETBLOCKFMTNAMES = 5012
# TODO : need a IDISPATCH interface
# sub GetBlockFmtNames {
#   croak("Usage: GetBlockFmtNames()") if @_ != 1;
#   my $self = shift;
#   first create a IDispatch interface IDEGetBlockFmtNamesParam  ??
#   call $self->SUPER::CallMethod ("ExecCommand", 5012, 2, );
#   list all value
# }
#   DECMD_GETFONTNAME = 5013 | Return a string with font name or empty string
sub GetFontName {
  croak("Usage: GetFontName()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5013, 0);
}
#   DECMD_GETFONTSIZE = 5014 | Return a font (1-7) size or empty string
sub GetFontSize {
  croak("Usage: GetFontSize()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5014, 0);
}
#   DECMD_GETFORECOLOR = 5015 | Return a string #RRGGBB or empty string
sub GetForeColor {
  croak("Usage: GetForeColor()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5015, 2);
}
#   DECMD_HYPERLINK = 5016 | Add an LINK (no dialog if url on parametre)
sub HyperLink {
  croak("Usage: HyperLink([url])") if (@_ != 1 && @_ != 2);
  my ($self, $url) = @_;

  if (defined $url) {
    return $self->SUPER::CallMethod ("ExecCommand", 5016, 2, $url);
  }
  else {
    return $self->SUPER::CallMethod ("ExecCommand", 5016, 1);
  }
}
#   DECMD_IMAGE = 5017 | Add an IMAGE (no dialog if url on parametre)
sub Image {
  croak("Usage: Image([url])") if (@_ != 1 && @_ != 2);
  my ($self, $url) = @_;

  if (defined $url) {
    return $self->SUPER::CallMethod ("ExecCommand", 5017, 2, $url);
  }
  else {
    return $self->SUPER::CallMethod ("ExecCommand", 5017, 1);
  }
}
#   DECMD_INDENT = 5018,
sub Indent {
  croak("Usage: Indent()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5018, 0);
}
#   DECMD_INSERTCELL = 5019,
sub InsertCell {
  croak("Usage: InsertCell()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5019, 0);
}
#   DECMD_INSERTCOL = 5020,
sub InsertCol {
  croak("Usage: InsertCol()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5020, 0);
}
#   DECMD_INSERTROW = 5021,
sub InsertRow {
  croak("Usage: InsertRow()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5021, 0);
}
#   DECMD_INSERTTABLE = 5022,
# TODO : PARAM SafeArray
#  Element 1 : I4 number of row
#  Element 2 : I4 number of line
#  Element 3 : BSTR Table attribut ex: "BORDER=1 BGCOLOR=black"
#  Element 4 : BSTR Cell atribut ex : "BGCOLOR=white"
#  Element 5 : BSTR Table caption
sub InsertTable {
   croak("Usage: InsertTable()") if @_ != 1;
   my $self = shift;
   return $self->SUPER::CallMethod ("ExecCommand", 5022, 0);
}
#   DECMD_ITALIC = 5023,
sub Italic {
  croak("Usage: Italic()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5023, 0);
}
#   DECMD_JUSTIFYCENTER = 5024,
sub JustifyCenter {
  croak("Usage: JustifyCenter()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5024, 0);
}
#   DECMD_JUSTIFYLEFT = 5025,
sub JustifyLeft {
  croak("Usage: JustifyLeft()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5025, 0);
}
#   DECMD_JUSTIFYRIGHT = 5026,
sub JustifyRight {
  croak("Usage: JustifyRight()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5026, 0);
}
#   DECMD_LOCK_ELEMENT = 5027,
sub LockElement {
  croak("Usage: LockElement()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5027, 0);
}
#   DECMD_MAKE_ABSOLUTE = 5028,
sub MakeAbsolute {
  croak("Usage: MakeAbsolute()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5028, 0);
}
#   DECMD_MERGECELLS = 5029,
sub MergeCells {
  croak("Usage: MergeCells()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5029, 0);
}
#   DECMD_ORDERLIST = 5030,
sub OrderList {
  croak("Usage: OrderList()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5030, 0);
}
#   DECMD_OUTDENT = 5031,
sub Outdent {
  croak("Usage: Outdent()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5031, 0);
}
#   DECMD_PASTE = 5032,
sub Paste {
  croak("Usage: Paste()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5032, 0);
}
#   DECMD_REDO = 5033,
sub Redo {
  croak("Usage: Redo()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5033, 0);
}
#   DECMD_REMOVEFORMAT = 5034,
sub RemoveFormat {
  croak("Usage: RemoveFormat()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5034, 0);
}
#   DECMD_SELECTALL = 5035,
sub SelectAll {
  croak("Usage: SelectAll()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5035, 0);
}
#   DECMD_SEND_BACKWARD = 5036,
sub SendBackward {
  croak("Usage: SendBackward()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5036, 0);
}
#   DECMD_BRING_FORWARD = 5037,
sub BringForward {
  croak("Usage: BringForward()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5037, 0);
}
#   DECMD_SEND_BELOW_TEXT = 5038,
sub SendBelowText {
  croak("Usage: SendBelowText()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5038, 0);
}
#   DECMD_BRING_ABOVE_TEXT = 5039,
sub BringAboveText {
  croak("Usage: BringAboveText()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5039, 0);
}
#   DECMD_SEND_TO_BACK = 5040,
sub SendToBack {
  croak("Usage: SendToBack()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5040, 0);
}
#   DECMD_BRING_TO_FRONT = 5041,
sub BringToFront {
  croak("Usage: BringToFront()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5041, 0);
}
#   DECMD_SETBACKCOLOR = 5042,
sub SetBackColor {
  croak("Usage: SetBackColor(colorstring)") if @_ != 2;
  my ($self, $value)  = @_;
  return $self->SUPER::CallMethod ("ExecCommand", 5042, 0, $value);
}
#   DECMD_SETBLOCKFMT = 5043,
sub SetBlockFmt {
  croak("Usage: SetBlockFmt(formatstring)") if @_ != 1;
  my ($self, $value)  = @_;
  return $self->SUPER::CallMethod ("ExecCommand", 5043, 0, $value);
}
#   DECMD_SETFONTNAME = 5044,
sub SetFontName {
  croak("Usage: SetFontName(namestring)") if @_ != 1;
  my ($self, $value)  = @_;
  return $self->SUPER::CallMethod ("ExecCommand", 5044, 0, $value);
}
#   DECMD_SETFONTSIZE = 5045,
sub SetFontSize {
  croak("Usage: SetFontSize(size)") if @_ != 1;
  my ($self, $value)  = @_;
  return $self->SUPER::CallMethod ("ExecCommand", 5045, 0, $value);
}
#   DECMD_SETFORECOLOR = 5046,
sub SetForeColor {
  croak("Usage: SetForeColor(colorstring)") if @_ != 1;
  my ($self, $value)  = @_;
  return $self->SUPER::CallMethod ("ExecCommand", 5046, 0, $value);
}
#   DECMD_SPLITCELL = 5047,
sub SplitCell {
  croak("Usage: SplitCell()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5047, 0);
}
#   DECMD_UNDERLINE = 5048,
sub Underline {
  croak("Usage: Underline()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5048, 0);
}
#   DECMD_UNDO = 5049,
sub Undo {
  croak("Usage: Undo()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5049, 0);
}
#   DECMD_UNLINK = 5050,
sub Unlink {
  croak("Usage: Unlink()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5050, 0);
}
#   DECMD_UNORDERLIST = 5051,
sub UnOrderList {
  croak("Usage: UnOrderList()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5051, 0);
}
#   DECMD_PROPERTIES = 5052
sub Properties {
  croak("Usage: Properties()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5052, 0);
}

#
# QueryStatut
#
#    Constants for DHTMLEdit QueryStatus
# enum {
#    DECMDF_NOTSUPPORTED = 0,
#    DECMDF_DISABLED = 1,
#    DECMDF_ENABLED = 3,
#    DECMDF_LATCHED = 7,
#    DECMDF_NINCHED = 11
# } DHTMLEDITCMDF;
#

# TODO : Check if it's work for all

#  DECMD_BOLD = 5000,
sub QueryBold {
  croak("Usage: QueryBold ()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5000);
}
#   DECMD_COPY = 5002,
sub QueryCopy {
  croak("Usage: QueryCopy ()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5002);
}
#   DECMD_CUT = 5003,
sub QueryCut {
  croak("Usage: QueryCut ()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5003);
}
#   DECMD_DELETE = 5004,
sub QueryDelete {
  croak("Usage: QueryDelete ()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5004);
}
#   DECMD_DELETECELLS = 5005,
sub QueryDeleteCells {
  croak("Usage: QueryDeleteCells()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5005);
}
#   DECMD_DELETECOLS = 5006,
sub QueryDeleteCols {
  croak("Usage: QueryDeleteCols()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5006);
}
#   DECMD_DELETEROWS = 5007,
sub QueryDeleteRows {
  croak("Usage: QueryDeleteRows()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5007);
}
#   DECMD_FINDTEXT = 5008,
sub QueryFindText {
  croak("Usage: QueryFindText()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5008);
}
#   DECMD_FONT = 5009,
sub QueryFont {
  croak("Usage: QueryFont()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5009);
}
#   DECMD_GETBACKCOLOR = 5010,
sub QueryGetBackColor {
  croak("Usage: QueryGetBackColor()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5010);
}
#   DECMD_GETBLOCKFMT = 5011,
sub QueryGetBlockFmt {
  croak("Usage: QueryGetBlockFmt()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5011);
}
#   DECMD_GETBLOCKFMTNAMES = 5012,
sub QueryGetBlockFmtNames {
  croak("Usage: QueryGetBlockFmtNames()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5012);
}
#   DECMD_GETFONTNAME = 5013,
sub QueryGetFontName {
  croak("Usage: QueryGetFontName()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5013);
}
#   DECMD_GETFONTSIZE = 5014,
sub QueryGetFontSize {
  croak("Usage: QueryGetFontSize()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5014);
}
#   DECMD_GETFORECOLOR = 5015,
sub QueryGetForeColor {
  croak("Usage: QueryGetForeColor()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5015);
}
#   DECMD_HYPERLINK = 5016,
sub QueryHyperLink {
  croak("Usage: QueryHyperLink()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5016);
}
#   DECMD_IMAGE = 5017,
sub QueryImage {
  croak("Usage: QueryImage()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5017);
}
#   DECMD_INDENT = 5018,
sub QueryIndent {
  croak("Usage: QueryIndent()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5018);
}
#   DECMD_INSERTCELL = 5019,
sub QueryInsertCell {
  croak("Usage: QueryInsertCell()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5019);
}
#   DECMD_INSERTCOL = 5020,
sub QueryInsertCol {
  croak("Usage: QueryInsertCol()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5020);
}
#   DECMD_INSERTROW = 5021,
sub QueryInsertRow {
  croak("Usage: QueryInsertRow()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5021);
}
#   DECMD_INSERTTABLE = 5022,
sub QueryInsertTable {
  croak("Usage: QueryInsertTable()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5022);
}
#   DECMD_ITALIC = 5023,
sub QueryItalic {
  croak("Usage: QueryItalic()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5023);
}
#   DECMD_JUSTIFYCENTER = 5024,
sub QueryJustifyCenter {
  croak("Usage: QueryJustifyCenter()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5024);
}
#   DECMD_JUSTIFYLEFT = 5025,
sub QueryJustifyLeft {
  croak("Usage: QueryJustifyLeft()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5025);
}
#   DECMD_JUSTIFYRIGHT = 5026,
sub QueryJustifyRight {
  croak("Usage: QueryJustifyRight()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5026);
}
#   DECMD_LOCK_ELEMENT = 5027,
sub QueryLockElement {
  croak("Usage: QueryLockElement()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5027);
}
#   DECMD_MAKE_ABSOLUTE = 5028,
sub QueryMakeAbsolute {
  croak("Usage: QueryMakeAbsolute()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5028);
}
#   DECMD_MERGECELLS = 5029,
sub QueryMergeCells {
  croak("Usage: QueryMergeCells()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5029);
}
#   DECMD_ORDERLIST = 5030,
sub QueryOrderList {
  croak("Usage: QueryOrderList()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5030);
}
#   DECMD_OUTDENT = 5031,
sub QueryOutDent {
  croak("Usage: QueryOutDent()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5031);
}
#   DECMD_PASTE = 5032,
sub QueryPaste {
  croak("Usage: QueryPaste()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5032);
}
#   DECMD_REDO = 5033,
sub QueryRedo {
  croak("Usage: QueryRedo()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5033);
}
#   DECMD_REMOVEFORMAT = 5034,
sub QueryRemoveFormat {
  croak("Usage: QueryRemoveFormat()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5034);
}
#   DECMD_SELECTALL = 5035,
sub QuerySelectAll {
  croak("Usage: QuerySelectAll()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5035);
}
#   DECMD_SEND_BACKWARD = 5036,
sub QuerySendBackward {
  croak("Usage: QuerySendBackward()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5036);
}
#   DECMD_BRING_FORWARD = 5037,
sub QueryBringForward {
  croak("Usage: QueryBringForward()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5037);
}
#   DECMD_SEND_BELOW_TEXT = 5038,
sub QuerySendBelowText {
  croak("Usage: QuerySendBelowText()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("ExecCommand", 5038);
}
#   DECMD_BRING_ABOVE_TEXT = 5039,
sub QueryBringAboveText {
  croak("Usage: QueryBringAboveText()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5039);
}
#   DECMD_SEND_TO_BACK = 5040,
sub QuerySendToBack {
  croak("Usage: QuerySendToBack()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5040);
}
#   DECMD_BRING_TO_FRONT = 5041,
sub QueryBringToFront {
  croak("Usage: QueryBringToFront()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5041);
}
#   DECMD_SETBACKCOLOR = 5042,
sub QuerySetBackColor {
  croak("Usage: QuerySetBackColor()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5042);
}
#   DECMD_SETBLOCKFMT = 5043,
sub QuerySetBlockFmt {
  croak("Usage: QuerySetBlockFmt()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5043);
}
#   DECMD_SETFONTNAME = 5044,
sub QuerySetFontName {
  croak("Usage: QuerySetFontName()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5044);
}
#   DECMD_SETFONTSIZE = 5045,
sub QuerySetFontSize {
  croak("Usage: QuerySetFontSize()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5045);
}
#   DECMD_SETFORECOLOR = 5046,
sub QuerySetForeColor {
  croak("Usage: QuerySetForeColor()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5046);
}
#   DECMD_SPLITCELL = 5047,
sub QuerySplitCell {
  croak("Usage: QuerySplitCell()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5047);
}
#   DECMD_UNDERLINE = 5048,
sub QueryUnderline {
  croak("Usage: QueryUnderline()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5048);
}
#   DECMD_UNDO = 5049,
sub QueryUndo {
  croak("Usage: QueryUndo()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5049);
}
#   DECMD_UNLINK = 5050,
sub QueryUnlink {
  croak("Usage: QueryUnlink()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5050);
}
#   DECMD_UNORDERLIST = 5051,
sub QueryUnOrderList {
  croak("Usage: QueryUnOrderList()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5051);
}
#   DECMD_PROPERTIES = 5052
sub QueryProperties {
  croak("Usage: QueryProperties()") if @_ != 1;
  my $self = shift;
  return $self->SUPER::CallMethod ("QueryStatus", 5052);
}

#########################################################################
#                          P R O P E R T Y                              #
#########################################################################

#
# DocumentHTML
#

sub DocumentHTML {

  croak("Usage: DocumentHTML ([string])") if (@_ == 0 || @_ > 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("DocumentHTML" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("DocumentHTML");
  }
}

#
# BrowseMode
#

sub BrowseMode {

  croak("Usage: BrowseMode ([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) = @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("BrowseMode" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("BrowseMode");
  }
}

#
# ActivateApplets
#

sub ActivateApplets {

  croak("Usage: ActivateApplets ([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("ActivateApplets" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("ActivateApplets");
  }
}

#
# ActivateActiveXControls
#

sub ActivateApplets {

  croak("Usage: ActivateActiveXControls([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("ActivateActiveXControls" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("ActivateActiveXControls");
  }
}

#
# ActivateDTCs
#

sub ActivateDTCs {

  croak("Usage: ActivateDTCs([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("ActivateDTCs" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("ActivateDTCs");
  }
}

#
# ShowDetails
#

sub ShowDetails {

  croak("Usage: ShowDetails([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("ShowDetails" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("ShowDetails");
  }
}

#
# ShowBorders
#

sub ShowBorders {

  croak("Usage: ShowBorders([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("ShowBorders" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("ShowBorders");
  }
}

#
# Appearance
#

sub Appearance {

  croak("Usage: Appearance([FLAT=0/3D=1])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("Appearance" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("Appearance");
  }
}

#
# Scrollbars
#

sub Scrollbars {

  croak("Usage: Scrollbars([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;;

  if (defined $value) {
    return $self->SUPER::SetProperty ("Scrollbars" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("Scrollbars");
  }
}

#
# ScrollbarAppearance
#

sub ScrollbarAppearance {

  croak("Usage: ScrollbarAppearance([FLAT=0/3D=1])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("ScrollbarAppearance" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("ScrollbarAppearance");
  }
}

#
# SourceCodePreservation
#

sub SourceCodePreservation {

  croak("Usage: SourceCodePreservation([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("SourceCodePreservation" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("SourceCodePreservation");
  }
}

#
# AbsoluteDropMode
#

sub AbsoluteDropMode {

  croak("Usage: AbsoluteDropMode([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("AbsoluteDropMode" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("AbsoluteDropMode");
  }
}

#
# SnapToGridX
#

sub SnapToGridX {

  croak("Usage: SnapToGridX([LONG])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("SnapToGridX" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("SnapToGridX");
  }
}

#
# SnapToGridY
#

sub SnapToGridY {

  croak("Usage: SnapToGridY([LONG])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("SnapToGridY" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("SnapToGridY");
  }
}

#
# SnapToGrid
#

sub SnapToGrid {

  croak("Usage: SnapToGrid ([LONG])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("SnapToGrid" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("SnapToGrid");
  }
}


#
# BaseURL
#

sub BaseURL {

  croak("Usage: BaseURL([String])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("BaseURL" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("BaseURL");
  }
}

#
# UseDivOnCarriageReturn
#

sub UseDivOnCarriageReturn {

  croak("Usage: UseDivOnCarriageReturn([BOOL])") if (@_ == 0 || @_ > 2);

  my ($self, $value) =  @_;

  if (defined $value) {
    return $self->SUPER::SetProperty ("UseDivOnCarriageReturn" , $value);
  }
  else {
    return $self->SUPER::GetProperty ("UseDivOnCarriageReturn");
  }
}

#
# IsDirty
#

sub IsDirty {

  croak("Usage: IsDirty ()") if (@_ != 1);

  my ($self) = @_;

  return $self->SUPER::GetProperty ("IsDirty");
}


#
# CurrentDocumentPath
#

sub CurrentDocumentPath{

  croak("Usage: CurrentDocumentPath()") if (@_ != 1);

  my ($self) = @_;

  return $self->SUPER::GetProperty ("CurrentDocumentPath");
}

#
# CurrentDocumentPath
#

sub CurrentDocumentPath{

  croak("Usage: CurrentDocumentPath()") if (@_ != 1);

  my ($self) = @_;

  return $self->SUPER::GetProperty ("CurrentDocumentPath");
}


#
# DocumentTitle
#

sub CurrentDocumentPath{

  croak("Usage: DocumentTitle()") if (@_ != 1);

  my ($self) = @_;

  return $self->SUPER::GetProperty ("DocumentTitle");
}

#
# Busy
#

sub IsBusy {

  croak("Usage: IsBusy ()") if (@_ != 1);

  my ($self) = @_;

  return $self->SUPER::GetProperty ("Busy");
}


#########################################################################
#                            E V E N T                                  #
#########################################################################

#
# DocumentComplete
#

sub OnDocumentComplete {

  croak("Usage: OnDocumentComplete (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("DocumentComplete", $callback);
}

#
# DisplayChanged
#

sub OnDisplayChanged {

  croak("Usage: OnDisplayChanged (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("DisplayChanged", $callback);
}

#
# ShowContextMenu  (long xPos, long yPos)
#

sub OnShowContextMenu {

  croak("Usage: OnShowContextMenu (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("ShowContextMenu", $callback);
}

#
# ContextMenuAction (long itemIndex)
#

sub OnContextMenuAction {

  croak("Usage: OnContextMenuAction (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("ContextMenuAction", $callback);
}

#
# onmousedown
#

sub OnMouseDown {

  croak("Usage: OnMouseDown (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onmousedown", $callback);
}

#
# onmousemove
#

sub OnMouseMove {

  croak("Usage: OnMouseMove (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onmousemove", $callback);
}

#
# onmouseup
#

sub OnMouseUp {

  croak("Usage: OnMouseUp (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onmouseup", $callback);
}

#
# onmouseout
#

sub OnMouseOut {

  croak("Usage: OnMouseOut (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onmouseout", $callback);
}

#
# onmouseover
#

sub OnMouseOver {

  croak("Usage: OnMouseOver (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onmouseover", $callback);
}

#
# onclick
#

sub OnClick {

  croak("Usage: OnClick (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onclick", $callback);
}

#
# ondblclick
#

sub OnDblClick {

  croak("Usage: OnDblClick (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("ondblclick", $callback);
}

#
# onkeydown
#

sub OnKeyDown {

  croak("Usage: OnKeyDown (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onkeydown", $callback);
}

#
# onkeypress
#

sub OnKeyPress {

  croak("Usage: OnKeyPress (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onkeypress", $callback);
}

#
# onkeyup
#

sub OnKeyUp {

  croak("Usage: OnKeyUp (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onkeyup", $callback);
}

#
# onblur
#

sub OnBlur {

  croak("Usage: OnBlur (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onblur", $callback);
}

#
# onreadystatechange
#

sub OnReadyStateChange {

  croak("Usage: OnReadyStateChange (CallBack)") if (@_ != 2);

  my ($self, $callback) = @_;

  $self->RegisterEvent ("onreadystatechange", $callback);
}

1;
