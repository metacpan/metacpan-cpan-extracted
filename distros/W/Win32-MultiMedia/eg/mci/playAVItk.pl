use Win32::MultiMedia::Mci;
use Tk;
$mw = MainWindow->new();
$win = $mw->Frame(-width=>200,-height=>200)->form(-top=>["%0"],-left=>["%0"]);

$mci = Win32::MultiMedia::Mci->open("count.avi", parent=>hex($win->id), style=>"child");
#$mci = Win32::MultiMedia::Mci->open("count.avi", parent=>hex($win->id), style=>"overlapped");
#$mci = Win32::MultiMedia::Mci->open("count.avi", parent=>hex($win->id), style=>"popup");

$mw->Button(-text=>"Repeat",-command=>[sub{$mci->play("repeat")}])
      ->form(-bottom=>["%100"],-left=>["%0"]);

$mw->Button(-text=>"Step 1", -command=>[sub{$mci->step}])
      ->form(-bottom=>["%100"],-left=>["%25"]);

$mw->Button(-text=>"Step -1", -command=>[sub{$mci->step("reverse")}])
      ->form(-bottom=>["%100"],-left=>["%55"]);

$mw->Button(-text=>"Stop", -command=>[sub{$mci->stop}])
      ->form(-bottom=>["%100"],-right=>["%100"]);

MainLoop;
$mci->close;
