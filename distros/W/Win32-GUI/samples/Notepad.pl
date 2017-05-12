#! perl -w
#######################################################################
#  NotePad.pl : Notepad clone with Perl & Win32::GUI.
#######################################################################

use strict;
use warnings;
use Win32::GUI qw( MB_ICONQUESTION MB_ICONINFORMATION MB_YESNOCANCEL
                   MB_OK IDYES IDCANCEL );

my $CurrentFile = "";

my $FindDlg;

my $EditFont = new Win32::GUI::Font (
	-name => "Fixedsys",
	-size => 12,
    );

# Make Menu
my $Menu = Win32::GUI::MakeMenu(
    "&File"                => "File",
    " > &New"              => { -name => "Exit",       -onClick => \&Notepad_OnNewFile },
    " > &Open..."          => { -name => "Open",       -onClick => \&Notepad_OnOpenFile },
    " > &Save"             => { -name => "Save",       -onClick => \&Notepad_OnSaveFile },
    " > Save &As ..."      => { -name => "SaveAs",     -onClick => \&Notepad_OnSaveAsFile },
    " > -"                 => 0,
    " > Print &Setup ..."  => { -name => "PrintSetup", -enabled => 0 },
    " > &Print"            => { -name => "Print",      -enabled => 0 },
    " > -"                 => 0,
    " > E&xit"             => { -name => "Exit",       -onClick => \&Notepad_OnQuitFile },
    "&Edit"                => "Edit",
    " > &Undo"             => { -name => "Undo",
                                -onClick => sub { my $self = shift; $self->Edit->Undo(); 0; }
                              },
    " > -"                 => 0,
    " > Cu&t"              => { -name => "Cut",
                                -onClick => sub { my $self = shift; $self->Edit->Cut();  0; }
                              },
    " > &Copy"             => { -name => "Copy",
                                -onClick => sub { my $self = shift; $self->Edit->Copy(); 0; }
                              },
    " > &Paste"            => { -name => "Paste",
                                -onClick => sub { my $self = shift; $self->Edit->Paste(); 0; }
                              },
    " > &Delete"           => { -name => "Delete",
                                -onClick => sub { my $self = shift; $self->Edit->Clear(); 0; }
                              },
    " > -"                 => 0,
    " > &Select All"       => { -name => "SelectAll",
                                -onClick => sub { my $self = shift; $self->Edit->SelectAll(); 0; }
                              },
    " > -"                 => 0,
    " > Choose &Font..."   => { -name => "ChooseFont", -onClick => \&Notepad_OnChooseFont },
    "F&ind"                => "_Find",
    " > &Find..."          => { -name => "Find",       -onClick => \&Notepad_OnFind  },
    " > Find &Next"        => { -name => "FindNext",   -onClick => \&Notepad_FindText },
    "&?"                   => "?",
    " > &Help"             => { -name => "Help",       -enabled => 0  },
    " > -"                 => 0,
    " > &About"            => { -name => "About",      -onClick => \&Notepad_OnAbout },
);

# Create Main Window
my $Window = new Win32::GUI::Window (
    -name     => "Window",
    -title    => "Notepad",
    -pos      => [100, 100],
    -size     => [400, 400],
    -menu     => $Menu,
    -onResize   => \&Notepad_OnSize,
    -onInitMenu => \&Notepad_OnInitMenu,
    -onTerminate => \&Notepad_OnQuitFile, 

) or die "new Window";

# Create Textfield for Edit Text
$Window->AddTextfield(
    -name      => "Edit",
    -pos       => [0, 0],
    -size      => [100, 100],
    -multiline => 1,
    -hscroll   => 1,
    -vscroll   => 1,
    -autohscroll => 1,
    -autovscroll => 1,
    -keepselection => 1 ,
    -font => $EditFont,
);

# Create Find DialogBox
$FindDlg = new Win32::GUI::DialogBox(
              -name  => "FindDlg",
              -title => "Find",
              -pos   => [ 150, 150 ],
              -size  => [ 360, 115 ],
              -parent => $Window,       # Set $Window as parent for be modeless but not Top.
      );

# Text to find
$FindDlg->AddTextfield (
              -name  => "FindDlg_Text",              
              -pos   => [10, 12],
              -size  => [220, 21],              
              -prompt  => [ "Find : ", 30],
              -tabstop => 1,
              -onChange => sub { $FindDlg->FindDlg_Find->Enable(length($FindDlg->FindDlg_Text->Text) != 0); 0; },
      );

# Case sensitive checkbox
$FindDlg->AddCheckbox (
              -name  => "FindDlg_Case",
              -text  => "Match case",
              -pos   => [10, 60],
              -size  => [100, 21],
              -tabstop => 1,
      );

# 
$FindDlg->AddGroupbox(
              -text  => "Direction",
              -pos   => [140, 40],
              -size  => [120, 40],
      );
# Search Up RadioButton
$FindDlg->AddRadioButton(
              -name  => "FindDlg_FindUp",
              -text  => "Up",
              -pos   => [150, 55],
              -size  => [50,  20],
              -group => 1,
      );

# Search Down RadioButton
$FindDlg->AddRadioButton(
              -name  => "FindDlg_FindDown",
              -text  => "Down",
              -pos   => [200, 55],
              -size  => [50, 20],
              -tabstop => 1,
              -checked => 1,
      );

# Find button
$FindDlg->AddButton (
              -name  => "FindDlg_Find",
              -text  => "&Find",
              -pos   => [270, 10],
              -size  => [75 , 21],
              -onClick => sub { Notepad_FindText($Window); 0; },
              -group => 1,
              -tabstop => 1,
      );

# Cancel Button
$FindDlg->AddButton (
              -name  => "FindDlg_Cancel",
              -text  => "C&ancel",
              -pos   => [270, 40],
              -size  => [75 , 21],
              -onClick => sub { $FindDlg->Hide(); 0; },
              -tabstop => 1,
      );

# Set Focus to Edit and show Window
$Window->Edit->SetFocus();
$Window->Show();

Win32::GUI::Dialog();

#######################################################################
#  Window Event

# Resize Window
sub Notepad_OnSize {
  my ($self) = @_;
  my ($width, $height) = ($self->GetClientRect())[2..3];
  $self->Edit->Resize($width+1, $height+1) if exists $self->{Edit};
}

# Refresh menu item
sub Notepad_OnInitMenu {
  my $self = shift;

  # File Menu

  # Edit Menu
  my $bSel = $self->Edit->HaveSel();

  $Menu->{Undo}->Enabled($self->Edit->CanUndo());
  $Menu->{Cut}->Enabled($bSel);
  $Menu->{Copy}->Enabled($bSel);
  $Menu->{Paste}->Enabled($self->Edit->CanPaste());
  $Menu->{Delete}->Enabled($bSel);

  # Find Menu
  $Menu->{FindNext}->Enabled(length($FindDlg->FindDlg_Text->Text) != 0);

  0;
}

#
#######################################################################

sub NotePad_CheckSaveCurrentFile {
  my $self = shift;

  # Check if need to save
  if ($self->Edit->Modify()) {

    my $ret = $self->MessageBox ( "Save current file ?",
                           "Notepad", MB_ICONQUESTION | MB_YESNOCANCEL);

    if ($ret == IDYES) {
        Notepad_OnSaveFile($self);
    }
    elsif ($ret == IDCANCEL) {
      return IDCANCEL;
    }
  }

  return IDYES;
}

# Find Text in Edit (search is defined by FindDlg)
sub Notepad_FindText {
  my $self = shift;

  my $text = $self->Edit->Text;                          # Get Edit text
  my $find = $FindDlg->FindDlg_Text->Text;               # Get text to find
  my ($start, $end) = $self->Edit->GetSel();             # Get current Edit Selection
  my $index;

  unless ( $FindDlg->FindDlg_Case->Checked() ) {         # Check for case unsensitive search
    $text = lc $text;                                    # Transform both to lowercase
    $find = lc $find;
  }

  if ($FindDlg->FindDlg_FindDown->Checked()) {           # Search to botton ?
    $index = index($text, $find, $end);
  } else {                                               # Or Search to Up ?
    $index = rindex($text, $find, $start-1);
  }

  if ($index >= 0) {
    $self->Edit->SetSel($index, $index + length $find);  # Select text found
    $self->Edit->ScrollCaret();                          # Make selected text visible
  } else {
    Win32::GUI::MessageBeep;                             # Sound if not found
  }

  0;
}

#######################################################################
#  Menu Event

#
#  File menu
#

# New File
sub Notepad_OnNewFile {
  my $self = shift;

  # Need to save current file ?
  return 0 if NotePad_CheckSaveCurrentFile($self) == IDCANCEL;

  # Set Default filename
  $CurrentFile = "";
  $self->Text("Notepad");                                # Change main window Title

  # Reset Edit
  $self->Edit->Text("");                                 # Set Edit text Empty
  $self->Edit->EmptyUndoBuffer();                        # Empty Undo buffer
  $self->Edit->Modify(0);                                # Set Modified state to false
  $self->Edit->SetFocus();                               # Focus to Edit
  0;
}

# Open file
sub Notepad_OnOpenFile {
  my $self = shift;

  # Need to save current file ?
  return 0 if NotePad_CheckSaveCurrentFile($self) == IDCANCEL;

  # Open a file
  my $file = Win32::GUI::GetOpenFileName(
                   -owner  => $Window,
                   -title  => "Open a text file",
                   -filter => [
                       'Perl script (*.pl)' => '*.pl',
                       'Text file (*.txt)' => '*.txt',
                       'All files' => '*.*',
                    ],
                   );

  # Load file
  if ($file) {
     # Keep Current file. 
     $CurrentFile = $file;
     $self->Text( "$CurrentFile - Notepad");

     # Load File in Edit
     $self->Edit->LockWindowUpdate;                       # Lock Painting on Edit
     $self->Edit->Text("");                               # Empty Edit

     open F, "<$file" or die "Open file : $file";
     while ( <F> ) {
       chomp;
       $self->Edit->Append($_."\r\n");                    # Need to add \r
     }
     close F;

     # Reset Edit
     $self->Edit->EmptyUndoBuffer();
     $self->Edit->Modify(0);
     $self->Edit->Select(0,0);                            # Set Cursor on first char
     $self->Edit->ScrollCaret();                          # Make cursor visible
     $self->Edit->LockWindowUpdate(1);                    # Unlock Painting on Edit
     $self->Edit->SetFocus();

  } elsif (Win32::GUI::CommDlgExtendedError()) {
     $self->MessageBox ("ERROR : ".Win32::GUI::CommDlgExtendedError(),
                        "GetOpenFileName Error");
  }
  0;
}

# Save File
sub Notepad_OnSaveFile {
  my $self = shift;

  # No filename, call SaveAs.
  return Notepad_OnSaveAsFile($self) unless (-f $CurrentFile );

  # Retrieve Text 
  my $text = $self->Edit->Text;
  $text =~ s/\r\n/\n/mg;                                  # Need to remove \r
   
  # Save file 
  open F, ">$CurrentFile" or die "Open file : $CurrentFile";
  print F $text;
  close F;

  # Reset Edit state
  $self->Edit->Modify(0);
  $self->Edit->SetFocus();

  0;
}

# Save File
sub Notepad_OnSaveAsFile {
  my $self = shift;

  # Open a file
  my $file = Win32::GUI::GetSaveFileName(
                   -owner  => $Window,
                   -title  => "Save As",
                   -file   => $CurrentFile,                   
                   -filter => [
                       'Perl script (*.pl)' => '*.pl',
                       'Text file (*.txt)' => '*.txt',
                       'All files' => '*.*',
                    ],
                   -defaultextension => "pl",
                   -createprompt => 1,
                   );

  # Save file
  if (defined $file) {
    # Keep Current file. 
    $CurrentFile = $file;
    $self->Text( "$CurrentFile - Notepad");

    # Retrieve Text 
    my $text = $self->Edit->Text();
    $text =~ s/\r\n/\n/mg;
   
    # Save file 
    open F, ">$file" or die "Open file : $file";
    print F $text;
    close F;

    # Reset Edit state
    $self->Edit->Modify(0);
    $self->Edit->SetFocus();

  } elsif (Win32::GUI::CommDlgExtendedError()) {
     $self->MessageBox ("ERROR : ".Win32::GUI::CommDlgExtendedError(),
                        "GetSaveFileName Error");
  }

  0;
}

# Quit Notepad
sub Notepad_OnQuitFile {

  my $self = shift;
  
  # Need to save current file ?
  if (NotePad_CheckSaveCurrentFile($self) == IDCANCEL) {
    return 0;
  } else {
    return -1;
  }
}

#
#  Edit menu
#

sub Notepad_OnChooseFont {
  my $self = shift;

  # Choose font
  my @font = Win32::GUI::ChooseFont(
                   -owner  => $Window, 
                   $EditFont->Info()
                   );

  if ($#font) {
    $EditFont = new Win32::GUI::Font (@font);
    $self->Edit->Change( -font => $EditFont);
    $self->Edit->Update();
  }

  0;
}

#
#  Find menu
#

sub Notepad_OnFind {

  # Set focus and Enable Find button as appropriate
  $FindDlg->FindDlg_Text->SetFocus;
  $FindDlg->FindDlg_Find->Enable(length($FindDlg->FindDlg_Text->Text) != 0);

  $FindDlg->Show();
  0;
}

#
#  Help menu
#

# About box
sub Notepad_OnAbout {
  my $self = shift;

  $self->MessageBox(
     "Perl Notepad, version 1.0\r\n".
     "Win32::GUI Demo",
     "About...",
     MB_ICONINFORMATION | MB_OK,
  );

  0;
}

#
#######################################################################
