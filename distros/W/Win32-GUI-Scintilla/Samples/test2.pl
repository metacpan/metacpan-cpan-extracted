# perl -w
use Win32::GUI;
use Win32::GUI::Scintilla;
use Win32::GUI::Scintilla::Perl;

# main Window
$Window = new Win32::GUI::Window (
    -name     => "Window",
    -title    => "Scintilla test",
    -pos      => [100, 100],
    -size     => [400, 400],
) or die "new Window";

# Create Scintilla Edit Window
# $Edit = new Win32::GUI::Scintilla  (
#               -parent  => $Window,
# Or
$Edit = $Window->AddScintillaPerl  (
               -name    => "Edit",
               -pos     => [0, 0],
               -size    => [400, 400],
               -text    => "my \$Test\n",
) or die "new Edit";

# Call Some method
$Edit->AddText ("if (\$i == 1) {\n \$i++;\n}\n");

# Event loop
$Window->Show();
Win32::GUI::Dialog();

# Main window event handler
sub Window_Terminate {
 return -1;
}

# Main window resize
sub Window_Resize {

  if (defined $Window) {
    ($width, $height) = ($Window->GetClientRect)[2..3];
    $Edit->Resize ($width, $height);
  }
}

# Scintilla Event Notification
sub Edit_Notify {

  my (%evt) = @_;
  print "Edit Notify = ", %evt, "\n";
}

