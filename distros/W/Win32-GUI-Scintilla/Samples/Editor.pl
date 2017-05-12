# Perl Editor
#-----------------------------------------------------------------------
# perl -v
use strict;
use Cwd;
use Win32::GUI;
use Win32::GUI::Scintilla;

my $VERSION = "1.0alpha1";
my $CurrentFile = "";
my $Directory = cwd;

my %faces = ( 'times'  => 'Times New Roman',
              'mono'   => 'Courier New',
              'helv'   => 'Lucida Console',
              'lucida' => 'Lucida Console',
              'other'  => 'Comic Sans MS',
              'size'   => '10',
              'size2'  => '9',
              'backcol'=> '#FFFFFF',
            );

my $PERL_KEYWORD = q{
NULL __FILE__ __LINE__ __PACKAGE__ __DATA__ __END__ AUTOLOAD
BEGIN CORE DESTROY END EQ GE GT INIT LE LT NE CHECK abs accept
alarm and atan2 bind binmode bless caller chdir chmod chomp chop
chown chr chroot close closedir cmp connect continue cos crypt
dbmclose dbmopen defined delete die do dump each else elsif endgrent
endhostent endnetent endprotoent endpwent endservent eof eq eval
exec exists exit exp fcntl fileno flock for foreach fork format
formline ge getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname
gethostent getlogin getnetbyaddr getnetbyname getnetent getpeername
getpgrp getppid getpriority getprotobyname getprotobynumber getprotoent
getpwent getpwnam getpwuid getservbyname getservbyport getservent
getsockname getsockopt glob gmtime goto grep gt hex if index
int ioctl join keys kill last lc lcfirst le length link listen
local localtime lock log lstat lt m map mkdir msgctl msgget msgrcv
msgsnd my ne next no not oct open opendir or ord our pack package
pipe pop pos print printf prototype push q qq qr quotemeta qu
qw qx rand read readdir readline readlink readpipe recv redo
ref rename require reset return reverse rewinddir rindex rmdir
s scalar seek seekdir select semctl semget semop send setgrent
sethostent setnetent setpgrp setpriority setprotoent setpwent
setservent setsockopt shift shmctl shmget shmread shmwrite shutdown
sin sleep socket socketpair sort splice split sprintf sqrt srand
stat study sub substr symlink syscall sysopen sysread sysseek
system syswrite tell telldir tie tied time times tr truncate
uc ucfirst umask undef unless unlink unpack unshift untie until
use utime values vec wait waitpid wantarray warn while write
x xor y
};


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
my $Window = new Win32::GUI::Window (
                   -name     => "Window",
                   -title    => "Perl Editor",
                   -pos      => [100, 100],
                   -size     => [400, 400],
                   -menu     => $Menu,
                   ) or die "new Window";

# Create Scintilla Edit Window
# $Edit = new Win32::GUI::Scintilla  (
#               -parent  => $Window,
my $Editor = $Window->AddScintilla  (
                        -name    => "Editor",
                        -pos     => [0, 0],
                        -size    => [400, 400],
                        -addexstyle => WS_EX_CLIENTEDGE,
                        ) or die "new Edit";
# Init editor
InitEditor();

# Create FindDlg window
my $FindDlg = CreateFindDlg ();

# Event loop
$Window->Show();
Win32::GUI::Dialog();

# Free FindDlg
$FindDlg->CloseWindow();


sub InitEditor {

  # Set Perl Lexer
  $Editor->SetLexer(Win32::GUI::Scintilla::SCLEX_PERL);

  # Set Perl Keyword
  $Editor->SetKeyWords(0, $PERL_KEYWORD);

  # Folder ????
  $Editor->SetProperty("fold", "1");
  $Editor->SetProperty("tab.timmy.whinge.level", "1");

  # Indenetation
  $Editor->SetIndentationGuides(1);
  $Editor->SetUseTabs(1);
  $Editor->SetTabWidth(3);
  $Editor->SetIndent(3);

  # Edge Mode
  $Editor->SetEdgeMode(Win32::GUI::Scintilla::EDGE_LINE); #Win32::GUI::Scintilla::EDGE_BACKGROUND
  $Editor->SetEdgeColumn(80);

  # Define margin
  # $Editor->SetMargins(0,0);
  $Editor->SetMarginTypeN(1, Win32::GUI::Scintilla::SC_MARGIN_NUMBER);
  $Editor->SetMarginWidthN(1, 25);

  $Editor->SetMarginTypeN(2, Win32::GUI::Scintilla::SC_MARGIN_SYMBOL);
  $Editor->SetMarginMaskN(2, Win32::GUI::Scintilla::SC_MASK_FOLDERS);
  $Editor->SetMarginSensitiveN(2, 1);
  $Editor->SetMarginWidthN(2, 12);

  # Define marker
  $Editor->MarkerDefine(Win32::GUI::Scintilla::SC_MARKNUM_FOLDEREND,     Win32::GUI::Scintilla::SC_MARK_BOXPLUSCONNECTED);
  $Editor->MarkerSetFore(Win32::GUI::Scintilla::SC_MARKNUM_FOLDEREND, '#FFFFFF');
  $Editor->MarkerSetBack(Win32::GUI::Scintilla::SC_MARKNUM_FOLDEREND, '#000000');
  $Editor->MarkerDefine(Win32::GUI::Scintilla::SC_MARKNUM_FOLDEROPENMID, Win32::GUI::Scintilla::SC_MARK_BOXMINUSCONNECTED);
  $Editor->MarkerSetFore(Win32::GUI::Scintilla::SC_MARKNUM_FOLDEROPENMID, '#FFFFFF');
  $Editor->MarkerSetBack(Win32::GUI::Scintilla::SC_MARKNUM_FOLDEROPENMID, '#000000');
  $Editor->MarkerDefine(Win32::GUI::Scintilla::SC_MARKNUM_FOLDERMIDTAIL, Win32::GUI::Scintilla::SC_MARK_TCORNER);
  $Editor->MarkerSetFore(Win32::GUI::Scintilla::SC_MARKNUM_FOLDERMIDTAIL, '#FFFFFF');
  $Editor->MarkerSetBack(Win32::GUI::Scintilla::SC_MARKNUM_FOLDERMIDTAIL, '#000000');
  $Editor->MarkerDefine(Win32::GUI::Scintilla::SC_MARKNUM_FOLDERTAIL,    Win32::GUI::Scintilla::SC_MARK_LCORNER);
  $Editor->MarkerSetFore(Win32::GUI::Scintilla::SC_MARKNUM_FOLDERTAIL, '#FFFFFF');
  $Editor->MarkerSetBack(Win32::GUI::Scintilla::SC_MARKNUM_FOLDERTAIL, '#000000');
  $Editor->MarkerDefine(Win32::GUI::Scintilla::SC_MARKNUM_FOLDERSUB,     Win32::GUI::Scintilla::SC_MARK_VLINE);
  $Editor->MarkerSetFore(Win32::GUI::Scintilla::SC_MARKNUM_FOLDERSUB, '#FFFFFF');
  $Editor->MarkerSetBack(Win32::GUI::Scintilla::SC_MARKNUM_FOLDERSUB, '#000000');
  $Editor->MarkerDefine(Win32::GUI::Scintilla::SC_MARKNUM_FOLDER,        Win32::GUI::Scintilla::SC_MARK_BOXPLUS);
  $Editor->MarkerSetFore(Win32::GUI::Scintilla::SC_MARKNUM_FOLDER, '#FFFFFF');
  $Editor->MarkerSetBack(Win32::GUI::Scintilla::SC_MARKNUM_FOLDER, '#000000');
  $Editor->MarkerDefine(Win32::GUI::Scintilla::SC_MARKNUM_FOLDEROPEN,    Win32::GUI::Scintilla::SC_MARK_BOXMINUS);
  $Editor->MarkerSetFore(Win32::GUI::Scintilla::SC_MARKNUM_FOLDEROPEN, '#FFFFFF');
  $Editor->MarkerSetBack(Win32::GUI::Scintilla::SC_MARKNUM_FOLDEROPEN, '#000000');

  # Define Style
  $Editor->StyleClearAll();

  # Global default styles for all languages
  $Editor->StyleSetSpec(Win32::GUI::Scintilla::STYLE_DEFAULT,     "face:$faces{'mono'},size:$faces{'size'}");
  $Editor->StyleSetSpec(Win32::GUI::Scintilla::STYLE_LINENUMBER,  "back:#C0C0C0,face:$faces{mono}");
  $Editor->StyleSetSpec(Win32::GUI::Scintilla::STYLE_CONTROLCHAR, "face:$faces{mono}");
  $Editor->StyleSetSpec(Win32::GUI::Scintilla::STYLE_BRACELIGHT,  "fore:#FFFFFF,back:#0000FF,bold");
  $Editor->StyleSetSpec(Win32::GUI::Scintilla::STYLE_BRACEBAD,    "fore:#000000,back:#FF0000,bold");

  # White space
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_DEFAULT, "fore:#808080,face:$faces{'mono'}");
  # Error
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_ERROR , "fore:#0000FF");
  # Comment
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_COMMENTLINE, "fore:#007F00");
  # POD: = at beginning of line
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_POD, "fore:#004000,back:#E0FFE0,eolfilled");
  # Number
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_NUMBER, "fore:#007F7F");
  # Keyword
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_WORD , "fore:#00007F,bold");
  # Double quoted string
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_STRING, "fore:#7F007F,face:$faces{'mono'},italic");
  # Single quoted string
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_CHARACTER, "fore:#7F0000,face:$faces{'mono'},italic");
  # Symbols / Punctuation. Currently not used by LexPerl.
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_PUNCTUATION, "fore:#00007F,bold");
  # Preprocessor. Currently not used by LexPerl.
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_PREPROCESSOR, "fore:#00007F,bold");
  # Operators
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_OPERATOR , "bold");
  # Identifiers (functions, etc.)
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_IDENTIFIER , "fore:#000000");
  # Scalars: $var
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_SCALAR, "fore:#000000,back:#FFE0E0");
  # Array: @var
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_ARRAY, "fore:#000000,back:#FFFFE0");
  # Hash: %var
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_HASH, "fore:#000000,back:#FFE0FF");
  # Symbol table: *var
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_SYMBOLTABLE, "fore:#000000,back:#E0E0E0");
  # Regex: /re/ or m{re}
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_REGEX, "fore:#000000,back:#A0FFA0");
  # Substitution: s/re/ore/
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_REGSUBST, "fore:#000000,back:#F0E080");
  # Long Quote (qq, qr, qw, qx) -- obsolete: replaced by qq, qx, qr, qw
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_LONGQUOTE, "fore:#FFFF00,back:#8080A0");
  # Back Ticks
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_BACKTICKS, "fore:#FFFF00,back:#A08080");
  # Data Section: __DATA__ or __END__ at beginning of line
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_DATASECTION, "#600000,back:#FFF0D8,eolfilled");
  # Here-doc (delimiter)
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_HERE_DELIM, "fore:#000000,back:#DDD0DD");
  # Here-doc (single quoted, q)
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_HERE_Q, "fore:#7F007F,back:#DDD0DD,eolfilled,notbold");
  # Here-doc (double quoted, qq)
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_HERE_QQ, "fore:#7F007F,back:#DDD0DD,eolfilled,bold");
  # Here-doc (back ticks, qx)
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_HERE_QX, "fore:#7F007F,back:#DDD0DD,eolfilled,italics");
  # Single quoted string, generic
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_STRING_Q, "fore:#7F007F,notbold");
  # qq = Double quoted string
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_STRING_QQ, "fore:#7F007F,italic");
  # qx = Back ticks
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_STRING_QX, "fore:#FFFF00,back:#A08080");
  # qr = Regex
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_STRING_QR, "fore:#000000,back:#A0FFA0");
  # qw = Array
  $Editor->StyleSetSpec (Win32::GUI::Scintilla::SCE_PL_STRING_QW, "fore:#000000,back:#FFFFE0");
}

sub Editor_Notify {

  my (%evt) = @_;

  if ($evt{-code} == Win32::GUI::Scintilla::SCN_UPDATEUI)
  {
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
  elsif ($evt{-code} == Win32::GUI::Scintilla::SCN_MARGINCLICK)
  {
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
}

#######################################################################
#
#  File Menu
#
#######################################################################

sub FileNew_Click {

  $Editor->NewFile();
  $CurrentFile = "";
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
     Win32::GUI::MessageBox (0, "ERROR : ".Win32::GUI::CommDlgExtendedError(),
                            "GetOpenFileName Error");
  }
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

}

sub FileDirectory_Click {

  my $ret = Win32::GUI::BrowseForFolder (
                        -title      => "Select default directory",
                        -directory  => $Directory,
                        -folderonly => 1,
                        );
  $Directory = $ret if ($ret);
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
}

sub EditRedo_Click {
  $Editor->Redo();
}

sub EditCut_Click {
  $Editor->Cut();
}

sub EditCopy_Click {
  $Editor->Copy();
}

sub EditPaste_Click {
  $Editor->Paste();
}

sub EditSelectAll_Click {
  $Editor->SelectAll();
}

sub EditClear_Click {
  $Editor->Clear();
}

sub EditFind_Click {

  $FindDlg->Show();
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
                  -name  => "FindDlg_Label",
                  -text  => "Find what...",
                  -pos   => [10, 12],
                  -size  => [100, 13],
          );

  $FindDlg->AddTextfield (
                  -name  => "FindDlg_Text",
                  -pos   => [10, 30],
                  -size  => [150, 21],
          );

  $FindDlg->AddCheckbox (
                  -name  => "FindDlg_Case",
                  -text  => "Match case",
                  -pos   => [10, 50],
                  -size  => [100, 21],
          );

  $FindDlg->AddCheckbox (
                  -name  => "FindDlg_Word",
                  -text  => "Find Whole word only",
                  -pos   => [10, 70],
                  -size  => [100, 21],
          );

  $FindDlg->AddCheckbox (
                  -name  => "FindDlg_REGEX",
                  -text  => "Regular expression",
                  -pos   => [10, 90],
                  -size  => [75, 21],
          );

  $FindDlg->AddButton (
                  -name  => "FindDlg_Forward",
                  -text  => "&Forward",
                  -pos   => [180, 10],
                  -size  => [75 , 21],
          );

  $FindDlg->AddButton (
                  -name  => "FindDlg_Backware",
                  -text  => "&Backware",
                  -pos   => [180, 40],
                  -size  => [75 , 21],
          );

  $FindDlg->AddButton (
                  -name  => "FindDlg_Close",
                  -text  => "C&lose",
                  -pos   => [180, 70],
                  -size  => [75 , 21],
          );

  return $FindDlg;
}


sub FindDlg_Forward_Click {

  my $text = $FindDlg->FindDlg_Text->Text();
  my $flag = 0;


  $flag |= Win32::GUI::Scintilla::SCFIND_MATCHCASE if ($FindDlg->FindDlg_Case->Checked());
  $flag |= Win32::GUI::Scintilla::SCFIND_WHOLEWORD if ($FindDlg->FindDlg_Word->Checked());
  $flag |= Win32::GUI::Scintilla::SCFIND_REGEXP    if ($FindDlg->FindDlg_REGEX->Checked());

  if ($Editor->FindAndSelect ($text, $flag, 1, 1) == -1)
  {
    Win32::GUI::MessageBox($FindDlg, "Text not found", "Find...");
  }

  0;
}

sub FindDlg_Backware_Click {

  my $text = $FindDlg->FindDlg_Text->Text();
  my $flag = 0;

  $flag |= Win32::GUI::Scintilla::SCFIND_MATCHCASE if ($FindDlg->FindDlg_Case->Checked());
  $flag |= Win32::GUI::Scintilla::SCFIND_WHOLEWORD if ($FindDlg->FindDlg_Word->Checked());
  $flag |= Win32::GUI::Scintilla::SCFIND_REGEXP    if ($FindDlg->FindDlg_REGEX->Checked());

  if ($Editor->FindAndSelect ($text, $flag, -1, 1) == -1)
  {
    Win32::GUI::MessageBox($FindDlg, "Text not found", "Find...");
  }
  0;
}

sub FindDlg_Close_Click {

  $FindDlg->Hide();
  0;
}

sub FindDlg_Terminate {

  return FindDlg_Close_Click();
}

