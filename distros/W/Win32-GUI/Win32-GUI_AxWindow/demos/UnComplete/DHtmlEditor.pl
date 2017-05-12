# perl -w
#
#  Hosting DHtmlEdit and use wrapper package
#
#
use Cwd;
use Win32::GUI;
use DHtmlEdit;

my $HtmlFile  = "";
my $Directory = cwd;

# main menu
my $Menu =  Win32::GUI::MakeMenu(
    "&File"                   => "File",
    "   > &New..."            => "FileNew",
    "   > &Open..."           => "FileOpen",
    "   > -"                  => 0,
    "   > &Save"              => "FileSave",
    "   > Save &As..."        => "FileSaveAs",
    "   > -"                  => 0,
    "   > &Print"             => "FilePrint",
    "   > -"                  => 0,
    "   > &Directory..."      => "FileDirectory",
    "   > -"                  => 0,
    "   > E&xit"              => "FileExit",
    "&Edit"                   => "Edit",
    "   > &Undo"              => "EditUndo",
    "   > &Redo"              => "EditRedo",
    "   > -"                  => 0,
    "   > Cu&t"               => "EditCut",
    "   > &Copy"              => "EditCopy",
    "   > &Paste"             => "EditPaste",
    "   > -"                  => 0,
    "   > &Select All"        => "EditSelectAll",
    "   > &Delete"            => "EditDelete",
    "   > -"                  => 0,
    "   > &Find "             => "EditFind",
    "&Format"                 => "Format",
    "   > &Bold"              => "FormatBold",
    "   > &Italic"            => "FormatItalic",
    "   > &Underline"         => "FormatUnderline",
    "   > &Font..."           => "FormatFont",
    "   > -"                  => 0,
    "   > Justify &Left"      => "FormatJustifyLeft",
    "   > Justify &Center"    => "FormatJustifyCenter",
    "   > Justify &Right"     => "FormatJustifyRight",
    "   > -"                  => 0,
    "   > &Indent"            => "FormatIndent",
    "   > &Outdent"           => "FormatOutdent",
    "&Insert"                 => "Insert",
    "   > &HyperLink..."      => "InsertHyperLink",
    "   > &Image..."          => "InsertImage",
    "   > -"                  => 0,
    "   > &OrderList"         => "InsertOrderList",
    "   > &UnOrderList"       => "InsertUnOrderList",
    "   > -"                  => 0,
    "   > &Unlink"            => "InsertUnlink",
    "&Help"                   => "Help",
    "   > &About"             => "HelpAbout",
    );

# main Window
$Window = new Win32::GUI::Window (
    -name     => "Window",
    -title    => "Win32::GUI::AxWindow test",
    -pos      => [100, 100],
    -size     => [400, 400],
    -menu     => $Menu,
) or die "new Window";

# Create AxWindow
$Control = new Win32::GUI::DHtmlEdit  (
               -parent  => $Window,
               -name    => "Control",
               -pos     => [0, 0],
               -size    => [400, 400],
 ) or die "new Control";

# Method call
$Control->DocumentHTML('<HTML><BODY><B>Hello World !!!</B></BODY></HTML>');

# Event handler

$Control->OnDisplayChanged ( "Event_DisplayChanged" );

# Event loop
$Window->Show();
Win32::GUI::Dialog();

sub Event_DisplayChanged {

  my $self = shift;

  # Check Edit menu

  if ($Control->QueryUndo() == 3) { $Menu->{EditUndo}->Enabled(1); }
                             else { $Menu->{EditUndo}->Enabled(0); }

  if ($Control->QueryRedo() == 3) { $Menu->{EditRedo}->Enabled(1); }
                             else { $Menu->{EditRedo}->Enabled(0); }

  if ($Control->QueryCut() == 3)  { $Menu->{EditCut}->Enabled(1);  }
                             else { $Menu->{EditCut}->Enabled(0);  }

  if ($Control->QueryCopy() == 3) { $Menu->{EditCopy}->Enabled(1); }
                             else { $Menu->{EditCopy}->Enabled(0); }

  if ($Control->QueryPaste() == 3) { $Menu->{EditPaste}->Enabled(1); }
                              else { $Menu->{EditPaste}->Enabled(0); }

  if ($Control->QuerySelectAll() == 3) { $Menu->{EditSelectAll}->Enabled(1); }
                                  else { $Menu->{EditSelectAll}->Enabled(0); }

  if ($Control->QueryDelete() == 3) { $Menu->{EditDelete}->Enabled(1); }
                               else { $Menu->{EditDelete}->Enabled(0); }

}

# Finish method
sub Finish {

  # Change after last save.
  if ($Control->IsDirty()) {
    FileSave_Click();
  }

  return -1;
}

# Main window event handler

sub Window_Terminate {

  return Finish ();
}

sub Window_Resize {

  if (defined $Window) {
    ($width, $height) = ($Window->GetClientRect)[2..3];
    $Control->Move   (0, 0);
    $Control->Resize ($width, $height);
  }
}

#######################################################################
#
#  File Menu
#
#######################################################################

# New
sub FileNew_Click {

  $Control->NewDocument ();
  $HtmlFile = "";
}

# Open
sub FileOpen_Click {

  my $ret = Win32::GUI::GetOpenFileName(
                 -title     => "Open html File",
                 -filter    => [
                     "Html Document (*.htm, *.html)" => "*.htm;*.html",
                     "All files", "*.*",
                               ],
                 -directory => $Directory,
                 );
  if ($ret) {

    $HtmlFile = $ret;
    $Control->LoadDocument ($HtmlFile);

  }
  elsif (Win32::GUI::CommDlgExtendedError()) {
     Win32::GUI::MessageBox (0, "ERROR : ".Win32::GUI::CommDlgExtendedError(),
                            "GetOpenFileName Error");
  }
}

# Save
sub FileSave_Click {

  unless ($HtmlFile eq "") {
    my $ret = Win32::GUI::MessageBox (0, "Overwrite existing file ?",
                           "Save",MB_ICONQUESTION | MB_YESNOCANCEL);
    if ($ret == 6) {
      $ret = $Control->SaveDocument ($HtmlFile);
      unless ($ret) {
        Win32::GUI::MessageBox (0, "ERROR : SaveDocument ", "Save Error");
      }
    }
    elsif ($ret == 7) {
      FileSaveAs_Click();
    }
  }
  else {
    FileSaveAs_Click();
  }
}

# SaveAs
sub FileSaveAs_Click {

  my $ret = Win32::GUI::GetSaveFileName(
                 -title     => "Save html File As",
                 -filter    => ["Html Document (*.htm, *.html)" => "*.htm;*.html"],
                 -directory => $Directory,
                 );

  if ($ret) {
    $HtmlFile = $ret;
    $ret = $Control->SaveDocument ($HtmlFile);
    unless ($ret) {
      Win32::GUI::MessageBox (0, "ERROR : SaveDocument ", "Save Error");
    }
  }
  elsif (Win32::GUI::CommDlgExtendedError()) {
     Win32::GUI::MessageBox (0, "ERROR : ".Win32::GUI::CommDlgExtendedError(),
                            "GetSaveFileName Error");
  }

}

# Print
sub FilePrint_Click {

  $ret = $Control->PrintDocument (1);
}

# Directory
sub FileDirectory_Click {

  my $ret = Win32::GUI::BrowseForFolder (
                        -title      => "Select default directory",
                        -directory  => $Directory,
                        -folderonly => 1,
                        );
  $Directory = $ret if ($ret);
}

# Exit
sub FileExit_Click {

  return Finish();
}

#######################################################################
#
#  Edit Menu
#
#######################################################################

sub EditUndo_Click {
  $Control->Undo();
}

sub EditRedo_Click {
  $Control->Redo();
}

sub EditCut_Click {
  $Control->Cut();
}

sub EditCopy_Click {
  $Control->Copy();
}

sub EditPaste_Click {
  $Control->Paste();
}

sub EditSelectAll_Click {
  $Control->SelectAll();
}

sub EditDelete_Click {
  $Control->Delete();
}

sub EditFind_Click {
  $Control->FindText();
}

#######################################################################
#
#  Format Menu
#
#######################################################################

sub FormatBold_Click {
  $Control->Bold();
}

sub FormatItalic_Click {
  $Control->Italic();
}

sub FormatUnderline_Click {
  $Control->Underline();
}

sub FormatFont_Click {
  $Control->Font();
}

sub FormatJustifyLeft_Click {
  $Control->JustifyLeft();
}

sub FormatJustifyCenter_Click {
  $Control->JustifyCenter();
}

sub FormatJustifyRight_Click {
  $Control->JustifyRight();
}

sub FormatIndent_Click {
  $Control->Indent();
}

sub FormatOutdent_Click {
  $Control->Outdent();
}

#######################################################################
#
#  Insert Menu
#
#######################################################################

sub InsertHyperLink_Click {
  $Control->HyperLink();
}

sub InsertImage_Click {
  $Control->Image();
}

sub InsertOrderList {
  $Control->OrderList();
}

sub InsertUnOrderList {
  $Control->UnOrderList();
}

sub InsertUnlink_Click {
  $Control->Unlink();
}

#######################################################################
#
#  Help Menu
#
#######################################################################

sub HelpAbout_Click {

  Win32::GUI::MessageBox (0, "Perl Html Editor 0.1 by Laurent Rocher",
                         "About",MB_ICONINFORMATION);

}

