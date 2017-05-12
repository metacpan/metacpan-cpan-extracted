# perl -w
#
#  Hosting WebBrowser
#    - Create a WebBrowser control and get a Win32::OLe handler.
#    - Navigate on Google.fr
#    - When document loaded (DoucmentComplete event), set Win32::GUI::AxWindow in serach edit then submit
#       If Google Html page change, must change Item index.
#
use Cwd;
use Win32::GUI;
use Win32::OLE;
use Win32::GUI::AxWindow;

# main Window
$Window = new Win32::GUI::Window (
    -title    => "Win32::GUI::AxWindow and Win32::OLE",
    -pos     => [100, 100],
    -size    => [400, 400],
    -name     => "Window",
) or die "new Window";

# Create AxWindow with a webbrowser
$Control = new Win32::GUI::AxWindow  (
               -parent  => $Window,
               -name    => "Control",
               -pos     => [0, 100],
               -size    => [400, 300],
               -control => "Shell.Explorer.2",
 ) or die "new Control";

# Register Event
$Control->RegisterEvent ("DocumentComplete", "DocumentComplete_Event" );

# Get Ole object
$OLEControl = $Control->GetOLE();

# Navigate to google
$Control->CallMethod("Navigate", 'http://www.google.fr/');

# Event loop
$Window->Show();
Win32::GUI::Dialog();

# Event handler
sub DocumentComplete_Event { 
  
  # print $OLEControl->{LocationUrl}, "\n";
  return unless $OLEControl->{LocationUrl} eq 'http://www.google.fr/';
  
  print "Search Win32::GUI::AXWindow\n";

  my $all = $OLEControl->{Document}->{all};

  # List all HTML TAG
  # for $i (0..$all->length) {
  #  my $item = $all->item($i);
  #   print "$i = ", $item->outerHTML , "\n\n";    	
  # }

  # Input text
  my $inputText = $all->item(49);    
  $inputText->{value} = "Win32::GUI::AxWindow";

  # Submit
  my $Submit     = $all->item(55);
  $Submit->click;
}	

# Main window event handler

sub Window_Terminate {

  # Release all before destroy window
  undef $OLEControl;
  # $Control->Release();

  return -1;
}

sub Window_Resize {

  if (defined $Window) {
    ($width, $height) = ($Window->GetClientRect)[2..3];
    $Control->Move   (0, 0);
    $Control->Resize ($width, $height);
  }
}
