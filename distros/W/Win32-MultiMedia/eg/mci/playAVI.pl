use Win32::MultiMedia::Mci;

$mci = Win32::MultiMedia::Mci->open("count.avi");
$mci->play("wait","repeat");
$mci->close;
