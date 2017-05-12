use Tk;
use Win32::HideConsole;
	
hide_console;
	
my $main_window = MainWindow->new();
$main_window->Label(-text => 'A GUI app with the console hidden!',
		    -font => 'arial 14')->pack(-side => 'top');
$main_window->MainLoop();
