use Tk;
use UpDown;

my $mw = MainWindow->new();
$obj = $mw->UpDown(-height => 50, -width => 50, -relief => 'sunken', -bg => 'darkgreen', -fg => 'white', -initdigit => '1', -enddigit => '10', -step => 1, -beep => 1);
$obj->pack();

MainLoop;
