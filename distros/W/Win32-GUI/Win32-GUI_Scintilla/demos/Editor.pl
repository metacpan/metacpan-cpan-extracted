#!perl -w
# Perl Editor
#-----------------------------------------------------------------------
# perl -v
use strict;
use warnings;

use Cwd;
use Win32::GUI qw(MB_OK MB_ICONQUESTION MB_ICONINFORMATION MB_YESNOCANCEL
                  WS_EX_CLIENTEDGE WS_CLIPCHILDREN);
use Win32::GUI::Scintilla::Perl();

my $VERSION = "1.0alpha2";
my $CurrentFile = "";
my $Directory = cwd;

my $Menu =  Win32::GUI::MakeMenu(
    "&File"                   => "File",
    "   > &New"               => "FileNew",
    "   > &Open..."           => "FileOpen",
    "   > -"                  => 0,
    "   > &Save"              => "FileSave",
    "   > &Save As..."        => "FileSaveAs",
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
    "   > &Delete"            => "EditClear",
    "   > -"                  => 0,
    "   > Select A&ll"        => "EditSelectAll",
    "   > -"                  => 0,
    "   > &Find..."           => "EditFind",
    "&Help"                   => "Help",
    "   > &About..."          => "HelpAbout",
    );

# main Window
my $Window = Win32::GUI::Window->new(
    -name      => "Window",
    -title     => "Perl Editor",
    -pos       => [100, 100],
    -size      => [400, 400],
    -pushstyle => WS_CLIPCHILDREN,
    -menu      => $Menu,
) or die "new Window";

# Create Scintilla Edit Window
my $Editor = $Window->AddScintillaPerl(
    -name       => "Editor",
    -pos        => [0, 0],
    -size       => [400, 400],
    -addexstyle => WS_EX_CLIENTEDGE,
) or die "new Edit";

# Create FindDlg window
my $FindDlg = CreateFindDlg();

# Event loop
$Window->Show();
Win32::GUI::Dialog();
$Window->Hide();

# Free FindDlg
$FindDlg->CloseWindow();

exit(0);

sub Editor_Notify {
    my (%evt) = @_;

    if ($evt{-code} == Win32::GUI::Scintilla::SCN_UPDATEUI) {
        # Update menu
        my $Sel = ($Editor->GetSelectionStart() !=  $Editor->GetSelectionEnd());
        $Menu->{EditUndo}->Enabled($Editor->CanUndo());
        $Menu->{EditRedo}->Enabled($Editor->CanRedo());
        $Menu->{EditCut}->Enabled($Sel);
        $Menu->{EditCopy}->Enabled($Sel);
        $Menu->{EditPaste}->Enabled($Editor->CanPaste());
        $Menu->{EditClear}->Enabled($Sel);

        # check for matching braces
        $Editor->BraceHighEvent();
    }
    elsif ($evt{-code} == Win32::GUI::Scintilla::SCN_MARGINCLICK) {
        # Click on folder margin
        if ($evt{-margin} == 2) {
            # Manage Folder
            $Editor->FolderEvent(%evt);
            # caret visible
            $Editor->ScrollCaret();
        }
    }
}

# Main window event handler
sub Window_Terminate {
    return FileExit_Click();
}

sub Window_Resize {
    if (defined $Window) {
        my ($width, $height) = ($Window->GetClientRect)[2..3];
        $Editor->Move   (0, 0);
        $Editor->Resize ($width, $height);
    }
    return 1;
}

#######################################################################
#
#  File Menu
#
#######################################################################

sub FileNew_Click {
    $Editor->NewFile();
    $CurrentFile = "";
    return 1;
}

sub FileOpen_Click {
    my $file = Win32::GUI::GetOpenFileName(
        -owner  => $Window,
        -title  => "Open a text file",
        -filter => [
                    'Perl script (*.pl)' => '*.pl',
                    'All files' => '*.*',
                   ],
        -directory => $Directory,
    );

    if ($file) {
        $Editor->LoadFile ($file);
        $CurrentFile = $file;
    }
    elsif (Win32::GUI::CommDlgExtendedError()) {
        Win32::GUI::MessageBox(0, "ERROR : ".Win32::GUI::CommDlgExtendedError(),
                            "GetOpenFileName Error");
    }
    return 1;
}

sub FileSave_Click {
    unless ($CurrentFile eq "") {
        my $ret = Win32::GUI::MessageBox (0, "Overwrite existing file ?",
                           "Save", MB_ICONQUESTION | MB_YESNOCANCEL);
        if ($ret == 6) {
            $ret = $Editor->SaveFile ($CurrentFile);
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
    return 1;
}

sub FileSaveAs_Click {
    my $ret = Win32::GUI::GetSaveFileName (
        -title     => "Save text file As",
        -filter => [
                    'Perl script (*.pl)' => '*.pl',
                    'All files' => '*.*',
                   ],
        -directory => $Directory,
    );

    if ($ret) {
        $CurrentFile = $ret;
        $ret = $Editor->SaveFile ($CurrentFile);
        unless ($ret) {
            Win32::GUI::MessageBox (0, "ERROR : SaveDocument ", "Save Error");
        }
    }
    elsif (Win32::GUI::CommDlgExtendedError()) {
        Win32::GUI::MessageBox (0, "ERROR : ".Win32::GUI::CommDlgExtendedError(),
                            "GetSaveFileName Error");
    }
    return 1;
}

sub FileDirectory_Click {
    my $ret = Win32::GUI::BrowseForFolder (
        -title      => "Select default directory",
        -directory  => $Directory,
        -folderonly => 1,
    );
    $Directory = $ret if ($ret);
    return 1;
}

sub FileExit_Click {
    return -1
}

#######################################################################
#
#  Edit Menu
#
#######################################################################

sub EditUndo_Click {
    $Editor->Undo();
    return 1;
}

sub EditRedo_Click {
    $Editor->Redo();
    return 1;
}

sub EditCut_Click {
    $Editor->Cut();
    return 1;
}

sub EditCopy_Click {
    $Editor->Copy();
    return 1;
}

sub EditPaste_Click {
    $Editor->Paste();
    return 1;
}

sub EditSelectAll_Click {
    $Editor->SelectAll();
    return 1;
}

sub EditClear_Click {
    $Editor->Clear();
    return 1;
}

sub EditFind_Click {
    $FindDlg->Show();
    return 1;
}

#######################################################################
#
#  Help Menu
#
#######################################################################

sub HelpAbout_Click  {
  Win32::GUI::MessageBox(
     0,
     "Perl Editor, version $VERSION\r\n".
     "Laurent ROCHER",
     "About...",
     MB_ICONINFORMATION | MB_OK,
  );

  return 1;
}

#######################################################################
#
#  FindWindow
#
#######################################################################

sub CreateFindDlg {

    my $FindDlg = new Win32::GUI::Window(
        -name  => "FindDlg",
        -title => "Find",
        -pos   => [ 150, 150 ],
        -size  => [ 270, 140 ],
    );

    $FindDlg->AddLabel (
        -name => "FindDlg_Label",
        -text => "Find what...",
        -pos  => [10, 12],
        -size => [100, 13],
    );

    $FindDlg->AddTextfield (
        -name => "FindDlg_Text",
        -pos  => [10, 30],
        -size => [150, 21],
    );

    $FindDlg->AddCheckbox (
        -name => "FindDlg_Case",
        -text => "Match case",
        -pos  => [10, 50],
        -size => [100, 21],
    );

    $FindDlg->AddCheckbox (
        -name => "FindDlg_Word",
        -text => "Find Whole word only",
        -pos  => [10, 70],
        -size => [100, 21],
    );

    $FindDlg->AddCheckbox (
        -name => "FindDlg_REGEX",
        -text => "Regular expression",
        -pos  => [10, 90],
        -size => [75, 21],
    );

    $FindDlg->AddButton (
        -name => "FindDlg_Forward",
        -text => "&Forward",
        -pos  => [180, 10],
        -size => [75 , 21],
    );

    $FindDlg->AddButton (
        -name => "FindDlg_Backware",
        -text => "&Backware",
        -pos  => [180, 40],
        -size => [75 , 21],
    );

    $FindDlg->AddButton (
        -name => "FindDlg_Close",
        -text => "C&lose",
        -pos  => [180, 70],
        -size => [75 , 21],
    );

    return $FindDlg;
}


sub FindDlg_Forward_Click {
    my $text = $FindDlg->FindDlg_Text->Text();
    my $flag = 0;

    $flag |= Win32::GUI::Scintilla::SCFIND_MATCHCASE
        if ($FindDlg->FindDlg_Case->Checked());
    $flag |= Win32::GUI::Scintilla::SCFIND_WHOLEWORD
        if ($FindDlg->FindDlg_Word->Checked());
    $flag |= Win32::GUI::Scintilla::SCFIND_REGEXP
        if ($FindDlg->FindDlg_REGEX->Checked());

    if ($Editor->FindAndSelect ($text, $flag, 1, 1) == -1)
    {
        Win32::GUI::MessageBox($FindDlg, "Text not found", "Find...");
    }

    return 0;
}

sub FindDlg_Backware_Click {
    my $text = $FindDlg->FindDlg_Text->Text();
    my $flag = 0;

    $flag |= Win32::GUI::Scintilla::SCFIND_MATCHCASE
        if ($FindDlg->FindDlg_Case->Checked());
    $flag |= Win32::GUI::Scintilla::SCFIND_WHOLEWORD
        if ($FindDlg->FindDlg_Word->Checked());
    $flag |= Win32::GUI::Scintilla::SCFIND_REGEXP
        if ($FindDlg->FindDlg_REGEX->Checked());

    if ($Editor->FindAndSelect ($text, $flag, -1, 1) == -1)
    {
        Win32::GUI::MessageBox($FindDlg, "Text not found", "Find...");
    }

    return 0;
}

sub FindDlg_Close_Click {
    $FindDlg->Hide();
    return 0;
}

sub FindDlg_Terminate {
    return FindDlg_Close_Click();
}

